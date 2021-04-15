; Miscellaneous useful functions.

;-------------------------------------------------------------------------------
; Subroutine:	Sleep
; Summary:		Pause execution for a number of milliseconds.
; Remarks:		Assumes you're running in high-speed mode.
; Parameters:
;	Y:	# milliseconds to sleep.
;-------------------------------------------------------------------------------
Sleep:
		PSHS	X,Y
	@Wait1:
		LDX		#$F5
	@Wait2:
		LEAX	-1,X
		CMPX	#0
		BNE		@Wait2
		LEAY	-1,Y
		CMPY	#0
		BNE		@Wait1
		PULS	X,Y,PC
