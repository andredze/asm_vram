.model tiny
.code

org 100h

Start:		mov ax, 0b800h 			; b800h - segment of vram
		mov es, ax			; es - extended segment
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

		mov cx, 5			; make 5 iterations
		L:

		; put symbol in first byte
		; put color in second byte
		mov byte ptr es:[bx], 03h 
		mov byte ptr es:[bx + 01], (4eh or 80h)

		add bx, 2

		loop L			; jmp back if cx is not 0

		mov ax, 4c00h		; exit(0)
		int 21h			; int for DOS func call

end		Start
