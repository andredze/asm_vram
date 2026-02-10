.model tiny
.code

org 100h

END_STR		equ '$'

Start:      	mov ax, 0b800h 			; b800h - segment of vram
		mov es, ax			; es - extended segment
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

		mov cx, 1000			; CX = 1000 - max of iters
		mov di, offset Hello		; DX = &Hello

LOOP_START:
		mov byte ptr al, [di]		; al = *(Hello + iters)

		cmp al, END_STR			; check for the '$' symbol

		je line_end

		; put symbol in first byte
		; put color in second byte

		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 01], (4eh or 80h)

		add bx, 2		; go to the next symbol in vram
		add di, 1		; get next symbol

		dec cx

		loop LOOP_START 	; jmp back if cx is not 0

line_end:

		mov ax, 4c00h		; exit(0)
		int 21h			; int for DOS func call

Hello   	db 'MEOW MIR', 03h, '$'

end		Start
