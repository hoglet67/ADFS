CurrentDrv=&CD
VID=MA+&10E0				; VID
\DRIVE_INDEX0=VID 			; 4 bytes
\DRIVE_INDEX4=VID+4			; 4 bytes
MMC_SECTOR=VID+8			; 3 bytes
MMC_CIDCRC=VID+&B			; 2 bytes
\CHECK_CRC7=VID+&D			; 1 byte

\\ Stubbed out code
        
.CheckCRC7
.LoadDrive
.MMC_Sector_Reset
    RTS

