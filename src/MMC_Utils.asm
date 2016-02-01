    \\ Save AXY and restore after
	\\ calling subroutine exited
.RememberAXY
	PHA
	TXA 
	PHA 
	TYA 
	PHA 
	LDA #HI(rAXY_restore-1)		; Return to rAXY_restore
	PHA 
	LDA #LO(rAXY_restore-1)
	PHA 

.rAXY_loop_init
{
	LDY #&05
.rAXY_loop
	TSX
	LDA &0107,X
	PHA
	DEY
	BNE rAXY_loop
	LDY #&0A
.rAXY_loop2
	LDA &0109,X
	STA &010B,X
	DEX
	DEY
	BNE rAXY_loop2
	PLA
	PLA
}

.rAXY_restore
	PLA 
	TAY 
	PLA 
	TAX 
	PLA 
	RTS 

	\ Illuminate Caps Lock & Shift Lock
.SetLEDS
	LDX #&6
	STX &FE40
	INX
	STX &FE40
	RTS

	\ Reset LEDs
.ResetLEDS
	JSR RememberAXY
	LDA #&76
	JMP OSBYTE

.PrintHex100
{
	PHA 				; Print hex to &100+Y
	JSR A_rorx4
	JSR phex100
	PLA 
.phex100
	JSR NibToASC
	STA &0100,Y
	INY
}
.noesc
	RTS

.A_rorx4
	LSR A
	LSR A
	LSR A
	LSR A
	RTS

	\ Convert low nibble to ASCII
.NibToASC
{
	AND #&0F
	CMP #&0A
	BCC nibasc
	ADC #&06
.nibasc
	ADC #&30
	RTS
}
