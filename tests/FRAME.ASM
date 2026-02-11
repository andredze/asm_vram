.model tiny
.code

org 100h

;//------------------------------------------------------------------------------------------

FRAME_COLOR		equ 0Fh
FRAME_WIDTH		equ 40
FRAME_HEIGHT 	equ 5

HORIZ_LINE	equ 0cdh
VERT_LINE	equ 0bah
LUCORNER	equ 0c9h
RUCORNER	equ 0bbh
LDCORNER	equ 0c8h
RDCORNER	equ 0bch

BRT_RED_CLR	equ 0ch
BLINKING	equ 80h
VIDEO_SEG	equ 0b800h

;//------------------------------------------------------------------------------------------

Start:
;	go to the segment
		mov ax, VIDEO_SEG 				; b800h - segment of vram
		mov es, ax						; es - extended segment

;//------------------------------------------------------------------------------------------

;	center the first line of frame
		mov bx, (2 * 80 * 5 + 2 * 40)   ; bx = (center of 5th line)
		sub bx, FRAME_WIDTH		; center the frame
		mov cx, FRAME_WIDTH - 2	; -2 for corners

		mov ah, FRAME_COLOR
		mov al, LUCORNER

		mov es:[bx], ax
		add bx, 2

		mov al, HORIZ_LINE

; 	DRAW horizontal line

L_HORIZ_START:
		mov es:[bx], ax
		add bx, 2

		loop L_HORIZ_START

		mov al, RUCORNER

		mov es:[bx], ax
		add bx, 2

;//------------------------------------------------------------------------------------------

;	DRAW vertical lhs
		add bx, ((80 - FRAME_WIDTH) * 2) ; newline + move to the left side of a frame
		mov al, VERT_LINE
		mov es:[bx], ax

;	DRAW vertical rhs
		add bx, ((FRAME_WIDTH - 1) * 2) ; move to the right side of a frame
										; (-1 for the side)
		mov al, VERT_LINE
		mov es:[bx], ax

;//------------------------------------------------------------------------------------------

		sub bx, (FRAME_WIDTH - 2) 	; move to the center of DOS window
									; (-2 to get back to the start of side)

; 	center the text

		mov si, 80h
		mov byte ptr cl, [si]	; CX = CmdTailLen (-1 for \r)
		sub cx, 1
		mov di, 82h		; DI = &CmdTail

		mov si, cx		; si = CmdTailLen

; 	if CmdTailLen is odd
		test si, 01h

		jz EVEN_NUMBER
		inc si			; if the number is odd -> move 1 byte more left
EVEN_NUMBER:

						; no need to div by 2, as there are 2 bytes in vram
		sub bx, si		; center the CmdLine

;//------------------------------------------------------------------------------------------

; 	print the text

		jcxz PRINT_LINE_END

		mov ah, (BRT_RED_CLR or BLINKING) ; color in the second byte

PRINT_LINE_LOOP:
		mov al, [di]

		; put symbol in first byte
		; put color in second byte
		mov es:[bx], ax

		add bx, 2		; go to the next symbol in vram
		add di, 1		; get next symbol

		loop PRINT_LINE_LOOP 	; jmp back if cx is not 0

PRINT_LINE_END:

;//------------------------------------------------------------------------------------------

; 	move to the center for the second frame line

		add bx, si
		mov di, 80h
		mov byte ptr cl, [di]
		shl cx, 1
		sub bx, cx
		add bx, 2

;//------------------------------------------------------------------------------------------

;	DRAW the second line

		add bx, 80 * 2 - FRAME_WIDTH		; TODO: * amount of \n

		xor cx, cx
		mov cx, FRAME_WIDTH - 2				; -2 for corners

		mov ah, FRAME_COLOR

		mov al, LDCORNER
		mov es:[bx], ax
		add bx, 2

		mov al, HORIZ_LINE

		; DRAW horizontal line

L_HORIZ_END:
		mov es:[bx], ax
		add bx, 2

		loop L_HORIZ_END

		mov al, RDCORNER
		mov es:[bx], ax
		add bx, 2

;//------------------------------------------------------------------------------------------

;	end program
		mov ax, 4c00h	; exit(0)
		int 21h			; int for DOS func call

end		Start
