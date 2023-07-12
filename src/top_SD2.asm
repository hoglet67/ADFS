PATCH_IDE=FALSE
PATCH_SD=TRUE
PATCH_FULL_ACCESS=TRUE
PATCH_INFO=TRUE
PATCH_UNSUPPORTED_OSFILE=TRUE
PATCH_PRESERVE_CONTEXT=TRUE
TEST_SHIFT=FALSE
INCLUDE_FLOPPY=FALSE
PATCH_IDFS=FALSE
PATCH_XDFS=FALSE

;;; Used in the SD Build only
_VIA_BASE=&FE80                 ; Base Address of 6522 VIA
_TUBE_BASE=&FEE0                ; Base Address of Tube
_TURBOMMC=0                     ; 1 = build for TurboMMC, and enable PB2-4 as outputs

TUBE_R3_DATA        = _TUBE_BASE + &05

MAX_DRIVES          = 2         ; don't make this bigger than 2 or the drive table below will overflow

attempts%           = &C2E9     ; 1 byte
sectorcount%        = &C2EA     ; 1 byte
cardsort%           = &C2EB     ; 1 byte
mmcstate%           = &C2EC     ; 1 byte
numdrives%          = &C2ED     ; 1 byte
cmdseq%             = &C2F0     ; 8 bytes
drivetable%         = &C2F8     ; 4 * MAX_DRIVES

mbrsector%          = &C000     ; 512 bytes tmp storage before fs is mounted
        
datptr%             = &B2

EscapeFlag          = &FF

include "adfs150.asm"
