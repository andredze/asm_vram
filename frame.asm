.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

FRAME_COLOR		equ 0Fh
FRAME_WIDTH		equ 40
FRAME_HEIGHT 	equ 5

HORIZ_LINE	equ 0cdh
VERT_LINE	equ 0bah
CORNER		equ 0c9h

BRT_RED_CLR	equ 0ch
BLINKING	equ 80h
VIDEO_SEG	equ 0b800h

;//------------------------------------------------------------------------------------------

Start:
		mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

;//——————————————————————————————————————————————————————————————————————————————————————————

		sub bx, FRAME_WIDTH		; center the frame
		mov cx, FRAME_WIDTH

		mov ah, FRAME_COLOR
		mov al, HORIZ_LINE

		; DRAW horizontal line

L_HORIZ_START:
		mov es:[bx], ax
		add bx, 2

		loop L_HORIZ_START

;//——————————————————————————————————————————————————————————————————————————————————————————

		sub bx, FRAME_WIDTH
		add bx, 40 * 2

		mov si, 80h
		mov byte ptr cl, [si]	; CX = CmdTailLen (-1 for \r)
		sub cx, 1
		mov di, 82h		; DI = &CmdTail

		mov si, cx		; si = CmdTailLen

;//------------------------------------------------------------------------------------------
		; if CmdTailLen is odd
		test si, 01h

		jz EVEN_NUMBER
		inc si			; if the number is odd -> move 1 byte more left
EVEN_NUMBER:
;//------------------------------------------------------------------------------------------

						; no need to div by 2, as there are 2 bytes in vram
		sub bx, si		; center the CmdLine

		jcxz PRINT_LINE_END
PRINT_LINE_LOOP:
		mov al, [di]

		; put symbol in first byte
		; put color in second byte

		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 01], (BRT_RED_CLR or BLINKING)
		; brt red with blinking

		add bx, 2		; go to the next symbol in vram
		add di, 1		; get next symbol

		loop PRINT_LINE_LOOP 	; jmp back if cx is not 0

PRINT_LINE_END:

;//——————————————————————————————————————————————————————————————————————————————————————————

		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call

end		Start
