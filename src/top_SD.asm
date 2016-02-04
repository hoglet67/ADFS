PATCH_IDE=FALSE
PATCH_SD=TRUE
PATCH_FULL_ACCESS=TRUE
PATCH_INFO=TRUE
PATCH_UNSUPPORTED_OSFILE=FALSE
PATCH_PRESERVE_CONTEXT=TRUE
TEST_SHIFT=FALSE
INCLUDE_FLOPPY=FALSE

;;; Used in the SD Build only
_VIA_BASE=&FE60         ; Base Address of 6522 VIA
_TUBE_BASE=&FEE0        ; Base Address of Tube
_TURBOMMC=0             ; 1 = build for TurboMMC, and enable PB2-4 as outputs

TUBE_R3_DATA        = _TUBE_BASE + &05

sectorcount%        = &C2ED
cardsort%           = &C2EE
mmcstate%           = &C2EF
cmdseq%             = &C2F0

        
datptr%             = &B2        

attempts%           = &80  ;; TODO: Change this to a safe ZP location !!
errno%              = &80  ;; TODO: Change this to a safe ZP location !!
errflag%            = &81  ;; TODO: Change this to a safe ZP location !!
errptr%             = &82  ;; TODO: Change this to a safe ZP location !!

EscapeFlag          = &FF
        
        
include "adfs150.asm"

SAVE "../build/SD", &8000, &C000
