.model tiny
.code

org 100h

Start:		mov ax, 0b800h		  	; b800h - segment of vram
		mov es, ax		  	; es - extended segment
		xor bx, bx		  	; bx = 0
		mov byte ptr es:[bx], 03h 	; put symbol in first byte
		mov byte ptr es:[bx + 01], (4eh or 80h)  
		; put color in second byte
		
		mov ax, 4c00h			; exit(0)
		int 21h				; int for DOS func call

end		Start