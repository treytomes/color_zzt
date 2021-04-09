; Graphics routines targeting 256x192 16-color mode for use in other programs.

ScreenWidth		EQU 256
PixelsPerByte	EQU 2
ScreenByteWidth	EQU ScreenWidth/PixelsPerByte
ScreenHeight	EQU 192

ScreenStart		EQU $6000
ScreenCenter	EQU ScreenStart+ScreenByteWidth*ScreenHeight/2+ScreenByteWidth/2
ScreenEnd		EQU ScreenStart+ScreenByteWidth*(ScreenHeight-1)+(ScreenByteWidth-1)

;-------------------------------------------------------------------------------
; Subroutine:	EnableVSync
;-------------------------------------------------------------------------------
EnableVSync:
		PSHS	A
		LDA		IRQ_VSYNC								; Load the VSYNC value.
		ORA		#$01									; Bit 1 IRQ POLARITY 0=flag set on falling edge 1=set on rising edge.
		STA		IRQ_VSYNC								; VSYNC is now enabled.
		PULS	A,PC

;-------------------------------------------------------------------------------
; Subroutine:	EnableVSync
; Summary:		Wait for VSync before continuing execution.
; Remarks:		Clobbers the A register.
;-------------------------------------------------------------------------------
WaitVSync:
		LDA		IRQ_VSYNC
		BPL		WaitVSync
		LDA		IRQ_ACK									; Acknowledge the interrupt.
		PULS	PC

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

;****************************************
;* Set Pallete
;* X=address of 16 byte palette
;****************************************
;-------------------------------------------------------------------------------
; Subroutine:	BuildPalette
; Summary:		Setup the palette colors.
; Remarks:		Clobbers the D and U registers.
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
