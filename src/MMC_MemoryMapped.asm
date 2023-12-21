;; ADFS MMC Card Driver for the Memory Mapped Interface in BeebFPGA
;; (C) 2023 David Banks


_MASTER_ =? TRUE

IF _MASTER_
mmc%=&FEDC
ELSE
mmc%=&FE1C
ENDIF

;; Shifting starts on a write to mmc%
;; On BeebFPGA it only takes 1us to complete

;; TODO: Is this used elsewhere ???

MACRO SHIFT_DELAY
    NOP
    NOP
    NOP
ENDMACRO

;; RESET DEVICE
.MMC_DEVICE_RESET
    RTS

;; Read byte (User Port)
;; Write FF
.MMC_GetByte
    LDA #&FF
    STA mmc%
    SHIFT_DELAY
    LDA mmc%
    RTS


;; *** Send &FF to MMC Y times ***
;; Y=0=256
.MMC_16Clocks
    LDY #2
.MMC_Clocks
{
    LDA #&FF
.clk1
    STA mmc%
    SHIFT_DELAY
    DEY
    BNE clk1
    RTS             ; A=&FF, Y=0
}

;; *** Send command to MMC ***
;; On exit A=result, Z=result=0
.MMC_DoCommand
{
    LDX #0
    LDY #8
.dcmd1
    LDA cmdseq%,X
    STA mmc%
    SHIFT_DELAY
    INX
    DEY
    BNE dcmd1
    LDX #&FF
    \ Wait for response, Y=0
.wR1mm
    STX mmc%
    SHIFT_DELAY
    LDA mmc%
    BPL dcmdex
    DEY
    BNE wR1mm
    CMP #0
.dcmdex
    RTS
}                   ; A=result, X=X+8, Y=?


;; *** Wait for data token ***
.MMC_WaitForData
{
    LDX #&FF
.wl1
    STX mmc%
    SHIFT_DELAY
    LDA mmc%
    CMP #&FE            ;\ data token
    BNE wl1
    RTS             ; A=&FE, X=&FF, Y unchanged
}


;; *** Read 256 bytes to datptr ***
.MMC_Read256
    LDX #0

.MMC_ReadX
    LDY #0
    BIT &CD
    BVS MMC_ReadToTube

.MMC_ReadToMemory
    LDA #&FF      ; Read byte
    STA mmc%
    SHIFT_DELAY
    LDA mmc%
    STA (datptr%),Y
    LDA #&FF      ; Skip dummy byte
    STA mmc%
    SHIFT_DELAY
    INY
    DEX
    BNE MMC_ReadToMemory
    RTS

.MMC_ReadToTube
    LDA #&FF      ; Read first byte
    STA mmc%
    SHIFT_DELAY
    LDA mmc%
    STA TUBE_R3_DATA
    LDA #&FF       ; Skip dummy byte
    STA mmc%
    SHIFT_DELAY
    INY
    DEX
    BNE MMC_ReadToTube
    RTS

;; **** Send Data Token to card ****
.MMC_SendingData
    LDX #&FF
    STX mmc%
    SHIFT_DELAY
    STX mmc%
    SHIFT_DELAY
    DEX
    STX mmc%
    SHIFT_DELAY
    RTS

;; **** Complete Write Operation *****
.MMC_EndWrite
{
    JSR MMC_16Clocks
    LDX #&FF
    STX mmc%
    SHIFT_DELAY
    LDA mmc%
    TAY
    AND #&1F
    CMP #5
    BNE error

    LDA #&FF
.ew1
    STX mmc%
    SHIFT_DELAY
    CMP mmc%
    BNE ew1
    RTS
.error
    JMP errWrite
}

;; **** Write 256 bytes from dataptr% ****
.MMC_Write256
{
    LDY #0
    BIT &CD
    BVS MMC_WriteFromTube
.MMC_WriteFromMemory
    LDA (datptr%),Y  ; Write byte
    STA mmc%
    SHIFT_DELAY
    LDA #0           ; Write dummy byte
    STA mmc%
    SHIFT_DELAY
    INY
    BNE MMC_WriteFromMemory
    RTS

.MMC_WriteFromTube
    LDA TUBE_R3_DATA ; Write byte
    STA mmc%
    SHIFT_DELAY
    LDA #0           ; Write dummy byte
    STA mmc%
    SHIFT_DELAY
    INY
    BNE MMC_WriteFromTube
    RTS
}

;; *** Read 512 byte sector to datptr
.MMC_Read512
{
    LDX #2
    LDY #0
.loop
    LDA #&FF
    STA mmc%
    SHIFT_DELAY
    LDA mmc%
    STA (datptr%),Y
    INY
    BNE loop
    INC datptr%+1
    DEX
    BNE loop
    RTS
}
