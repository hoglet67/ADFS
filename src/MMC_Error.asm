
.errWrite2
	TYA
	JSR ReportMMCErrS
	EQUB &C5
	EQUS "MMC Write response fault "
	BRK


    \ *********** MMC ERROR CODE ***********

	\\ Report MMC error
	\\ A=MMC response
	\\ If X<>0 print sector/parameter

errno%=&B0
errflag%=&B1
errptr%=&B8

.ReportMMCErrS
	LDX #&FF
	BNE rmmc

.ReportMMCErr
	LDX #0
.rmmc
{
	LDY #&FF
	STY CurrentCat			; make catalogue invalid
	STA errno%
	STX errflag%
	JSR ResetLEDS
	PLA
	STA errptr%
	PLA
	STA errptr%+1

	LDY #0
	STY MMC_STATE
	STY &100
.rmmc_loop
	INY
	BEQ rmmc_cont
	LDA (errptr%),Y
	STA &100,Y
	BNE rmmc_loop

.rmmc_cont
	LDA errno%
	JSR PrintHex100

	LDA errflag%
	BEQ rmmc_j100
	LDA #'/'
	STA &100,Y
	INY

	LDA par%
	JSR PrintHex100
	LDA par%+1
	JSR PrintHex100
	LDA par%+2
	JSR PrintHex100

.rmmc_j100
	LDA #0
	STA &100,Y
	JMP &100
}

.ReportError
	LDX #&02
	LDA #&00			; "BRK"
	STA &0100
.ErrCONTINUE
	\STA &B3			; Save A???
	JSR ResetLEDS
.ReportError2
	PLA 				; Word &AE = Calling address + 1
	STA &AE
	PLA 
	STA &AF
	\LDA &B3			; Restore A???
	LDY #&00
	JSR inc_word_AE
	LDA (&AE),Y			; Get byte
	STA &0101			; Error number
	DEX 
.errstr_loop
	JSR inc_word_AE
	INX 
	LDA (&AE),Y
	STA &0100,X
	BMI prtstr_return2		; Bit 7 set, return
	BNE errstr_loop
	JSR TUBE_RELEASE
	JMP &0100

.inc_word_AE
{
	INC &AE
	BNE inc_word_AE_exit
	INC &AF
.inc_word_AE_exit
	RTS
}
        
.prtstr_return2
	CLC 
	JMP (&00AE)			; Return to caller
