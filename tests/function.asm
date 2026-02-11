.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

SCREEN_WIDTH	equ 80
VIDEO_SEG	    equ 0b800h

FRAME_COLOR		equ 0Fh
FRAME_WIDTH		equ 40
FRAME_HEIGHT 	equ 5

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
;	go to the segment
		mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment

;//------------------------------------------------------------------------------------------

;	center the first line
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

        call DrawCorners
        call DrawHorizontalLine

		add bx, (2 * 80)   ; newline

        mov di, 80h
        mov byte ptr cl, [di]
        dec cx  ; for the last \r

        mov si, 82h
        mov di, bx

        mov ah, FRAME_COLOR

    LoadString:

        lodsb
        stosw

        loop LoadString

		add bx, (2 * 80)   ; newline

        call DrawHorizontalLine

;	end program
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call

;//------------------------------------------------------------------------------------------

; function should get bx - position in vram in the center of the DOS screen
; bx doesn't get changed
; ax, cx, di doesn't save their values

DrawHorizontalLine:

    mov di, bx

    ; move left from the center by a half of frame width
    ; (not dividing by 2 as 1 symbol = 2 bytes)
    sub di, FRAME_WIDTH

    ; 1st ax byte = symbol
    mov al, HORIZ_LINE
    ; 2nd ax byte = color
    mov ah, FRAME_COLOR

    mov cx, FRAME_WIDTH
    rep stosw

    ret

;//------------------------------------------------------------------------------------------

; function should get bx - position in vram in the center
; of the DOS screen of first frame line
; bx doesn't get changed
; ax, cx, di doesn't save their values

DrawCorners:

    mov di, bx

    ; 2nd ax byte = color
    mov ah, FRAME_COLOR

    ; move to the left side
    sub di, (FRAME_WIDTH + 2)
    mov al, LU_CORNER
    stosw

    ; move to the lower corner
    ; (-2) for the shift after the first op
    add di, (SCREEN_WIDTH * 2 * (FRAME_HEIGHT + 1) - 2)
    mov al, LD_CORNER
    stosw

    add di, (FRAME_WIDTH * 2)
    mov al, RD_CORNER
    stosw

    sub di, (2 + SCREEN_WIDTH * 2 * (FRAME_HEIGHT + 1))
    mov al, RU_CORNER
    stosw

    ret

;//------------------------------------------------------------------------------------------

end		Start
