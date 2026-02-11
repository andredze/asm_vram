.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

SCREEN_WIDTH	equ 80
VIDEO_SEG	    equ 0b800h

FRAME_START_LINE equ 5

FRAME_COLOR		equ 0Fh
FRAME_WIDTH		equ 40
FRAME_HEIGHT 	equ 7

HORIZ_LINE	    equ 0cdh
VERT_LINE	    equ 0bah
LU_CORNER	    equ 0c9h
RU_CORNER	    equ 0bbh
LD_CORNER	    equ 0c8h
RD_CORNER	    equ 0bch

BRT_RED_CLR	    equ 0ch
BLINKING	    equ 80h

;//------------------------------------------------------------------------------------------

Start:
		mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment

        ; di = (center of start line)
		mov di, (2 * SCREEN_WIDTH * FRAME_START_LINE + SCREEN_WIDTH)

        push di
        call DrawFrame
        pop di

    ; //TODO - move to the center of the frame
		add di, (2 * 80)   ; newline

;//------------------------------------------------------------------------------------------
; get cmd line

        ; CX = CmdTailLen - 1 (for the last \r)
        mov si, 80h
        mov byte ptr cl, [si]

        ; if CmdTailLen == 0 -> jump to the end
        jcxz LoadLineEnd

        dec cx

        ; SI = &CmdTail
        mov si, 82h

;//------------------------------------------------------------------------------------------
; center the text

        ; BX = shift to the left
        ; BX = StringLen
        mov bx, cx

        ; if CmdTailLen is odd: bx++ (shift one more)
        test bx, 01h
        jz EvenLen
        inc bx
    EvenLen:
                        ; no need to div by 2, as there are 2 bytes in vram
		sub di, bx		; di = center - shift

;//------------------------------------------------------------------------------------------
; load the text

        ; 2nd ax byte = color in vram
		mov ah, (BRT_RED_CLR or BLINKING)

    LoadString:

        lodsb
        stosw

        loop LoadString

    LoadLineEnd:

; end program
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call

;//------------------------------------------------------------------------------------------

; function should get di:
; di = position in vram in the center of the DOS screen, where frame should start
; ax, cx, di doesn't save their values

DrawFrame:

    ; 2nd ax byte = color in vram
    mov ah, FRAME_COLOR

    ; move to the left side (a half of frame width)
    ; not div 2, because 1 symbol = 2 bytes in vram
    sub di, FRAME_WIDTH

    mov al, LU_CORNER
    stosw

    call DrawHorizontalLine

    mov al, RU_CORNER
    stosw

    ; move back to the left side
    ; and go to newline to skip corner
    add di, (-FRAME_WIDTH * 2 + SCREEN_WIDTH * 2)

    call DrawVerticalLine

    mov al, LD_CORNER
    stosw

    call DrawHorizontalLine

    mov al, RD_CORNER
    stosw

    ; +2 to get in front of the corner
    ; move up below the right corner
    ; -2 of height to skip the upper corner
    sub di, (2 + SCREEN_WIDTH * 2 * (FRAME_HEIGHT - 2))

    call DrawVerticalLine

    ret

;//------------------------------------------------------------------------------------------

DrawHorizontalLine:

    ; 1st ax byte = symbol
    mov al, HORIZ_LINE
    mov cx, (FRAME_WIDTH - 2)
    rep stosw

    ret

;//------------------------------------------------------------------------------------------

DrawVerticalLine:

    ; 1st ax byte = symbol
    mov al, VERT_LINE
    mov cx, (FRAME_HEIGHT - 2)

    VerticalLineLoop:
    mov es:[di], ax
    add di, (SCREEN_WIDTH * 2)

    loop VerticalLineLoop

    ret

;//------------------------------------------------------------------------------------------

end		Start
