; Use a hi-res graphics mode to render the 16-color palette.


; Other Constants

VDGPort		EQU $FF22									; I/O port for control bits for VDG
Pmode1VDG	EQU %11001000								; Upper 5 bits sets the VDG to pmode 1.
Pmode4VDG	EQU %11111000								; Upper 5 bits sets the VDG to pmode 4

SAMvregs	EQU $FFC0           						; SAM's V-mode registers (3-Bits)
SAMvregsBC	EQU 3										; Number of bits for V-mode
SAMpmode1	EQU %100									; Graphics Pmode1 for setting the V1, V2 & V3
SAMpmode4	EQU %110									; Graphics Pmode4 for setting the V1,V2 & V3
SAMmemLoc	EQU $FFC6									; Sam's Video Address registers (7-Bits)
SAMmemLocBC	EQU 7										; Number of bits for V-address

ScreenWidth		EQU 256
PixelsPerByte	EQU 2
ScreenByteWidth	EQU ScreenWidth/PixelsPerByte
ScreenHeight	EQU 192

ScreenStart		EQU $6000
ScreenCenter	EQU ScreenStart+ScreenByteWidth*ScreenHeight/2+ScreenByteWidth/2
ScreenEnd		EQU ScreenStart+ScreenByteWidth*(ScreenHeight-2)+(ScreenByteWidth-1)

PIA0RowRegister	EQU $FF00
IRQ_ACK			EQU $FF02								; Acknowledge the VSYNC interrupt.
IRQ_VSYNC		EQU $FF03								; VSYNC: Bit 7 is low when this IRQ triggered.

		ORG	$0E00

Palette:
		FCB 0,1,2,3,4,5,6,56,7,15,23,31,39,47,55,63


;-------------------------------------------------------------------------------
; Subroutine:	EnableVSync
;-------------------------------------------------------------------------------
EnableVSync:
		PSHS	A
		LDA		IRQ_VSYNC								; Load the VSYNC value.
		ORA		#$01									; Bit 1 IRQ POLARITY 0=flag set on falling edge 1=set on rising edge.
		STA		IRQ_VSYNC								; VSYNC is now enabled.
		PULS	A,PC

WaitVSync:
		TST		IRQ_ACK									; Ackowledge the VSYNC interrupt.
	@Loop:
		TST		IRQ_VSYNC								; Loop until VSYNC is triggered.
		BPL		@Loop
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

ClearScreen:
		LDD		#$0000
		LDX		#ScreenStart
	@Loop:
		STD		,X++
		CMPX	#$e000
		BLO		@Loop
		RTS

;****************************************
;* Set Pallete
;* X=address of 16 byte palette
;****************************************
BuildPalette:
		LDX		#Palette
    @WaitVSync:
		LDA		$FF03									; Wait for vsync
		BPL		@WaitVSync								; so we don't get
		LDA		$FF02									; sparklies	
		LDU		#$FFB0									; Start with palette index 0.
	@Loop:
		LDD		,X++									; Update 2 colors at a time.
		STD		,U++
		CMPU	#$FFC0
		BLO		@Loop
		RTS

Start:
	; Disable interrupts.  Not sure yet why it's needed, but it is.
		ORCC	#$50
	; This sets the stack pointer.  You gotta do this if your program start is inside the existing stack.
		LDS		#$5FF

		JSR		EnableVSync	
		JSR		SetGraphicsMode
		JSR		ClearScreen
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
		JSR	WaitVSync
		BRA	Loop
		END Start
