.model tiny
.code

org 100h

locals @@

;--------------------------------------------------------------------------------

FS_STYLE_LENGTH     equ 18

CMD_TAIL_LEN_INDEX  equ 80h
CMD_TAIL_INDEX      equ 82h

ZERO_BG_COLOR       equ 0afh
GRAY_BKGND_COLOR    equ 070h
SCREEN_WIDTH        equ 80
SCREEN_HEIGHT       equ 23
VIDEO_SEG           equ 0b800h

FRAME_START_LINE    equ 5

FRAME_COLOR         equ 0ch
FRAME_WIDTH         equ 40
FRAME_HEIGHT        equ 6

HORIZ_LINE          equ 0cdh
VERT_LINE           equ 0bah
LU_CORNER           equ 0c9h
RU_CORNER           equ 0bbh
LD_CORNER           equ 0c8h
RD_CORNER           equ 0bch

GRAY_BG             equ 70h
BLACK               equ 00h
PINK                equ 05h
BRT_RED             equ 0ch
BLINKING            equ 80h

; --------------------------------- MACROS ---------------------------------

;--------------------------------------------------------------------------------
; Short:   draws symbol in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      symbol = symbol code in ASCII
; Out:     DI++ (DI = pos after that symbol in vram)
; Destroy: AX
;--------------------------------------------------------------------------------

DrawSymbol macro symbol

        mov ax, symbol
        stosw
        endm

; ---------------------------------- CODE ----------------------------------

Start:
    call Main
    call Exit

; ---------------------------------- DATA ----------------------------------

FrameStyle struc
    TextColor           dw ?
    BGColor             dw ?
    LUCorner            dw ?
    UHorizLine          dw ?
    RUCorner            dw ?
    LVertLine           dw ?
    RVertLine           dw ?
    LDCorner            dw ?
    DHorizLine          dw ?
    RDCorner            dw ?
FrameStyle ends

;//==========================================================================================

Main proc

    mov ax, VIDEO_SEG
    ; es - extended segment
    mov es, ax

    call GetCmdLine

    call ParseCmdLine
    ; AX -> frame params

    push dx bx
    mov bx, FS_STYLE_LENGTH
    mul bx
    add ax, offset DefaultFS
    pop bx dx

    push si

    ; SI = AX (as ax can not be indexed)
    mov si, ax

    ; AX = &Text
    pop ax

    ; di = 0
    xor di, di

    ; save values
    push ax si
    ; arguments
    push bx dx
    call GetFrameLeftUpperCornerPos
    ; no need to return sp --> pascal type function
    pop si ax

    ; save frame style ptr
    push si

    ; 2nd ax byte = color in vram
    ; text color
    push [si + TextColor]

    ; get &Text from ax
    mov si, ax

    ; get text color
    pop ax

    push bx di
    call DrawCenteredText
    pop di bx

    ; get frame style ptr
    pop si

; FIXME - maybe no need to save si (?)
    push di si

    push si dx bx di
    call DrawFrame
    ; have to return sp --> c_decl type function
    add sp, 8

    pop si di

    ; BackGround Color
    mov ax, [si + BGColor]

    call DrawFrameBackground

    ret
Main endp

;--------------------------------------------------------------------------------
; Short:   gets cmd line and it's length into registers
; Exp:     -
; In:      -
; Out:     CX = CmdTailLen
;          SI = &CmdTail
; Destroy: -
;--------------------------------------------------------------------------------

GetCmdLine proc

    ; CX = CmdTailLen - 1 (for the last \r)
    mov si, CMD_TAIL_LEN_INDEX
    mov byte ptr cl, [si]

    jcxz @@End
    dec cx
    @@End:

    ; SI = &CmdTail
    mov si, CMD_TAIL_INDEX

    ret
GetCmdLine endp

;--------------------------------------------------------------------------------
; Short:   Parses cmd line into text, its length, frame style, frame size
; Exp:     -
; In:      CX = CmdTailLen
;          SI = &CmdTail
; Out:     SI = &Text
;          AX = FrameStyle
;          BX = FrameWidth
;          CX = TextLen
;          DX = FrameHeight
; Destroy: DI
;--------------------------------------------------------------------------------

ParseCmdLine proc

    ; Get FrameStyle
    ; call SkipSpaces

    ; Get FrameStyle
    call GetInt
    call SkipSpaces

    push ax

    ; Get FrameWidth
    call GetInt
    mov bx, ax

    call SkipSpaces

    ; Get FrameHeight
    push bx
    call GetInt
    mov dx, ax
    pop bx

    call SkipSpaces

    mov ax, bx
    call MakeEven
    mov bx, ax

    pop ax

    ret
ParseCmdLine endp

;--------------------------------------------------------------------------------
; Short:   skips spaces
; Exp:     -
; In:      SI --> &String
;          CX = StringLen
; Out:     CX = StringLen - SpacesCount
;          SI --> first non-space symbol
; Destroy: -
;--------------------------------------------------------------------------------

;//TODO - make function
SkipSpaces proc


    inc si
    dec cx

    ret
SkipSpaces endp

;--------------------------------------------------------------------------------
; Short:   increments if number is odd
; Exp:     -
; In:      AX = any number
; Out:     AX = even number
; Destroy: -
;--------------------------------------------------------------------------------

MakeEven proc

    test ax, 01h
    jz @@EvenLen
    inc ax
    @@EvenLen:

    ret
MakeEven endp

;--------------------------------------------------------------------------------
; Short:   Gets an integer value from string (until the ' ')
; Exp:     -
; In:      CX = StringLen
;          SI --> String
; Out:     AX = integer value
;          SI --> pos of the ' ' in string
;          CX = length of left string
; Destroy: BX, DX, DI
;--------------------------------------------------------------------------------

GetInt proc

    ; if StringLen <= 0 --> end
    cmp cx, 0
    jle @@End

    ; dx = 0
    xor dx, dx

    ; ax = 0
    xor ax, ax

    @@Next:
        ; dl = curr symbol
        mov byte ptr dl, [si]

        ; end when not a digit
        call IsDigit
        cmp bx, 0
        je @@End

        ; save dl for mul
        mov di, dx

        ; ax *= 10
        mov bx, 10
        mul bx

        ; get value of digit
        sub di, '0'

        ; ax += digit
        add ax, di

        inc si

    loop @@Next

    @@End:

    ret
GetInt endp

;--------------------------------------------------------------------------------
; Short:   Check if given ASCII code represents an integer
; Exp:     -
; In:      DL = symbol
; Out:     BX = 0 if not a digit
;          BX = 1 if a digit
; Destroy: -
;--------------------------------------------------------------------------------

IsDigit proc

    ; bx = 0
    xor bx, bx

    cmp dl, '0'
    jl @@NotDigit

    cmp dl, '9'
    jg @@NotDigit

    inc bx
    ret

    @@NotDigit:

    ret
IsDigit endp

;--------------------------------------------------------------------------------
;                       PASCAL TYPE
; Short:   moves DI to the frame left upper corner
; Exp:     DI = 0 (start of vram)
; In:      push in stack in order:
;          [0] = frame width  (BX)
;          [1] = frame height (DX)
; Out:     DI = lu corner pos
; Destroy: AX, SI
;--------------------------------------------------------------------------------

GetFrameLeftUpperCornerPos proc

    push bp
    mov bp, sp

    mov bx, [bp + 6]
    mov dx, [bp + 4]

    ; di = center of the screen
    mov di, (SCREEN_WIDTH * 2 * (SCREEN_HEIGHT / 2) + SCREEN_WIDTH)

    ; move left half a frame
    sub di, bx

    ; move up half a frame
    push dx

    ; if height is odd --> add one to divide by 2
    mov ax, dx
    call MakeEven

    mov si, SCREEN_WIDTH
    mul si

    sub di, ax

    pop dx

    pop bp
    ret 4
GetFrameLeftUpperCornerPos endp

;--------------------------------------------------------------------------------
;                   C-DECL TYPE
; Short:   Draws a centered const size frame
; Exp:     DF = 0
; In:      push in stack in order:
;          [3] = position of left upper corner of a frame (DI)
;          [2] = frame width (BX)
;          [1] = frame height (DX)
;          [0] --> frame style format (SI)
; Out:     -
; Destroy: AX, CX, DI, SI
; Note:    add sp, 8 after usage
;--------------------------------------------------------------------------------

DrawFrame proc

    push bp
    mov bp, sp

    ; get arguments from stack
    mov di, [bp + 4]
    mov bx, [bp + 6]
    mov dx, [bp + 8]
    mov si, [bp + 10]

    ; save lu corner pos in stack
    push di

    ; Draw Left Upper corner
    mov ax, [si + LuCorner]
    stosw

    ; AX = upper horizontal line symbol
    mov ax, [si + UHorizLine]
    call DrawHorizontalLine

    ; Draw Right Upper corner
    mov ax, [si + RuCorner]
    stosw

    push si

    ; move back to the left side
    ; -FRAME_WIDTH * 2
    mov si, bx
    shl si, 1
    sub di, si

    ; and go to newline to skip corner
    add di, (SCREEN_WIDTH * 2)

    pop si

    ; AX = left vertical line symbol
    mov ax, [si + LVertLine]
    call DrawVerticalLine

    ; Draw Left Down corner
    mov ax, [si + LdCorner]
    stosw

    ; AX = down horizontal line symbol
    mov ax, [si + DHorizLine]
    call DrawHorizontalLine

    ; Draw Right Down corner
    mov ax, [si + RdCorner]
    stosw

    ; get lu corner pos
    pop di

    ; move up below the right corner
    push bx

    ; bx = shift
    ; di = lu_corner_pos + (2 * (FRAME_WIDTH + SCREEN_WIDTH - 1))
    add bx, (SCREEN_WIDTH - 1)
    shl bx, 1
    add di, bx

    pop bx

    ; AX = right vertical line symbol
    mov ax, [si + RVertLine]
    call DrawVerticalLine

    pop bp
    ret
DrawFrame endp

;--------------------------------------------------------------------------------
; Short:   Draws horizontal frame line in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = start pos to draw line
;          BX = frame width
;          AX = symbol to write line with
; Out:     DI = end pos of newly drown line
; Destroy: CX
;--------------------------------------------------------------------------------

DrawHorizontalLine proc

    mov cx, bx
    sub cx, 2
    rep stosw

    ret
DrawHorizontalLine endp

;--------------------------------------------------------------------------------
; Short:   Draws vertical frame line in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = start pos to draw line
;          DX = frame height
;          AX = symbol to write line with
; Out:     DI = end pos of newly drown line
; Destroy: CX
;--------------------------------------------------------------------------------

DrawVerticalLine proc

    mov cx, dx
    sub cx, 2

    @@Next:
        mov es:[di], ax
        add di, (SCREEN_WIDTH * 2)
    loop @@Next

    ret
DrawVerticalLine endp

;--------------------------------------------------------------------------------
; Short:   Prints cmd line in vram in the center of the frame
; Exp:     DF = 0
; In:      DI = lu frame corner pos
;          CX = text length
;          SI --> text
;          AH = text color
; Out:     -
; Destroy: BX, CX, DI, SI
;--------------------------------------------------------------------------------

DrawCenteredText proc

    ; if TextLen <= 0 -> jump to the end
    cmp cx, 0
    jle @@End

    push si ax
    call SetWritingStartPos
    pop ax si

    call LoadText

    @@End:

    ret
DrawCenteredText endp

;--------------------------------------------------------------------------------
; Short:   Sets DI to a pos to write text
; Exp:
; In:      CX = text length
;          DI = lu frame corner pos
;          BX = frame width
;          DX = frame height
; Out:     DI = start pos for writing text
; Destroy: AX, BX, SI
;--------------------------------------------------------------------------------

SetWritingStartPos proc

    ; ---------- go to the frame center ------------

    ; move right half a frame
    add di, bx

    ; move down half a frame
    push dx

    ; if height is odd --> add one to divide by 2
    mov ax, dx
    call MakeEven
    sub ax, 2

    mov si, SCREEN_WIDTH
    mul si

    add di, ax

    pop dx

    ; --------------- shift left -----------------

    ; BX = shift to the left = StringLen
    mov bx, cx

    test bx, 01h

    jz @@EvenLen
        ; if CmdTailLen is odd: bx++ (shift one more)
        inc bx
    @@EvenLen:

    ; no need to div by 2, as there are 2 bytes in vram
    ; di = center - shift
    sub di, bx

    ret
SetWritingStartPos endp

;--------------------------------------------------------------------------------
; Short:   Loads the text to vram
; Exp:     ES = VideoSegment
;          DF = 0
; In:      DI = text start pos in vram
;          SI = text start pos in data
;          CX = text length
;          AH = text color
; Out:     -
; Destroy: CX, DI, SI
;--------------------------------------------------------------------------------

LoadText proc

    @@Next:
        lodsb
        stosw

    loop @@Next

    ret
LoadText endp

;--------------------------------------------------------------------------------
; Short:   Draws background for the frame
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = pos of the lu frame corner
;          BX = frame width
;          DX = frame height
;          AH = background color
; Out:     -
; Destroy: SI, DI, CX, BP
;--------------------------------------------------------------------------------

DrawFrameBackground proc

    ; si = iterator for lines
    mov si, dx

    ; bp = 2 * (SCREEN_WIDTH - FRAME_WIDTH)
    ; bp = shift for DI in loop
    mov bp, (2 * (SCREEN_WIDTH - FRAME_WIDTH))
    sub bp, bx
    shl bp, 1

    @@NextLine:
        ; cx = iterator for columns
        mov cx, bx

        @@NextSymbol:
            and byte ptr es:[di + 1], ZERO_BG_COLOR
            or  byte ptr es:[di + 1], ah

            add di, 2

        loop @@NextSymbol

        ; move to the next line start
        add di, bp

        dec si

    cmp si, 0
    jnz @@NextLine

    ret
DrawFrameBackground endp

;--------------------------------------------------------------------------------
; Short:   ends the program
; Exp:     -
; In:      -
; Out:     -
; Destroy: AX
;--------------------------------------------------------------------------------

Exit proc

    ; exit(0)
    mov ax, 4c00h
    ; int for DOS func call
    int 21h

    ret
Exit endp

;--------------------------------------------------------------------------------

.data

; 0           1         2     4       6   8       10
; [TEXT_COLOR][BG_COLOR][LUx2][UP_HOR][RU][L_VERT][]
; FrameStyle      db PINK, GRAY_BG
;                 db LU_CORNER, BRT_RED, HORIZ_LINE, BRT_RED, RU_CORNER, BRT_RED
;                 db VERT_LINE, BRT_RED, VERT_LINE, BRT_RED
;                 db LD_CORNER, BRT_RED, HORIZ_LINE, BRT_RED, RD_CORNER, BRT_RED

DefaultFS FrameStyle <(PINK * 100h), (GRAY_BG * 100h), (LU_CORNER + BRT_RED * 100h), (HORIZ_LINE + BRT_RED * 100h), (RU_CORNER + BRT_RED * 100h), (VERT_LINE + BRT_RED * 100h), (VERT_LINE + BRT_RED * 100h), (LD_CORNER + BRT_RED * 100h), (HORIZ_LINE + BRT_RED * 100h), (RD_CORNER + BRT_RED * 100h)>

; FrameStyles label FrameStyle
;     FrameStyle <BLACK, GRAY_BG, 0cdh, 0bah, 0c9h, 0bbh, 0c8h, 0bch>
;     FrameStyle <BLACK, GRAY_BG, 0cdh, 0bah, 0c9h, 0bbh, 0c8h, 0bch>
;     FrameStyle <BLACK, GRAY_BG, 0cdh, 0bah, 0c9h, 0bbh, 0c8h, 0bch>

;================================================================================

end     Start
