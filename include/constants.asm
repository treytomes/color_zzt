; Miscellaneous useful constants.

;
; ROM Routines
;

; Set 32-columns and CLS. (clear to what attribute?)
ClearTo32Columns	    equ $f652

;
; Memory Locations
;

TextMemory              equ $400

;
; Ports
;

VDGPort			EQU $FF22								; I/O port for control bits for VDG
Pmode1VDG		EQU %11001000							; Upper 5 bits sets the VDG to pmode 1.
Pmode4VDG		EQU %11111000							; Upper 5 bits sets the VDG to pmode 4

SAMvregs		EQU $FFC0           					; SAM's V-mode registers (3-Bits)
SAMvregsBC		EQU 3									; Number of bits for V-mode
SAMpmode1		EQU %100								; Graphics Pmode1 for setting the V1, V2 & V3
SAMpmode4		EQU %110								; Graphics Pmode4 for setting the V1,V2 & V3
SAMmemLoc		EQU $FFC6								; Sam's Video Address registers (7-Bits)
SAMmemLocBC		EQU 7									; Number of bits for V-address

PIA0RowRegister	EQU $FF00
IRQ_ACK			EQU $FF02								; Acknowledge the VSYNC interrupt.
IRQ_VSYNC		EQU $FF03								; VSYNC: Bit 7 is low when this IRQ triggered.
