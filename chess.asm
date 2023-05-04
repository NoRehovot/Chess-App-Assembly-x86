IDEAL
MODEL small
STACK 100h
DATASEG

stor   	 	dw      0      ;our memory location storage
imgHeight dw 200  ;Height of image that fits screen
imgWidth dw 200   ;Width of image that fits screen
adjustCX dw ?     ;Adjusts register CX
filename db 20 dup (?) ;Generates the file's name 
filehandle dw ?  ;Handles the file
Header db 54 dup (0)  ;Read BMP file header, 54 bytes
Palette db 256*4 dup (0)  ;Enable colors
ScrLine db 320 dup (0)   ;Screen Line
Errormsg db 'Error', 13, 10, '$'   ;In case of not having all the files, Error message pops
printAdd dw 0   ;Enable to add new graphics
x dw ?; temporarily saves the x co-ordinate of a square
y dw ?; temporarily saves the y co-ordinate of a square
boardPos dw ?; temporarily saves the board array position of a square
possibleMoves db 64 dup (64); array to temporarily hold the possible moves of a tools, where the numbers in the array represent the squares the tool can go to and 64 represents no square
boardPosEx dw ?; too help with calculations
ColorOfToolOnSquare dw ? ;represents the color of the tool thats on the square (helps with calculations)
KingPosW dw ? ; represents the white king's position on the board
KingPosB dw ? ; represents the black king's position on the board
colorTemp dw ? ; temporarily saves the color of a tool
InPossibleMoves dw 0 ; represents if a square the player clicked on is in the possibleMoves array
ToolClickedOn dw 0 ; represents the number of the tool the player clicked on
boardArrEx db 64 dup (0) ;extra array that represents the board, to help with calculations
possibleMovesEx db 64 dup (0) ;extra array that stores possible moves, to help with calculations
squareColor db ?
CheckMateW db 0 ; 1 if white lost
CheckMateB db 0 ; 1 if black lost
castleAW dw 64;represents wether the white player can castle to the to one side
castleSW dw 64;represents wether the white player can castle to the to the other side
castleAB dw 64;represents wether the black player can castle to the to one side
castleSB dw 64;represents wether the black player can castle to the to the other side


sizeOfSquare db 25 ;size of each square on the board
boardArr db 64 dup (0) ;array that represents the board
player1Color db ? ;color of player 1 (0 for white, 1 for black)
player2Color db ?; color of player 2 (0 for white, 1 for black)
turn dw 0 ;represents whose turn it is (starts with 0 for white)
IsCheckW dw 0 ; represents whether there is a check for the white king (0 for no, 1 for yes)
IsCheckB dw 0 ; represents whether there is a check for the black king (0 for no, 1 for yes)
KingMovedW dw 0 ; represents whether whites king moved in this game (0 for no, 1 for yes)
RookMovedW dw 0 ; represents whether whites rook moved in this game (0 for no, 1 for yes)
KingMovedB dw 0 ; represents whether blacks king moved in this game (0 for no, 1 for yes)
RookMovedB dw 0 ; represents whether blacks rook moved in this game (0 for no, 1 for yes)

red db 0
green db 0
blue db 0


board db 'boardCh.bmp', 0   ;Openning image (bmp)

;white tools
WbishopW db 'WbishopW.bmp', 0
WkingW db 'WkingW.bmp', 0
WknightW db 'WknightW.bmp', 0
WpawnW db 'WpawnW.bmp', 0
WqueenW db 'WqueenW.bmp', 0
WrookW db 'WrookW.bmp', 0
WbishopB db 'WbishopB.bmp', 0
WkingB db 'WkingB.bmp', 0
WknightB db 'WknightB.bmp', 0
WpawnB db 'WpawnB.bmp', 0
WqueenB db 'WqueenB.bmp', 0
WrookB db 'WrookB.bmp', 0

;black tools
BbishopW db 'BbishopW.bmp', 0
BkingW db 'BkingW.bmp', 0
BknightW db 'BknightW.bmp', 0
BpawnW db 'BpawnW.bmp', 0
BqueenW db 'BqueenW.bmp', 0
BrookW db 'BrookW.bmp', 0
BbishopB db 'BbishopB.bmp', 0
BkingB db 'BkingB.bmp', 0
BknightB db 'BknightB.bmp', 0
BpawnB db 'BpawnB.bmp', 0
BqueenB db 'BqueenB.bmp', 0
BrookB db 'BrookB.bmp', 0

;square that indicated possible moves
moveInd db 'moveInd.bmp', 0

;image of reverse board button
reverse db 'reverse.bmp', 0

;image that appears when white won the game
WhiteW db 'WhiteW.bmp', 0

;image that appears when black won the game
BlackW db 'BlackW.bmp', 0

;image of game over
GameOC db 'GameOC.bmp', 0

;image of a restart game button
ResC db 'ResC.bmp', 0


CODESEG
proc PrintBmp
	push cx
	push di
	push si
	push cx
	push ax
	xor di, di
	mov di, ax
	mov si, offset filename
	mov cx, 20
Copy:
	mov al, [di]
	mov [si], al
	inc di
	inc si
	loop Copy
	pop ax
	pop cx
	pop si
	pop di
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitMap
	call CloseFile
	
	pop cx
	ret
endp PrintBmp

proc GraphicsMode
	push ax
	
	mov ax, 13h
	int 10h
		
	pop ax
	ret
endp GraphicsMode

;in proc PrintBmp
proc OpenFile
	mov ah,3Dh
	xor al,al ;for reading only
	mov dx, offset filename
	int 21h
	jc OpenError
	mov [filehandle],ax
	ret
OpenError:
	mov dx,offset Errormsg
	mov ah,9h
	int 21h
	ret
endp OpenFile

;in proc PrintBmp
proc ReadHeader
;Read BMP file header, 54 bytes
	mov ah,3Fh
	mov bx,[filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

;in proc PrintBmp
proc ReadPalette
;Read BMP file color palette, 256 colors*4bytes for each (400h)
	mov ah,3Fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette

;in proc PrintBmp
proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h ;port of Graphics Card
	mov al,0 ;number of first color
	;Copy starting color to port 3C8h
	out dx,al
	;Copy palette itself to port 3C9h
	inc dx
PalLoop:
	;Note: Colors in a BMP file are saved as BGR values rather than RGB.	
	mov al ,[si+2] ;get red value
	mov [red], al
	
	;out dx,al ;send it to port
	mov al,[si +1];get green value
	mov [green], al
	
	;out dx,al	;send it
	mov al,[si]
	mov [blue], al
	
	;out dx,al 	;send it
	xor ax, ax
	mov ax, [word ptr red]
	add ax, [word ptr green]
	add ax, [word ptr blue]
	cmp ax, 765
	je dont
	
draw:
	shr [red],2 	; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4
	shr [green],2
	shr [blue],2
	mov al, [red]
	out dx, al
	mov al, [green]
	out dx, al
	mov al, [blue]
	out dx, al
	add si,4	;Point to next color (There is a null chr. after every color)
	
dont:
	
	loop PalLoop
	ret
endp CopyPal

;in proc PrintBmp
proc CopyBitMap
; BMP graphics are saved upside-down.
; Read the graphic line by line ([height] lines in VGA format),
; displaying the lines from bottom to top.
	mov ax,0A000h ;value of start of video memory
	mov es,ax	
	push ax
	push bx
	mov ax, [imgWidth]
	mov bx, 4
	div bl
	
	cmp ah, 0
	jne NotZero
Zero:
	mov [adjustCX], 0
	jmp Continue
NotZero:
	mov [adjustCX], 4
	xor bx, bx
    mov bl, ah
	sub [adjustCX], bx
Continue:
	pop bx
	pop ax
	mov cx, [imgHeight]	;reading the BMP data - upside down
	
PrintBMPLoop:
	push cx
	xor di, di
	push cx
	dec cx
	Multi:
		add di, 320
		loop Multi
	pop cx

    add di, [printAdd]
	mov ah, 3fh
	mov cx, [imgWidth]
	add cx, [adjustCX]
	mov dx, offset ScrLine
	int 21h
	;Copy one line into video memory
	cld	;clear direction flag - due to the use of rep
	mov cx, [imgWidth]
	mov si, offset ScrLine
	rep movsb 	;do cx times:
				;mov es:di,ds:si -- Copy single value form ScrLine to video memory
				;inc si --inc - because of cld
				;inc di --inc - because of cld
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitMap

;in proc PrintBmp
proc CloseFile
	mov ah,3Eh
	mov bx,[filehandle]
	int 21h
	ret
endp CloseFile

;enables graphics mode
;IN: X
;OUT: graphics mode enabled

proc BoardForWhite
	xor bx, bx
	mov bx, offset boardArr
	mov [bx], 9 ;set black rook
	mov [bx + 1], 11 ;set black knight
	mov [bx + 2], 10 ;set black bishop
	mov [bx + 3], 8 ;set black queen
	mov [bx + 4], 7 ;set black king
	mov [bx + 5], 10 ;set black bishop
	mov [bx + 6], 11 ;set black knight
	mov [bx + 7], 9 ;set black rook
	mov [bx + 8], 12 ;set black pawn
	mov [bx + 9], 12 ;set black pawn
	mov [bx + 10], 12 ;set black pawn
	mov [bx + 11], 12 ;set black pawn
	mov [bx + 12], 12 ;set black pawn
	mov [bx + 13], 12 ;set black pawn
	mov [bx + 14], 12 ;set black pawn
	mov [bx + 15], 12 ;set black pawn
	
	mov [bx + 48], 6 ;set white pawn
	mov [bx + 49], 6 ;set white pawn
	mov [bx + 50], 6 ;set white pawn
	mov [bx + 51], 6 ;set white pawn
	mov [bx + 52], 6 ;set white pawn
	mov [bx + 53], 6 ;set white pawn
	mov [bx + 54], 6 ;set white pawn
	mov [bx + 55], 6 ;set white pawn
	mov [bx + 56], 3 ;set white rook
	mov [bx + 57], 5 ;set white knight
	mov [bx + 58], 4 ;set white bishop
	mov [bx + 59], 2 ;set white queen
	mov [bx + 60], 1 ;set white king
	mov [bx + 61], 4 ;set white bishop
	mov [bx + 62], 5 ;set white knight
	mov [bx + 63], 3 ;set white rook
	
	
	
	
	ret
endp BoardForWhite

proc BoardForBlack
	xor bx, bx
	mov bx, offset boardArr
	mov [bx + 48], 12 ;set black pawn
	mov [bx + 49], 12 ;set black pawn
	mov [bx + 50], 12 ;set black pawn
	mov [bx + 51], 12 ;set black pawn
	mov [bx + 52], 12 ;set black pawn
	mov [bx + 53], 12 ;set black pawn
	mov [bx + 54], 12 ;set black pawn
	mov [bx + 55], 12 ;set black pawn
	mov [bx + 56], 9 ;set black rook
	mov [bx + 57], 11 ;set black knight
	mov [bx + 58], 10 ;set black bishop
	mov [bx + 59], 7 ;set black king
	mov [bx + 60], 8 ;set black queen
	mov [bx + 61], 10 ;set black bishop
	mov [bx + 62], 11 ;set black knight
	mov [bx + 63], 9 ;set black rook

	
	mov [bx], 3 ;set white rook
	mov [bx + 1], 5 ;set white knight
	mov [bx + 2], 4 ;set white bishop
	mov [bx + 3], 1 ;set white king
	mov [bx + 4], 2 ;set white queen
	mov [bx + 5], 4 ;set white bishop
	mov [bx + 6], 5 ;set white knight
	mov [bx + 7], 3 ;set white rook
	mov [bx + 8], 6 ;set white pawn
	mov [bx + 9], 6 ;set white pawn
	mov [bx + 10], 6 ;set white pawn
	mov [bx + 11], 6 ;set white pawn
	mov [bx + 12], 6 ;set white pawn
	mov [bx + 13], 6 ;set white pawn
	mov [bx + 14], 6 ;set white pawn
	mov [bx + 15], 6 ;set white pawn
	
	ret
endp BoardForBlack

proc ResetBoard
	mov cx, 64
	mov bx, offset boardArr
	
ResetLoop:
	mov [bx], 0
	inc bx
	loop ResetLoop
	
	ret
endp ResetBoard


proc DecideBoard
	; if player1 is white, generate a board array for white, if not, generate for black
	cmp [player1Color], 0
	je GenerateForWhite
	
GenerateForBlack:
	call BoardForBlack
	jmp next
GenerateForWhite:
	call BoardForWhite
next:
	;xor bx, bx
	;xor ax, ax
	
	ret
endp DecideBoard

;finds the co-ordinates of a square given its position in the board array, and saves them in x and y
proc FindSquareCoords
	push ax
	push bx
	push dx
	push [boardPos]
	;; :)
	
	;find y
	mov ax, [boardPos]
	mov bx, 8
	xor dx, dx
	div bx
	mov bx, 25 * 320
	xor dx, dx
	mul bx
	mov [y], ax
	
	;find x
	mov ax, [boardPos]
	mov bx, 8
	xor dx, dx
	div bx
	xor dx, dx
	mul bx
	sub [boardPos], ax
	mov ax, [boardPos]
	mov bx, 25
	xor dx, dx
	mul bx
	mov [x], ax
	
	xor dx, dx
	xor ax, ax
	
	pop [boardPos]
	pop dx
	pop bx
	pop ax
	
	ret
endp FindSquareCoords

; finds the array position of a square baised on its coordinates
proc FindSquareArr
	push [bx]
	
	mov ax, [x]
	xor dx, dx
	mov bx, 25
	div bx
	mov [boardPos], ax
	
	mov ax, [y]
	xor dx, dx
	mov bx, 25
	div bx
	xor dx, dx
	mov bx, 8
	xor dx, dx
	mul bx
	add [boardPos], ax
	
	xor ax, ax
	xor dx, dx
	
	pop [bx]
	ret
endp FindSquareArr


proc SquareBrownOrWhite
	push dx
	mov dx, [boardPos]
	shr dx, 3
	
	and dx, 00000001b
	cmp dx, 0
	je evenS

oddS:
	mov dx, [boardPos]
	and dx, 00000001b
	cmp dx, 0
	je oWhiteS

oBlackS:
	mov [squareColor], 1
	jmp finC

oWhiteS:
	mov [squareColor], 0
	jmp finC

evenS:
	mov dx, [boardPos]
	and dx, 00000001b
	cmp dx, 0
	je eWhiteS

eBlackS:
	mov [squareColor], 0
	jmp finC

eWhiteS:
	mov [squareColor], 1

finC:
	pop dx

	ret
endp SquareBrownOrWhite


;the following procedures are for printing specific troops
;---------------------------------------------------------

proc DrawWPawn
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWP

BSWP:
	mov ax, offset WpawnB
	jmp pWP
	
WSWP:
	mov ax, offset WpawnW

pWP:
	call PrintBmp
	
	ret
endp DrawWPawn


proc DrawWKnight
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWN

BSWN:
	mov ax, offset WknightB
	jmp pWN
	
WSWN:
	mov ax, offset WknightW

pWN:
	call PrintBmp
	
	
	ret
endp DrawWKnight

proc DrawWBishop
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWB

BSWB:
	mov ax, offset WbishopB
	jmp pWN
	
WSWB:
	mov ax, offset WbishopW

pWB:
	call PrintBmp
	
	
	ret
endp DrawWBishop

proc DrawWRook
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWR

BSWR:
	mov ax, offset WrookB
	jmp pWR
	
WSWR:
	mov ax, offset WrookW

pWR:
	call PrintBmp
	
	ret
endp DrawWRook

proc DrawWQueen
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWQ

BSWQ:
	mov ax, offset WqueenB
	jmp pWQ
	
WSWQ:
	mov ax, offset WqueenW

pWQ:
	call PrintBmp
	
	ret
endp DrawWQueen

proc DrawWKing
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSWK

BSWK:
	mov ax, offset WKingB
	jmp pWK
	
WSWK:
	mov ax, offset WKingW

pWK:
	call PrintBmp
	
	ret
endp DrawWKing

proc DrawBPawn
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBP

BSBP:
	mov ax, offset BPawnB
	jmp pBP
	
WSBP:
	mov ax, offset BPawnW

pBP:
	call PrintBmp
	
	ret
endp DrawBPawn

proc DrawBKnight
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBN

BSBN:
	mov ax, offset BKnightB
	jmp pWN
	
WSBN:
	mov ax, offset BknightW

pBN:
	call PrintBmp
	
	ret
endp DrawBKnight

proc DrawBBishop
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBB

BSBB:
	mov ax, offset BbishopB
	jmp pWN
	
WSBB:
	mov ax, offset BbishopW

pBB:
	call PrintBmp
	
	ret
endp DrawBBishop

proc DrawBRook
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBR

BSBR:
	mov ax, offset BrookB
	jmp pWN
	
WSBR:
	mov ax, offset BrookW

pBR:
	call PrintBmp
	
	ret
endp DrawBRook

proc DrawBQueen
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBQ

BSBQ:
	mov ax, offset BqueenB
	jmp pWN
	
WSBQ:
	mov ax, offset BqueenW

pBQ:
	call PrintBmp
	
	ret
endp DrawBQueen

proc DrawBKing
	
	call FindSquareCoords
	mov dx, [x]
	mov [printAdd], dx
	mov dx, [y]
	add [printAdd], dx
	call SquareBrownOrWhite
	cmp [squareColor], 0
	je WSBK

BSBK:
	mov ax, offset BKingB
	jmp pBK
	
WSBK:
	mov ax, offset BKingW

pBK:
	call PrintBmp
	
	ret
endp DrawBKing

;proc that decides which troop to print, because the loop in "DrawBoard" was too long
proc DecideWhoToDraw
	
	mov dx, [bx]
	cmp dl, 1
	je DWKing
	
	mov dx, [bx]
	cmp dl, 2
	je DWQueen
	
	mov dx, [bx]
	cmp dl, 3
	je DWRook
	
	mov dx, [bx]
	cmp dl, 4
	je DWBishop
	
	mov dx, [bx]
	cmp dl, 5
	je DWKnight
	
	mov dx, [bx]
	cmp dl, 6
	je DWPawn
	
	mov dx, [bx]
	cmp dl, 7
	je DBKing
	
	mov dx, [bx]
	cmp dl, 8
	je DBQueen
	
	mov dx, [bx]
	cmp dl, 9
	je DBRook
	
	mov dx, [bx]
	cmp dl, 10
	je DBBishop
	
	mov dx, [bx]
	cmp dl, 11
	je DBKnight
	
	mov dx, [bx]
	cmp dl, 12
	je DBPawn
	
	mov dl, [bx]
	cmp dl, 0
	je continued

	DWKing:
		call DrawWKing
		jmp continued
		
	DWQueen:
		call DrawWQueen
		jmp continued

	DWRook:
		call DrawWRook
		jmp continued

	DWBishop:
		call DrawWBishop
		jmp continued

	DWKnight:
		call DrawWKnight
		jmp continued
		
	DWPawn:
		call DrawWPawn
		jmp continued
	
	DBKing:
		call DrawBKing
		jmp continued
		
	DBQueen:
		call DrawBQueen
		jmp continued

	DBRook:
		call DrawBRook
		jmp continued

	DBBishop:
		call DrawBBishop
		jmp continued

	DBKnight:
		call DrawBKnight
		jmp continued
		
	DBPawn:
		call DrawBPawn
		jmp continued

	continued:
		xor dx, dx
		xor ax, ax
	
	ret
endp DecideWhoToDraw

; prints the troops on the board based on the board array and the decide who to draw procedure
proc DrawBoard
	push [boardPos]
	push cx
	push bx

	mov bx, offset boardArr
	mov cx, 64
	
	
	mov [boardPos], 0
	
drawB:
	push cx
	push bx
	
	call DecideWhoToDraw
	
	pop bx
	inc bx
	
	inc [boardPos]
	pop cx
	loop drawB
	
	pop bx
	pop cx
	pop [boardPos]
	
	
	ret
endp DrawBoard

;resets the possible moves array
proc ResetPossibleMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
reset:
	mov [bx], 64
	inc bx
	loop reset
	
	ret
endp ResetPossibleMoves

;finds the possible moves for a bishop and srores them in the possibleMoves array
proc FindPossibleBishopMoves
	push [boardPosEX]
	mov ax, [boardPos]
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	xor dx, dx
	
findBa:
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopBa
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopBa
	
	
	add ax, 7
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopBa
	
	cmp al, 63
	jg stopBa
	jmp continueBa
	
	stopBa:
		jmp LBa
		
	continueBa:
		mov [bx], ax
		inc bx
		jmp findBa
	LBa:
		xor dx, dx
	

	mov ax, [boardPos]
	
findBb:
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopBb
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopBb
	
	add ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je StopBb
	
	cmp al, 63
	jg stopBb
	jmp continueBb
	
	stopBb:
		jmp LBb
		
	continueBb:
		mov [bx], ax
		inc bx
		jmp findBb
	LBb:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
findBc:
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopBc
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopBc
	
	sub ax, 7
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopBc
	
	cmp al, 0
	jl stopBc
	jmp continueBc
	
	stopBc:
		jmp LBc
		
	continueBc:
		mov [bx], ax
		inc bx
		jmp findBc
	LBc:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
findBd:
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopBd
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopBd
	
	sub ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopBd
	
	cmp al, 0
	jl stopBd
	jmp continueBd
	
	stopBd:
		jmp LBd
		
	continueBd:
		mov [bx], ax
		inc bx
		jmp findBd
	LBd:
		xor dx, dx

	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleBishopMoves

;finds the possible moves for a rook and srores them in the possibleMoves array
proc FindPossibleRookMoves
	mov ax, [boardPos]
	push [boardPosEX]
	
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	xor dx, dx
	
findRa:
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopRa
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopRa
	
	sub ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopRa
	
	jmp continueRa
	
	stopRa:
		jmp LRa
		
	continueRa:
		mov [bx], ax
		inc bx
		jmp findRa
	LRa:
		xor dx, dx
	

	mov ax, [boardPos]
	
findRb:
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopRb
	
	add ax, 8
	cmp al, 63
	jg stopRb
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopRb
	
	jmp continueRb
	
	stopRb:
		jmp LRb
		
	continueRb:
		mov [bx], ax
		inc bx
		jmp findRb
	LRb:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
findRc:
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopRc
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopRc
	
	add ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopRc
	
	jmp continueRc
	
	stopRc:
		jmp LRc
		
	continueRc:
		mov [bx], ax
		inc bx
		jmp findRc
	LRc:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
findRd:
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov cx, 1
	sub cl, [byte ptr colorTemp]
	cmp dl, cl
	je stopRd
	
	sub ax, 8
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopRd
	
	cmp al, 0
	jl stopRd
	jmp continueRd
	
	stopRd:
		jmp LRd
		
	continueRd:
		mov [bx], ax
		inc bx
		jmp findRd
	LRd:
		xor dx, dx

	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleRookMoves

;finds the possible moves for a queen and srores them in the possibleMoves array
proc FindPossibleQueenMoves
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	call FindPossibleRookMoves
	
	ret
endp FindPossibleQueenMoves

;finds the possible moves for a queen and srores them in the possibleMoves array
proc FindPossibleKingMoves
	mov ax, [boardPos]
	push [boardPosEX]
	
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	xor dx, dx
	
	mov bx, offset possibleMoves
	
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopKa
	
	
	sub ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKa
	
	jmp continueKa
	
	stopKa:
		jmp LKa
		
	continueKa:
		mov [bx], ax
		inc bx
	LKa:
		xor dx, dx
	

	mov ax, [boardPos]
	
	
	add ax, 8
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKb
	
	cmp al, 63
	jg stopKb
	jmp continueKb
	
	stopKb:
		jmp LKb
		
	continueKb:
		mov [bx], ax
		inc bx
	LKb:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopKc
	
	
	add ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKc
	
	jmp continueKc
	
	stopKc:
		jmp LKc
		
	continueKc:
		mov [bx], ax
		inc bx
	LKc:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	
	sub ax, 8
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKd
	
	cmp al, 0
	jl stopKd
	jmp continueKd
	
	stopKd:
		jmp LKd
		
	continueKd:
		mov [bx], ax
		inc bx
	LKd:
		xor dx, dx
	
	mov ax, [boardPos]
	
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopKe
	
	
	add ax, 7
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKe
	
	cmp al, 63
	jg stopKe
	jmp continueKe
	
	stopKe:
		jmp LKe
		
	continueKe:
		mov [bx], ax
		inc bx
	LKe:
		xor dx, dx
	

	mov ax, [boardPos]
	
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopKf
	
	
	add ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKf
	
	cmp al, 63
	jg stopKf
	jmp continueKf
	
	stopKf:
		jmp LKf
		
	continueKf:
		mov [bx], ax
		inc bx
	LKf:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopKg
	
	sub ax, 7
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKg
	
	cmp al, 0
	jl stopKg
	jmp continueKg
	
	stopKg:
		jmp LKg
		
	continueKg:
		mov [bx], ax
		inc bx
	LKg:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopKh
	
	
	sub ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopKh
	
	cmp al, 0
	jl stopKh
	jmp continueKh
	
	stopKh:
		jmp LKh
		
	continueKh:
		mov [bx], ax
		inc bx
	LKh:
		xor dx, dx
	
	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleKingMoves

;finds the possible moves for a pawn that advances up in the board and srores them in the possibleMoves array
proc FindPossibleUpPawnMoves
	push [boardPosEX]
	mov ax, [boardPos]
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	xor dx, dx

	mov bx, offset possibleMoves
	mov ax, [boardPos]

findUPa:
	sub ax, 8
	cmp al, 0
	jl stopUPa
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopUPa
	
	jmp continueUPa
	
	stopUPa:
		jmp LUPa
		
	continueUPa:
		mov [bx], ax
		inc bx
	LUPa:
		xor dx, dx
	
	mov ax, [boardPos]
	
	;diagonal capturing
	;-------------------------------------------
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopUPb
	
	sub ax, 7
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopUPb
	cmp dl, 2
	je stopUPb
	
	cmp al, 0
	jl stopUPb
	jmp continueUPb
	
	stopUPb:
		jmp LUpb
		
	continueUPb:
		mov [bx], ax
		inc bx
	LUPb:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopUPc
	
	sub ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopUpc
	cmp dl, 2
	je stopUpc
	
	cmp al, 0
	jl stopUPc
	jmp continueUPc
	
	stopUPc:
		jmp LUPc
		
	continueUPc:
		mov [bx], ax
		inc bx
	LUPc:
		xor dx, dx
	
	mov ax, [boardPos]
	sub ax, 16
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopUPd
	push ax
	mov ax, [boardPos]
	sub ax, 8
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	pop ax
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopUPd
	
	cmp [byte ptr boardPos], 48
	jl stopUPd
	cmp [byte ptr boardPos], 55
	jg stopUPd
	cmp al, 63
	jg stopUPd
	jmp continueUPd
	
	stopUPd:
		jmp LUPd
		
	continueUPd:
		mov [bx], ax
		inc bx
	LUPd:
		xor dx, dx
	
	
	
	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleUpPawnMoves

proc FindPossibleDownPawnMoves
	push [boardPosEX]
	mov ax, [boardPos]
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	xor dx, dx

	mov bx, offset possibleMoves
	mov ax, [boardPos]

findDPa:
	add ax, 8
	cmp al, 64
	jg stopDPa
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopDPa
	
	jmp continueDPa
	
	stopDPa:
		jmp LDPa
		
	continueDPa:
		mov [bx], ax
		inc bx
	LDPa:
		xor dx, dx
	
	mov ax, [boardPos]
	
	;diagonal capturing
	;-------------------------------------------
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopDPb
	
	add ax, 7
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopDPb
	cmp dl, 2
	je stopDPb
	
	cmp al, 63
	jg stopDPb
	jmp continueDPb
	
	stopDPb:
		jmp LDPb
		
	continueDPb:
		mov [bx], ax
		inc bx
	LDPb:
		xor dx, dx
		
	
	mov ax, [boardPos]
	
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopDPc
	
	add ax, 9
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopDPc
	cmp dl, 2
	je stopDPc
	
	cmp al, 63
	jg stopDPc
	jmp continueDPc
	
	stopDPc:
		jmp LDPc
		
	continueDPc:
		mov [bx], ax
		inc bx
	LDPc:
		xor dx, dx
	
	
	mov ax, [boardPos]
	add ax, 16
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopDPd
	push ax
	mov ax, [boardPos]
	add ax, 8
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	pop ax
	mov dx, [ColorOfToolOnSquare]
	cmp dl, 2
	jne stopDPd
	
	cmp [byte ptr boardPos], 8
	jl stopDPd
	cmp [byte ptr boardPos], 15
	jg stopDPd
	cmp al, 63
	jg stopDPd
	jmp continueDPd
	
	stopDPd:
		jmp LDPd
		
	continueDPd:
		mov [bx], ax
		inc bx
	LDPd:
		xor dx, dx
	
	
	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleDownPawnMoves


proc FindPossibleKnightMoves

	push [boardPosEX]

	mov ax, [boardPos]
	push bx
	mov [boardPosEX], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	mov [colorTemp], dx
	
	xor dx, dx

	mov bx, offset possibleMoves

	
	
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopNa
	
	sub ax, 15
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNa
	
	cmp al, 0
	jl stopNa
	jmp continueNa
	
	stopNa:
		jmp LNa
		
	continueNa:
		mov [bx], ax
		inc bx
	LNa:
		xor dx, dx
	

	mov ax, [boardPos]
	
	
	
	;check if ax is in the left edge of the board, if it is, stop the loop
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopNb
	
	add ax, 15
	
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNb
	
	cmp al, 63
	jg stopNb
	
	jmp continueNb
	
	stopNb:
		jmp LNb
		
	continueNb:
		mov [bx], ax
		inc bx
	LNb:
		xor dx, dx
		
	
	mov ax, [boardPos]

	
	;check if ax is in the right edge of the board, if it is, stop the loop
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopNc
	

	add ax, 17
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	
	cmp dl, [byte ptr colorTemp]
	je stopNc
	
	
	cmp al, 63
	jg stopNc
	jmp continueNc
	
	stopNc:
		jmp LNc
		
	continueNc:
		
		mov [bx], ax
		inc bx
	LNc:
		xor dx, dx
	
	mov ax, [boardPos]
	
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopNd
	
	mov ax, [boardPos]
	sub ax, 17
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNd
	
	cmp al, 0
	jl stopNd
	jmp continueNd
	
	stopNd:
		jmp LNd
		
	continueNd:
		mov [bx], ax
		inc bx
	LNd:
		xor dx, dx
	
	mov ax, [boardPos]
	
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopNe
	mov dx, ax
	dec dx
	and dx, 00000111b
	cmp dx, 0
	je stopNe
	
	mov ax, [boardPos]
	sub ax, 10
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNe
	
	cmp al, 0
	jl stopNe
	jmp continueNe
	
	stopNe:
		jmp LNe
		
	continueNe:
		mov [bx], ax
		inc bx
	LNe:
		xor dx, dx
	
	mov ax, [boardPos]
	
	mov dx, ax
	and dx, 00000111b
	cmp dx, 0
	je stopNf
	mov dx, ax
	dec dx
	and dx, 00000111b
	cmp dx, 0
	je stopNf
	
	mov ax, [boardPos]
	add ax, 6
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNf
	
	cmp al, 64
	jg stopNf
	jmp continueNf
	
	stopNf:
		jmp LNf
		
	continueNf:
		mov [bx], ax
		inc bx
	LNf:
		xor dx, dx
	
	
	mov ax, [boardPos]
	
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopNg
	mov dx, ax
	add dx, 2
	and dx, 00000111b
	cmp dx, 0
	je stopNg
	
	mov ax, [boardPos]
	add ax, 10
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNg
	
	cmp al, 63
	jg stopNg
	jmp continueNg
	
	stopNg:
		jmp LNg
		
	continueNg:
		mov [bx], ax
		inc bx
	LNg:
		xor dx, dx
	
	
	mov ax, [boardPos]
	
	mov dx, ax
	inc dx
	and dx, 00000111b
	cmp dx, 0
	je stopNh
	mov dx, ax
	add dx, 2
	and dx, 00000111b
	cmp dx, 0
	je stopNh
	
	mov ax, [boardPos]
	sub ax, 6
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	mov dx, [ColorOfToolOnSquare]
	cmp dl, [byte ptr colorTemp]
	je stopNh
	
	cmp al, 0
	jl stopNh
	jmp continueNh
	
	stopNh:
		jmp LNh
		
	continueNh:
		mov [bx], ax
		inc bx
	LNh:
		xor dx, dx
	
	pop [boardPosEX]
	
	call AdjustPossibleMovesZero
	
	ret
endp FindPossibleKnightMoves

proc FindColorOfToolOnSquare
	mov bx, offset boardArr
	add bx, [boardPosEx]
	mov dl, 7
	cmp [bx], dl
	jl forWhite
	mov dl, 0
	cmp [bx], dl
	je noTool

forBlack:
	mov [ColorOfToolOnSquare], 1
	jmp res

forWhite:
	mov dl, 0
	cmp [bx], dl
	je noTool
	mov [ColorOfToolOnSquare], 0
	jmp res
	
noTool:
	mov [ColorOfToolOnSquare], 2

res:
	xor bx, bx

	ret
endp FindColorOfToolOnSquare

;finds if there's a check from a white pawn
proc FindCheckFromBPawn

	mov bx, offset possibleMoves
	mov dl, 0
	cmp [player1Color], dl
	je downBP
	call FindPossibleUpPawnMoves
	mov cx, 64
	mov bx, offset possibleMoves
	jmp isThereBpawnCheck

downBP:
	call FindPossibleDownPawnMoves
	mov cx, 64
	mov bx, offset possibleMoves
	
isThereBpawnCheck:	
	mov dx, [KingPosW]
	cmp [bx], dl
	je foundBpawnCheck
	inc bx
	loop isThereBpawnCheck
	jmp notfoundBpawnCheck

foundBpawnCheck:
	mov	[IsCheckW], 1
	
notfoundBpawnCheck:
	
	ret
endp FindCheckFromBPawn


proc FindCheckFromBKnight
	mov bx, offset possibleMoves
	call FindPossibleKnightMoves
	mov bx, offset possibleMoves
	mov cx, 64
	xor dx, dx
	
	
	
isThereBknightCheck:	
	mov dl, [byte ptr KingPosW]
	cmp [bx], dl
	je foundBknightCheck
	inc bx
	loop isThereBknightCheck
	jmp notfoundBKnightCheck
	
foundBknightCheck:
	mov	[IsCheckW], 1
	
notfoundBKnightCheck:

	ret
endp FindCheckFromBKnight


proc FindCheckFromBBishop
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereBbishopCheck:	
	mov dl, [byte ptr KingPosW]
	cmp [bx], dl
	je foundBbishopCheck
	inc bx
	loop isThereBbishopCheck
	jmp notfoundBbishopCheck
	
foundBbishopCheck:
	mov	[IsCheckW], 1

notfoundBbishopCheck:
	
	ret
endp FindCheckFromBBishop

proc FindCheckFromBRook
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereBrookCheck:	
	mov dl, [byte ptr KingPosW]
	cmp [bx], dl
	je foundBrookCheck
	inc bx
	loop isThereBrookCheck
	jmp notfoundBRookCheck
	
foundBrookCheck:
	mov	[IsCheckW], 1
	
notfoundBRookCheck:
	
	ret
endp FindCheckFromBRook

proc FindCheckFromBQueen
	mov bx, offset possibleMoves
	call FindPossibleQueenMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereBqueenCheck:	
	mov dl, [byte ptr KingPosW]
	cmp [bx], dl
	je foundBqueenCheck
	inc bx
	loop isThereBqueenCheck
	jmp notfoundBQueenCheck
	
foundBqueenCheck:
	mov	[IsCheckW], 1

notfoundBQueenCheck:

	ret
endp FindCheckFromBQueen

proc FindCheckFromBKing
	mov bx, offset possibleMoves
	call FindPossibleKingMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereBkingCheck:	
	mov dl, [byte ptr KingPosW]
	cmp [bx], dl
	je foundBkingCheck
	inc bx
	loop isThereBkingCheck
	jmp notfoundBKingCheck
	
foundBkingCheck:
	mov	[IsCheckW], 1

notfoundBKingCheck:

	ret
endp FindCheckFromBKing

;proc that tells you if theres a check for the white king
;---------------------------------------------------------
;It does so by going over the black pieces possible moves, and checking if one of them intersects with the
;position of the white king
;---------------------------------------------------------
proc IsThereCheckW
	push bx
	push cx
	push [boardPos]
	push ax
	push [boardPosEX]
	call FindKingW
	
	mov ax, 0
	mov bx, offset possibleMoves
	mov cx, 64

copyPosToExChW:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMovesEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExChW
	
	mov bx, offset boardArr
	mov [boardPos], 0
	mov cx, 64
	
	
	
	
findCheckW:
	push [KingPosW]
	push bx
	push cx
	call ResetPossibleMoves
	pop cx
	pop bx
	push bx
	push cx
	mov dl, 6
	cmp [bx], dl
	jg isBlackTool
	jmp runLCW
	
isBlackTool:
	mov dl, 7
	cmp [bx], dl
	je BkingCheck
	mov dl, 8
	cmp [bx], dl
	je BqueenCheck
	mov dl, 9
	cmp [bx], dl
	je BrookCheck
	mov dl, 10
	cmp [bx], dl
	je BbishopCheck
	mov dl, 11
	cmp [bx], dl
	je BknightCheck
	mov dl, 12
	cmp [bx], dl
	je BpawnCheck
	
BkingCheck:
	call FindCheckFromBKing
	jmp runLCW
	
BqueenCheck:
	call FindCheckFromBQueen
	jmp runLCW

BrookCheck:
	call FindCheckFromBRook
	jmp runLCW
	
BbishopCheck:
	call FindCheckFromBBishop
	jmp runLCW

BknightCheck:
	call FindCheckFromBKnight
	
	jmp runLCW

BpawnCheck:
	call FindCheckFromBPawn
	jmp runLCW

runLCW:
	pop cx
	pop bx
	inc bx
	inc [boardPos]
	pop [KingPosW]
	loop findCheckW
	
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

copyExToPosChW:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMoves
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyExToPosChW
	
	pop [boardPosEX]
	pop ax
	pop [boardPos]
	pop cx
	pop bx
	ret
endp IsThereCheckW

;proc that finds the white king 
proc FindKingW
	push [boardPosEx]
	mov bx, offset boardArr
	mov cx, 64
	mov [boardPosEX], 0

findKW:
	mov dl, 1
	cmp [bx], dl
	je foundKW
	jmp continueKW

foundKW:
	mov ax, [boardPosEx]
	mov [KingPosW], ax

continueKW:
	xor ax, ax
	inc bx
	inc [boardPosEX]
	loop findKW
	
	pop [BoardPosEx]
	
	ret
endp FindKingW

proc FindCheckFromWPawn
	mov bx, offset possibleMoves
	mov dl, 1
	cmp [player1Color], dl
	je downWP
	call FindPossibleUpPawnMoves
	mov cx, 64
	mov bx, offset possibleMoves
	jmp isThereWpawnCheck

downWP:
	call FindPossibleDownPawnMoves
	mov cx, 64
	mov bx, offset possibleMoves
	
isThereWpawnCheck:	
	mov dx, [KingPosB]
	cmp [bx], dl
	je foundWpawnCheck
	inc bx
	loop isThereWpawnCheck
	jmp notfoundWpawnCheck

foundWpawnCheck:
	mov	[IsCheckB], 1
	
notfoundWpawnCheck:
	
	ret
endp FindCheckFromWPawn


proc FindCheckFromWKnight
	mov bx, offset possibleMoves
	call FindPossibleKnightMoves
	mov bx, offset possibleMoves

	mov cx, 64
	xor dx, dx
	
	
	
isThereWknightCheck:	
	mov dl, [byte ptr KingPosB]
	cmp [bx], dl
	je foundWknightCheck
	inc bx
	loop isThereWknightCheck
	jmp notfoundWKnightCheck
	
foundWknightCheck:
	mov	[IsCheckB], 1
	
notfoundWKnightCheck:

	ret
endp FindCheckFromWKnight


proc FindCheckFromWBishop
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereWbishopCheck:	
	mov dl, [byte ptr KingPosB]
	cmp [bx], dl
	je foundWbishopCheck
	inc bx
	loop isThereWbishopCheck
	jmp notfoundWbishopCheck
	
foundWbishopCheck:
	mov	[IsCheckB], 1

notfoundWbishopCheck:
	
	ret
endp FindCheckFromWBishop

proc FindCheckFromWRook
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereWrookCheck:
	mov dl, [byte ptr KingPosB]
	cmp [bx], dl
	je foundWrookCheck
	inc bx
	loop isThereWrookCheck
	jmp notfoundWRookCheck
	
foundWrookCheck:
	mov	[IsCheckB], 1
	
notfoundWRookCheck:
	
	ret
endp FindCheckFromWRook

proc FindCheckFromWQueen
	mov bx, offset possibleMoves
	call FindPossibleQueenMoves
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereWqueenCheck:	
	mov dl, [byte ptr KingPosB]
	cmp [bx], dl
	je foundWqueenCheck
	inc bx
	loop isThereWqueenCheck
	jmp notfoundWQueenCheck
	
foundWqueenCheck:
	mov	[IsCheckB], 1

notfoundWQueenCheck:

	ret
endp FindCheckFromWQueen

proc FindCheckFromWKing
	mov bx, offset possibleMoves
	call FindPossibleKingMoves
	
	mov bx, offset possibleMoves
	mov cx, 64
	
isThereWkingCheck:	
	mov dl, [byte ptr KingPosB]
	cmp [bx], dl
	je foundWkingCheck
	inc bx
	loop isThereWkingCheck
	jmp notfoundWKingCheck
	
foundWkingCheck:
	mov	[IsCheckB], 1

notfoundWKingCheck:

	ret
endp FindCheckFromWKing

;proc that tells you if theres a check for the black king
;---------------------------------------------------------
;It does so by going over the white pieces possible moves, and checking if one of them intersects with the
;position of the black king
;---------------------------------------------------------
proc IsThereCheckB
	push [boardPos]
	push bx
	push cx
	push ax
	push dx
	call FindKingB
	
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

copyPosToExChB:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMoves
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExChB
	
	mov bx, offset boardArr
	mov [boardPos], 0
	mov cx, 64
	
	
	
	
findCheckB:
	push [KingPosB]
	push bx
	push cx
	call ResetPossibleMoves
	pop cx
	pop bx
	push bx
	push cx
	mov dl, 7
	cmp [bx], dl
	jl isWhiteTool
	jmp runLCB
	
isWhiteTool:
	mov dl, 0
	cmp [bx], dl
	je runLCB
	mov dl, 1
	cmp [bx], dl
	je WkingCheck
	mov dl, 2
	cmp [bx], dl
	je WqueenCheck
	mov dl, 3
	cmp [bx], dl
	je WrookCheck
	mov dl, 4
	cmp [bx], dl
	je WbishopCheck
	mov dl, 5
	cmp [bx], dl
	je WknightCheck
	mov dl, 6
	cmp [bx], dl
	je WpawnCheck
	
WkingCheck:
	call FindCheckFromWKing
	jmp runLCB
	
WqueenCheck:
	call FindCheckFromWQueen
	jmp runLCB

WrookCheck:
	call FindCheckFromWRook
	jmp runLCB
	
WbishopCheck:
	call FindCheckFromWBishop
	jmp runLCB

WknightCheck:
	call FindCheckFromWKnight
	jmp runLCB

WpawnCheck:
	call FindCheckFromWPawn
	jmp runLCB

runLCB:
	pop cx
	pop bx
	inc bx
	inc [boardPos]
	pop [KingPosB]
	loop findCheckB
	
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

copyExToPosChB:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMoves
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyExToPosChB
	
	pop dx
	pop ax
	pop cx
	pop bx
	pop [boardPos]
	ret
endp IsThereCheckB

;proc that finds the white king 
proc FindKingB
	push [boardPosEX]
	mov bx, offset boardArr
	mov cx, 64
	mov [boardPosEX], 0

findKB:
	mov dl, 7
	cmp [bx], dl
	je foundKB
	jmp continueKBa

foundKB:
	mov ax, [boardPosEx]
	mov [KingPosB], ax

continueKBa:
	xor ax, ax
	inc bx
	inc [boardPosEX]
	loop findKB

	pop [boardPosEX]

	ret
endp FindKingB

;proc for drawing the green square that indicates a possible move
proc DrawMoveInd
	push dx
	push ax
	call FindSquareCoords
	mov dx, [x]
	add dx, 9
	mov [printAdd], dx
	mov dx, [y]
	add dx, 9*320
	add [printAdd], dx
	mov ax, offset moveInd
	call PrintBmp
	pop ax
	pop dx
	
	ret
endp DrawMoveInd

;proc that goes over the possible moves array and draws a green square where there's a valid move
proc DrawPossibleMoves
	mov bx, offset possibleMoves
	mov cx, 64
	xor ax, ax
	xor dx, dx
	mov [boardPos], 0
	
drawPos:
	mov [x], 0
	mov [y], 0
	mov [printAdd], 0
	push cx
	push bx
	cmp [byte ptr bx], 64
	je continueDrawPos
	
	xor ax, ax
	
	mov dh, 0
	mov dl, [byte ptr bx]
	
	xor bx, bx
	mov [boardPos], dx
	call DrawMoveInd
	

continueDrawPos:
	xor ax, ax
	pop bx
	pop cx
	inc bx
	loop drawPos

	ret
endp DrawPossibleMoves

;draws the castle moves
proc DrawCastle
	push [boardPos]
	push ax
	
	cmp [byte ptr castleAW], 64
	jne DrawCastleA
	jmp continueCastleA
	
DrawCastleA:
	mov ax, [CastleAW]
	mov [boardPos], ax
	call DrawMoveInd
	
continueCastleA:
	cmp [byte ptr castleAB], 64
	jne DrawCastleB
	jmp continueCastleB
	
DrawCastleB:
	mov ax, [CastleAB]
	mov [boardPos], ax
	call DrawMoveInd
	
continueCastleB:
	cmp [byte ptr castleSW], 64
	jne DrawCastleC
	jmp continueCastleC
	
DrawCastleC:
	mov ax, [CastleSW]
	mov [boardPos], ax
	call DrawMoveInd
	
continueCastleC:
	cmp [byte ptr castleSB], 64
	jne DrawCastleD
	jmp continueCastleD
	
DrawCastleD:
	mov ax, [CastleSB]
	mov [boardPos], ax
	call DrawMoveInd
	
continueCastleD:
	pop ax
	pop [boardPos]
	
	ret
endp DrawCastle

;the following procedures are for specific cases of the white player clicking on the board
;----------------------------------------------------------------------------------------
proc WClickedOnWking
	mov [ToolClickedOn], 1
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleKingMoves
	call AdjustPossibleMovesCheckW
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	call CanCastleW
	call DrawCastle

	ret
endp WClickedOnWking


proc WClickedOnWQueen
	mov [ToolClickedOn], 2
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleQueenMoves
	call AdjustPossibleMovesCheckW
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp WClickedOnWQueen


proc WClickedOnWRook
	mov [ToolClickedOn], 3
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	push bx
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	call AdjustPossibleMovesCheckW
	pop bx
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp WClickedOnWRook


proc WClickedOnWBishop
	mov [ToolClickedOn], 4
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	push bx
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	call AdjustPossibleMovesCheckW
	pop bx
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp WClickedOnWBishop


proc WClickedOnWKnight
	mov [ToolClickedOn], 5
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleKnightMoves
	call AdjustPossibleMovesCheckW
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp WClickedOnWKnight


proc WClickedOnWPawn
	call ResetPossibleMoves
	mov [ToolClickedOn], 6
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	cmp [player1Color], 1
	je whitePawnDown
	
whitePawnUp:
	call FindPossibleUpPawnMoves
	call AdjustPossibleMovesCheckW
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	jmp fin
	
whitePawnDown:
	call FindPossibleDownPawnMoves
	call AdjustPossibleMovesCheckW
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	
fin:

	
	ret
endp WClickedOnWPawn


proc WClickedOnBlackOrEmptySquare
	push bx
	push cx
	push ax
	
	
	call ClickedOnCastleW
	call CheckIfInPossibleMoves
	cmp [byte ptr InPossibleMoves], 1
	je BOEInPos
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	call ResetPossibleMoves
	mov [CastleAW], 64
	mov [CastleSW], 64
	jmp endWBOE
	
BOEInPos:
	mov bx, offset boardArr
	add bx, [boardPosEX]
	mov dl, 0
	mov [bx], dl 
	mov bx, offset boardArr
	add bx, [boardPos]
	mov ax, [ToolClickedOn]
	mov [bx], al
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	call ResetPossibleMoves
	mov [turn], 1
	cmp [byte ptr ToolClickedOn], 1
	je KmovedW
	cmp [byte ptr ToolClickedOn], 3
	je RmovedW
	jmp endWBOE

KmovedW:
	mov [KingMovedW], 1
	jmp endWBOE

RmovedW:
	mov [RookMovedW], 1
	
endWBOE:
	pop ax
	pop cx
	pop bx

	ret
endp WClickedOnBlackOrEmptySquare

;proc for when white wants to castle
proc ClickedOnCastleW
	push ax
	push bx
	push dx
	push cx
	push [boardPos]
	
	cmp [byte ptr ToolClickedOn], 1
	
	call FindKingW
	
	mov ax, [CastleAW]
	cmp ax, [boardPos]
	je AddCastleW
	mov ax, [CastleSW]
	cmp ax, [boardPos]
	jne endCW

SubCastleW:
	mov bx, offset boardArr
	add bx, [KingPosW]
	mov dl, 0
	mov [bx], dl
	sub bx, 2
	mov dl, 1
	mov [bx], dl
	inc bx
	mov dl, 3
	mov [bx], dl
	mov cx, 2
	call FindKingW
	mov bx, offset boardArr
	add bx, [KingPosW]
	
SubDelRW:
	dec bx
	mov dl, [bx]
	cmp dl, 3
	je delRW
	loop SubDelRW
	jmp endCW
	
AddCastleW:
	mov bx, offset boardArr
	add bx, [KingPosW]
	mov dl, 0
	mov [bx], dl
	add bx, 2
	mov dl, 1
	mov [bx], dl
	dec bx
	mov dl, 3
	mov [bx], dl
	mov cx, 2
	call FindKingW
	mov bx, offset boardArr
	add bx, [KingPosW]
	
AddDelRW:
	inc bx
	mov dl, [bx]
	cmp dl, 3
	je delRW
	loop AddDelRW

delRW:
	mov dl, 0
	mov [bx], dl 
	mov [turn], 1
	
endCW:
	pop [boardPos]
	pop cx
	pop dx
	pop bx
	pop ax
	
	ret
endp ClickedOnCastleW


;proc for when white wants to castle
proc ClickedOnCastleB
	push ax
	push bx
	push dx
	push cx
	push [boardPos]
	
	cmp [byte ptr ToolClickedOn], 7
	
	call FindKingB
	
	mov ax, [CastleAB]
	cmp ax, [boardPos]
	je AddCastleB
	mov ax, [CastleSB]
	cmp ax, [boardPos]
	jne endCB

SubCastleB:
	mov bx, offset boardArr
	add bx, [KingPosB]
	mov dl, 0
	mov [bx], dl
	sub bx, 2
	mov dl, 7
	mov [bx], dl
	inc bx
	mov dl, 9
	mov [bx], dl
	mov cx, 2
	call FindKingB
	mov bx, offset boardArr
	add bx, [KingPosB]
	
SubDelRB:
	dec bx
	mov dl, [bx]
	cmp dl, 9
	je delRB
	loop SubDelRB
	jmp endCB
	
AddCastleB:
	mov bx, offset boardArr
	add bx, [KingPosB]
	mov dl, 0
	mov [bx], dl
	add bx, 2
	mov dl, 7
	mov [bx], dl
	dec bx
	mov dl, 9
	mov [bx], dl
	mov cx, 2
	call FindKingB
	mov bx, offset boardArr
	add bx, [KingPosB]
	
AddDelRB:
	inc bx
	mov dl, [bx]
	cmp dl, 9
	je delRB
	loop AddDelRB

delRB:
	mov dl, 0
	mov [bx], dl 
	mov [turn], 0
	
endCB:
	pop [boardPos]
	pop cx
	pop dx
	pop bx
	pop ax
	
	ret
endp ClickedOnCastleB



;checks if a position on the board is in the possibleMoves array
proc CheckIfInPossibleMoves
	push cx
	push bx
	mov cx, 64
	mov bx, offset possibleMoves
	
isInPos:
	mov al, [bx]
	cmp [byte ptr boardPos], al
	je foundInPos
	inc bx
	loop isInPos
	jmp endInPos
	
foundInPos:
	mov [InPossibleMoves], 1
	
endInPos:
	pop bx
	pop cx

	ret
endp CheckIfInPossibleMoves

;handle the case in which the white player clicked on the board
proc WhiteClicked
	
	call FindSquareArr
	mov bx, offset boardArr
	add bx, [boardPos]
	cmp [byte ptr bx], 1
	je ClickedOnWKing
	cmp [byte ptr bx], 2
	je ClickedOnWQueen
	cmp [byte ptr bx], 3
	je ClickedOnWRook
	cmp [byte ptr bx], 4
	je ClickedOnWBishop
	cmp [byte ptr bx], 5
	je ClickedOnWKnight
	cmp [byte ptr bx], 6
	je ClickedOnWPawn
	jmp ClickedOnBlackOrEmptySquare

ClickedOnWKing:
	call WClickedOnWking
	jmp continueWC
	
ClickedOnWQueen:
	call WClickedOnWQueen
	jmp continueWC
	
ClickedOnWRook:
	call WClickedOnWRook
	jmp continueWC
	
ClickedOnWBishop:
	call WClickedOnWBishop
	jmp continueWC
	
ClickedOnWKnight:
	call WClickedOnWKnight
	jmp continueWC
	
ClickedOnWPawn:
	call WClickedOnWPawn
	jmp continueWc
	
ClickedOnBlackOrEmptySquare:
	call WClickedOnBlackOrEmptySquare
	
continueWC:
	
	
	ret
endp WhiteClicked


;the following procedures are for specific cases of the black player clicking on the board
;----------------------------------------------------------------------------------------
proc BClickedOnBking
	mov [ToolClickedOn], 7
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleKingMoves
	call AdjustPossibleMovesCheckB
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	call CanCastleB
	call DrawCastle

	ret
endp BClickedOnBking


proc BClickedOnBQueen
	mov [ToolClickedOn], 8
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleQueenMoves
	call AdjustPossibleMovesCheckB
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp BClickedOnBQueen


proc BClickedOnBRook
	mov [ToolClickedOn], 9
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	push bx
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	call AdjustPossibleMovesCheckB
	pop bx
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp BClickedOnBRook


proc BClickedOnBBishop
	mov [ToolClickedOn], 10
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	push bx
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	call AdjustPossibleMovesCheckB
	pop bx
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp BClickedOnBBishop


proc BClickedOnBKnight
	mov [ToolClickedOn], 11
	call ResetPossibleMoves
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	call FindPossibleKnightMoves
	call AdjustPossibleMovesCheckB
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves

	ret
endp BClickedOnBKnight


proc BClickedOnBPawn
	call ResetPossibleMoves
	mov [ToolClickedOn], 12
	push [boardPos]
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	
	pop [boardPos]
	mov ax, [boardPos]
	mov [boardPosEX], ax
	cmp [player1Color], 0
	je blackPawnDown
	
blackPawnUp:
	call FindPossibleUpPawnMoves
	call AdjustPossibleMovesCheckB
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	jmp finB
	
blackPawnDown:
	call FindPossibleDownPawnMoves
	call AdjustPossibleMovesCheckB
	mov [imgHeight], 7
	mov [imgWidth], 7
	call DrawPossibleMoves
	
finB:
	
	ret
endp BClickedOnBPawn


proc BClickedOnWhiteOrEmptySquare
	push bx
	push cx
	push ax
	
	call CheckIfInPossibleMoves
	call ClickedOnCastleB
	cmp [byte ptr InPossibleMoves], 1
	je WOEInPos
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	call ResetPossibleMoves
	mov [CastleAB], 64
	mov [CastleSB], 64
	jmp endBWOE
	
WOEInPos:
	mov bx, offset boardArr
	add bx, [boardPosEX]
	mov dl, 0
	mov [bx], dl 
	mov bx, offset boardArr
	add bx, [boardPos]
	mov ax, [ToolClickedOn]
	mov [bx], al
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	call ResetPossibleMoves
	mov [turn], 0
	cmp [byte ptr ToolClickedOn], 7
	je KmovedB
	cmp [byte ptr ToolClickedOn], 9
	je RmovedB
	jmp endBWOE

KmovedB:
	mov [KingMovedB], 1
	jmp endBWOE

RmovedB:
	mov [RookMovedB], 1
	
endBWOE:
	pop ax
	pop cx
	pop bx

	ret
endp BClickedOnWhiteOrEmptySquare


;handle the case in which the black player clicked on the board
proc BlackClicked
	
	call FindSquareArr
	mov bx, offset boardArr
	add bx, [boardPos]
	cmp [byte ptr bx], 7
	je ClickedOnBKing
	cmp [byte ptr bx], 8
	je ClickedOnBQueen
	cmp [byte ptr bx], 9
	je ClickedOnBRook
	cmp [byte ptr bx], 10
	je ClickedOnBBishop
	cmp [byte ptr bx], 11
	je ClickedOnBKnight
	cmp [byte ptr bx], 12
	je ClickedOnBPawn
	jmp ClickedOnWhiteOrEmptySquare

ClickedOnBKing:
	call BClickedOnBking
	jmp continueBCl
	
ClickedOnBQueen:
	call BClickedOnBQueen
	jmp continueBCl
	
ClickedOnBRook:
	call BClickedOnBRook
	jmp continueBCl
	
ClickedOnBBishop:
	call BClickedOnBBishop
	jmp continueBCl
	
ClickedOnBKnight:
	call BClickedOnBKnight
	jmp continueBCl
	
ClickedOnBPawn:
	call BClickedOnBPawn
	jmp continueBCl
	
ClickedOnWhiteOrEmptySquare:
	call BClickedOnWhiteOrEmptySquare
	
continueBCl:
	
	
	ret
endp BlackClicked

;adjusts the possibleMoves array considering if theres a check for the white king
;---------------------------------------------------------------------------------
;It does so by going over the possible moves array, and "playing" the each move temporarily in the boardArr
;Then it checks if there's a Check for the white king in the position created after the move "is played"
;And if there is, it deletes this move from t  he possibleMoves array, and continues going over the array.
;---------------------------------------------------------------------------------
proc AdjustPossibleMovesCheckW
	push cx
	push bx
	push ax
	push dx
	push [boardPosEX]
	mov ax, 0
	mov bx, offset boardArr
	mov cx, 64
	
copyBoardToExW:
	mov dl, [bx]
	push bx
	mov bx, offset boardArrEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyBoardToExW

	mov ax, 0
	mov bx, offset possibleMoves
	mov cx, 64

copyPosToExW:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMovesEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExW

	mov bx, offset possibleMoves
	mov cx, 64
	mov ax, 0
	
checkPosW:
	push [boardPosEX]
	push cx
	push bx
	push ax
	mov [IsCheckW], 0
	mov dh, 0
	mov dl, [bx]
	cmp dl, 64
	je CCPW
	mov bx, offset boardArr
	add bx, [boardPosEX]
	push dx
	mov dl, 0
	mov [bx], dl
	pop dx
	mov bx, offset boardArr
	add bx, dx
	mov ax, [ToolClickedOn]
	mov [bx], al
	call IsThereCheckW
	cmp [byte ptr IsCheckW], 0
	je CCPW
	
theresCheckW:
	mov bx, offset possibleMovesEx
	pop ax
	add bx, ax
	mov dl, 64
	mov [bx], dl
	push ax
	
CCPW:
	mov ax, 0
	mov bx, offset boardArrEx
	mov cx, 64
	copyExToBoardW:
		mov dl, [bx]
		push bx
		mov bx, offset boardArr
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToBoardW
	
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

	copyExToPosW:
		mov dl, [bx]
		push bx
		mov bx, offset possibleMoves
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToPosW
	
	pop ax
	inc ax
	pop bx
	inc bx
	pop cx
	pop [boardPosEx]
	loop checkPosW 
	
	pop [boardPosEX]
	pop dx
	pop ax
	pop bx
	pop cx

	ret
endp AdjustPossibleMovesCheckW

;adjusts the possibleMoves array considering if theres a check for the black king
;---------------------------------------------------------------------------------
;It does so by going over the possible moves array, and "playing" the each move temporarily in the boardArr
;Then it checks if there's a Check for the black king in the position created after the move "is played"
;And if there is, it deletes this move from the possibleMoves array, and continues going over the array.
;---------------------------------------------------------------------------------
proc AdjustPossibleMovesCheckB
	push cx
	push bx
	push ax
	push dx
	push [boardPosEX]
	mov ax, 0
	mov bx, offset boardArr
	mov cx, 64
	
copyBoardToExB:
	mov dl, [bx]
	push bx
	mov bx, offset boardArrEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyBoardToExB

	mov ax, 0
	mov bx, offset possibleMoves
	mov cx, 64

copyPosToExB:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMovesEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExB

	mov bx, offset possibleMoves
	mov cx, 64
	mov ax, 0
	
checkPosB:
	push cx
	push bx
	push ax
	mov [IsCheckB], 0
	mov dh, 0
	mov dl, [bx]
	cmp dl, 64
	je CCPB
	mov bx, offset boardArr
	add bx, [boardPosEX]
	push dx
	mov dl, 0
	mov [bx], dl
	pop dx
	mov bx, offset boardArr
	add bx, dx
	mov ax, [ToolClickedOn]
	mov [bx], al
	call IsThereCheckB
	cmp [byte ptr IsCheckB], 0
	je CCPB
	
theresCheckB:
	mov bx, offset possibleMovesEx
	pop ax
	add bx, ax
	mov dl, 64
	mov [bx], dl
	push ax
	
CCPB:
	call CopyExToBoard
	
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

	copyExToPosB:
		mov dl, [bx]
		push bx
		mov bx, offset possibleMoves
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToPosB
	
	pop ax
	inc ax
	pop bx
	inc bx
	pop cx
	loop checkPosB
	
	pop [boardPosEX]
	pop dx
	pop ax
	pop bx
	pop cx

	ret
endp AdjustPossibleMovesCheckB

;proc that reverses the board
proc ReverseBoard
	push bx
	push ax
	push dx
	push cx
	
	mov bx, offset boardArr
	mov cx, 32
	mov ax, 0
	
reverseLoop:
	push ax
	mov dx, 63
	sub dx, ax
	mov ax, dx
	xor dx, dx
	mov dl, [bx]
	push bx
	mov bx, offset boardArr
	add bx, ax
	xor ax, ax
	mov al, [bx]
	mov [bx], dl
	pop bx
	mov [bx], al
	pop ax
	inc ax
	inc bx
	loop reverseLoop
	
	xor ax, ax
	mov al, 1
	sub al, [player1Color]
	mov [player1Color], al
	mov al, 1
	sub al, [player2Color]
	mov [player2Color], al
	
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	mov ax, offset board
	call PrintBmp
	
	push [boardPos]
	mov [imgHeight], 25
	mov [imgWidth], 25
	call DrawBoard
	pop [boardPos]
	
	
	pop cx
	pop dx
	pop ax
	pop bx

	ret
endp ReverseBoard

;checks if user clicked on the reverse button
proc CheckIfClickedOnReverse
	cmp cx, 220
	jl notOnRev
	cmp cx, 258
	jg notOnRev
	cmp dx, 25
	jg notOnRev
	
	call ReverseBoard
	
notOnRev:
	

	ret
endp CheckIfClickedOnReverse


;checks if white won
;-------------------------------------------------------------------------
;It does so by checking if there's a check for the black king, and if so, if none of the black pieces have
;Moves, it means that black lost
;-------------------------------------------------------------------------
proc CheckIfMateB
	push [ToolClickedOn]
	push ax
	push cx
	push bx
	push [boardPos]
	push [boardPosEX]
	
	mov cx, 64
	mov ax, 0
	mov bx, offset possibleMoves
	
copyPosToExCmB:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMovesEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExCmB
	
	call IsThereCheckB
	cmp [byte ptr IsCheckB], 0
	je endCMStopB
	
yesCheckB:
	
	mov bx, offset boardArr
	mov cx, 64
	mov [boardPos], 0
	
scanB:
	push bx
	push cx
	push [boardPos]
	push bx
	push cx
	call ResetPossibleMoves
	pop cx
	pop bx
	
	cmp [byte ptr bx], 7
	je BKPos
	cmp [byte ptr bx], 8
	je BQPos
	cmp [byte ptr bx], 9
	je BRPos
	cmp [byte ptr bx], 10
	je BBPos
	cmp [byte ptr bx], 11
	je BNPos
	cmp [byte ptr bx], 12
	je BPPos
	jmp continueScanB

endCMStopB:
	jmp endCheckMateB

loopStopCMB:
	loop scanB
	jmp yesCheckMateB
	
BKPos:
	mov [ToolClickedOn], 7
	call FindPossibleKingMoves
	jmp CheckIfMovesB

BQPos:
	mov [ToolClickedOn], 8
	call FindPossibleQueenMoves
	jmp CheckIfMovesB
	
BRPos:
	mov [ToolClickedOn], 9
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	jmp CheckIfMovesB
	
BBPos:
	mov [ToolClickedOn], 10
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	jmp CheckIfMovesB
	
BNPos:
	mov [ToolClickedOn], 11
	call FindPossibleKnightMoves
	jmp CheckIfMovesB
	
BPPos:
	mov [ToolClickedOn], 12
	cmp [byte ptr player1Color], 0
	je BDPPOS
	call FindPossibleUpPawnMoves
	jmp CheckIfMovesB
	
BDPPOS:
	call FindPossibleDownPawnMoves

CheckIfMovesB:
	call AdjustPossibleMovesCheckB
	mov bx, offset possibleMoves
	mov cx, 64
	
CheckIfMovesBLoop:
	cmp [byte ptr bx], 64
	jne endScanB
	inc bx
	loop CheckIfMovesBLoop

continueScanB:
	call ResetPossibleMoves
	pop [boardPos]
	pop cx
	pop bx
	inc bx
	inc [boardPos]
	jmp loopStopCMB

yesCheckMateB:
	mov [CheckMateB], 1
	jmp endCheckMateB
	
endScanB:
	pop [boardPos]
	pop cx
	pop bx
	
	
	
	
endCheckMateB:
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

	copyExToPosCmB:
		mov dl, [bx]
		push bx
		mov bx, offset possibleMoves
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToPosCmB

	pop [boardPosEX]
	pop [boardPos]
	pop bx
	pop cx
	pop ax
	pop [ToolClickedOn]
	
	ret
endp CheckIfMateB


;check if black won
;-------------------------------------------------------------------------
;It does so by checking if there's a check for the white king, and if so, if none of the white pieces have
;Moves, it means that white lost
;-------------------------------------------------------------------------
proc CheckIfMateW
	push [ToolClickedOn]
	push ax
	push cx
	push bx
	push [boardPos]
	push [boardPosEX]
	
	mov cx, 64
	mov ax, 0
	mov bx, offset possibleMoves
	
copyPosToExCmW:
	mov dl, [bx]
	push bx
	mov bx, offset possibleMovesEx
	add bx, ax
	mov [bx], dl
	pop bx
	inc bx
	inc ax
	loop copyPosToExCmW
	
	call IsThereCheckW
	cmp [byte ptr IsCheckW], 0
	je endCMStopW
	
	
yesCheckW:
	
	mov bx, offset boardArr
	mov cx, 64
	mov [boardPos], 0
	
scanW:
	push bx
	push cx
	push [boardPos]
	push bx
	push cx
	call ResetPossibleMoves
	pop cx
	pop bx
	
	cmp [byte ptr bx], 1
	je WKPos
	cmp [byte ptr bx], 2
	je WQPos
	cmp [byte ptr bx], 3
	je WRPos
	cmp [byte ptr bx], 4
	je WBPos
	cmp [byte ptr bx], 5
	je WNPos
	cmp [byte ptr bx], 6
	je WPPos
	jmp continueScanW

endCMStopW:
	jmp endCheckMateW

loopStopCMW:
	loop scanW
	jmp yesCheckMateW
	
WKPos:
	mov [ToolClickedOn], 1
	call FindPossibleKingMoves
	jmp CheckIfMovesW

WQPos:
	mov [ToolClickedOn], 2
	call FindPossibleQueenMoves
	jmp CheckIfMovesW
	
WRPos:
	mov [ToolClickedOn], 3
	mov bx, offset possibleMoves
	call FindPossibleRookMoves
	jmp CheckIfMovesW
	
WBPos:
	mov [ToolClickedOn], 4
	mov bx, offset possibleMoves
	call FindPossibleBishopMoves
	jmp CheckIfMovesW
	
WNPos:
	mov [ToolClickedOn], 5
	call FindPossibleKnightMoves
	jmp CheckIfMovesW
	
WPPos:
	mov [ToolClickedOn], 6
	cmp [byte ptr player1Color], 1
	je WDPPOS
	call FindPossibleUpPawnMoves
	jmp CheckIfMovesW
	
WDPPOS:
	call FindPossibleDownPawnMoves

CheckIfMovesW:
	call AdjustPossibleMovesCheckW
	mov bx, offset possibleMoves
	mov cx, 64
	
CheckIfMovesWLoop:
	cmp [byte ptr bx], 64
	jne endScanW
	inc bx
	loop CheckIfMovesWLoop

continueScanW:
	call ResetPossibleMoves
	pop [boardPos]
	pop cx
	pop bx
	inc bx
	inc [boardPos]
	jmp loopStopCMW

yesCheckMateW:
	mov [CheckMateW], 1
	jmp endCheckMateW
	
endScanW:
	pop [boardPos]
	pop cx
	pop bx
	
	
	
	
endCheckMateW:
	mov ax, 0
	mov bx, offset possibleMovesEx
	mov cx, 64

	copyExToPosCmW:
		mov dl, [bx]
		push bx
		mov bx, offset possibleMoves
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToPosCmW

	pop [boardPosEX]
	pop [boardPos]
	pop bx
	pop cx
	pop ax
	pop [ToolClickedOn]
	
	ret
endp CheckIfMateW

;shows the screen for when white won the game
proc WhiteWonScreen
	push ax
	
	;reset the screen
	call GraphicsMode
	
	;print the picture that says white won
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	
	mov ax, offset WhiteW
	call PrintBmp
	
	;print the picture that says the game is over
	mov [printAdd], 212
	add [printAdd], 75*320
	mov [imgHeight], 75
	mov [imgWidth], 96
	mov ax, offset GameOC
	call PrintBmp
	
	;print the restart button
	mov [printAdd], 244
	add [printAdd], 120*320
	mov [imgHeight], 25
	mov [imgWidth], 32
	mov ax, offset ResC
	call PrintBmp
	
	mov ax, 0h
	int 33h
	mov ax, 1h
	int 33h
	
	;wait until the player clicks the restart game button
WaitForRestartW:
	mov ax, 3h
	int 33h
	cmp bx, 1
	jne WaitForRestartW
	shr cx, 1
	cmp cx, 244
	jl WaitForRestartW
	cmp cx, 276
	jg WaitForRestartW
	cmp dx, 120
	jl WaitForRestartW
	cmp dx, 145
	jg WaitForRestartW
	
	
	
	ret
endp WhiteWonScreen

;shows the screen for when black won the game
proc BlackWonScreen
	push ax
	
	;reset the screen
	call GraphicsMode
	
	;print the picture that says black won
	mov [printAdd], 0
	mov [imgHeight], 200
	mov [imgWidth], 200
	
	mov ax, offset BlackW
	call PrintBmp
	
	;print the picture that says the game is over
	mov [printAdd], 212
	add [printAdd], 75*320
	mov [imgHeight], 75
	mov [imgWidth], 96
	mov ax, offset GameOC
	call PrintBmp
	
	;print the restart button
	mov [printAdd], 244
	add [printAdd], 120*320
	mov [imgHeight], 25
	mov [imgWidth], 32
	mov ax, offset ResC
	call PrintBmp
	
	mov ax, 1h
	int 33h
	
	;wait until the player clicks the restart game button
WaitForRestartB:
	mov ax, 3h
	int 33h
	cmp bx, 1
	jne WaitForRestartB
	shr cx, 1
	cmp cx, 244
	jl WaitForRestartB
	cmp cx, 276
	jg WaitForRestartB
	cmp dx, 120
	jl WaitForRestartB
	cmp dx, 145
	jg WaitForRestartB
	
	
	
	ret
endp BlackWonScreen

;proc that checks if white can castle
proc CanCastleW
	push ax
	push bx
	push dx
	push cx
	push [boardPos]
	push [boardPosEx]
	
	call FindKingW
	mov ax, [KingPosW]
	mov [boardPos], ax
	
	call CopyBoardToEx
	
	cmp [byte ptr player1Color], 0
	je TwoRunsW

ThreeRunsW:
	mov cx, 2
	push cx
	mov cx, 3
	jmp CheckCondW
	
TwoRunsW:
	mov cx, 3
	push cx
	mov cx, 2
	
CheckCondW:
	
	;if king moved, white cant castle
	cmp [byte ptr KingMovedW], 1
	je endCastleWstop
	
	;if rook moved, white cant castle
	cmp [byte ptr RookMovedW], 1
	je endCastleWstop
	
	;if theres check, white cant castle
	call IsThereCheckW
	cmp [byte ptr IsCheckW], 1
	je endCastleWstop
	
SetAWLoop:
	mov ax, [boardPos]
	
castleAWL:
	add ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	cmp [byte ptr ColorOfToolOnSquare], 2
	jne SetSWLoop
	
	mov bx, offset boardArr
	add bx, [boardPos]
	mov dl, 0
	mov [bx], dl
	mov bx, offset boardArr
	add bx, ax
	mov dl, 1
	mov [bx], dl
	
	call IsThereCheckW
	cmp [byte ptr IsCheckW], 1
	je SetSWLoop
	
	push ax
	push cx
	
	call CopyExToBoard
	
	pop cx
	pop ax
	loop castleAWL
	
	;the white player can castle to one side
	mov ax, [boardPos]
	add ax, 2
	mov [CastleAW], ax
	
	
	
SetSWLoop:
	call CopyExToBoard
	mov ax, [boardPos]
	pop cx
	jmp CastleSWL
	
endCastleWstop:
	pop cx
	jmp endCastleW
	
castleSWL:
	sub ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	cmp [byte ptr ColorOfToolOnSquare], 2
	jne endCastleW
	
	mov bx, offset boardArr
	add bx, [boardPos]
	mov dl, 0
	mov [bx], dl
	mov bx, offset boardArr
	add bx, ax
	mov dl, 1
	mov [bx], dl
	
	call IsThereCheckW
	cmp [byte ptr IsCheckW], 1
	je endCastleW
	
	push ax
	push cx
	
	call CopyExToBoard
	
	pop cx
	pop ax
	loop castleSWL
	
	;the white player can castle to the other side
	mov ax, [boardPos]
	sub ax, 2
	mov [CastleSW], ax
	
endCastleW:
	call CopyExToBoard
	pop [boardPosEx]
	pop [boardPos]
	pop cx
	pop dx
	pop bx
	pop cx

	ret
endp CanCastleW


;proc that checks if black can castle
proc CanCastleB
	push ax
	push bx
	push dx
	push cx
	push [boardPos]
	push [boardPosEx]
	
	
	call FindKingB
	mov ax, [KingPosB]
	mov [boardPos], ax
	
	call CopyBoardToEx
	
	
	cmp [byte ptr player1Color], 0
	je TwoRunsB

ThreeRunsB:
	mov cx, 2
	push cx
	mov cx, 3
	jmp CheckCondB
	
TwoRunsB:
	mov cx, 3
	push cx
	mov cx, 2
	
CheckCondB:
	
	;if king moved, white cant castle
	cmp [byte ptr KingMovedB], 1
	je endCastleBstop
	
	;if rook moved, white cant castle
	cmp [byte ptr RookMovedB], 1
	je endCastleBstop
	
	;if theres check, white cant castle
	
	call IsThereCheckB
	cmp [byte ptr IsCheckB], 1
	je endCastleBstop
	
SetABLoop:
	mov ax, [boardPos]
	
castleABL:
	add ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	cmp [byte ptr ColorOfToolOnSquare], 2
	jne SetSBLoop
	
	mov bx, offset boardArr
	add bx, [boardPos]
	mov dl, 0
	mov [bx], dl
	mov bx, offset boardArr
	add bx, ax
	mov dl, 7
	mov [bx], dl
	
	call IsThereCheckB
	cmp [byte ptr IsCheckB], 1
	je SetSBLoop
	
	push ax
	push cx
	
	call CopyExToBoard
	
	pop cx
	pop ax
	loop castleABL
	
	;the white player can castle to one side
	mov ax, [boardPos]
	add ax, 2
	mov [CastleAB], ax
	
	
	
SetSBLoop:
	call CopyExToBoard
	mov ax, [boardPos]
	pop cx
	jmp CastleSBL
	
endCastleBstop:
	pop cx
	jmp endCastleB
	
castleSBL:
	sub ax, 1
	
	push bx
	mov [boardPosEx], ax
	call FindColorOfToolOnSquare
	pop bx
	cmp [byte ptr ColorOfToolOnSquare], 2
	jne endCastleB
	
	mov bx, offset boardArr
	add bx, [boardPos]
	mov dl, 0
	mov [bx], dl
	mov bx, offset boardArr
	add bx, ax
	mov dl, 7
	mov [bx], dl
	
	call IsThereCheckB
	cmp [byte ptr IsCheckB], 1
	je endCastleB
	
	push ax
	push cx
	
	call CopyExToBoard
	
	pop cx
	pop ax
	loop castleSBL
	
	;the black player can castle to the other side
	mov ax, [boardPos]
	sub ax, 2
	mov [CastleSB], ax
	
endCastleB:
	call CopyExToBoard
	pop [boardPosEx]
	pop [boardPos]
	pop cx
	pop dx
	pop bx
	pop cx
	
	ret
endp CanCastleB



proc CopyBoardToEx
	mov ax, 0
	mov bx, offset boardArr
	mov cx, 64
	
	copyBoardToExP:
		mov dl, [bx]
		push bx
		mov bx, offset boardArrEx
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyBoardToExP

	ret
endp CopyBoardToEx


proc CopyExToBoard
	mov ax, 0
	mov bx, offset boardArrEx
	mov cx, 64
	
	copyExToBoardP:
		mov dl, [bx]
		push bx
		mov bx, offset boardArr
		add bx, ax
		mov [bx], dl
		pop bx
		inc bx
		inc ax
		loop copyExToBoardP

	ret
endp CopyExToBoard


;-------------------------------------------
;in the possible moves array there's a bug: there's an unwanted '0' square move no matter what
;so this proc deletes this move
;-------------------------------------------
proc AdjustPossibleMovesZero
	push cx
	push bx
	mov bx, offset possibleMoves
	mov cx, 64
	
findZero:
	cmp [byte ptr bx], 0
	je foundZero
	inc bx
	loop findZero
	jmp notFoundZero
	
foundZero:
	mov dl, 64
	mov [bx], dl

notFoundZero:
	pop bx
	pop cx

	ret
endp AdjustPossibleMovesZero


;handles the game itself - moves, clicks in general
proc HandleMouseAndMoves
	mov ax, 0h
	int 33h
	mov ax, 1h
	int 33h

waitForInput:
	
	xor ax, ax
	xor bx, bx
	mov ax, 3h
	int 33h
	cmp bx, 1
	jne continueHM
	
	
leftClick:
	mov [InPossibleMoves], 0
	mov [y], dx
	shr cx, 1
	mov ax, cx
	mov [x], ax
	cmp cx, 200
	jg continueHML
	
	;if it's whites turn, treat the mouse click like its white who clicked on the board, if not, treat it like black did
	cmp [byte ptr turn], 0
	je whiteC
	
;black clicked
blackC:
	xor ax, ax
	xor dx, dx
	call BlackClicked
	
	;check if black won this move
	call CheckIfMateW
	
	cmp [byte ptr CheckMateW], 1
	je blackWon
	
	jmp continueHM
	
;white clicked
whiteC:
	xor ax, ax
	xor dx, dx
	call WhiteClicked
	
	
	
	;check if white won this move
	call CheckIfMateB
	
	cmp [byte ptr CheckMateB], 1
	je whiteWon
	
	;check if black won this move
	call CheckIfMateW
	
	cmp [byte ptr CheckMateW], 1
	je whiteWon
	
	jmp continueHM
	
continueHML:
	call CheckIfClickedOnReverse
	
	;check if player clicked on the restart button, if yes end the loop
	cmp cx, 258
	jl continueHM
	cmp cx, 290
	jg continueHM
	cmp dx, 25
	jg continueHM
	jmp endHandleMoves
	
continueHM:
	jmp waitForInput
	
whiteWon:
	call WhiteWonScreen
	jmp endHandleMoves

blackWon:
	call BlackWonScreen
	jmp endHandleMoves

endHandleMoves:
	
	
	ret
endp HandleMouseAndMoves





;procedure that runs the game
proc MainGame
	;make sure the board is reset
	call ResetBoard
	call GraphicsMode
	
	;make sure white starts the game
	mov [turn], 0
	
	;restart the king and rook moved variables
	mov [KingMovedB], 0
	mov [KingMovedW], 0
	mov [RookMovedB], 0
	mov [RookMovedW], 0
	
	;print the actual image of the board
	mov [printAdd], 0
	mov ax, offset board
	mov [imgHeight], 200
	mov [imgWidth], 200
	call PrintBmp
	xor ax, ax
	
	;print the restart button
	mov [printAdd], 258
	mov [imgHeight], 25
	mov [imgWidth], 32
	mov ax, offset ResC
	call PrintBmp
	
	;print the image that reverses the board
	mov ax, offset reverse
	mov [imgHeight], 25
	mov [imgWidth], 38
	mov [printAdd], 220
	call PrintBmp
	xor ax, ax
	
	;make sure the checkmate variables are set to zero
	mov [CheckMateB], 0
	mov [CheckMateW], 0
	
	
	;set the starter color for the players (player 1 is the one who is at the bottom of the screen)
	mov [player1Color], 0
	mov [player2Color], 1
	
	;create board array based on the colors of the players
	call DecideBoard
	
	;sets the image sizes
	mov al, [sizeOfSquare]
	mov [byte ptr imgHeight], al
	mov [byte ptr imgWidth], al
	
	xor ax, ax
	xor dx, dx
	
	;print the pieces
	call DrawBoard
	
	;handle the game itself - mouse clicks, draw possible moves and move tool
	call HandleMouseAndMoves
	
	ret
endp MainGame

start:
	mov ax, @data
	mov ds, ax
	
loopGame:
	call MainGame
	jmp loopGame
	
	
exit:
	mov ax, 4c00h
	int 21h
END start
	


