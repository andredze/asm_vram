.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

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

;//------------------------------------------------------------------------------------------

Start:
        call Main
        call Exit

;//==========================================================================================

Main:   proc
        mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment

        ; di = (center of start line)
		mov di, (2 * SCREEN_WIDTH * FRAME_START_LINE + SCREEN_WIDTH)

        push di
        call DrawFrame
        pop di

        push di

		add di, (2 * SCREEN_WIDTH * ((FRAME_HEIGHT - 1) / 2))   ;

        call PrintCmdLine

        pop di
        call DrawFrameBackground
        ret
        endp

;--------------------------------------------------------------------------------
; Short:   Draws a centered const size frame
; Exp:     -
; In:      DI = position of center of the first line of a frame
; Out:     -
; Destroy: AX, CX, DI
;--------------------------------------------------------------------------------

DrawFrame   proc

    ; move to the left side (a half of frame width)
    ; not div 2, because 1 symbol = 2 bytes in vram
    sub di, FRAME_WIDTH

    ; 2nd ax byte = color in vram
    mov ah, FRAME_COLOR

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
    endp

;//------------------------------------------------------------------------------------------

DrawFrameBackground     proc

    ; move to the left side (a half of frame width)
    ; not div 2, because 1 symbol = 2 bytes in vram
    sub di, FRAME_WIDTH

    ; si = iterator for lines
    mov si, FRAME_HEIGHT

DrawBkgndLoop:

    ; cx = iterator for columns
    mov cx, FRAME_WIDTH

    DrawBkgndLineLoop:

        and byte ptr es:[di + 1], 0afh
        or  byte ptr es:[di + 1], BKGND_COLOR

        add di, 2

    loop DrawBkgndLineLoop

    add di, (2 * (SCREEN_WIDTH - FRAME_WIDTH))

    dec si
    cmp si, 0
    jnz DrawBkgndLoop

    ret
    endp

;//------------------------------------------------------------------------------------------

DrawHorizontalLine  proc

    ; 1st ax byte = symbol
    mov al, HORIZ_LINE
    mov cx, (FRAME_WIDTH - 2)
    rep stosw

    ret
    endp

;//------------------------------------------------------------------------------------------

DrawVerticalLine    proc

    ; 1st ax byte = symbol
    mov al, VERT_LINE
    mov cx, (FRAME_HEIGHT - 2)

    VerticalLineLoop:
    mov es:[di], ax
    add di, (SCREEN_WIDTH * 2)

    loop VerticalLineLoop

    ret
    endp

;//==========================================================================================

PrintCmdLine    proc

; get cmd line

        ; CX = CmdTailLen - 1 (for the last \r)
        mov si, 80h
        mov byte ptr cl, [si]

        ; if CmdTailLen == 0 -> jump to the end
        jcxz PrintCmdLineEnd

        dec cx

        ; SI = &CmdTail
        mov si, 82h

    ;------------------------------------
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

    ;------------------------------------
; load the text

        ; 2nd ax byte = color in vram
        mov ah, (BRT_RED_CLR or BLINKING)

    LoadString:

        lodsb
        stosw

        loop LoadString

    PrintCmdLineEnd:

    ret
    endp

;--------------------------------------------------------------------------------
; Short:   ends the program
; Exp:     -
; In:      -
; Out:     -
; Destroy: ax
;--------------------------------------------------------------------------------

Exit:   proc
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call
        ret
        endp

;================================================================================

end		Start
