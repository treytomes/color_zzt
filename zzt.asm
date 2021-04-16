; Use a hi-res graphics mode to render the Extended ASCII character set.

	INCLUDE		include\constants.asm

		ORG		$0E00

	INCLUDE		include\graphics.asm

PLAYER_GEMS		EQU 0
PLAYER_HEALTH	EQU 2
PLAYER_AMMO		EQU 4
PLAYER_TORCHES	EQU 6
PLAYER_KEYS		EQU 8
PLAYER_SCORE	EQU	9
; Aside from the keys, all numbers here are BCD
PlayerData:
		FCB		$21,$03									; gems
		FCB		$54,$06									; health
		FCB		$87,$09									; ammo
		FCB		$89,$07									; torches
		FCB		%11111111								; key bit flags
		FCB		$56,$34,$02								; score

ScreenData:
	INCLUDEBIN	screen.bin

DrawChart:
		LDB		#$0F									; The color attribute.
		JSR		SetColor
		LDX		#ScreenStart
		LDA		#0										; The character to draw.
		LDY		#16										; 16 rows.
	@RenderRowsLoop:
		PSHS	Y
		LDY		#16										; 16 columns.
	@RenderLoop:
		JSR		DrawChar
		INCA
		LEAX	(CharWidth/PixelsPerByte),X
		LEAY	-1,Y
		BNE		@RenderLoop
		PULS	Y
		LEAX	(ScreenByteWidth-(CharWidth/PixelsPerByte*16)+(CharHeight-1)*ScreenByteWidth),X
		LEAY	-1,Y
		BNE		@RenderRowsLoop
		RTS

DrawBox:
		LDB		#$0E									; The color attribute.
		JSR		SetColor
		LDA		#177									; Character index to draw.
	; Begin top.
		LDX		#ScreenStart
		LDY		#TextColumns
	@TopLoop:
		JSR		DrawChar
		LEAX	(CharWidth/PixelsPerByte),X
		LEAY	-1,Y
		BNE		@TopLoop
	; Begin bottom.
		LDX		#(ScreenStart+ScreenByteWidth*184)
		LDY		#TextColumns
	@BottomLoop:
		JSR		DrawChar
		LEAX	(CharWidth/PixelsPerByte),X
		LEAY	-1,Y
		BNE		@BottomLoop
	; Begin left.
		LDX		#(ScreenStart+ScreenByteWidth*8)
		LDY		#(TextRows-2)
	@LeftLoop:
		JSR		DrawChar
		LEAX	(ScreenByteWidth*8),X
		LEAY	-1,Y
		BNE		@LeftLoop
	; Begin right.
		LDX		#(ScreenStart+ScreenByteWidth*8+ScreenByteWidth-CharWidth/PixelsPerByte)
		LDY		#(TextRows-2)
	@RightLoop:
		JSR		DrawChar
		LEAX	(ScreenByteWidth*8),X
		LEAY	-1,Y
		BNE		@RightLoop
		RTS

;--------------------------------------------------------------------------------
; Subroutine:	WriteByteHex
; Summary:		Write an 8-bit number to the screen in hexadecimal.
; Parameters:
;	A:	The digit to write.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteByteHex:
		PSHS	X
		BSR		WriteNibbleHigh
		LEAX	(CharWidth/PixelsPerByte),X				; Move over for the next digit.
		BSR		WriteNibbleLow
		PULS	X,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteNibbleHigh
; Summary:		Write the most significant 4-bit digit to the screen.
; Parameters:
;	A:	The upper 4-bits of this digit will be written.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteNibbleHigh:
		PSHS	A
		LSRA											; Move the high nibble into the low nibble.
		LSRA
		LSRA
		LSRA
		BSR		WriteNibbleLow							; Write the high nibble.
		PULS	A,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteNibbleLow
; Summary:		Write the least significant 4-bit digit to the screen.
; Parameters:
;	A:	The lower 4-bits of this digit will be written.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteNibbleLow:
		PSHS	A
		ANDA	#%00001111								; Isolate the lower 4-bits.
		CMPA	#$9
		BGT		@Letter
		ADDA	#'0'
		JSR		DrawChar
		PULS	A,PC
	@Letter:
		ADDA	#('A'-10)
		JSR		DrawChar
		PULS	A,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteBCD3
; Summary:		Write 3 BCD digits to the screen.
; Remarks:		The variable technically holds a 4th digit; I just don't want to see it.
; Parameters:
;	X:	Screen location to start writing at.
;	Y:	Pointer to the BCD variable.
;--------------------------------------------------------------------------------
WriteBCD3:
		PSHS	D,X
		LDA		1,Y
		JSR		WriteNibbleLow
		LEAX	(CharWidth/PixelsPerByte),X
		LDA		0,Y
		JSR		WriteByteHex
		PULS	D,X,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteBCD5
; Summary:		Write 5 BCD digits to the screen.
; Remarks:		The variable technically holds a 6th digit; I just don't want to see it.
; Parameters:
;	X:	Screen location to start writing at.
;	Y:	Pointer to the BCD variable.
;--------------------------------------------------------------------------------
WriteBCD5:
		PSHS	D,X
		LDA		2,Y
		JSR		WriteNibbleLow
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDA		1,Y
		JSR		WriteByteHex
		LEAX	(2*CharWidth/PixelsPerByte),X
		LDA		0,Y
		JSR		WriteByteHex
		PULS	D,X,PC

RenderHUD:
	;DrawHLine(32, 0x10, LEFT, RIGHT, TOP);
		LDX		#ScreenStart
		LDB		#$1F
		JSR		SetColor
		LDA		#32
	@BarLoop:
		JSR		DrawChar
	; END BarLoop

		LDX		#ScreenStart
	; Health
		LDB		#$1C
		JSR		SetColor
		LDA		#3
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		#$1F
		JSR		SetColor
		LDY		#PlayerData
		LEAY	PLAYER_HEALTH,Y
		JSR		WriteBCD3
		LEAX	(3*CharWidth/PixelsPerByte),X
	; Ammo
		LDB		#$13
		JSR		SetColor
		LDA		#(8*16+4)
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		#$1F
		JSR		SetColor
		LDY		#PlayerData
		LEAY	PLAYER_AMMO,Y
		JSR		WriteBCD3
		LEAX	(3*CharWidth/PixelsPerByte),X
	; Torches
		LDB		#$16
		JSR		SetColor
		LDA		#(9*16+13)
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		#$1F
		JSR		SetColor
		LDY		#PlayerData
		LEAY	PLAYER_TORCHES,Y
		JSR		WriteBCD3
		LEAX	(3*CharWidth/PixelsPerByte),X
	; Gems
		LDB		#$1B
		JSR		SetColor
		LDA		#4
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		#$1F
		JSR		SetColor
		LDY		#PlayerData
		LEAY	PLAYER_GEMS,Y
		JSR		WriteBCD3
		LEAX	(3*CharWidth/PixelsPerByte),X
	; Keys
		LDY		#PlayerData
		LDA		#' '
		LDB		PLAYER_KEYS,Y
		ANDB	#%00000001
		BEQ		@SkipKey0
		LDB		#$18
		JSR		SetColor
		LDA		#12
	@SkipKey0:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%00000010
		BEQ		@SkipKey1
		LDB		#$19
		JSR		SetColor
		LDA		#12
	@SkipKey1:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%00000100
		BEQ		@SkipKey2
		LDB		#$1A
		JSR		SetColor
		LDA		#12
	@SkipKey2:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%00001000
		BEQ		@SkipKey3
		LDB		#$1B
		JSR		SetColor
		LDA		#12
	@SkipKey3:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%00010000
		BEQ		@SkipKey4
		LDB		#$1C
		JSR		SetColor
		LDA		#12
	@SkipKey4:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%00100000
		BEQ		@SkipKey5
		LDB		#$1D
		JSR		SetColor
		LDA		#12
	@SkipKey5:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%01000000
		BEQ		@SkipKey6
		LDB		#$1E
		JSR		SetColor
		LDA		#12
	@SkipKey6:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDB		PLAYER_KEYS,Y
		ANDB	#%10000000
		BEQ		@SkipKey7
		LDB		#$1F
		JSR		SetColor
		LDA		#12
	@SkipKey7:
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
	; A bit of blank space before drawing the score.
		LDB		#$1F
		JSR		SetColor
		LDA		#' '
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDA		#' '
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
		LDA		#' '
		JSR		DrawChar
		LEAX	(1*CharWidth/PixelsPerByte),X
	; Score
		LDY		#PlayerData
		LEAY	PLAYER_SCORE,Y
		JSR		WriteBCD5
	; Done!
		RTS

Start:
	; Disable interrupts.  Not sure yet why it's needed, but it is.
		ORCC	#%01010000
	; This sets the stack pointer.  Probably only needed if your program start is inside the existing stack.
		LDS		#$5FF

    ; High speed!
		;CLRA											; Clearing A is not necessary?
		STA		$FFD9
		STA		$FFD7

		JSR		SetGraphicsMode
		JSR		EnableVSync

		JSR		ClearScreen

		LDX		#Palette
		JSR		BuildPalette

		;JSR		DrawChart
		;JSR		DrawBox

		;LDB		#$1F
		;JSR		SetColor
		;LDA		#2
		;LDX		#(ScreenStart+ScreenByteWidth*CharHeight*8+CharWidth/PixelsPerByte*4)
		;JSR		DrawChar

		LDY		#ScreenData
		LDX		#ScreenStart
		LDB		#TextRows								; 24 text rows.
	@RenderRowsLoop:
		PSHS	B
		LDB		#TextColumns							; 32 text columns.
	@RenderLoop:
		PSHS	B
		LDD		,Y++
		JSR		SetColor
		JSR		DrawChar
		LEAX	(CharWidth/PixelsPerByte),X
		PULS	B
		DECB
		BNE		@RenderLoop
		LEAX	((CharHeight-1)*ScreenByteWidth),X
		PULS	B
		DECB
		BNE		@RenderRowsLoop

		JSR		RenderHUD


Loop:
		BRA		Loop
		
		END Start
