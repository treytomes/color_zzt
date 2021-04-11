; Write some numbers to the low-res text screen.

	include include\constants.asm

		org		$4000

;-------------------------------------------------------------------------------
; Subroutine:	WriteByteBin
; Summary:	Write an 8-bit number to the screen in binary.
; Parameters:
;	A:	The digit to write.
;	X:	The address to write the digit at.
;-------------------------------------------------------------------------------
WriteByteBin:
		pshs	D,X,Y
		ldy		#8										; Write 8 digits.
    @Loop:
		lsla
		bcs		@One
    @Zero:
		ldb		#(48+64)								; 48 is the ASCII code for '0'.  +64 makes it upper-case.  Only needed on the low-res text screen.
		bra		@Draw
	@One:
		ldb		#(49+64)								; 49 is the ASCII code for '1'.  +64 makes it upper-case.
	@Draw:
		stb		,X+										; Write the character to the screen and increment the screen pointer.
		leay	-1,Y									; Exit when Y=0.
		bne		@Loop
		puls	Y,X,D,PC

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
; Subroutine:	WriteByteDec
; Summary:		Write an 8-bit number to the screen in decimal.
; Parameters:
;	A:	The digit to write.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
WriteByteDec:
		pshs	D,Y,X
		ldy		#0										; Y counts the number of base-10 digits.
	@ResetLoop:
	; Perform base-10 division by subtracting over and over again.
	; The quotient is collected in B; the remainder will be A+10 just after the loop.
		clrb											; Reset the quotient counter.
    @Mod10Loop:
		incb
		suba	#10										; We're dividing by 10.
		bcc		@Mod10Loop								; Continue until B<0
		adda	#10										; Remainder=B+10
		pshs	A										; We'll pop these off later in reverse order.
		leay	1,Y										; Need to keep count of the digits.
		tfr		B,A										; A=B
		deca											; B will be just a bit too high at this point.
		bne		@ResetLoop								; Keep looping until B=0
    @Draw:
		puls	A										; Pull the next digit off the stack.
		adda	#(48+64)								; 48 is the ASCII code for '0'.  +64 makes it upper-case.
		sta		,X
		leax	1,X
		leay	-1,Y
		bne		@Draw									; Keep writing digits until Y=0.
		puls	X,Y,D,PC								; All done!

;--------------------------------------------------------------------------------
; Subroutine:	WriteByteDec2
; Summary:		Write a 16-bit number to the screen in decimal.
;	Attempting to reproduce Ben Eater's 6502 algorithm.  Doesn't work yet.
; Parameters:
;	D:	The digit to write.
;	X:	The address to write the digit at.
;--------------------------------------------------------------------------------
number	fdb 1729
value	fdb	0
mod10	fdb 0

WriteByteDecv2:
	; Initialize value to be the number we want to convert.
		lda		number
		sta		value
		lda		number+1
		sta		value+1
		ldx		#$0402
	@divide:
	; Initialize the remainder to 0.
		lda		#0
		sta		mod10
		sta		mod10+1
		andcc	#%11111110								; clear the carry bit
	; Initialize the loop.
		ldy		#16
	@divloop:
	; Rotate quotient and remainder.
		rol		value
		rol		value+1
		rol		mod10
		rol		mod10+1
	; a,b = dividend - divisor
		orcc	#%00000001								; set the carry bit
		lda		mod10
		sbca	#10										; subtract with carry
		tfr		A,B										; save low byte in B
		lda		mod10+1
		sbca	#0	
		bcc		@ignore_result							; branch if dividend < divisor
	; Store B into the modulus.
		stb		mod10
		sta		mod10+1
	@ignore_result:
		leay	-1,Y
		bne		@divloop
		rol		value									; shift in the last bit of the quotient
		rol		value+1
		lda		mod10
		adda	#'0'
		sta		,X
		leax	1,X
	; if value != 0 (if any bits are set), then continue dividing
		lda		value
		ora		value+1
		bne		@divide									; branch if value not zero
		rts

;--------------------------------------------------------------------------------


;--------------------------------------------------------------------------------
Start:
		jsr		ClearTo32Columns
		ldx		#(TextMemory+32*0+1)					; Start on row 0 column 1.
		lda		#%10010000								; This will be the first byte written to the screen.
		ldb		#16										; Write 16 numbers.
Loop:
	; Write the binary value.
		jsr		WriteByteBin
		leax	9,X										; Move into the next column to write the hexadecimal value.
		jsr		WriteByteHex
		leax	3,X										; Move over another column to write the decimal value.
		jsr		WriteByteDec
		leax	-9-3,X									; Move back to start.
		leax	$20,X									; Move to the next line.
		inca											; Load the next number to write.
		decb											; Decrement the column counter.
		bge		Loop									; Keep looping until A<0.

		;jsr		WriteByteDecv2

		puls	PC

		end		Start