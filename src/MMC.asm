;; ADFS MMC Card Driver
;; (C) 2015 David Banks
;; Based on code from MMFS ROM by Martin Mather

trys%=&32

go_idle_state    =&40
send_op_cond     =&41
send_cid         =&4A
set_blklen       =&50
read_single_block=&51
write_block      =&58

;; **** Begin Read Transaction ****
.MMC_StartRead
     JSR MMC_DoCommand
     BNE errRead
     JMP MMC_WaitForData

;; **** Begin Write Transaction ****
.MMC_StartWrite
     JSR MMC_DoCommand
     BNE errWrite
     JMP MMC_SendingData

.errRead
     ORA #&40  ;; Setting bit 6 in the fault code will ensure it's printed
     TAX
     JSR L8374 ;; This version prints the fault code in X
     EQUB &C5
     EQUS "MMC Read fault"
     EQUB &00

.errWrite
     ORA #&40  ;; Setting bit 6 in the fault code will ensure it's printed
     TAX
     JSR L8374 ;; This version prints the fault code in X
     EQUB &C5
     EQUS "MMC Write fault"
     EQUB &00


;; **** Set-up MMC command sequence ****
;; C=0 for read, C=1 for write 
.MMC_SetupRW
     LDA #write_block
     BCS MMC_SetCommand
     LDA #read_single_block
        
;; **** Reset MMC Command Sequence ****
;; A=cmd, token=&FF

.MMC_SetCommand
     STA cmdseq%+1
     LDA #0
     STA cmdseq%+2
     STA cmdseq%+3
     STA cmdseq%+4
     STA cmdseq%+5
     LDA #&FF
     STA cmdseq%
     STA cmdseq%+6                   ;; token
     STA cmdseq%+7
     RTS

;; ***** Initialise MMC card *****
;; Carry=0 if ok
;; Carry=1 if card doesn't repsond at all!
;; corrupts A,X,Y
.MMC_INIT
{
     LDA #0
     STA mmcstate%

     LDA #trys%
     STA attempts%

     ;; 80 Clocks
.iloop
     LDY #10
     JSR MMC_Clocks

     ;; CMD0
     LDA #go_idle_state
     JSR MMC_SetCommand
     LDA #&95
     STA cmdseq%+6                   ; token (crc7)
     JSR MMC_DoCommand
     AND #&81                        ; ignore errors
     CMP #1
     BEQ il0
     JMP ifail
.il0
     LDA #&01
     STA cardsort%
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
     STA cardsort%
.il1
     ;; CMD1
     LDA #send_op_cond
     JSR MMC_SetCommand
     JSR MMC_DoCommand
     CMP #2
     BCC il11
     JMP ifail
.il11
     BIT EscapeFlag                  ; may hang
     BMI ifail
     CMP #0
     BNE il1
     LDA #&02
     STA cardsort%
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
     STA cardsort%

     ;; Set blklen=512
.iok
     LDA #set_blklen
     JSR MMC_SetCommand
     LDA #2
     STA cmdseq%+4
     JSR MMC_DoCommand
     BNE blkerr

     ;; All OK!
     LDA #&40
     STA mmcstate%
     CLC
     RTS

.ifail
     ;; Try again?
     DEC attempts%
     BEQ ifaildone
     JMP iloop

.ifaildone
     ;; Give up!
     SEC
     RTS

     ;; Failed to set block length
.blkerr
     JSR L8372
     EQUB &CD
     EQUS "MMC Set block len error"
     EQUB &00
}

.MMC_BEGIN
{
     PHA
     ;; Reset device
     JSR MMC_DEVICE_RESET

     ;; Check if MMC initialised
     ;; If not intialise the card
     BIT mmcstate%
     BVS beg2

     PHX
     PHY
     JSR MMC_INIT
     PLY
     PLX
     BCS carderr
.beg2
     PLA
     RTS

;; Failed to initialise card!
.carderr
     JSR L8372
     EQUB &CD
     EQUS "Card?"
     EQUB &00
     
}

;; Translate the sector number into a SPI Command Address
;; Sector number is in 256 bytes sectors which are stretched to become 512 byte sectors
;; For SDHC cards this is in blocks (which are also sectors)
;; For SD cards this needs converting to bytes by multiplying by 512

.setRandomAddress
{
    PHX
    LDA #0         ;; MSB of sector number
    PHA
    LDA &C203,X
    PHA
    LDA &C202,X
    PHA
    LDA &C201,X    ;; LSB of sector number
    PHA
    BRA setAddressFromStack
}

;; (&B0) + 8 is the LSB
;; (&B0) + 6 is the MSB
;; cmdseq%+5 is the LSB
;; cmdseq%+2 is the MSB

.setCommandAddress
{
    PHX
    LDA #0          ;; MSB of sector number
    PHA
    LDY #6          ;; Point to sector MSB in the control block
    LDX #3          ;; sector number is 3 bytes
.loop
    LDA (&B0), Y    ;; Stack the MSB first, LSB last
    PHA
    INY
    DEX
    BNE loop
}    

        
.setAddressFromStack
{
;; Process the drive number
     TSX
     LDA &103, X    ;; Bits 7-5 are the drive number
     PHA
     ORA &C317      ;; Add in current drive
     STA &C333      ;; Store for any error

     CLC            ;; Shift into bits 0-2
     ROL A
     ROL A
     ROL A
     ROL A
     AND #&07
     CMP numdrives% ;; check against number of ADFS partitions found 
     BCS invalidDrive

     ASL A          ;; Shift into bits 4-2 to index the drive table
     ASL A
     TAY            ;; Y will be used to index the drive table

     PLA            ;; Mask out the drive number, leaving just the MS sector
     AND #&1F
     STA &103, X

     CLC
.addDriveOffset
     LDA &101, X
     ADC drivetable%, Y
     STA &101, X
     INX
     INY
     TYA
     AND #&03
     BNE addDriveOffset 

     LDX #3          ;; sector number is 4 bytes
;;
     LDA cardsort%   ;; Skip multiply for SDHC cards (cardsort = 01)
     CMP #2
     BNE setCommandAddressSDHC
;;
;; Convert to bytes by multiplying by 512
;;
     CLC
.loop                ;; for SD the command address is bytes
     PLA
     ROL A
     STA cmdseq%+1, X
     DEX
     BNE loop
     STZ cmdseq%+5   ;; LSB is always 0
     BCS overflow    ;; if carry is set, overflow has occurred
     PLA             ;; if the MS byte of the original sector
     BNE overflow    ;; was non zero, overflow has occurred
     PLX
     RTS

.invalidDrive
     JSR L8372        ;; Generate error
     EQUB &A9         ;; ERR=169
     EQUS "Invalid drive"
     EQUB &00

.overflow
     JSR L8372        ;; Generate error
     EQUB &A9         ;; ERR=169
     EQUS "Sector overflow"
     EQUB &00
}

.setCommandAddressSDHC
{
.loop                ;; for SDHC the command address is sectors
     PLA             ;; copy directly to cmdseq%+2 ...cmdseq%+5
     STA cmdseq%+2, X
     DEX
     BPL loop
     PLX
     RTS
}

.incCommandAddress
{
     LDA cardsort%
     CMP #2
     BNE incCommandAddressSDHC
;; Add 512 to address (Sector always even)
     INC cmdseq%+4
.incMS
     INC cmdseq%+4
     BNE incDone
     INC cmdseq%+3
     BNE incDone
     INC cmdseq%+2
.incDone
     RTS

;; Add one to address
.incCommandAddressSDHC
     INC cmdseq%+5
     BEQ incMS
     RTS
}

.initializeDriveTable
{
;; Load 512b sector 0 (MBR) to &C000-&C1FF
;; Normally MBR resides here, but we do this before MBR is loaded
;; We can't use OSWORD &72 to do this, as we don't want alternative bytes skipped
     JSR MMC_BEGIN      ;; Initialize the card, if not already initialized
     CLC                ;; C=0 for Read
     JSR MMC_SetupRW
     JSR MMC_StartRead
     LDA #<mbrsector%
     STA datptr%
     LDA #>mbrsector%
     STA datptr% + 1
     JSR MMC_Read512
     JSR MMC_16Clocks	;; ignore CRC

     LDA mbrsector% + &1FE
     CMP #&55
     BNE noMBR
     LDA mbrsector% + &1FF
     CMP #&AA
     BNE noMBR

;; Partition entry 0 is 1BE
;; Partition entry 1 is 1CE
;; Partition entry 2 is 1DE
;; Partition entry 3 is 1EE
        
;; Partition entry has following structure
;; 00 = status (whether bootable)
;; 01-03 = CHS address of first absolute sector in partition
;; 04 = partition type (AD for ADFS)
;; 05-07 = CHS address of last absolute sector in partition
;; 08-0B = LBA of first absolute sector in partition
;; 0C-0F = Number of sectors in partition

     LDA #<(mbrsector% + &1BE)  ;; The start of the first partition entry
     STA datptr%                ;; is offset &1BE into the MBR
     LDA #>(mbrsector% + &1BE)
     STA datptr%+1

     LDX #(MAX_DRIVES * 4)      ;; Clear the drive table
.loop
     STZ drivetable% - 1, X     ;; all zeros is treated as an invalid drive
     DEX
     BNE loop
     STZ numdrives%             ;; clear the number of drives
        
.testPartition
     LDY #&04
     LDA (datptr%),Y
     CMP #&AD                   ;; ADFS = partition type AD
     BNE nextPartition
     INC numdrives%
     LDY #&08
.copyLBA
     LDA (datptr%),Y            ;; Read the LBA from the partition entry
     STA drivetable%, X         ;; Store it in the drive table
     INX
     INY
     CPY #&0C
     BNE copyLBA     
     CPX #(MAX_DRIVES * 4)
     BEQ done

.nextPartition
     CLC
     LDA datptr%               ;; Move to the next partition entry
     ADC #&10
     STA datptr%
     CMP #&FE                   ;; &FE = &BE + &10 * 4
     BNE testPartition

.done
     CPX #0                     ;; Did we find any ADFS partitions?
     BEQ noADFS                 ;; No, then fatal error
     RTS

.noMBR
     JSR L8372
     EQUB &CD
     EQUS "No MBR!"
     EQUB &00
    
.noADFS
     JSR L8372
     EQUB &CD
     EQUS "No ADFS partitions!"
     EQUB &00
}
