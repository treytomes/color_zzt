; Use a hi-res graphics mode to render the 16-color palette.

	include constants.asm

		ORG	$0E00

	include graphics.asm

Palette:
		FCB 0,1,2,3,4,5,6,56,7,15,23,31,39,47,55,63


Start:
	; Disable interrupts.  Not sure yet why it's needed, but it is.
		ORCC	#%01010000
	; This sets the stack pointer.  Probably only needed if your program start is inside the existing stack.
		LDS		#$5FF

		JSR		EnableVSync	
		JSR		SetGraphicsMode
		JSR		ClearScreen

		LDX		#Palette
		JSR		BuildPalette

		LDX		#ScreenStart
	@BarLoop:
		LDD		#$0000
	@ColorLoop:
		STD		,X++
		STD		,X++
		STD		,X++
		STD		,X++
		ADDD	#$1111
		BCC		@ColorLoop
		CMPX	#ScreenEnd
		BLO		@BarLoop
		
Loop:
		BRA	Loop
		END Start
