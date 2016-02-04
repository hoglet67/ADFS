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

TUBE_R3_DATA        = _TUBE_BASE + &05

attempts%           = &C2EC
sectorcount%        = &C2ED
cardsort%           = &C2EE
mmcstate%           = &C2EF
cmdseq%             = &C2F0

datptr%             = &B2

EscapeFlag          = &FF

include "adfs150.asm"

SAVE "../build/SD", &8000, &C000
