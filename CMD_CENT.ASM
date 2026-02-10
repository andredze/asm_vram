.model tiny
.code

org 100h

BRT_RED_CLR	equ 0ch
BLINKING	equ 80h
VIDEO_SEG	equ 0b800h

Start:      	mov ax, VIDEO_SEG 		; b800h - segment of vram
		mov es, ax			; es - extended segment
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)

		mov si, 80h
		mov byte ptr cl, [si]		; CX = CmdTailLen (-1 for \r)
		sub cx, 1
		mov di, 82h		; DI = &CmdTail

		mov si, cx		; si = CmdTailLen
		
		; if CmdTailLen is odd
		test si, 01h
		
		jz EVEN_NUMBER
		inc si			; if the number is odd -> move 1 byte more left
EVEN_NUMBER:																
					; no need to div by 2, as there are 2 bytes in vram
		sub bx, si		; center the CmdLine

		jcxz LOOP_END

LOOP_START:
		mov al, [di]

		; put symbol in first byte
		; put color in second byte

		mov byte ptr es:[bx], al
		mov byte ptr es:[bx + 01], (BRT_RED_CLR or BLINKING) 
		; brt red with blinking

		add bx, 2		; go to the next symbol in vram
		add di, 1		; get next symbol

		loop LOOP_START 	; jmp back if cx is not 0

LOOP_END:
		mov ax, 4c00h		; exit(0)
		int 21h			; int for DOS func call

end		Start
