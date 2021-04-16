; Math routines.

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
