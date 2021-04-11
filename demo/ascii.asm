; Use a hi-res graphics mode to render the Extended ASCII character set.

	include include\constants.asm

		ORG	$0E00

	include include\graphics.asm

Palette:
		FCB 0,1,2,3,4,5,6,56,7,15,23,31,39,47,55,63

CharWidth		EQU	8
CharHeight		EQU	8
BytesPerChar	EQU	CharHeight

ASCII:
	includebin OEM437.bin

TextBackground:
		RMB		1										; Background color should have the same number in the high and low nibbles.
TextForegroundHigh:
		RMB		1										; Store the foreground color in the high nibble.
TextForegroundLow:
		RMB		1										; Store the foreground color in the low nibble.

;-------------------------------------------------------------------------------
; Subroutine:	SetColor
; Summary:		Set the foreground and background text colors.
; Parameters:
;	B:	The color attribute.  High nibble is background, low nibble is foreground.
;-------------------------------------------------------------------------------
SetColor:
		PSHS	D
	; Calculate the 3 color variables from B.
		TFR		B,A										; A=B
		ANDB	#$F0									; Isolate the background.
		STB		TextBackground
		LSRB
		LSRB
		LSRB
		LSRB											; Move background into the low nibble.
		ORB		TextBackground							; Recombine with background to duplicate the value.
		STB		TextBackground							; This should save the final background value.
		ANDA	#$0F									; Isolate the foreground.
		STA		TextForegroundLow
		LSLA
		LSLA
		LSLA
		LSLA											; Move the attribute into the high nibble.
		STA		TextForegroundHigh
		PULS	D,PC

;-------------------------------------------------------------------------------
; Subroutine:	DrawChar
; Parameters:
;	A:	The character index to draw.
;	B:	The color attribute.  High nibble is background, low nibble is foreground.
;	X:	Row/column. (TODO)
;-------------------------------------------------------------------------------
DrawChar:
		PSHS	D,X,Y
	; Begin calculating ASCII table pointer.
		TFR		A,B										; B=A
		CLRA
		ASLB											; D*=8
		ROLA
		ASLB
		ROLA
		ASLB
		ROLA
		LDY		#ASCII
		LEAY	D,Y
	; Done calculating ASCII table pointer.
		LDB		#CharHeight
	@RowLoop:
		PSHS	B
		LDB		#(CharWidth/PixelsPerByte)
		LDA		,Y+
	@ColLoop:
		PSHS	B
		LDB		TextBackground							; Load the background color.
		TSTA
		BPL		@Skip1									; Is the high bit 0?
		ANDB	#$0F									; Clear out the background color.
		ORB		TextForegroundHigh						; Load the foreground color.
	@Skip1:
		LSLA
		;TSTA											; Don't need to test A when we just operated on it.
		BPL		@Skip2									; Is the high bit 0?
		ANDB	#$F0									; Clear out the background color.
		ORB		TextForegroundLow						; Load the foreground color.
	@Skip2:
		LSLA
		STB		,X+										; Write the next 2 pixels to the screen.
		PULS	B
		DECB
		BNE		@ColLoop
		PULS	B
		LEAX	(ScreenByteWidth-BytesPerChar/PixelsPerByte),X
		DECB
		BNE		@RowLoop
		PULS	D,X,Y,PC

Start:
	; Disable interrupts.  Not sure yet why it's needed, but it is.
		ORCC	#%01010000
	; This sets the stack pointer.  Probably only needed if your program start is inside the existing stack.
		LDS		#$5FF

    ; High speed!
		CLRA
		STA		$FFD9
		STA		$FFD7

		JSR		EnableVSync	
		JSR		SetGraphicsMode
		JSR		ClearScreen

		LDX		#Palette
		JSR		BuildPalette

		LDB		#$0F									; The color attribute.
	@ColorLoop:
		JSR		SetColor
		LDX		#ScreenStart
		LDA		#0										; The character to draw.
		LDY		#24										; 24 text rows.
	@RenderRowsLoop:
		PSHS	Y
		LDY		#32										; 32 text columns.
	@RenderLoop:
		JSR		DrawChar
		INCA
		;ADDB	#11
		LEAX	(CharWidth/PixelsPerByte),X
		LEAY	-1,Y
		BNE		@RenderLoop
		PULS	Y
		LEAX	((CharHeight-1)*ScreenByteWidth),X
		LEAY	-1,Y
		BNE		@RenderRowsLoop
		ADDB	#$11
		BRA		@ColorLoop
		
Loop:
		BRA	Loop
		END Start
