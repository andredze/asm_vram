.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

VIDEO_SEG	    equ 0b800h

FRAME_COLOR		equ 0Fh
FRAME_WIDTH		equ 40
FRAME_HEIGHT 	equ 5

HORIZ_LINE	    equ 0cdh
VERT_LINE	    equ 0bah
LUCORNER	    equ 0c9h
RUCORNER	    equ 0bbh
LDCORNER	    equ 0c8h
RDCORNER	    equ 0bch

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

;//------------------------------------------------------------------------------------------

;	end program
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call

end		Start
