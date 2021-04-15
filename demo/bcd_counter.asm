; Count in BCD.

	include include\constants.asm

		org		$4000

	include include\system.asm

;--------------------------------------------------------------------------------
; Subroutine:	WriteByteHex
; Summary:		Write an 8-bit number to the screen in hexadecimal.
; Parameters:
;	A:	The digit to write.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteByteHex:
		pshs	X
		bsr		WriteNibbleHigh
		leax	1,X										; Move over for the next digit.
		bsr		WriteNibbleLow
		puls	X,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteNibbleHigh
; Summary:		Write the most significant 4-bit digit to the screen.
; Parameters:
;	A:	The upper 4-bits of this digit will be written.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteNibbleHigh:
		pshs	A
		lsra											; Move the high nibble into the low nibble.
		lsra
		lsra
		lsra
		bsr		WriteNibbleLow							; Write the high nibble.
		puls	A,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteNibbleLow
; Summary:		Write the least significant 4-bit digit to the screen.
; Parameters:
;	A:	The lower 4-bits of this digit will be written.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteNibbleLow:
		pshs	A
		anda	#%00001111								; Isolate the lower 4-bits.
		cmpa	#$9
		bgt		@Letter
		adda	#(48+64)								; 48 is the ASCII code for '0'.  +64 makes it upper-case.
		sta		,X										; Write B to the memory location in X.
		puls	A,PC
	@Letter:
		adda	#(-10+65)								; 10="A"
		sta		,X										; Write B to the memory location in X.
		puls	A,PC

;--------------------------------------------------------------------------------
; Subroutine:	WriteBCD
; Summary:		Write a series of BCD bytes to the screen.
; Parameters:
;	X:	Screen location to start writing at.
;	Y:	Pointer to the BCD variable.
;	B:	Number of bytes to write.  It'll get weird if this value=0.
;--------------------------------------------------------------------------------
WriteBCD:
		PSHS	D,X
	@WriteLoop:
		DECB
		BEQ		@Done
		LDA		B,Y
		JSR		WriteByteHex
		LEAX	2,X
		BRA		@WriteLoop
	@Done:
		LDA		B,Y										; Still need to write the final digit.
		JSR		WriteByteHex
		PULS	D,X,PC

;--------------------------------------------------------------------------------
; Subroutine:	AddBCD1
; Summary:		Add a value to a 1-byte BCD value.
; Parameters:
;	Y:	Pointer to the BCD variable.
;	B:	The value to add.  If carry is > 1 then things will get weird.
;--------------------------------------------------------------------------------
AddBCD1:
		PSHS	A
		LDA		0,Y
		STB		@Temp
		ADDA	@Temp
		DAA
		STA		0,Y
		PULS	A,PC
	@Temp:
		FCB 0

;--------------------------------------------------------------------------------
; Subroutine:	AddBCD2
; Summary:		Add a value to a 2-byte BCD value.
; Parameters:
;	Y:	Pointer to the BCD variable.
;	B:	The value to add.  If carry is > 1 then things will get weird.
;--------------------------------------------------------------------------------
AddBCD2:
		PSHS	A
		ANDCC	#$FE									; Clear the carry bit.
		JSR		AddBCD1
		BCC		@Done
	; Carry to the next digit.
		LDA		1,Y
		ADDA	#1
		DAA
		STA		1,Y
	@Done:
		PULS	A,PC

;--------------------------------------------------------------------------------
; Subroutine:	AddBCD3
; Summary:		Add a value to a 3-byte BCD value.
; Parameters:
;	Y:	Pointer to the BCD variable.
;	B:	The value to add.  If carry is > 1 then things will get weird.
;--------------------------------------------------------------------------------
AddBCD3:
		PSHS	A
		JSR		AddBCD2
		BCC		@Done
	; Carry to the next digit.
		LDA		2,Y
		ADDA	#1
		DAA
		STA		2,Y
	@Done:
		PULS	A,PC

;--------------------------------------------------------------------------------
Start:
    ; High speed!
		STA		$FFD9
		STA		$FFD7

		JSR		ClearTo32Columns
		
		LDX		#(TextMemory)							; Start on row 0 column 1.
Loop:
		LDY		#digits
		LDB		#3
		JSR		WriteBCD								; Write a 3-byte BCD value to the screen.
		LDB		#7
		JSR		AddBCD3									; Add 7 to the BCD value.

DoneAdding:
		LDY		#100
		JSR		Sleep
		BRA		Loop

		PULS	PC

digits			FCB 0,0,0								; 6-digit number, least significant digits first

		end		Start