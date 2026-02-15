.model tiny
.code

org 100h

locals @@

;--------------------------------------------------------------------------------

BKGND_COLOR      equ 070h
SCREEN_WIDTH	 equ 80
VIDEO_SEG	     equ 0b800h

FRAME_START_LINE equ 5

FRAME_COLOR		 equ 00h
FRAME_WIDTH		 equ 40
FRAME_HEIGHT 	 equ 6

HORIZ_LINE	     equ 0cdh
VERT_LINE	     equ 0bah
LU_CORNER	     equ 0c9h
RU_CORNER	     equ 0bbh
LD_CORNER	     equ 0c8h
RD_CORNER	     equ 0bch

BRT_RED_CLR	     equ 0ch
BLINKING	     equ 80h

; --------------------------------- MACROS ---------------------------------

;--------------------------------------------------------------------------------
; Short:   draws set symbol in vram
; Exp:     ES = Video Segment
;          AH = Symbol Color
;          DF = 0
; In:      symbol = symbol code in ASCII
; Out:     DI++ (DI = pos after that symbol in vram)
; Destroy: AL
;--------------------------------------------------------------------------------

DrawSymbol  macro symbol
        mov al, symbol
        stosw
        endm

; ---------------------------------- CODE ----------------------------------

Start:
        call Main
        call Exit

;//==========================================================================================

Main    proc
        mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment

        call GetFrameLeftUpperCornerPos

        push di
        call DrawFrame
        pop di

        push di
        call PrintCmdLine
        pop di

        call DrawFrameBackground

        ret
        endp

;--------------------------------------------------------------------------------
; Short:   moves DI to the frame left upper corner
; Exp:     DI = 0 (start of vram)
; In:      -
; Out:     DI = lu corner pos
; Destroy: -
;--------------------------------------------------------------------------------

GetFrameLeftUpperCornerPos proc

        ; 1) di = (center of start line)
        ; 2) move to the left side (a half of frame width)
        ; -FRAME_WIDTH: not div 2, because 1 symbol = 2 bytes in vram
        mov di, (2 * SCREEN_WIDTH * FRAME_START_LINE + SCREEN_WIDTH - FRAME_WIDTH)

        ret
        endp

;--------------------------------------------------------------------------------
; Short:   Draws a centered const size frame
; Exp:     DF = 0
; In:      DI = position of left upper corner of a frame
; Out:     -
; Destroy: AX, CX, DI
;--------------------------------------------------------------------------------

DrawFrame   proc

    ; 2nd ax byte = color in vram
    mov ah, FRAME_COLOR

    DrawSymbol LU_CORNER

    call DrawHorizontalLine

    DrawSymbol RU_CORNER

    ; move back to the left side
    ; and go to newline to skip corner
    add di, (-FRAME_WIDTH * 2 + SCREEN_WIDTH * 2)

    call DrawVerticalLine

    DrawSymbol LD_CORNER

    call DrawHorizontalLine

    DrawSymbol RD_CORNER

    ; +2 to get in front of the corner
    ; move up below the right corner
    ; -2 of height to skip the upper corner
    sub di, (2 + SCREEN_WIDTH * 2 * (FRAME_HEIGHT - 2))

    call DrawVerticalLine

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   Draws horizontal frame line in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = start pos to draw line
; Out:     DI = end pos of newly drown line
; Destroy: AL, CX
;--------------------------------------------------------------------------------

DrawHorizontalLine  proc

    ; 1st ax byte = symbol
    mov al, HORIZ_LINE
    mov cx, (FRAME_WIDTH - 2)
    rep stosw

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   Draws vertical frame line in vram
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = start pos to draw line
; Out:     DI = end pos of newly drown line
; Destroy: AL, CX
;--------------------------------------------------------------------------------

DrawVerticalLine    proc

    ; 1st ax byte = symbol
    mov al, VERT_LINE
    mov cx, (FRAME_HEIGHT - 2)

    @@Next:
        mov es:[di], ax
        add di, (SCREEN_WIDTH * 2)
    loop @@Next

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   Prints cmd line in vram in the center of the frame
; Exp:     DF = 0
; In:      DI = lu frame corner pos
; Out:     -
; Destroy: AX, BX, CX, DI, SI
;--------------------------------------------------------------------------------

PrintCmdLine    proc

    call GetCmdLine
    call GetWritingStartPos
    call LoadText

    PrintCmdLineEnd:

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   gets cmd line and it's length into registers
; Exp:     -
; In:      -
; Out:     CX = CmdTailLen
;          SI = &CmdTail
; Destroy: -
;--------------------------------------------------------------------------------

GetCmdLine      proc

        ; CX = CmdTailLen - 1 (for the last \r)
        mov si, 80h
        mov byte ptr cl, [si]

        ; if CmdTailLen == 0 -> jump to the end
        jcxz PrintCmdLineEnd

        dec cx

        ; SI = &CmdTail
        mov si, 82h

        ret
        endp

;--------------------------------------------------------------------------------
; Short:   Moves
; Exp:     CX = text length
;          DI = lu frame corner pos
; In:      -
; Out:     DI = start pos for writing text
; Destroy: BX
;--------------------------------------------------------------------------------

GetWritingStartPos   proc

        ; DI = center of the line to write
        add di, (2 * SCREEN_WIDTH * ((FRAME_HEIGHT - 1) / 2) + FRAME_WIDTH)

        ; BX = shift to the left = StringLen
        mov bx, cx

        test bx, 01h

        jz @@EvenLen
            ; if CmdTailLen is odd: bx++ (shift one more)
            inc bx
        @@EvenLen:
                        ; no need to div by 2, as there are 2 bytes in vram
		sub di, bx		; di = center - shift

        ret
        endp

;--------------------------------------------------------------------------------
; Short:   Loads the text to vram
; Exp:     ES = VideoSegment
;          DF = 0
; In:      DI = text start pos in vram
;          SI = text start pos in data
;          CX = text length
; Out:     -
; Destroy: AX, CX, DI, SI
;--------------------------------------------------------------------------------

LoadText    proc
        ; 2nd ax byte = color in vram
        mov ah, (BRT_RED_CLR or BLINKING)

    @@Next:
        lodsb
        stosw

        loop @@Next

        ret
        endp

;--------------------------------------------------------------------------------
; Short:   Draws background for the frame
; Exp:     ES = Video Segment
;          DF = 0
; In:      DI = pos of the lu frame corner
; Out:     -
; Destroy: SI, DI, CX
;--------------------------------------------------------------------------------

DrawFrameBackground     proc

    ; si = iterator for lines
    mov si, FRAME_HEIGHT

    @@NextLine:
        ; cx = iterator for columns
        mov cx, FRAME_WIDTH

        @@NextSymbol:
            and byte ptr es:[di + 1], 0afh
            or  byte ptr es:[di + 1], BKGND_COLOR

            add di, 2

        loop @@NextSymbol

        ; move to the next line start
        add di, (2 * (SCREEN_WIDTH - FRAME_WIDTH))

        dec si

    cmp si, 0
    jnz @@NextLine

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   ends the program
; Exp:     -
; In:      -
; Out:     -
; Destroy: AX
;--------------------------------------------------------------------------------

Exit    proc
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call
        ret
        endp

;================================================================================

end		Start
