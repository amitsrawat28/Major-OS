
;---------------------------------------------------- 1). Bootloader.asm-----------------------------------------------------------------
;	SIZE 		= 	512 BYTES
;	FUNCTION	=	It loads the kernel and set the Directory table and Disk Map for the files residing on the Boot disk and available sectors


	BITS 16
	[org 0x00]								; Tell the Assembler that our code is loaded at 0x0000. However the bootloader is loaded
											; at 0x7c00, which we will tell by setting the CS to 0x7c0 in the next instruction

	JMP 0x7c0:START							; The only way change CS is to make far jump  using a CS:IP pair

START:
	MOV bx , 0x7c0							; We can't set the segment with the immediate value but with
	MOV ds , bx								; another register. This is a two-step process.

	MOV BYTE [0X01FD] , dl					; The BIOS saves the Boot drive no. in lower 8-Bits of DX register

	MOV bx , 0x4000							; Setting up Stack
	MOV ss , bx
	MOV bp , 0x000
	MOV sp , bp

	MOV si , BOOT_MSG
	CALL PRINT_STRING

	MOV si , KERNEL_MSG
	CALL PRINT_STRING

	MOV ah , 0								; Interrupt(16h) to take inputs from Keyboard
	INT 16h									; AH = 0x00   --->   Function to take keypress and store it in Register AL


;__________________________Loading OS Kernel from sector 4 of disk to address 0x1000:0x0000____________________________

	MOV bx , 0x1000							; Setting ES:BX pair
	MOV es , bx
	MOV bx , 0x0000

	CALL LOAD_KERNEL

	JMP 0x1000:0x0000		 				; Our kernel is loaded at 0x10000

;----------------------------------------------------------------KERNEL FUNTIONS USED IN BOOTLOADER----------------------------------------------------

	LOAD_KERNEL:
										; Interrupt(13h) to access the Disk(i.e. Disk no. stored in DL), before the interrupt can perform
				MOV al , 1				; actual function, it is necessary to set some register
				MOV ah , 2				; AL = No. of sectors to read
				MOV ch , 0x00			; AH = 0x02 (funtion to load sectors from disk)
				MOV dh , 0x00			; CH = Cylinder No.
				MOV dl , [0X01FD]		; DL = DRIVE NUMBER (Saved in program bootloader.asm at 0X07c0:0x01fd)
				MOV cl , 4				; DH = Track No.
				INT 0x13				; Cl = Starting Sector No. from where to load
										; ES:BX = Starting address from where the sector(s) will be loaded

				JC .DISK_ERROR			; Carry flag is set when there is a fault while reading disk like disk not inserted,
										; an attempt is made to read a faulty sector, we indexed a sector beyond the limit
										; of the disk, etc
				RET

	.DISK_ERROR:
				MOV si , DISK_ERROR_MSG
				CALL PRINT_STRING
				jmp $

	PRINT_STRING:
					pusha
					MOV ah , 0x0e
			.START:
					LODSB
					cmp al,0
					JE .END
					INT 0x10
					JMP .START
			.END:
					popa
					RET

;--------------------------------------------------------------------DATA----------------------------------------------------------

	BOOT_MSG		:	db 10,13,10,13,"  Booting Successfull",10 , 13 , 0
	DISK_ERROR_MSG 	:   db "Disk Read Error !" , 0
	KERNEL_MSG		:	DB "  Kernel loaded at address 0x1000:0000" ,10 , 13, "  Press any key to continue.......... " , 10 , 13  ,10,13,10,13,0


	times 510-($-$$) db 0
	DW 0xaa55			;		BOOTLOADER SIGNATURE