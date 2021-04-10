; Use a hi-res graphics mode to render the Extended ASCII character set.

	include constants.asm

		ORG	$0E00

	include graphics.asm

Palette:
		FCB 0,1,2,3,4,5,6,56,7,15,23,31,39,47,55,63

CharWidth		EQU	8
CharHeight		EQU	8
BytesPerChar	EQU	CharHeight

ASCII:
	includebin OEM437.bin

ASCIIPointers:
	;RMD			256
	FDB ASCII+0
	FDB ASCII+8
	FDB ASCII+65*8
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	FCB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;-------------------------------------------------------------------------------
; Subroutine:	PopulateASCIIPointers
; Summary:		Generate the pointer table at ASCIIPointers for accessing character data.
; Remarks:		Clobbers X, Y, and B.
;-------------------------------------------------------------------------------
PopulateASCIIPointers:
		LDX		#ASCII									; Load the address of ASCII into X.
		LDY		#ASCIIPointers							; Load the address of ASCIIPointers into Y.
		CLRB
	@Loop:
		STX		,Y++									; Store the current address into ASCIIPointers, then move to the next pointer.
		LEAX	BytesPerChar,X							; Move X to the next character.
		;LEAY	2,Y
		INCB
		BNE		@Loop									; Keep looping until B overflows.
		RTS

;-------------------------------------------------------------------------------
; Subroutine:	DrawChar
; Parameters:
;	A:	The character index to draw.
;	B:	The color attribute.  High nibble is background, low nibble is foreground.
;	X:	Row/column. (TODO)
;-------------------------------------------------------------------------------
DrawChar:
	; Calculate the 3 color variables from B.
		PSHS	B										; Save the color for a moment.
		ANDB	#$F0									; Isolate the background.
		STB		@Background
		LSRB
		LSRB
		LSRB
		LSRB											; Move background into the low nibble.
		ORB		@Background								; Recombine with background to duplicate the value.
		STB		@Background								; This should save the final background value.
		PULS	B										; Re-load the full color attribute.
		ANDB	#$0F									; Isolate the foreground.
		STB		@Foreground2
		LSLB
		LSLB
		LSLB
		LSLB											; Move the attribute into the high nibble.
		STB		@Foreground1
	; All done loading color variables.
		LDX		#ScreenStart
		LDY		#(ASCII+65*BytesPerChar)
		;LDY		#ASCIIPointers
		;LEAY	2,Y
		LDB		#CharHeight
	@RowLoop:
		PSHS	B
		LDB		#(CharWidth/PixelsPerByte)
		LDA		,Y+
	@ColLoop:
		PSHS	B
		LDB		@Background								; Load the background color.
		TSTA
		BPL		@Skip1									; Is the high bit 0?
		ANDB	#$0F									; Clear out the background color.
		ORB		@Foreground1							; Load the foreground color.
	@Skip1:
		LSLA
		;TSTA											; Don't need to test A when we just operated on it.
		BPL		@Skip2									; Is the high bit 0?
		ANDB	#$F0									; Clear out the background color.
		ORB		@Foreground2							; Load the foreground color.
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
		RTS
	@Background:
		RMB		1										; Background color should have the same number in the high and low nibbles.
	@Foreground1:
		RMB		1										; Store the foreground color in the high nibble.
	@Foreground2:
		RMB		1										; Store the foreground color in the low nibble.

Start:
	; Disable interrupts.  Not sure yet why it's needed, but it is.
		ORCC	#%01010000
	; This sets the stack pointer.  Probably only needed if your program start is inside the existing stack.
		LDS		#$5FF

		;JSR		PopulateASCIIPointers

		JSR		EnableVSync	
		JSR		SetGraphicsMode
		JSR		ClearScreen

		LDX		#Palette
		JSR		BuildPalette

		LDA		#'*'									; The character to draw.
		LDB		#$1F									; The color attribute.
		JSR		DrawChar
		
Loop:
		BRA	Loop
		END Start
