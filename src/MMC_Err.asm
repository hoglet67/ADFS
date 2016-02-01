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
