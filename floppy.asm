;-----------------------------------------floppy.asm--------------------------
;		It creates a floppy(in binary) of 512 sectors filled with 0x00
;		SECTOR 	=	512 BYTES
;		262144 = 512 * 512

times 262144 db 0