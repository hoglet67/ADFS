PATCH_IDE=FALSE
PATCH_SD=TRUE
PATCH_FULL_ACCESS=TRUE
PATCH_INFO=TRUE
PATCH_UNSUPPORTED_OSFILE=TRUE
PATCH_PRESERVE_CONTEXT=TRUE
TEST_SHIFT=FALSE
INCLUDE_FLOPPY=FALSE

;;; Used in the SD Build only
_VIA_BASE=&FE60         ; Base Address of 6522 VIA
_TUBE_BASE=&FEE0        ; Base Address of Tube
_TURBOMMC=0             ; 1 = build for TurboMMC, and enable PB2-4 as outputs

MA=&C000-&0E00			; Offset to Master hidden static workspace
MP=HI(MA)

buf%              =MA+&0E00
cmdseq%           =MA+&1087
par%              =MA+&1089
TubeNoTransferIf0 =MA+&109E
MMC_STATE         =MA+&109F			; Bit 6 set if card initialised
TubePresentIf0    =MA+&10D6
CardSort          =MA+&10D7

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

datptr%       =&BC
sec%          =&BE
seccount%     =&C1
skipsec%      =&C2
attempts%     =&C2
byteslastsec% =&C3
EscapeFlag    =&FF

tubeid%=&0A			; See Tube Application Note No.004 Page 7
        
include "adfs150.asm"

SAVE "../build/SD", &8000, &C000
