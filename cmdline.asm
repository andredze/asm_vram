.model tiny
.code

org 100h

END_STR		equ '$'
VIDEO_SEG	equ 0b800h

Start:      	mov ax, VIDEO_SEG 		; b800h - segment of vram
		mov es, ax			; es - extended segment
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

		mov si, 80h
		mov byte ptr cl, [si]		; CX = CmdTailLen (-1 for \r)
		sub cx, 1
		mov di, 82h		; DI = &CmdTail

		jcxz LOOP_END

LOOP_START:
		mov al, [di]

		; put symbol in first byte
		; put color in second byte

		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 01], (4eh or 80h)

		add bx, 2		; go to the next symbol in vram
		add di, 1		; get next symbol

		loop LOOP_START 	; jmp back if cx is not 0

LOOP_END:

		mov ax, 4c00h		; exit(0)
		int 21h			; int for DOS func call

Hello   	db 'MEOW MIR', 03h, '$'

end		Start
