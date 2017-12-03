;-------------------------------------------------------------4).kernel.asm--------------------------------------------
;	 FUNCTION	=	The heart of the OS that manages all the hardware and software. It makes user and application programs
;	 				to interact with the hardware through Commnand line interface and it loads the available programs
;					for execution that resides on the disk.
;

	bits 16
	[org 0x00]

;-----------------------------------------------------------USER EVIRONMENT---------------------------------------------------------------

START:
	MOV bx , 0x1000
	MOV ds , bx
	MOV BX , 0X000

	MOV SI , WECOME_KERNEL
	CALL PRINT_STRING

;__________________________Loading Disk-Map from sector 2 of disk to address 0x0800:0x0000____________________________

	MOV SI , DISK_MAP_MSG
	CALL PRINT_STRING


	MOV BX , 0X0800
	MOV ES , BX
	MOV BX , 0X0000
	MOV BYTE [TOTAL_SECTORS] , 1
	MOV BYTE [SECTOR_START] , 2
	CALL READ_SECTOR


;__________________________Loading Directory table from sector 3 of disk to address 0x0840:0x0000____________________________
	MOV SI , DIRECTORY_MSG
	CALL PRINT_STRING
	MOV BX , 0X0840
	MOV ES , BX
	MOV BX , 0X0000
	MOV BYTE [TOTAL_SECTORS] , 1
	MOV BYTE [SECTOR_START] , 3
	CALL READ_SECTOR

;__________________________Loading Shell_____________________________________
	MOV SI , SHELL_MSG
	CALL PRINT_STRING

	MOV BX , 0X2000
	MOV ES , BX
	MOV BX , 0X0000
	MOV BYTE [TOTAL_SECTORS] , 14
	MOV BYTE [SECTOR_START] , 5
	CALL READ_SECTOR

	mov ah , 0
	int 16h

	JMP 0X2000:0X0000


;---------------------------------------------------------------KERNEL FUNCTIONS-----------------------------------------------------------------
	READ_SECTOR:
				PUSH DS
				PUSH BX
				MOV BX , 0X7C0
				MOV DS , BX
				MOV BX , 0X01FD
				MOV dl , [DS:BX]					; DL = DRIVE NUMBER (Saved in program bootloader.asm at 0X7C0:0x01FD)
				POP BX
				POP DS
				MOV ah , 2							; AH = 0x02 (funtion to load sectors from disk)
				MOV al , [TOTAL_SECTORS]			; AL = No. of sectors to read
				MOV ch , [CYLINDER_NO]				; CH = Cylinder No.
				MOV dh , [TRACK_NO]					; DH = Track No.
				MOV cl , [SECTOR_START]				; Cl = Sector No. from where to load

				INT 0x13				 			; INT 13H to Call Disk accecc interrupt
													; ES:BX = Starting address from where the sector(s) will be loaded
				MOV BYTE [TOTAL_SECTORS] , 0
				MOV BYTE [SECTOR_START] , 0
				JC .DISK_ERROR						; Carry flag is set when there is a fault while reading disk like disk not inserted,
													; an attempt is made to read a faulty sector, we indexed a sector beyond the limit
													; of the disk, etc
				RET

	.DISK_ERROR:
				MOV si , DISK_ERROR_MSG
				CALL PRINT_STRING
				jmp $


	PRINT_HEX:
				XOR CL,CL
				MOV bx , 0xf0f0
				and bx , dx
				shr bx , 4
				INC CL
				jmp .HEX_ASCII
		.FIRST:
				MOV [TEST_HEX + 2], bh
				MOV [TEST_HEX + 4] , bl
				MOV bx , 0x0f0f
				and bx , dx
				INC CL
				jmp .HEX_ASCII
		.SECOND:
				MOV [TEST_HEX + 3] , bh
				MOV [TEST_HEX + 5] , bl
				MOV si , TEST_HEX
				CALL PRINT_STRING
				MOV AH , 0X0E
				MOV al , 10
				INT 0x10
				MOV al , 13
				INT 0x10
				RET

		.HEX_ASCII:

		.CMPBH :
				CMP bh , 0x9
				JLE .NUMBH
				add bh , 0x37
				JMP .CMPBL

		.NUMBH:
				add bh , 0x30
				JMP .CMPBL

		.CMPBL:
				CMP bl , 0x9
				JLE .NUMBL
				add bl , 0x37
				JMP .END

		.NUMBL:
				add bl , 0x30
				JMP .END

		.END:
				CMP CL , 1
				JE .FIRST
				JMP .SECOND


	PRINT_STRING:
				pusha
				MOV ah , 0x0e
		.START:
				LODSB
				CMP al,0
				JE .END
				INT 0x10
				JMP .START
		.END:
				popa
				RET

;-------------------------------------------------------DATA--------------------------------------------------------
	TOTAL_SECTORS	:  	DB 0
	CYLINDER_NO		:	DB 0
	TRACK_NO		:	DB 0
	SECTOR_START	:	DB 0
	DISK_ERROR_MSG 	:   db "  Disk Read Error !" , 0
	DISK_MAP_MSG	:	DB "  Loading Disk-Map at address 0x0800:0000",10,13,0
	DIRECTORY_MSG	:   db "  Loading Directory table at address 0x0840:0000",10,13,0
	SHELL_MSG		:   db "  Loading Shell at address 0x2000:0000",10,13,0
	TEST_HEX		:	db '0x0000', 10 , 13 , 0
	WECOME_KERNEL	:	DB  10,13,"  Kernel welcomes you !",10,13,0

	times 512-($-$$) db 0