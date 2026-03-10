.model tiny
.code

org 100h

locals @@

;--------------------------------------------------------------------------------

GREEN_BG            equ 30h

MIN_FRAME_SIZE      equ 3d
MAX_FRAME_WIDTH     equ 80d
MAX_FRAME_HEIGHT    equ 20d
FS_STYLES_COUNT     equ 5

RESET_SYMBOL        equ 0720h
FRAME_ANIM_ITERS    equ 3
FS_STYLE_SIZE       equ 22

CMD_TAIL_LEN_INDEX  equ 80h
CMD_TAIL_INDEX      equ 82h

ZERO_BG_COLOR       equ 0afh
GRAY_BKGND_COLOR    equ 070h
SCREEN_WIDTH        equ 80
SCREEN_HEIGHT       equ 23
VIDEO_SEG           equ 0b800h

HEART               equ 03h
HORIZ_LINE          equ 0cdh
VERT_LINE           equ 0bah
LU_CORNER           equ 0c9h
RU_CORNER           equ 0bbh
LD_CORNER           equ 0c8h
RD_CORNER           equ 0bch
SPACE               equ ' '

GRAY_BG             equ 70h
BLACK               equ 00h
WHITE               equ 0fh
PINK                equ 0dh
PINK_BG             equ 50h
BRT_RED             equ 0ch
BLINKING            equ 80h
BLUE                equ 09h
BLUE_BG             equ 10h

; ------------------------------- DATA TYPES -------------------------------

FrameStyle struc
    TextColor           dw ?
    BGColor             dw ?
    LUCorner            dw ?
    UHorizLine          dw ?
    RUCorner            dw ?
    LVertLine           dw ?
    MHorizLine          dw ?
    RVertLine           dw ?
    LDCorner            dw ?
    DHorizLine          dw ?
    RDCorner            dw ?
FrameStyle ends

; ---------------------------------- CODE ----------------------------------

Start:
    call Main
    jmp  Exit

;=================================================================================

Main proc

    mov ax, VIDEO_SEG
    mov es, ax

    call GetCmdLine

    ; push args in direct order (pascal type)
    push cx si
    call ParseCmdLine
    ; stack was returned to it's state by the function (pascal type)

    ; push args in reversed order (c-decl type)
    push si dx cx bx ax
    call DrawAnimation
    ; have to return stack back after pushes (c-decl type)
    add sp, 10

    ret

Main endp

;--------------------------------------------------------------------------------
;                           C-DECL TYPE
; Short:   Draws animation of a frame growing and shredding
; In:      push in stack in reverse order (first arg pushed last):
;          [4] --> FrameStyle struct    (AX)
;          [3] = starting frame width   (BX)
;          [2] = text length            (CX)
;          [1] = starting frame height  (DX)
;          [0] --> text                 (SI)
; Destroy: AX, SI, DI
; Note: have to add 10 to sp after usage
;--------------------------------------------------------------------------------

DrawAnimation proc

    push bp
    mov bp, sp

    ; --> FrameStyle struct
    mov ax, [bp + 4]
    ; starting frame width
    mov bx, [bp + 6]
    ; text length
    mov cx, [bp + 8]
    ; starting frame height
    mov dx, [bp + 10]
    ; --> text
    mov si, [bp + 12]

    xchg si, ax

    ; bp will used for iterations
    mov bp, FRAME_ANIM_ITERS

    mov word ptr [AnimationStep], 2
    call AnimationLoop

    mov bp, FRAME_ANIM_ITERS

    mov word ptr [AnimationStep], -2
    call AnimationLoop

    pop bp

    ret

DrawAnimation endp

;--------------------------------------------------------------------------------
; Short:   Body for the DrawAnimation function,
;          draws an animation of a frame growing/shredding (depends on AnimationStep)
; Exp:     [AnimationStep] = increment for size of a frame (scan be negative)
; In:      BP = number of iterations
;          AX --> FrameStyle struct
;          BX = starting frame width
;          CX = text length
;          DX = starting frame height
;          SI --> text
; Destroy: BX, DX, BP, DI
;--------------------------------------------------------------------------------

AnimationLoop proc

    @@LoopNext:
        push ax cx di
        call ClearScreen
        pop di cx ax

        push ax bx cx si bp
        call DrawScreen
        pop bp si cx bx ax

        push bx cx
        call WaitTime
        pop cx bx

        add bx, [AnimationStep]
        add dx, [AnimationStep]

    dec bp
    cmp bp, 0
    jge @@LoopNext

    ret

AnimationLoop endp

;--------------------------------------------------------------------------------
; Short:   Draws frame, it's bg and text on the screen
; In:      BX = frame width
;          DX = frame height
;          CX = text length
;          SI --> frame style
;          AX --> text
; Destroy: AX, BX, CX, SI, DI
;--------------------------------------------------------------------------------

DrawScreen proc

    ; di = 0
    xor di, di

    ; save values
    push ax si
    call GetFrameLeftUpperCornerPos
    pop si ax

    push ax cx di si
    call DrawFrame
    pop si di cx ax

; get text color (prepare args for DrawText)

    push bx
    ; BX = frame style
    mov bx, si
    ; SI --> text
    mov si, ax
    ; AX = color
    mov ax, [bx + TextColor]
    pop bx

    ; tail call --> ret of inside function will return from our function
    jmp DrawCenteredText

    ret

DrawScreen endp

;--------------------------------------------------------------------------------
; Short:   Clears the screen
; Exp:     DF = 0
; Destroy: AX, CX, DI
;--------------------------------------------------------------------------------

ClearScreen proc

    ; AX = space with gray color ob black bg
    mov ax, RESET_SYMBOL
    xor di, di
    mov cx, (SCREEN_WIDTH * SCREEN_HEIGHT)

    rep stosw

    ret

ClearScreen endp

;--------------------------------------------------------------------------------
; Short:   Waits some time by making loops
; Destroy: BX CX
;--------------------------------------------------------------------------------

WaitTime proc

    mov bx, 2

    @@NextBigLoop:

    xor cx, cx
    dec cx

    @@Next:
        inc cx
        dec cx
    loop @@Next

    dec bx
    cmp bx, 0
    jge @@NextBigLoop

    ret

WaitTime endp

;--------------------------------------------------------------------------------
; Short:   Gets cmd line and it's length into registers
; Out:     CX = CmdTailLen
;          SI = &CmdTail
;--------------------------------------------------------------------------------

GetCmdLine proc

    ; CX = CmdTailLen - 1 (for the last \r)
    xor ch, ch
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
;                           PASCAL TYPE
; Short:   Parses cmd line into text, its length, frame style, frame size
; In:      push in stack in order:
;          [0] = CmdTailLen (CX)
;          [1] --> CmdTail  (SI)
; Out:     SI = &Text
;          AX = FrameStyle
;          BX = FrameWidth
;          CX = TextLen
;          DX = FrameHeight
; Destroy: DI
;--------------------------------------------------------------------------------

ParseCmdLine proc

    push bp
    mov bp, sp

    ; --> CmdTail
    mov si, [bp + 4]
    ; CmdTailLen
    mov cx, [bp + 6]

    call SkipSpaces

    ; Get FrameStyle index
    call GetInt
    call SkipSpaces
    push bx dx
    ; Get FrameStyleStruct ptr
    call GetFrameStyle
    pop dx bx

    push ax
    call GetFrameSize
    pop ax

    pop bp

    ; return and get stack back to it's state
    ; (add 4 for 2 arguments of 2 bytes)
    ret 4

ParseCmdLine endp

;--------------------------------------------------------------------------------
; Short:   Parse cmd line to get frame width and frame height
; In:      CX = cmd tail args end len
;          DS:[SI] --> cmd tail args
; Out:     BX = frame width
;          DX = frame height
; Destroy: AX
;--------------------------------------------------------------------------------

GetFrameSize proc

    ; Get FrameWidth
    call GetInt
    mov bx, ax

    ; check frame width for boundaries
    cmp bx, MIN_FRAME_SIZE
    jge @@FrameWidthIsOk
        mov bx, MIN_FRAME_SIZE

    cmp bx, MAX_FRAME_WIDTH
    jle @@FrameWidthIsOk
        mov bx, MAX_FRAME_WIDTH
    @@FrameWidthIsOk:

    call SkipSpaces

    ; Get FrameHeight
    push bx
    call GetInt
    pop bx
    mov dx, ax

    ; check frame height for boundaries
    cmp dx, MIN_FRAME_SIZE
    jge @@FrameHeightIsOk
        mov dx, MIN_FRAME_SIZE

    cmp bx, MAX_FRAME_HEIGHT
    jle @@FrameHeightIsOk
        mov bx, MAX_FRAME_HEIGHT

    @@FrameHeightIsOk:

    call SkipSpaces

    mov ax, bx
    call MakeEven
    mov bx, ax

    ret

GetFrameSize endp

;--------------------------------------------------------------------------------
; Short:   skips spaces
; In:      SI --> &String
;          CX = StringLen
; Out:     CX = StringLen - SpacesCount
;          SI --> first non-space symbol
;--------------------------------------------------------------------------------

SkipSpaces proc

    push bx

    ; check for 0 and negatives
    cmp cx, 0
    jle @@End

    @@Check:
    mov byte ptr bl, [si]
    cmp bl, ' '
    jne @@End
        inc si

    loop @@Check
    @@End:

    pop bx

    ret

SkipSpaces endp

;--------------------------------------------------------------------------------
; Short:   increments if number is odd
; In:      AX = any number
; Out:     AX = even number
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
; In:      CX = StringLen
;          SI --> String
; Out:     AX = integer value
;          SI --> pos of the ' ' in string
;          CX = length of left string
; Destroy: BX, DX, DI
;--------------------------------------------------------------------------------

GetInt proc
    xor ax, ax

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
; In:      DL = symbol
; Out:     BX = 0 if not a digit
;          BX = 1 if a digit
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
; Short:   Puts ptr to a frame style struct in AX (by index)
; In:      AX = Frame Style index
; Out:     AX --> FrameStyle
; Destroy: BX, DX
;--------------------------------------------------------------------------------

GetFrameStyle proc

    cmp ax, 0
    jne @@DefaultFrameStyle

    call ParseCustomFrameStyle
    mov ax, offset CustomFrameStyle
    call SkipSpaces

    jmp @@End

    @@DefaultFrameStyle:

    ; check index for negatives and overflow
    cmp ax, FS_STYLES_COUNT
    jg @@SetDefaultIndex

    cmp ax, 0
    jl @@SetDefaultIndex

    jmp @@PossibleIndex

    @@SetDefaultIndex:
    mov ax, 01h

    @@PossibleIndex:

    ; indexing starts from 0 but styles from 1
    dec ax

    ; count shift in FSTable
    mov bx, FS_STYLE_SIZE
    mul bx

    ; AX --> FrameStyleStruct
    add ax, offset FrameStylesTable

    @@End:

    ret

GetFrameStyle endp

;--------------------------------------------------------------------------------
; Short:   Puts symbols from terminal into a struct for custom frame style
; In:      DS:[SI] --> FrameStyle symbols
; Out:     DI      --> CustomFrameStyle
;          DS:[SI] --> symbol after frame style in cmd
;          CX = end of CmdLine len
; Destroy: AL, SI, DI
;--------------------------------------------------------------------------------

ParseCustomFrameStyle proc

    push cx

    mov di, offset CustomFrameStyle
    add di, LuCorner

    mov cx, 9

    @@Next:
        mov byte ptr al, ds:[si]
        mov byte ptr ds:[di], al
        add di, 2
        inc si

    loop @@Next

    pop cx

    sub cx, 9

    ret

ParseCustomFrameStyle endp

;--------------------------------------------------------------------------------
; Short:   moves DI to the frame left upper corner
; Exp:     DI = 0 (start of vram)
; In:      BX = frame width
;          DX = frame height
; Out:     DI = lu corner pos
; Destroy: AX, SI
;--------------------------------------------------------------------------------

GetFrameLeftUpperCornerPos proc

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

    ret

GetFrameLeftUpperCornerPos endp

;--------------------------------------------------------------------------------
; Short:   Draws horizontal frame line in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      SI --> data with line symbols [left, middle, right]
;                 (of 2 bytes: ascii, color)
;          DI = start pos to draw line
;          BX = frame width
; Out:     DI = end pos of newly drown line
; Destroy: AX, CX, SI, DI
;--------------------------------------------------------------------------------

mDrawHorizontalLine macro

; draw left symbol
    ; ds[si] = left symbol
    ; ax = ds:[si += 2]
    lodsw
    ; es:[di += 2] = ax
    stosw

; draw middle part
    ; ds[si] = middle symbol
    ; ax = ds:[si += 2]
    lodsw
    ; cx = FRAME_WIDTH - 2 for corners
    mov cx, bx
    sub cx, 2
    ; while (cx--) es:[di += 2] = ax
    rep stosw

; draw right symbol
    ; ds[si] = right symbol
    ; ax = ds:[si += 2]
    lodsw
    ; es:[di += 2] = ax
    stosw

    endm

;--------------------------------------------------------------------------------
; Short:   Draws a centered const size frame
; Exp:     DF = 0
; In:      SI --> frame style format
;          DX = frame height
;          BX = frame width
;          DI = position of left upper corner of a frame
; Destroy: AX, CX, SI, DI
;--------------------------------------------------------------------------------

DrawFrame proc

; Draw top line
;------------------------------------
    ; save lu corner pos in stack
    push di

    ; get top symbols
    add si, LuCorner
    mDrawHorizontalLine

    pop di

    ; new line
    add di, (SCREEN_WIDTH * 2)
;------------------------------------

; Draw middle part
;------------------------------------
    ; get middle symbols
    ; SI already points to the middle symbols,
    ; as they are stored continuously

    ; cx = middle part height (frame height - 2)
    mov cx, dx
    sub cx, 2

    @@Next:
        push cx si di
        mDrawHorizontalLine
        pop di si cx

        ; new line
        add di, (SCREEN_WIDTH * 2)
    loop @@Next
;------------------------------------

; Draw bottom line
;------------------------------------
    ; get bottom symbols
    ; shift for SI = add 2 bytes * 3 symbols are in 1 line
    add si, (2 * 03d)
    mDrawHorizontalLine
;------------------------------------

    ret

DrawFrame endp

;--------------------------------------------------------------------------------
; Short:   Prints cmd line in vram in the center of the frame
; Exp:     DF = 0
; In:      DI = lu frame corner pos
;          CX = text length
;          SI --> text
;          AH = text color
; Destroy: BX, CX, DI, SI
;--------------------------------------------------------------------------------

DrawCenteredText proc

    ; if TextLen <= 0 -> jump to the end
    cmp cx, 0
    jle @@End

    push si ax
    call SetWritingStartPos
    pop ax si

    ; tail call --> ret of inside function will return from our function
    jmp LoadText

    @@End:

    ret

DrawCenteredText endp

;--------------------------------------------------------------------------------
; Short:   Sets DI to a pos to write text
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
; Short:   ends the program
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

AnimationStep dw ?

CustomFrameStyle FrameStyle <                       \
        (             (GRAY_BG + BRT_RED) * 100h),  \
        (                         GRAY_BG * 100h),  \
        (LU_CORNER  + (GRAY_BG + BRT_RED) * 100h),  \
        (HORIZ_LINE + (GRAY_BG + BRT_RED) * 100h),  \
        (RU_CORNER  + (GRAY_BG + BRT_RED) * 100h),  \
        (VERT_LINE  + (GRAY_BG + BRT_RED) * 100h),  \
        (SPACE      + (GRAY_BG + WHITE  ) * 100h),  \
        (VERT_LINE  + (GRAY_BG + BRT_RED) * 100h),  \
        (LD_CORNER  + (GRAY_BG + BRT_RED) * 100h),  \
        (HORIZ_LINE + (GRAY_BG + BRT_RED) * 100h),  \
        (RD_CORNER  + (GRAY_BG + BRT_RED) * 100h)>

FrameStylesTable label FrameStyle

;------------------------------------
; [1] = normal

RegsFrameStyle FrameStyle <                     \
    (             (PINK    + GRAY_BG) * 100h),  \
    (                        GRAY_BG  * 100h),  \
    (LU_CORNER  + (BRT_RED + GRAY_BG) * 100h),  \
    (HORIZ_LINE + (BRT_RED + GRAY_BG) * 100h),  \
    (RU_CORNER  + (BRT_RED + GRAY_BG) * 100h),  \
    (VERT_LINE  + (BRT_RED + GRAY_BG) * 100h),  \
    (' '        + (BRT_RED + GRAY_BG) * 100h),  \
    (VERT_LINE  + (BRT_RED + GRAY_BG) * 100h),  \
    (LD_CORNER  + (BRT_RED + GRAY_BG) * 100h),  \
    (HORIZ_LINE + (BRT_RED + GRAY_BG) * 100h),  \
    (RD_CORNER  + (BRT_RED + GRAY_BG) * 100h)>

;------------------------------------
; [2] = pink
    FrameStyle <                            \
        (        (WHITE + PINK_BG) * 100h), \
        (                 PINK_BG  * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (PINK +  PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h), \
        (HEART + (WHITE + PINK_BG) * 100h)>

;------------------------------------
; [3] = cursed
    FrameStyle <                        \
        (             BLUE    * 100h),  \
        (             BLACK   * 100h),  \
        (0d2h       + BRT_RED * 100h),  \
        (06h        + BRT_RED * 100h),  \
        (0fh        + BRT_RED * 100h),  \
        (0ceh       + BRT_RED * 100h),  \
        ('0'        + BRT_RED * 100h),  \
        (0d8h       + BRT_RED * 100h),  \
        (04h        + BRT_RED * 100h),  \
        (0feh       + BRT_RED * 100h),  \
        (10h        + BRT_RED * 100h)>

;------------------------------------
; [4] = penis c1h c2h
    FrameStyle <                            \
        (                BLUE     * 100h),  \
        (                BLUE_BG  * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (0c2h  + (BLUE + BLUE_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (SPACE + (BRT_RED + GREEN_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h),  \
        (0c1h  + (BLUE + BLUE_BG) * 100h)>

;------------------------------------
; [5] = funny faces
    FrameStyle <                        \
        (              4eh    * 100h),  \
        (              4eh    * 100h),  \
        (02h         + 4eh    * 100h),  \
        (01h         + 4eh    * 100h),  \
        (02h         + 4eh    * 100h),  \
        (02h         + 4eh    * 100h),  \
        (SPACE      + BRT_RED * 100h),  \
        (02h         + 4eh    * 100h),  \
        (02h         + 4eh    * 100h),  \
        (01h         + 4eh    * 100h),  \
        (02h         + 4eh    * 100h)>

;================================================================================

end     Start
