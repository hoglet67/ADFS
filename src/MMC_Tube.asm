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

.TUBE_CheckIfPresent
	LDA #&EA			; Tube present?
	LDX #&00			; X=FF if Tube present
	LDY #&FF
	JSR OSBYTE
	TXA 
	EOR #&FF
	STA TubePresentIf0
	RTS 
        
