;------------------------------------------------------------------2)disk-map.asm-----------------------------------
;	SIZE		=	512 BYTES
;	FUNCTION	=	It consist of 512 bytes, which represents the availability of 512 sectors of Disk
;					0xFF ---------> Sector is being used
;					0x00 ---------> Sector is Free

DB 0xFF								; bootloader.asm
DB 0XFF								; disk-map.asm
DB 0XFF								; directory.asm
DB 0XFF								; kernel.asm
TIMES 14 DB 0XFF					; shell.asm
TIMES 512-($-$$) db 0X00			; Free sectors