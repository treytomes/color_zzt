; Write 2 characters to text memory using the 16-bit accumulator.

	pragma m80ext										; Enable the byte literals in FCC.

	include constants.asm

;
; Miscellaneous Constants
;

CharactersPerLine       equ 32


		org	$4000


;-------------------------------------------------------------------------------
; Subroutine:	WriteMessage
; Summary:		Write a null-terminated string to a low-resolution text screen.
; Parameters:
;	U:	The the address of the message.
;	X:	The address to write the message to.
;--------------------------------------------------------------------------------
		opt cc											; Reset the cycle count subtotal.
WriteMessage:
		pshs	D,X,U									; Save the registers we're about to clobber.
    @Loop:
		pulu	D										; Pull D off the (U)ser stack, setting A and B simultaneously.
		tsta											; Does A=0 yet?
		beq     @End									; A=0 @ end of string.
		tstb											; B=contents pointed to by U; U+=1.
		beq     @Finish									; B=0, but A contains data we still need to write.
		std     ,X++									; Store the contents of D (A&B) at the address pointed to by X; X+=2.
		bra     @Loop
	@Finish:
		sta	,X											; Store contents of A to the address pointed to by X.
	@End:
		puls    U,X,D,PC								; Restore the prior contents of the registers, then return to caller.

;--------------------------------------------------------------------------------

Message     fcc 'HELLO, WORLD!',0

Start:
	    pshs    u,x
	    ldu		#Message
	    ldx     #(TextMemory+8*CharactersPerLine+4)		; Write to column 4, row 8.
	    jsr		WriteMessage
	    puls    u,x,pc
	    end     Start
