; Use a hi-res graphics mode to render the Extended ASCII character set.

	include include\constants.asm

		ORG	$0E00

	include include\graphics.asm

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
		
		END Start
