; Graphics routines targeting 256x192 16-color mode for use in other programs.

ScreenWidth		EQU 256
PixelsPerByte	EQU 2
ScreenByteWidth	EQU ScreenWidth/PixelsPerByte
ScreenHeight	EQU 192

ScreenStart		EQU $6000
ScreenCenter	EQU ScreenStart+ScreenByteWidth*ScreenHeight/2+ScreenByteWidth/2
ScreenEnd		EQU ScreenStart+ScreenByteWidth*(ScreenHeight-1)+(ScreenByteWidth-1)

Palette:
		FCB 0,1,2,3,4,5,6,56,7,15,23,31,39,47,55,63

CharWidth		EQU	8
CharHeight		EQU	8
BytesPerChar	EQU	CharHeight
TextRows		EQU 24
TextColumns		EQU 32

ASCII:
	INCLUDEBIN OEM437.bin

TextBackground:
		RMB		1										; Background color should have the same number in the high and low nibbles.
TextForegroundHigh:
		RMB		1										; Store the foreground color in the high nibble.
TextForegroundLow:
		RMB		1										; Store the foreground color in the low nibble.

;-------------------------------------------------------------------------------
; Subroutine:	EnableVSync
; Remarks:		Clobbers the A register.
;-------------------------------------------------------------------------------
EnableVSync:
		LDA		IRQ_VSYNC								; Load the VSYNC value.
		ORA		#$01									; Bit 1 IRQ POLARITY 0=flag set on falling edge 1=set on rising edge.
		STA		IRQ_VSYNC								; VSYNC is now enabled.
		RTS

;-------------------------------------------------------------------------------
; Subroutine:	WaitVSync
; Summary:		Wait for VSync before continuing execution.
;-------------------------------------------------------------------------------
WaitVSync:
		PSHS	A
		LDA		IRQ_VSYNC
		BPL		WaitVSync
		LDA		IRQ_ACK									; Acknowledge the interrupt.
		PULS	A,PC

;-------------------------------------------------------------------------------
; Subroutine:	SetGraphicsMode
; Summary:		Set the display to 256x192 w/ 16 colors.
; Remarks:		Clobbers the D register.
;-------------------------------------------------------------------------------
SetGraphicsMode:
	;**********************************************
	;* 256 x 192 x 16 videomode + gime setup
	;**********************************************
		LDA		#%01001101
		STA		$ff90									; Init0
	; Bit 7: 0 = high resolution
		LDA		#%10000000									; 1 for graphics
		STA		$FF98										; Video Mode
	; Bit 7 (BP): 0 = hi-res text, 1 = hi-res graphics
	; Bits 2-0 (LPR2-0): Vertical size of a pixel or character.
		LDA		#%00011010	; 100=256 pixel width, 10=4 bits per pixel
		STA		$FF99		; Video Resolution
	; Bits 6-5 (VRES1-0): pixel height
	;	0, 0 = 192 (normal)
	;	0, 1 = 200 (larger)
	;	1, 0 = unused
	;	1, 1 = 225 (fullscreen)
	; Bits 4-2 (HRES2-0): horizontal display width
	;	HRES=#4/#%100 for 256 pixel width w/ 2bpp
	;	HRES=#6/#%110 for 256 pixel width w/ 4bpp
	; Bits 1-0 (CRES1-0): pixel format / bits per pixel
	;   1, 0 = 4 bits per pixel
		;ldd	#$803e		;803e
		;std	$ff98		; $98=Video Mode, $99=Video Resolutio
	;**********************************************
	;* screen offset at $6000 ($C000 = $6000 << 1)
	;**********************************************
		LDD		#$c000
		STD		$ff9d		; Vertical Offset1
	;**********************************************
	;* 32k of mmu banks at $6000
	;**********************************************
		LDD		#$3031
		STD		$ffa3    
		LDD		#$3233
		STD		$ffa5
		LDA		#$34
		STA		$ffa7
		RTS

;-------------------------------------------------------------------------------
; Subroutine:	ClearScreen
; Summary:		Clear the entire screen to color 0.
; Remarks:		Clobbers the D and X registers.
;-------------------------------------------------------------------------------
ClearScreen:
		LDD		#$0000
		LDX		#ScreenStart
	@Loop:
		STD		,X++
		CMPX	#ScreenEnd
		BLO		@Loop
		RTS

;-------------------------------------------------------------------------------
; Subroutine:	BuildPalette
; Summary:		Setup the palette colors.
; Remarks:		Clobbers the D and U registers.
; Parameters:
;	X:	Address of the 16-byte palette.
;-------------------------------------------------------------------------------
BuildPalette:
		JSR		WaitVSync
		LDU		#$FFB0									; Start with palette index 0.
	@Loop:
		LDD		,X++									; Update 2 colors at a time.
		STD		,U++
		CMPU	#$FFC0
		BLO		@Loop
		RTS

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
