; Write 2 characters to text memory using the 16-bit accumulator.

	pragma m80ext				; Enable the byte literals in FCC.


	include constants.asm

;
; Miscellaneous Constants
;

CharactersPerLine		equ 32


		org	$4000

Start:
        pshs    d
        ldd     #'HI
        ldx     #(TextMemory+8*CharactersPerLine+4)   ; Write to column 4, row 8.
        std     ,x
        puls    d,pc
        end     Start
