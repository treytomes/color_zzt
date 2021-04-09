;-------------------------------------------------------------------------------
; keys.asm
;
; Check the status of all 4 arrow keys.
; Display a message for each key that is pressed.
; End the program with a friendly "GOOD BYE!" when the user pressed BREAK.
;
; I have made a subroutine for each key to try to make the code more legible.
; I have also tried replacing my RTS usage with PULS PC.
; I hear it's a bit more efficient.  Every little bit helps.
;
; NOTE: This program won't work if you keyboard is mapped as the joystick in Vcc.
;-------------------------------------------------------------------------------

	include constants.asm

	ORG	$4000

UpMessage		FCN 'UP    '
DownMessage		FCN 'DOWN  '
LeftMessage		FCN 'LEFT  '
RightMessage	FCN 'RIGHT '
ShiftMessage	FCN 'SHIFT'
ClearMessage	FCN '      '
BreakMessage	FCN 'GOOD BYE!'


;-------------------------------------------------------------------------------
; BEGIN LIBRARY SUBROUTINES
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Subroutine:	WriteMessage
; Summary:	Write a 0-terminated string to a low-resolution text screen.
; Parameters:
;	U:	The the address of the message.
;	X:	The address to write the message to.  Text memory starts at $400.
; Returns:
;	Hopefully nothing.
;--------------------------------------------------------------------------------
WriteMessage:
		PSHS	D,X,U									; Save the registers we're about to clobber.
    @Loop:
		PULU	D										; Pull D off the (U)ser stack, setting A and B simultaneously.
		TSTA											; Does A=0 yet?
		BEQ     @End									; A=0 @ end of string.
		TSTB											; B=contents pointed to by U; U+=1.
		BEQ     @Finish									; B=0, but A contains data we still need to write.
		STD     ,X++									; Store the contents of D (A&B) at the address pointed to by X; X+=2.
		BRA     @Loop
    @Finish:
		STA		,X										; Store contents of A to the address pointed to by X.
    @End:
		PULS    U,X,D,PC								; Restore the prior contents of the registers, then return to caller.

;-------------------------------------------------------------------------------
; Subroutine:	CheckKey
; Summary:	Check the status of the key at the specified row and column
;		of the keyboard matrix.
; Remarks:	It would be more efficient to only initialize PIA0 at the
;		start of the keyboard check code.  Not as portable though.
; Parameters:
;	A	The column of the key (bit-flag).
;	B	The row of the key (bit-flag).
; Returns:
;	Z	The zero flag will be set if the key is not pressed.
;-------------------------------------------------------------------------------
CheckKey:
		PSHS	A,X,U
    ; Initialize PIA0.
		LDU	#PIA0RowRegister							; Restore U to point to PIA0.
		LDX	#$FF										; Column strobe reset.
		STX	2,U											; Save to $FF02	
    ; Check for the key.
		COMA											; Invert the bits.
		STA	2,U											; Strobe the column.
		LDA	,U											; Read the rows.
		COMA											; Invert the bits.
    ; You cannot A&B directly.  A can only be AND-ed with memory, so B must be copied.
		STB		@Temp									; Store the row in our temp variable.
		BITA	@Temp									; Test (A & temp) to see if the key is pressed.
		PULS	U,X,A,PC
    @Temp:
		FCB		0										; Temporary storage for the A&B operation.

;-------------------------------------------------------------------------------
; END LIBRARY SUBROUTINES
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Check for the up arrow key.
; Clobbers the A and B registers.
;-------------------------------------------------------------------------------
UpdateUpKey:
		PSHS	U,X										; Store the registers used for updating the display.
		LDA		#%00001000								; Column 3.
		LDB		#%00001000								; Row 3.
		JSR		CheckKey
		BEQ		@No										; Branch if the key was not pressed.
		LDU     #UpMessage								; Load the pressed message.
		BRA		@Write
    @No:
		LDU     #ClearMessage							; Load the cleared message.
    @Write:
		LDX     #$500
		JSR		WriteMessage
		PULS	X,U,PC

;-------------------------------------------------------------------------------
; Check for the down arrow key.
; Clobbers the A and B registers.
;-------------------------------------------------------------------------------
UpdateDownKey:
		PSHS	U,X										; Store the registers used for updating the display.
		LDA		#%00010000								; Column 4.
		LDB		#%00001000								; Row 3.
		JSR		CheckKey
		BEQ		@No										; Branch if the key was not pressed.
		LDU     #DownMessage							; Load the pressed message.
		BRA		@Write
    @No:
		LDU     #ClearMessage							; Load the cleared message.
    @Write:
		LDX     #$520
		JSR		WriteMessage
		PULS	X,U,PC

;-------------------------------------------------------------------------------
; Check for the left arrow key.
; Clobbers the A and B registers.
;-------------------------------------------------------------------------------
UpdateLeftKey:
		PSHS	U,X										; Store the registers used for updating the display.
		LDA		#%00100000								; Column 5.
		LDB		#%00001000								; Row 3.
		JSR		CheckKey
		BEQ		@No										; Branch if the key was not pressed.
		LDU     #LeftMessage							; Load the pressed message.
		BRA		@Write
    @No:
		LDU     #ClearMessage							; Load the cleared message.
    @Write:
		LDX     #$540
		JSR		WriteMessage
		PULS	X,U,PC

;-------------------------------------------------------------------------------
; Check for the right arrow key.
; Clobbers the A and B registers.
;-------------------------------------------------------------------------------
UpdateRightKey:
		PSHS	U,X										; Store the registers used for updating the display.
		LDA		#%01000000								; Column 6.
		LDB		#%00001000								; Row 3.
		JSR		CheckKey
		BEQ		@No										; Branch if the key was not pressed.
		LDU     #RightMessage							; Load the pressed message.
		BRA		@Write
    @No:
		LDU     #ClearMessage							; Load the cleared message.
    @Write:
		LDX     #$560
		JSR		WriteMessage
		PULS	X,U,PC

;-------------------------------------------------------------------------------
; Check for the left shift key.
; Clobbers the A and B registers.
;-------------------------------------------------------------------------------
UpdateShiftKey:
		PSHS	U,X										; Store the registers used for updating the display.
		LDA	#%10000000									; Column 7.
		LDB	#%01000000									; Row 6.
		JSR	CheckKey
		BEQ	@No											; Branch if the key was not pressed.
		LDU     #ShiftMessage							; Load the pressed message.
		BRA	@Write
    @No:
		LDU     #ClearMessage							; Load the cleared message.
    @Write:
		LDX     #$580
		JSR	WriteMessage
		PULS	X,U,PC

;-------------------------------------------------------------------------------
; Check for the BREAK key.  End the program if pressed.
; Clobbers the A, B, U, and X registers, but who cares?
; The U register matters for the keyboard check, but it's only clobbered on exit.
;
; I am pulling X AND PC because the BASIC return point is being obscured by
; the JSR return point.
;-------------------------------------------------------------------------------
UpdateBreakKey:
		LDA		#%00000100								; Column 2.
		LDB		#%01000000								; Row 6.
		JSR		CheckKey
		BNE		@ProgramEnd								; End program if key is pressed.
		PULS	PC
    @ProgramEnd:
		LDU     #BreakMessage							; Bid the user farewell.
		LDX     #$5C0
		JSR		WriteMessage
		PULS	X,PC									; Return to BASIC.

;-------------------------------------------------------------------------------
; Program start.
;-------------------------------------------------------------------------------
Start:
	; I could intialize PIA0 once here.  It would be more efficient
	; than including it in the CheckKey subroutine.
	; I haven't decided if I care more for size or portability yet.
		LDU	#PIA0RowRegister							; Restore U to point to PIA0.
		LDA	#$FF										; Column strobe reset.
		STA	2,U											; Save to $FF02
Loop:
		JSR	UpdateUpKey									; Check for the up arrow key.
		JSR	UpdateDownKey								; Check for the down arrow key.
		JSR	UpdateLeftKey								; Check for the left arrow key.
		JSR	UpdateRightKey								; Check for the right arrow key.
		JSR	UpdateShiftKey								; Check for the left shift key.
		JSR	UpdateBreakKey								; Check for the break key.
		JMP	Loop
		END	Start										; End
