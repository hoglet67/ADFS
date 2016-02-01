PATCH_IDE=1
PATCH_SD=0
PATCH_PRESERVE_CONTEXT=1
        
include "adfs150.asm"

SAVE "../build/IDE", &8000, &C000
