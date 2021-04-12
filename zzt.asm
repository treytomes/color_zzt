; Use a hi-res graphics mode to render the Extended ASCII character set.

	INCLUDE		include\constants.asm

		ORG		$0E00

	INCLUDE		include\graphics.asm

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
		JSR		DrawBox

		LDB		#$1F
		JSR		SetColor
		LDA		#2
		LDX		#(ScreenStart+ScreenByteWidth*CharHeight*8+CharWidth/PixelsPerByte*4)
		JSR		DrawChar

Loop:
		BRA		Loop
		
		END Start
