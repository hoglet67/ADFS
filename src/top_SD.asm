PATCH_IDE=0
PATCH_SD=1
PATCH_PRESERVE_CONTEXT=1

;;; Used in the SD Build only
_VIA_BASE=&FE60         ; Base Address of 6522 VIA
_TUBE_BASE=&FEE0        ; Base Address of Tube
_TURBOMMC=0             ; 1 = build for TurboMMC, and enable PB2-4 as outputs

MA=&C000-&0E00			; Offset to Master hidden static workspace
MP=HI(MA)
cmdseq%=MA+&1087
par%=MA+&1089
MMC_STATE=MA+&109F			; Bit 6 set if card initialised
CardSort=MA+&10D7
TubePresentIf0=MA+&10D6
TubeNoTransferIf0=MA+&109E
EscapeFlag=&FF
CurrentCat=MA+&1082

OSBYTE=&FFF4
        
TubeCode=&0406
TUBE_R1_STATUS=_TUBE_BASE + &00
TUBE_R1_DATA  =_TUBE_BASE + &01
TUBE_R2_STATUS=_TUBE_BASE + &02
TUBE_R2_DATA  =_TUBE_BASE + &03
TUBE_R3_STATUS=_TUBE_BASE + &04
TUBE_R3_DATA  =_TUBE_BASE + &05
TUBE_R4_STATUS=_TUBE_BASE + &06
TUBE_R4_DATA  =_TUBE_BASE + &07

datptr%=&BC
sec%=&BE
seccount%=&C1
skipsec%=&C2
byteslastsec%=&C3

tubeid%=&0A			; See Tube Application Note No.004 Page 7

buf%=MA+&E00
        
include "adfs150.asm"

SAVE "../build/SD", &8000, &C000
