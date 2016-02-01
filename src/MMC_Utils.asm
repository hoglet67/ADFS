
	\ Illuminate Caps Lock & Shift Lock
.SetLEDS
	LDX #&6
	STX &FE40
	INX
	STX &FE40
	RTS

	\ Reset LEDs
.ResetLEDS
    PHA
    TXA
    PHA
    TYA
    PHA
	LDA #&76
	JSR OSBYTE
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

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

.TUBE_CheckIfPresent
	LDA #&EA			; Tube present?
	LDX #&00			; X=FF if Tube present
	LDY #&FF
	JSR OSBYTE
	TXA 
	EOR #&FF
	STA TubePresentIf0
	RTS 

.TUBE_CLAIM
{
	PHA 
.tclaim_loop
	LDA #&C0+tubeid%
	JSR TubeCode
	BCC tclaim_loop
	PLA 
	RTS 
}

.TUBE_RELEASE
	JSR TUBE_CheckIfPresent
	BMI trelease_exit
.TUBE_RELEASE_NoCheck
	PHA 
	LDA #&80+tubeid%
	JSR TubeCode
	PLA 
.trelease_exit
	RTS 
