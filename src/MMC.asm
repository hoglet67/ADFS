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
     JSR ReportMMCErrS
     EQUB &C5
     EQUS "MMC Read fault ",0

.errWrite
     JSR ReportMMCErrS
     EQUB &C5
     EQUS "MMC Write fault ",0


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
     JSR ReportMMCErrS
     EQUB &FF
     EQUS "Set block len error ",0
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
     JSR ReportError
     EQUB &FF
     EQUS "Card?",0
}

;; Translate the sector number into a SPI Command Address
;; Sector number is in 256 bytes sectors which are stretched to become 512 byte sectors
;; For SDHC cards this is in blocks (which are also sectors)
;; For SD cards this needs converting to bytes by multiplying by 512

.setRandomAddress
{
    PHX
    LDA &C203,X    ;; MSB of sector number   
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
     LDX #3          ;; sector number is 3 bytes
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
     STX cmdseq%+5   ;; LSB is always 0
     PLX
     RTS
}

.setCommandAddressSDHC
{
.loop                ;; for SDHC the command address is sectors
     PLA
     STA cmdseq%+2, X
     DEX
     BNE loop
     STX cmdseq%+2   ;; MSB is always 0
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
