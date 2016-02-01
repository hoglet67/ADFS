\** MMFS ROM by Martin Mather
\** Compiled using BeebAsm V1.04
\** August 2011

\\ ******* HIGH LEVEL MMC CODE ********

go_idle_state=&40
send_op_cond=&41
send_cid=&4A
set_blklen=&50
read_single_block=&51
write_block=&58

	\\ **** Reset MMC Command Sequence ****
	\\ A=cmd, token=&FF
.MMC_SetCommand
	STA cmdseq%+1
	LDA #0
	STA cmdseq%+2
	STA cmdseq%+3
	STA cmdseq%+4
	STA cmdseq%+5
	LDA #&FF
	STA cmdseq%
	STA cmdseq%+6			;\ token
	STA cmdseq%+7
	RTS

	\\ ***** Initialise MMC card *****
	\\ Carry=0 if ok
	\\ Carry=1 if card doesn't repsond at all!
trys%=&32
attempts%=&C2

.MMC_INIT
{
	\\JSR SetLEDS
	LDA #0
	STA MMC_STATE

	LDA #trys%
	STA attempts%

	\\ 80 Clocks
.iloop
	LDY #10
	JSR MMC_Clocks

	\\ CMD0
	LDA #go_idle_state
	JSR MMC_SetCommand
	LDA #&95
	STA cmdseq%+6			; token (crc7)
	JSR MMC_DoCommand
	AND #&81			; ignore errors
	CMP #1
	BEQ il0
	JMP ifail
.il0
	LDA #&01
	STA CardSort
	LDA #&48
	JSR MMC_SetCommand
	LDA #&01
	STA cmdseq%+4
	LDA #&AA
	STA cmdseq%+5
	LDA #&87
	STA cmdseq%+6
	JSR MMC_DoCommand
	CMP #1
	BEQ isdhc

	LDA #&02
	STA CardSort
.il1
	\\ CMD1
	LDA #send_op_cond
	JSR MMC_SetCommand
	JSR MMC_DoCommand
	CMP #2
	BCC il11
	JMP ifail
.il11
	BIT EscapeFlag			; may hang
	BMI ifail
	CMP #0
	BNE il1
	LDA #&02
	STA CardSort
	JMP iok

.isdhc
	JSR UP_ReadByteX
	JSR UP_ReadByteX
	JSR UP_ReadByteX
	JSR UP_ReadByteX
.isdhc2
	LDA #&77
	JSR MMC_SetCommand
	JSR MMC_DoCommand
	LDA #&69
	JSR MMC_SetCommand
	LDA #&40
	STA cmdseq%+2
	JSR MMC_DoCommand
	CMP #&00
	BNE isdhc2
	LDA #&7A
	JSR MMC_SetCommand
	JSR MMC_DoCommand
	CMP #&00
	BNE ifail
	JSR UP_ReadByteX
	AND #&40
	PHA
	JSR UP_ReadByteX
	JSR UP_ReadByteX
	JSR UP_ReadByteX
	PLA
	BNE iok
	LDA #2
	STA CardSort

	\\ Set blklen=512
.iok
	LDA #set_blklen
	JSR MMC_SetCommand
	LDA #2
	STA par%+2
	JSR MMC_DoCommand
	BNE blkerr

	\\ All OK!
	LDA #&40
	STA MMC_STATE
	\\JSR ResetLEDS
	CLC
	RTS

.ifail
	\\ Try again?
	DEC attempts%
	BEQ ifaildone
	JMP iloop

.ifaildone
	\\ Give up!
	\\JSR ResetLEDS
	SEC
	RTS

	\\ Failed to set block length
.blkerr
    JSR L836B
	EQUB &FF
	EQUS "Set block len error "
    EQUB &00
}


	\ **** Set-up MMC command sequence ****
.MMC_SetupWrite
	LDA #write_block
	BNE setuprw

.MMC_SetupRead
	LDA #read_single_block
.setuprw
	JSR MMC_SetCommand
	JMP setCommandAddress

	\ **** Begin Read Transaction ****
.MMC_StartRead
	JSR MMC_DoCommand
	BNE errRead
	JMP MMC_WaitForData

.errRead
    JSR L836B
	EQUB &C5
	EQUS "MMC Read fault ",0

	\ **** Begin Write Transaction ****
.MMC_StartWrite
	JSR MMC_DoCommand
	BNE errWrite
	JMP MMC_SendingData

.errWrite
    JSR L836B
	EQUB &C5
	EQUS "MMC Write fault ",0



	\\ **** Read data block to memory ****
	\\ at loc. datptr%
	\\ sec%, seccount% & byteslastsec%
	\\ define block
.MMC_ReadBlock
{
	\\JSR SetLEDS
	JSR rdblk
	\\JMP ResetLEDS

.rb1_exit
	RTS

.rdblk
	LDX seccount%
	BEQ rb1_exit			; nothing to do

	\\LDA #1
	\\JSR MMC_RWBlock_CheckIfToTube

	LDX seccount%
	ROR sec%
	ROR skipsec%
	BPL rb2
	INX
.rb2
	STX seccount%
	ASL sec%			; sec always even

	JSR MMC_SetupRead

	LDX seccount%
	CPX #3
	BCS rb3				; X>2 = more than 2 sectors

.rb4_loop
	LDA byteslastsec%
	BNE rb5				; don't read whole sector
	CPX #1
	BEQ rb9				; one sector left

.rb3
	BIT skipsec%
	BPL rb6_loop

	\\ read odd sector
	JSR MMC_StartRead
	LDY #0
	STY skipsec%
	JSR MMC_Clocks
	JMP rb7

	\\ read even sectors
.rb6_loop
	JSR MMC_StartRead
	JSR MMC_Read256
	INC datptr%+1

.rb7
	JSR MMC_Read256
	INC datptr%+1
	JSR MMC_16Clocks		; ignore CRC

	\\ increment MMC sector
	JSR incCommandAddress

	LDX seccount%			; X>=2
	DEX
	DEX
	BEQ rb1_exit

	STX seccount%
	CPX #3
	BCS rb6_loop
	JMP rb4_loop


.rb9
	JSR MMC_StartRead
	JSR MMC_Read256
	JMP rbx4

	\\ A=byteslastsec>0
.rb5
	JSR MMC_StartRead

	BIT skipsec%
	BPL rbx1

	LDY #0				; Skip first MMC sector
	JSR MMC_Clocks
	JMP rbx2

.rbx1
	DEC seccount%			; =1 or =2
	BEQ rbx2

	JSR MMC_Read256
	INC datptr%+1

.rbx2
	JSR MMC_ReadBLS
	TYA				; BLS
	EOR #&FF
	TAY
	INY
	JSR MMC_Clocks

	LDA seccount%
	BNE rbx3

.rbx4
	LDY #0
	JSR MMC_Clocks

.rbx3
	JMP MMC_16Clocks
}

	\\ **** Write data block from memory ****
.wb1
	RTS

.MMC_WriteBlock
{
	\\JSR SetLEDS
	\\JSR wrblk
	\\JMP ResetLEDS

.wrblk
	LDX seccount%
	BEQ wb1				; nothing to do!

	\\LDA #0
	\\JSR MMC_RWBlock_CheckIfToTube

	LDX seccount%
	ROR sec%
	ROR A
	ASL sec%
	PHA

	JSR MMC_SetupWrite

	PLA
	BPL wb2				; sec even!

	\\ start is odd!
	\\ read mmc sector bytes 0-255
	\\ to buffer, then rewrite it
	\\ with page 1 of the data

	LDA #read_single_block
	STA cmdseq%+1
	JSR MMC_StartRead
	JSR MMC_ReadBuffer
	LDY #0
	JSR MMC_Clocks
	LDY #2
	JSR MMC_Clocks

	LDA #write_block
	STA cmdseq%+1
	JSR MMC_StartWrite
	JSR MMC_WriteBuffer
	JSR MMC_Write256
	JSR MMC_EndWrite
	DEC seccount%
	BEQ wb1				; finished
	INC datptr%+1

	\\ sector+=2
.wb4
	JSR incCommandAddress

.wb2
	LDX seccount%
	BEQ wb5				; finished
	DEX
	BNE wb3				; seccount>=2

	\\ 1 sector left
	\\ read mmc sector bytes 256-511
	\\ to buffer, then write last
	\\ page of data, followed by the
	\\ data in the buffer

	LDA #read_single_block
	STA cmdseq%+1
	JSR MMC_StartRead
	LDY #0
	JSR MMC_Clocks
	JSR MMC_ReadBuffer
	LDY #2
	JSR MMC_Clocks

	LDA #write_block
	STA cmdseq%+1
	JSR MMC_StartWrite
	JSR MMC_Write256
	JSR MMC_WriteBuffer
	JMP MMC_EndWrite		; finished

	\\ write whole sectors
	\\ i.e. 2 pages (512 bytes)

.wb3
	JSR MMC_StartWrite
	JSR MMC_Write256
	INC datptr%+1
	JSR MMC_Write256
	INC datptr%+1
	JSR MMC_EndWrite
	DEC seccount%
	DEC seccount%
	BNE wb4

.wb5
	RTS
}


	\\ **** BEGIN MMC TRANSACTION ****
.MMC_BEGIN
{

	\\ Reset device
	JSR MMC_DEVICE_RESET

	\\ Check if MMC initialised
	\\ If not intialise the card
	BIT MMC_STATE
	BVS beg2

	JSR MMC_INIT
	BCS carderr

.beg2
    RTS

	\\ Failed to initialise card!
.carderr
    JSR L836B
	EQUB &FF
	EQUS "Card?"
    EQUB &00
}


\\ Translate the sector number into a SPI Command Address
\\ Sector number is in 256 bytes sectors
\\ For SDHC cards this is in blocks (which are also sectors)
\\ For SD cards this needs converting to bytes by multiplying by 512

.setCommandAddress
{
\\ Skip multiply for SDHC cards (cardsort = 01)
	LDA CardSort
	CMP #2
	BNE setCommandAddressSDHC
\\ Convert to bytes by multiplying by 256
	LDA sec%+2
	STA cmdseq%+2
	LDA sec%+1
	STA cmdseq%+3
	LDA sec%
	STA cmdseq%+4
	LDA #0
	STA cmdseq%+5		
	RTS

		
.setCommandAddressSDHC
\\ Convert to 512b sectors by dividing by	
	LDA #0
	STA cmdseq%+2
	LDA sec%+2
	LSR A
	STA cmdseq%+3
	LDA sec%+1
	ROR A
	STA cmdseq%+4
	LDA sec%
	ROR A
	STA cmdseq%+5
	RTS
}

.incCommandAddress
{
	LDA CardSort
	CMP #2
	BNE incCommandAddressSDHC
\\ Add 512 to address (Sector always even)
	INC cmdseq%+4
.incMS
	INC cmdseq%+4
	BNE incDone
	INC cmdseq%+3
	BNE incDone
	INC cmdseq%+2
.incDone
	RTS

\\ Add one to address
.incCommandAddressSDHC
	INC cmdseq%+5
	BEQ incMS
	RTS
}

	
