;-----------------------------------------------------------5).shell.asm--------------------------------------------

;		It is a Command line interface from which the user will type the available command name and request to execute them from kernel.
;		User can create text files and save them to disk, which he/she can print later on screen.

	bits 16
	[org 0x00]
;--------------------------------------------------------------SHELL ENVIRONMENT-------------------------------------------------------

		MOV BX , 0X2000
		MOV DS , BX

		MOV al , 0x03								; Set the 80 X 25 text screen mode
		MOV ah , 0
		INT 10h

		MOV SI , SHELL_START
		CALL PRINT_STRING

		MOV AH , 0
		INT 16H

		MOV al , 0x03								; Set the 80 X 25 text screen mode
		MOV ah , 0
		INT 10h

		MOV AH , 0BH
		MOV BH , 00H
		MOV BL , 0x01
		INT 10H

		MOV si , SHELL_MSG
		CALL PRINT_STRING

	PRINT_PROMPT:

				MOV si , PROMPT
				CALL PRINT_STRING
				MOV di , CMD_BUFFER
				CALL CHECK_SECTOR

	READ_COMMAND:
					XOR CL , CL

			.START	:
					MOV ah, 0
					INT 16h

					CMP AL , 0X20
					JLE .BLANK

					CMP CL , 0X3f
					JE .START

					STOSB
					INC CL
					MOV ah , 0x0e
					INT 10h
					JMP .START

			.BLANK	:

					CMP al , 0x0d
					JE .END

					CMP al , 0x08						;	0X08 ---> Backspace
					JE .BACKSPACE

					JMP .START

			.BACKSPACE:
					CMP CL  , 0
					JE .START

					DEC DI
					MOV byte [DI] , 0
					DEC CL
					MOV AH , 0x0e
					MOV AL , 0x08
					INT 10H
					MOV	AL , ' '
					INT 10H
					MOV AL , 0x08
					INT 10H
					JMP .START

			.END	:
					MOV AH , 0X0E
					MOV AL , 10
					INT 10H
					MOV AL , 13
					INT 10H
					CMP CL , 0
					JE PRINT_PROMPT
					MOV AL , CL
					MOV BL , CL
					STOSB

		SEARCH_CMD:
					MOV SI , CMD_NAME
					MOV DI , CMD_BUFFER
					MOV DL , 1							; DL ---> COMMAND NUMBER (DEFAULT 1st)
					MOV CH , 0							; CH ---> NO. OF LETTERS EQUAL
			.LOOP:
					mov AL, [SI]
  					mov CL, [DI]
  					CMP AL , 13
 					JE .INVALID_CMD
   					cmp AL, CL
   					jne .NEXT

   					cmp CL , BL
 				  	je .DONE

   					inc di
 		  			inc si
   					INC CH
   					jmp .LOOP

 			.NEXT:
 					CMP CH , 0
 					JNE .RESET
 					INC DL
   					ADD SI , 9
   					JMP .LOOP

 			.RESET:
					CMP CH ,0
					JE .NEXT
 					DEC DI
 					DEC SI
 					DEC CH
 					JMP .RESET

 			.DONE:
   					JMP JUMP_TO_CMD

			.INVALID_CMD:

					MOV SI , CMD_ERR
					CALL PRINT_STRING
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

		JUMP_TO_CMD:
					CMP DL , 1
					JE HELP
					CMP DL , 2
					JE EDIT
					CMP DL , 3
					JE DIR
					CMP DL , 4
					JE VERSION
					CMP DL , 5
					JE AUTHOR
					CMP DL , 6
					JE CLEAR
					CMP DL , 7
					JE OPEN
					CMP DL , 8
					JE SHUTDOWN
					CMP DL , 9
					JE COPY
					CMP DL , 10
					JE DELETE


					MOV SI , WRONG
					CALL PRINT_STRING
					CALL PRINT_PROMPT

	JMP $

;------------------------------------------------------SHELL FUNCTIONS----------------------------------------------------------------------
	CLEAR_CMD_BUFFER:
			CMP CL , 0X40
			JE PRINT_PROMPT
			MOV BYTE [DI] , 0
			INC DI
			INC CL
			JMP CLEAR_CMD_BUFFER

	CLEAR_DISK_BUFFER:
			CMP CX , 0X400
			JE .DONE
			MOV BYTE [DI] , 0
			INC DI
			INC CX
			JMP CLEAR_DISK_BUFFER
		.DONE:
			RET

	COUNT_FILES:
			MOV BX , 0X840
			MOV ES , BX
			MOV BX , 16
			XOR CL , CL
	 .LOOP:
			MOV AL , [ES:BX]
			CMP AL , 0
			JE .DONE
			INC CL
			ADD BX , 16
			JMP .LOOP

	 .DONE:
	 		MOV BX , 0X2000
			MOV ES , BX
			RET

	 .NOFILE:
	 		MOV BX , 0X2000
			MOV ES , BX
	 		RET

	DIR_PRINT_FILE_NAME:
			CMP CL , 0
			JE .NOFILE

			DEC CL
			XOR DL , DL
			XOR CH , CH
			INC CH
			MOV AH , 0X0E
			MOV SI , FILE_DIR_MSG
			CALL PRINT_STRING
			MOV BX , 0X840
			MOV ES , BX
			MOV BX , 16

	  .LOOP:
	  		MOV AL , [ES:BX]

			CMP DL , AL
			JE .CHECKMORE

			INT 10H
			INC DL
			INC BX
			JMP .LOOP

	  .CHECKMORE:
	  		CMP CL , 0
	  		JE .DONE
	  		DEC CL
	  		INC CH
	  		XOR DH , DH
	  		SUB BX , DX
	  		ADD BX , 16
	  		MOV DL , 0
	  		CMP CH , 5
	  		JE .ADD_NEW_LINE
	  		JMP .SEPARATE_FILE

	  .ADD_NEW_LINE:
	  		MOV SI , NEW_L
	  		CALL PRINT_STRING

	  		MOV AH , 0X0E
	  		MOV AL , ' '
	  		INT 10H
	  		MOV AL , ' '
	  		INT 10H
	  		MOV AL , ' '
	  		INT 10H
	  		MOV CH , 1
	  		JMP .LOOP

	  .SEPARATE_FILE:
			MOV SI ,FILE_NAME_SPACE
			CALL PRINT_STRING
			JMP .LOOP

	  .NOFILE:
	  		MOV SI , NOFILE_MSG
	  		CALL PRINT_STRING
	  		MOV BX , 0X2000
			MOV ES , BX
			RET
	  .DONE:
	  		MOV SI , NEW_L
	  		CALL PRINT_STRING
	  		MOV BX , 0X2000
			MOV ES , BX
			RET

	CHECK_SECTOR:
				MOV BX , 0X0800
				MOV ES , BX
				MOV BX , 0X0000
				XOR CL , CL					;	CL	=	Used Sectors
				XOR DX , DX					;	DL	=	Free Sectors
				MOV AH , 0
				MOV CH , 1

		.LOOP:
				CMP DH , 0XFF
				JE .END
				MOV BYTE AL , [ES:BX]
				CMP AL , 0XFF
				JE .USED

				CMP CH , 1
				JE .FREE_ONE

				CMP CH , 2
				JE .CHECK_TWO

				CMP CH , 3
				JE .FREE_TWO

				INC DL
				INC BX
				INC DH
				JMP .LOOP

		.USED:
				INC CL
				INC BX
				INC DH
				MOV AH ,0
				JMP .LOOP

		.FREE_ONE:
				INC DH
				MOV [FREE_ONE] , DH
				INC DL
				INC BX
				INC CH
				INC AH

				JMP .LOOP

		.BOTH_SAME:
				PUSH AX
				MOV AL , [FREE_ONE]
				MOV [FREE_TWO] , AL
				POP AX
				INC DL
				INC BX
				MOV CH , 4
				INC DH
				JMP .LOOP

		.CHECK_TWO:
				CMP AH , 1
				JE .BOTH_SAME
				INC CH
				MOV AH , 0
				INC DL
				INC BX
				INC DH
				JMP .LOOP

		.FREE_TWO:
				CMP AH , 2
				JE .PUTTWO

				INC AH
				INC DL
				INC BX
				INC DH
				JMP .LOOP

		.PUTTWO:
				DEC DH
				MOV [FREE_TWO] , DH
				ADD DH , 2
				INC DL
				INC BX
				INC CH
				JMP .LOOP


		.END:
				MOV BYTE [USE_SECTORS] , CL
				MOV BYTE [FREE_SECTORS] , DL

				MOV BX , 0X2000
				MOV ES , BX
				RET

	HEX_DEC_PRINT:
			PUSHA
			MOV AL , 0X30					;			AL = ONES
			MOV AH , 0X30					;			AH = TENS
			MOV BL , 0X30					;			BL = HUNDREDS
			MOV BH , 0X30					;			BH = THOUSANDS
			MOV CL , 0X30					;			CL = TEN THOUSANDS

		.LOOP:

			CMP DX , 0X00
			JE .END

		.ONES:

			CMP AL , 0X39
			JE .TENS
			INC AL
			DEC DX
			JMP .LOOP

		.TENS:

			CMP AH ,0X39
			JE .HUNDREDS
			INC AH
			DEC DX
			MOV AL , 0X30
			JMP .LOOP

		.HUNDREDS:

			CMP BL , 0X39
			JE .THOUSANDS
			INC BL
			DEC DX
			MOV AL , 0X30
			MOV AH , 0X30
			JMP .LOOP

		.THOUSANDS:

			CMP BH , 0X39
			JE .10THOUSANDS
			INC BH
			DEC DX
			MOV AL , 0X30
			MOV AH , 0X30
			MOV BL , 0X30
			JMP .LOOP

		.10THOUSANDS:

			INC CL
			DEC DX
			MOV AL , 0X30
			MOV AH , 0X30
			MOV BL , 0X30
			MOV BH , 0X30
			JMP .LOOP

		.END:
			MOV BYTE [ONES] , AL
			MOV BYTE [TENS] , AH
			MOV BYTE [HUNDREDS] , BL
			MOV BYTE [THOUSANDS] , BH
			MOV BYTE [TEN_THOUSANDS], CL
			MOV AH , 0X0E

		.PRINT_10TH:
			CMP BYTE [TEN_THOUSANDS] , 0X30
			JE .PRINT_TH

			MOV AL , [TEN_THOUSANDS]
			INT 10H
			JMP .SKIPCHECK_TH

		.PRINT_TH:
			CMP BYTE [THOUSANDS] , 0X30
			JE .PRINT_H

		.SKIPCHECK_TH:
			MOV AL , [THOUSANDS]
			INT 10H
			JMP .SKIPCHECK_H

		.PRINT_H:
			CMP BYTE [HUNDREDS] , 0X30
			JE .PRINT_T

		.SKIPCHECK_H:
			MOV AL , [HUNDREDS]
			INT 10H
			JMP .SKIPCHECK_T

		.PRINT_T:
			CMP BYTE [TENS] , 0X30
			JE .PRINT_O

		.SKIPCHECK_T:
			MOV AL , [TENS]
			INT 10H

		.PRINT_O:
			MOV AL , [ONES]
			INT 10H
			MOV SI , NEW_L
			CALL PRINT_STRING
			JMP .CLEAR_DATA

		.CLEAR_DATA:
			MOV BYTE [ONES] , 0
			MOV BYTE [TENS] , 0
			MOV BYTE [HUNDREDS] , 0
			MOV BYTE [THOUSANDS] , 0
			MOV BYTE [TEN_THOUSANDS], 0
			POPA
			RET

	TYPE_FILE_NAME:
					XOR CL , CL
			.START:
					MOV ah, 0
					INT 16h

					CMP AL , 0X40
					JLE .BLANK

					CMP CL , 0X0D
					JE .START

					STOSB
					INC CL
					MOV ah , 0x0e
					INT 10h
					JMP .START

			.BLANK:
					CMP al , 0x0d
					JE .END

					CMP al , 0x08						;	0X08 ---> Backspace
					JE .BACKSPACE

					JMP .START

			.BACKSPACE:
					CMP CL  , 0
					JE .START

					DEC DI
					MOV byte [DI] , 0
					DEC CL
					MOV AH , 0x0e
					MOV AL , 0x08
					INT 10H
					MOV	AL , ' '
					INT 10H
					MOV AL , 0x08
					INT 10H
					JMP .START

			.END:
					CMP CL , 0
					JE .START
					MOV AL , CL
					STOSB
					MOV BX , 0X2000
					MOV ES , BX
					RET

	SEARCH_FILE:
					XOR CX , CX
					MOV BX , 0X840
					MOV ES , BX
					MOV BX , 16
		.LOOP:
					MOV AL , [ES:BX]
					MOV DL , [SI]

					CMP AL , 0
					JE .NOFILE

					CMP AL , DL
					JNE .NEXT

					CMP CL , AL
					JE .FOUND

					INC CL
					INC SI
					INC BX
					JMP .LOOP

		.NEXT:
					cmp CL , 0
					jne .RESET

					ADD BX , 16
					JMP .LOOP

		.RESET:
					XOR CH , CH
					SUB SI , CX
					SUB BX , CX
					ADD BX , 16
					XOR CX , CX
					JMP .LOOP

		.FOUND:
					XOR CH , CH
					SUB BX , CX
					MOV CL , 1
					PUSH DX
					MOV DX , 0X2000
					MOV ES , DX
					POP DX
					RET
		.NOFILE:
					XOR CX , CX
					MOV BX , 0X2000
					MOV ES , BX
					RET

	CLEAR_FILE_NAME:
					XOR CL, CL
					MOV DI , FILE_NAME
			.CLEAR_LOOP:
					CMP CL , 16
					JE .DONE
					MOV AL , 0
					STOSB
					INC CL
					JMP .CLEAR_LOOP
			.DONE:
					RET

	PUT_IN_DIR:
				MOV BX , 0X0840
				MOV ES , BX
				MOV BX , 0X0000
				XOR CL , CL
		.CHECK_DIR:
				MOV CL , [ES:BX]
				CMP CL , 0X00
				JE .HERE
				ADD BX , 16
				JMP .CHECK_DIR
		.HERE:
				MOV SI , FILE_NAME
				XOR CL,CL

		.LOOP:
				CMP CL , 16
				JE .DONE
				MOV BYTE AL , [SI]
				MOV BYTE [ES:BX] , AL
				INC BX
				INC CL
				INC SI
				JMP .LOOP

		.DONE:
				RET
;______________________________________________________HELP COMMAND______________________________________________________________
	HELP:
			MOV SI , HELP_MSG
			CALL PRINT_STRING
			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER
;______________________________________________________DIR COMMAND_________________________________________________________________
	DIR:
			MOV SI , DIR_MSG
			CALL PRINT_STRING

			CALL CHECK_SECTOR

			MOV SI , US_MSG
			CALL PRINT_STRING

			XOR DX , DX
			MOV DL , [USE_SECTORS]
			CALL HEX_DEC_PRINT

			MOV SI , FS_MSG
			CALL PRINT_STRING

			XOR DX, DX
			MOV DL , [FREE_SECTORS]
			CALL HEX_DEC_PRINT

			MOV SI , NEW_L
			CALL PRINT_STRING

			MOV SI , NUM_FILE_MSG
			CALL PRINT_STRING

			CALL COUNT_FILES
			XOR DX , DX
			MOV DL ,CL
			CALL HEX_DEC_PRINT

			CALL DIR_PRINT_FILE_NAME

			MOV SI , NEW_L
			CALL PRINT_STRING

			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER

;___________________________________________________________VERSION COMMAND__________________________________________________________________
	VERSION:
			MOV SI , VERSION_MSG
			CALL PRINT_STRING
			MOV SI , NEW_DL
			CALL PRINT_STRING
			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER
;__________________________________________________________AUTHOR COMMAND________________________________________________________________________
	AUTHOR:
			MOV SI , AUTHOR_MSG
			CALL PRINT_STRING
			MOV SI , NEW_DL
			CALL PRINT_STRING
			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER
;___________________________________________________________CLEAR COMMAND___________________________________________________________________________
	CLEAR:
			MOV al , 0x03
			MOV ah , 0
			INT 10h
			MOV AH , 0BH
			MOV BH , 00H
			MOV BL , 0x01
			INT 10H
			MOV si , SHELL_MSG
			CALL PRINT_STRING
			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER

;______________________________________________________________EDIT COMMAND_______________________________________________________________________
	EDIT:

			MOV AH , [USE_SECTORS]
			CMP AH , 0XFF
			JE .NO_MORE_FILES

			MOV SI , EDIT_MSG
			CALL PRINT_STRING

		.ENTRY:
			MOV AH , 0
			INT 16H

			CMP AL , 0X0D
			JE .CONTINUE_EDIT

			CMP AL , 0X1B
			JE .EXITEDIT

			JMP .ENTRY

		.NO_MORE_FILES:

			MOV SI , NO_MORE_FILES_MSG
			CALL PRINT_STRING

		.EXITEDIT:
			MOV SI , NEW_DL
			CALL PRINT_STRING

			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER

		.CONTINUE_EDIT:
			MOV al , 0x03
			MOV ah , 0
			INT 10h

			MOV AH , 0BH
			MOV BH , 00H
			MOV BL , 0x08
			INT 10H

			MOV AH , 5
			MOV AL , 0
			INT 10H

			MOV SI , EDITOR
			CALL PRINT_STRING

			XOR CX , CX
			XOR DL , DL									; DL	=	CHARACTER NO.
			XOR BX , BX
			MOV DH , 3									; DH	=	LINE NO.
			MOV AH , 02
			INT 10H

			MOV DI , DISK_BUFFER

			.START:
					MOV ah, 0
					INT 16h

					CMP AL , 0X20
					JLE .BLANK

					CMP CX , 1020
					JE .START

					CMP DL , 78
					JE .NEWPOS

					MOV ah , 0x0e
					INT 10h
					STOSB
					INC CX
					INC DL
					JMP .START

			.BLANK:
					CMP AL , 0x08
					JE .BACKSPACE

					CMP AL , 0X1B
					JE .END

					CMP CX , 1020
					JE .START

					CMP AL , 0X20					;	0x20 ---> space
					JE .SPACE

					CMP AL , 0x0d
					JE .NEWL

					JMP .START

			.NEWPOS:
					CMP DH , 23
					JE .START

					PUSH DX
					MOV BH , AL
					MOV AH , 0X0E
					MOV AL , 10
					STOSB
					INC CX
					INT 10H
					MOV AL , 13
					STOSB
					INC CX
					INT 10H
					MOV AL ,BH
					STOSB
					INT 10H
					INC CX
					MOV DL , 0
					MOV BH , 0
					INC DL
					INC DH
					JMP .START

			.SPACE:
					CMP CX , 0
					JE .START

					CMP DL , 78
					JE .NEWPOS

					STOSB
					MOV AH , 0X0E
					INT 10H
					INC CX
					INC DL
					JMP .START

			.BACKSPACE:
					CMP CX  , 0
					JE .START

					CMP DL , 0
					JE .PREVLINE

					dec di
					MOV byte [DI] , 0
					DEC CX
					DEC DL
					MOV AH , 0x0e
					MOV AL , 0x08
					INT 10H
					MOV	AL , ' '
					INT 10H
					MOV AL , 0x08
					INT 10H
					JMP .START

			.PREVLINE:

					MOV AH , 0X02
					MOV BH , 0
					POP DX
					INT 10H
					dec di
					MOV byte [DI] , 0
					DEC CX
					dec di
					MOV byte [DI] , 0
					DEC CX

					JMP .START

			.NEWL:
					CMP DH , 23
					JE .START

					CMP CX , 0
					JE .START

					PUSH DX
					MOV AH , 0X0E
					MOV AL , 10
					STOSB
					INC CX
					INT 10H
					MOV AL , 13
					STOSB
					INC CX
					INT 10H
					INC DH

					MOV DL , 0
					JMP .START

			.END:
					PUSH CX
					PUSH DI
					PUSH DX
					MOV DH , 23
					MOV DL , 0
					MOV AH , 02
					INT 10H
					MOV SI , ASK_USER
					CALL PRINT_STRING
			.ASK:
					MOV AH , 0
					INT 16H

					CMP AL , 'n'
					JE DONT_SAVE

					CMP AL , 'N'
					JE DONT_SAVE

					CMP AL , 0X1B
					JE .CANCEL

					CMP CX , 0
					JE .ASK

					CMP AL , 'y'
					JE SAVE

					CMP AL , 'Y'
					JE SAVE

					JMP .ASK

			.CANCEL:

					MOV AH , 0X0E
					INT 10H
					MOV DL , 43
			.LOOP:
					CMP DL , 0
					JE .CLEARED
					MOV AH , 0X0E
					MOV AL , 0X08
					INT 10H

					MOV AL , ' '
					INT 10H

					MOV AL , 0X08
					INT 10H
					DEC DL
					JMP .LOOP

			.CLEARED:
					MOV AH , 02
					MOV BH , 0
					POP DX
					INT 10H
					POP DI
					POP CX
					JMP .START

		DONT_SAVE:
					MOV AH , 0X0E
					INT 10H
					POP DX
					POP DI
					POP CX

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV si , SHELL_MSG
					CALL PRINT_STRING
					MOV CX , 0
					MOV DI , DISK_BUFFER
					CALL CLEAR_DISK_BUFFER
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

		SAVE:
					MOV AH , 0X0E
					INT 10H
					POP DX
					POP DI
					POP CX

					MOV AL , 0X1B
					STOSB
					INC CX
					MOV WORD [FILE_SIZE] , CX

					MOV SI , FILE_NAME_MSG
					call PRINT_STRING

		SAVE_AGAIN:
					MOV DI , FILE_NAME
					CALL TYPE_FILE_NAME

					MOV SI , FILE_NAME
					CALL SEARCH_FILE

					CMP CX , 1
					JE FILE_EXIST

					CALL CHECK_SECTOR
					JMP COUNT_SECTOR

		FILE_EXIST:
					MOV SI , ALREADY_EXIST
					CALL PRINT_STRING
					CALL CLEAR_FILE_NAME
					JMP SAVE_AGAIN

		COUNT_SECTOR:
					MOV DX , [FILE_SIZE]
					CMP DX , 0X200
					JLE .ONLYONE
					MOV CL , 2
					MOV BYTE [TOTAL_SECTORS] , CL
					MOV DL , [FREE_TWO]
					MOV [SECTOR_START] , DL
					INC DL
					MOV [SECTOR_END] , DL
					JMP WRITE_FILE_NAME

			.ONLYONE:
					MOV CL, 1
					MOV BYTE [TOTAL_SECTORS] , CL
					MOV DL , [FREE_ONE]
					MOV [SECTOR_START] , DL
					MOV [SECTOR_END] , DL
					JMP WRITE_FILE_NAME

	WRITE_FILE_NAME:
					MOV DI , FILE_NAME
					ADD DI , 14
					MOV AL , [SECTOR_START]
					MOV BYTE [DI] , AL
					INC DI
					MOV AL , [SECTOR_END]
					MOV BYTE [DI] , AL

					JMP UPDATE_DISKMAP

	UPDATE_DISKMAP:
					MOV BX , 0X800
					MOV ES , BX
					MOV	BX , 0

					MOV CL , [TOTAL_SECTORS]
					MOV DL , [SECTOR_START]
					DEC DL
					ADD BL , DL
			.LOOP:
					CMP CL,0
					JE WRITE_TO_DISK
					MOV BYTE [ES:BX] , 0XFF
					DEC CL
					INC BX
					JMP .LOOP

	WRITE_TO_DISK:
					MOV BX , 0X2000
					MOV ES , BX
					MOV BX , DISK_BUFFER

					CALL WRITE_SECTOR
					CALL PUT_IN_DIR

					CALL CLEAR_FILE_NAME
					MOV BX , 0X2000
					MOV ES , BX

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV si , SHELL_MSG
					CALL PRINT_STRING

					MOV CX , 0
					MOV DI , DISK_BUFFER
					CALL CLEAR_DISK_BUFFER
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

;_____________________________________________________________OPEN COMMAND_____________________________________________________________

		OPEN:
				MOV AH , [USE_SECTORS]
				CMP AH , 0X12
				JE .NO_FILES_TO_OPEN

			.PROMPT_AGAIN:
					MOV SI , OPEN_FILE_PROMPT
					CALL PRINT_STRING

			.ASK_AGAIN:
					MOV AH , 0
					INT 16H

					CMP AL , 0X0D
					JE .CONTINUE_OPEN

					CMP AL , 0X1B
					JE .CANCEL

					JMP .ASK_AGAIN

			.CONTINUE_OPEN:
					MOV BX , 0X2000
					MOV DS , BX
					MOV ES , BX

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV SI , OPEN_V
					CALL PRINT_STRING

					MOV SI , OPEN_MSG
					CALL PRINT_STRING

					MOV DI , FILE_NAME
					CALL TYPE_FILE_NAME

					MOV SI , FILE_NAME
					CALL SEARCH_FILE

					CMP CX , 1
					JE .FOUND

					MOV SI , FILE_NOT_EXIST
					CALL PRINT_STRING

					JMP .PROMPT_AGAIN

			.NO_FILES_TO_OPEN:
					MOV SI , NO_FILES_TO_OPEN_MSG
					CALL PRINT_STRING

			.CANCEL:
					MOV SI , NEW_DL
					CALL PRINT_STRING

					CALL CLEAR_FILE_NAME
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

			.FOUND:
					MOV CX , 0X840
					MOV ES , CX
					ADD BX , 14

					XOR CX, CX
					XOR AX , AX

					MOV AL , [ES:BX]
					MOV BYTE [SECTOR_START], AL
					INC BX
					MOV CL , [ES:BX]
					SUB CX , AX
					INC CX
					MOV BYTE [TOTAL_SECTORS] , CL
					MOV BX , 0X2000
					MOV ES , BX
					MOV BX , DISK_BUFFER

					CALL READ_SECTOR

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x09
					INT 10H

					MOV AH , 5
					MOV AL , 0
					INT 10H


					MOV SI , MIDDLE
					CALL PRINT_STRING

					MOV SI , FILE_NAME
					CALL PRINT_FILE_NAME

					MOV SI , UNDERLINE
					CALL PRINT_STRING

					MOV BX , DISK_BUFFER

	PRINT_FILE:
					MOV ah , 0x0e
			.START:
					MOV AL , [BX]

					CMP al , 0X1B
					JE .PRINTED

					INT 0x10
					INC BX
					JMP .START

			.PRINTED:
					MOV DH , 23
					MOV DL , 0
					MOV BH , 0
					MOV AH , 02
					INT 10H

					MOV SI , EXIT_FILE_MSG
					CALL PRINT_STRING

			.LOOP:
					MOV AH , 0
					INT 16H

					CMP AL , 0X1B
					JE .DONE

					JMP .LOOP

			.DONE:
					MOV BX , 0X2000
					MOV DS , BX
					MOV ES , BX

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV si , SHELL_MSG
					CALL PRINT_STRING

					CALL CLEAR_FILE_NAME

					MOV CX , 0
					MOV DI , DISK_BUFFER
					CALL CLEAR_DISK_BUFFER

					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

	PRINT_FILE_NAME:
					PUSHA
					MOV AH , 0x0E
			.START:
					LODSB
					CMP AL , 0X40
					JLE .END
					INT 0x10
					JMP .START
			.END:
					POPA
					RET
;__________________________________________________________________SHUTDOWN COMMAND______________________________________________________________________
	SHUTDOWN:
;
;	.CHECK_FOR_APM:
;			mov ah,53h				; apm command
;			mov al,00h            	; installation check command
;			xor bx,bx            	; device id(0 =  APM BIOS)
;			int 15h               	; call the BIOS function through interrupt 15h
;			jc APM_ERROR			; carry is set if any error occured
;			JMP .CONNECT_TO_REAL

			MOV SI , ASK_TO_SHUTDOWN
			CALL PRINT_STRING

	.AGAIN:
			MOV AH , 0
			INT 16H

			CMP AL , 0X0D
			JE .CONNECT_TO_REAL

			CMP AL , 0X1B
			JE .NOPE

			JMP .AGAIN

	.CONNECT_TO_REAL:
			MOV al , 0x03
			MOV ah , 0
			INT 10h

			mov ah,53h               ;this is an APM command
			mov al,1				 ;AL = MODE (01 REAL MODE )
			xor bx,bx                ;device id (0 = APM BIOS)
			int 15h                  ;call the BIOS function through interrupt 15h
;			jc APM_ERROR			 ;carry is set if any error occured

			MOV AH , 0BH
			MOV BH , 00H
			MOV BL , 0x04
			INT 10H

			XOR CX , CX
			XOR DL , DL
			XOR BX , BX
			MOV DH , 8
			MOV AH , 02
			INT 10H

			MOV SI , SHUTTING_DOWN
			CALL PRINT_STRING
			XOR BX , BX
	.WAIT:
			CMP BX , 30
			JE .ENABLE_POWER_ALL
			CMP BX , 60
			JE .PRINT_DOTS
			CMP BX , 100
			JE .PRINT_GOODBYE
			CMP BX , 130
			JE .PRINT_EMICON_I
			CMP BX , 160
			JE .PRINT_EMICON_II
			CMP BX , 190
			JE .PRINT_EMICON_III
			CMP BX , 230
			JE .POWER_OFF_ALL
			MOV AH , 86h
			MOV CX , 0
			MOV DX , 0XFFFF
			INT 15H
			INC BX
			JMP .WAIT

;	.DISCONNECT:
;			mov ah,53h               ;this is an APM command
;			mov al,04h               ;interface disconnect command
;			xor bx,bx                ;device id (0 = APM BIOS)
;			int 15h                  ;call the BIOS function through interrupt 15h
;			jc .disconnect_error     ; carry is set if any error occured. ERROR CODE IS STORED IN AH , IF 03 THEN NOT CONNECTED TO ANY MODE
;

	.ENABLE_POWER_ALL:
			MOV SI , SHUTTING_DOWN_DOT
			CALL PRINT_STRING
			mov ah,53h              ;APM command
			mov al,08h              ;CHANGE THE STATE OF POWER MANAGEMENT
			PUSH BX
			mov bx,0001h            ;01 FOR ALL DEVICES
			mov cx,0001h            ;POWER MANAGEMENT ON
			int 15h                 ;call the BIOS function through interrupt 15h
;			jc APM_ERROR
			POP BX
			INC BX
			JMP .WAIT
	.PRINT_DOTS:
			MOV SI , SHUTTING_DOWN_DOT
			CALL PRINT_STRING
			INC BX
			JMP .WAIT

	.PRINT_GOODBYE:
			PUSH BX
			MOV al , 0x03
			MOV ah , 0
			INT 10h

			MOV AH , 0BH
			MOV BH , 00H
			MOV BL , 0x00
			INT 10H

			XOR CX , CX
			XOR DL , DL
			XOR BX , BX
			MOV DH , 11
			MOV AH , 02
			INT 10H

			MOV SI , GOODBYE
			CALL PRINT_STRING
			POP BX
			INC BX
			JMP .WAIT


	.PRINT_EMICON_I:
			MOV SI , EMICON_I
			CALL PRINT_STRING
			INC BX
			JMP .WAIT

	.PRINT_EMICON_II:
			MOV SI , EMICON_II
			CALL PRINT_STRING
			INC BX
			JMP .WAIT

	.PRINT_EMICON_III:
			MOV SI , EMICON_III
			CALL PRINT_STRING
			INC BX
			JMP .WAIT

	.POWER_OFF_ALL:
			mov ah,53h              ;this is an APM command
			mov al,07h              ;Set the power state...
			mov bx,0001h            ;...on all devices to...
			mov cx , 3
			int 15h                 ;call the BIOS function through interrupt 15h
;			jc APM_ERROR

	.NOPE:
			MOV SI , NEW_DL
			CALL PRINT_STRING
			MOV CL , 0
			MOV DI , CMD_BUFFER
			JMP CLEAR_CMD_BUFFER

;_____________________________________________________________DELETE COMMAND______________________________________________________________

		DELETE:
				MOV AH , [USE_SECTORS]
				CMP AH , 0X12
				JE .NO_FILES_TO_DELETE

			.PROMPT_AGAIN:
					MOV SI , OPEN_FILE_PROMPT
					CALL PRINT_STRING

			.ASK_AGAIN:
					MOV AH , 0
					INT 16H

					CMP AL , 0X0D
					JE .CONTINUE_DELETE

					CMP AL , 0X1B
					JE .CANCEL

					JMP .ASK_AGAIN

			.CONTINUE_DELETE:

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV SI , DEL_MSG
					CALL PRINT_STRING

					MOV DI , FILE_NAME
					CALL TYPE_FILE_NAME

					MOV SI , FILE_NAME
					CALL SEARCH_FILE

					CMP CX , 1
					JE .FOUND

					MOV SI , FILE_NOT_EXIST
					CALL PRINT_STRING

					JMP .PROMPT_AGAIN


			.NO_FILES_TO_DELETE:

					MOV SI , NO_FILES_TO_DELETE_MSG
					CALL PRINT_STRING

			.CANCEL:
					MOV SI , NEW_DL
					CALL PRINT_STRING

					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

			.FOUND:
					PUSH BX
					MOV BX , 0X840
					MOV ES , BX
					POP BX
					ADD BX , 14
					MOV DX , BX
					MOV AL , [ES:BX]
					MOV [SECTOR_START] , AL
					INC BX
					MOV AH , [ES:BX]
					MOV [SECTOR_END] , AH

					MOV BX , 0X1E
			.LOOP:
					MOV CL  , [ES:BX]

					CMP DX , BX
					JE .BYPASS

					CMP AL , CL
					JE .COPYEXIST

					CMP CL , 0
					JE .NOCOPY

					ADD BX , 16
					JMP .LOOP

			.BYPASS:
					ADD BX , 16
					JMP .LOOP

			.NOCOPY:
					SUB BX , 30
					SUB DX , 14
					CMP BX , DX
					JE .NO_DIR_UPDATE
					PUSH BX								;LAST FILE ENTRY IN DIRECTORY
					PUSH DX								;OUR FILE ENTRY IN DIRECTORY
					XOR CL , CL
					JMP .UPDATE_DIR

			.COPYEXIST:
					SUB DX , 14
					MOV BX , 0
					XOR CL , CL
			.CHECK_LAST:
					MOV CL , [ES:BX]
					CMP CL , 0
					JE .HERE
					ADD BX , 16
					JMP .CHECK_LAST
			.HERE:
					SUB BX , 16
					MOV SI , BX
					XOR CL , CL
					MOV DI , DX
			.UPDATING_DIR:
					CMP CL , 16
					JE .CLEAR_DIR_ONLY
					MOV AL , [ES:SI]
					MOV [ES:DI] , AL
					INC SI
					INC DI
					INC CL
					JMP .UPDATING_DIR

			.CLEAR_DIR_ONLY:
					XOR CL , CL
				.LOOPING:
					CMP CL , 16
					JE .DONE

					MOV BYTE [ES:BX] , 0X00
					INC BX
					INC CL
					JMP .LOOPING


			.UPDATE_DIR:
					POP DX
					MOV DI , DX
					POP BX
					MOV SI , BX
					XOR CL , CL

			.UPDATING:
					CMP CL , 16
					JE .NO_DIR_UPDATE
					MOV AL , [ES:SI]
					MOV [ES:DI] , AL
					INC SI
					INC DI
					INC CL
					JMP .UPDATING

			.NO_DIR_UPDATE:
					XOR CL , CL
			.CLEAR:
					CMP CL , 16
					JE .CLEAR_FROM_DISKMAP

					MOV BYTE [ES:BX] , 0X00
					INC BX
					INC CL
					JMP .CLEAR

			.CLEAR_FROM_DISKMAP:
					MOV BX , 0X800
					MOV ES , BX
					MOV AL , [SECTOR_START]
					DEC AL
					XOR BX ,BX
					MOV BL , AL
					MOV BYTE [ES:BX] , 0X00
					MOV AL , [SECTOR_END]
					DEC AL
					MOV BL , AL
					MOV BYTE [ES:BX] , 0X00
					CALL CHECK_SECTOR
					CALL CLEAR_FILE_NAME
					JMP .DELETE_FILE_CONTENT

			.DELETE_FILE_CONTENT:
					MOV AL , [SECTOR_END]
					MOV BL , [SECTOR_START]
					SUB AL , BL
					INC AL
					MOV [TOTAL_SECTORS] , AL
					MOV BX , 0X2000
					MOV ES , BX
					MOV BX , DISK_BUFFER
					CALL WRITE_SECTOR

			.DONE:
					CALL CLEAR_FILE_NAME
					MOV BX , 0X2000
					MOV ES , BX
					MOV DS , BX

					MOV SI , NEW_DL
					CALL PRINT_STRING
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER


;
;_____________________________________________________________COPY COMMAND_______________________________________________________________

		COPY:
				MOV AH , [USE_SECTORS]
				CMP AH , 0X12
				JE .NO_FILES_TO_COPY

			.PROMPT_AGAIN:
					MOV SI , OPEN_FILE_PROMPT
					CALL PRINT_STRING

			.ASK_AGAIN:
					MOV AH , 0
					INT 16H

					CMP AL , 0X0D
					JE .CONTINUE_COPY

					CMP AL , 0X1B
					JE .CANCEL

					JMP .ASK_AGAIN

			.CONTINUE_COPY:

					MOV al , 0x03
					MOV ah , 0
					INT 10h

					MOV AH , 0BH
					MOV BH , 00H
					MOV BL , 0x01
					INT 10H

					MOV SI , COPY_MSG
					CALL PRINT_STRING

					MOV DI , FILE_NAME
					CALL TYPE_FILE_NAME

					MOV SI , FILE_NAME
					CALL SEARCH_FILE

					CMP CX , 1
					JE .FOUND

					MOV SI , FILE_NOT_EXIST
					CALL PRINT_STRING

					JMP .PROMPT_AGAIN

			.NO_FILES_TO_COPY:

					MOV SI , NO_FILES_COPY_MSG
					CALL PRINT_STRING

			.CANCEL:
					MOV SI , NEW_DL
					CALL PRINT_STRING

					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

			.FOUND:
					ADD BX , 14
					PUSH BX

					CALL CLEAR_FILE_NAME

					MOV SI , FILE_NAME_MSG
					CALL PRINT_STRING

			.HERE:
					MOV DI , FILE_NAME
					CALL TYPE_FILE_NAME

					MOV SI , FILE_NAME
					CALL SEARCH_FILE

					CMP CX , 1
					JE .ALREADY_EXIST

					MOV BX , 0X840
					MOV ES , BX

					POP BX

					MOV SI ,  FILE_NAME
					ADD SI , 14
					MOV AL , [ES:BX]
					MOV BYTE [SI] , AL
					INC SI
					INC BX
					MOV AL , [ES:BX]
					MOV BYTE [SI] , AL
					CALL PUT_IN_DIR

					CALL CLEAR_FILE_NAME
					MOV BX , 0X2000
					MOV ES , BX

					MOV SI , NEW_DL
					CALL PRINT_STRING
					MOV CL , 0
					MOV DI , CMD_BUFFER
					JMP CLEAR_CMD_BUFFER

		.ALREADY_EXIST:
					CALL CLEAR_FILE_NAME

					MOV SI , ALREADY_EXIST
					CALL PRINT_STRING

					JMP .HERE


;-----------------------------------------------------KERNEL FUNTION--------------------------------------------------------------------------
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
				MOV BYTE [SECTOR_END] , 0

				JC .DISK_ERROR						; Carry flag is set when there is a fault while reading disk like disk not inserted,
													; an attempt is made to read a faulty sector, we indexed a sector beyond the limit
													; of the disk, etc
				RET

		.DISK_ERROR:
					MOV si , DISK_ERROR_MSG
					CALL PRINT_STRING
					jmp $

	WRITE_SECTOR:
				PUSH DS
				PUSH BX
				MOV BX , 0X7C0
				MOV DS , BX
				MOV BX , 0X01FD
				MOV dl , [DS:BX]					; DL = DRIVE NUMBER (Saved in program bootloader.asm at 0X7C0:0x01FD)
				POP BX
				POP DS
				MOV ah , 3							; AH = 0x03 (funtion to write sectors to disk)
				MOV al , [TOTAL_SECTORS]			; AL = No. of sectors to read
				MOV ch , [CYLINDER_NO]				; CH = Cylinder No.
				MOV dh , [TRACK_NO]					; DH = Track No.
				MOV cl , [SECTOR_START]				; Cl = Sector No. where to load

				INT 0x13				 			; INT 13H to Call Disk accecc interrupt
													; ES:BX = Starting address from where the sector(s) will be loaded
				MOV BYTE [TOTAL_SECTORS] , 0
				MOV BYTE [SECTOR_START] , 0
				MOV BYTE [SECTOR_END] , 0

				JC .DISK_ERROR						; Carry flag is set when there is a fault while reading disk like disk not inserted,
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
				CMP al,0
				JE .END
				INT 0x10
				JMP .START
			.END:
				popa
				RET

;--------------------------------------------------------DATA----------------------------------------------------------------------------------
	SHELL_START		:	DB 10,13,10,13,"   SHELL LOADED SUCCESSFULLY " , 10,13,10,13,"   I am waiting for a keypress........",0
	SHELL_MSG		:   db " Welcome to My Operating System : MAJOR OS  ", 10 ,13, " I am glad you came <-- Amit Singh rawat" , 10 , 13 ,10,13, " Type HELP for the Commands available",10,13,10,13,0
	PROMPT 			:	db ">>" , 0
	CMD_ERR			: 	DB 10,13, "    ------------      NO COMMAND FOUND     ------------",10,13,10,13,0
	CMD_BUFFER	times 64 DB 0
	CMD_NAME		:	DB "HELP",4,0,0,0,0,"EDIT",4,0,0,0,0,"DIR",3,0,0,0,0,0,"VERSION",7,0,"AUTHOR",6,0,0,"CLEAR",5,0,0,0,"OPEN",4,0,0,0,0,"SHUTDOWN",8,"COPY",4,0,0,0,0,"DELETE",6,0,0,13
	WRONG			:	DB " YOU HAVE DONE SOMETHING WRONG",10,13,0
	HELP_MSG		:	DB 10,13,"  HELP v1.0",10,13,"  Description --> Prints all the commands available",10,13,"---------------------------------------------------------",10,13,10,13,"  HELP      --    Prints all available command",10,13,"  DIR       --    Prints the information of Directory table",10,13,"  CLEAR     --    Clears the Screen",10,13,"  EDIT      --    Opens Editor to create Text file",10,13,"  OPEN      --    Opens a user file and prints the content",10,13,"  COPY      --    Copies a user file with a new name",10,13,"  DELETE    --    Deletes a User file",10,13,"  VERSION   --    Prints the Current Version of the OS",10,13,"  AUTHOR    --    Prints the information about the Author",10,13,"  SHUTDOWN  --    Shuts your Computer down",10,13,10,13,0
	VERSION_MSG		:	DB 	10,13,"   MAJOR OS",10,13,"   ----------",10,13,"   Current Version 1.0(Stable)",10,13,"   copyLEFT Free Software",0
	AUTHOR_MSG		:	DB  10,13,"    DEVELOPER INFORMATION",10,13,"   ---------------------------",10,13,"    Amit Singh Rawat",10,13,"    amitsrawat28@gmail.com",0
	USE_SECTORS		: 	DB 0
	FREE_SECTORS	:   DB 0

	DIR_MSG			:	DB 10,13,"  DIRECTORY V1.0",10,13,10,13,0
	US_MSG			:	DB "  NUMBER OF USED SECTORS    ----    ",0
	FS_MSG			:	DB "  NUMBER OF FREE SECTORS    ----    ",0
	NUM_FILE_MSG	:	DB 10,13,"  NUMBER OF USER FILES   --   ",0
	FILE_DIR_MSG	:	DB 10,13,10,13,"   ALL USER FILE NAMES",10,13,"   -----------------------------------",10,13,"   ",0
	FILE_NAME_SPACE	:	DB "  |  ",0
	NOFILE_MSG		:	DB 10,13," ---- NO USER FILES RIGHT NOW, Create one with the EDIT Command ----",10,13,0


	NO_MORE_FILES_MSG:	DB 10,13,10,13,"    ---------- DISK FULL ! ---------",0
	EDIT_MSG		:	DB 10,13,"   Editor v1.0",10,13,10,13,"      CONTINUE(ENTER)               CANCEL(ESC) ",0
	EDITOR			:	DB "    Welcome to EDITOR V1.0",10,13,"    MAXIMUM FILE SIZE   ---->   1KB        Press ESC for EDITOR MENU ",10,13," ----------------------------------------------------------------------------",10,13,0

	DISK_ERROR_MSG 	:   db "Disk Read Error !" , 0

	ASK_USER		:	DB 10,13,"                   SAVE(Y)     EXIT(N)     CANCEL(ESC) ",0

	FILE_SIZE		:	DW 0
	FILE_NAME	TIMES 16 DB 0
	FILE_NAME_MSG	:	DB 10,13,"   Give your file a NAME (MAX 13) and press ENTER... ",0
	ALREADY_EXIST	:	DB 10,13,"   File name already exists , Choose another Name... : ",0
	TOTAL_SECTORS	:   DB 0
	CYLINDER_NO		:   DB 0
	TRACK_NO		:   DB 0
	SECTOR_START	:   DB 0
	SECTOR_END		:	DB 0
	FREE_ONE		:	DB 0
	FREE_TWO		:	DB 0

	ONES			:	DB 0
	TENS			:	DB 0
	HUNDREDS		:	DB 0
	THOUSANDS		:   DB 0
	TEN_THOUSANDS	:	DB 0

	NEW_L			:	DB 10,13,0
	NEW_DL			:	DB 10,13,10,13,0

	OPEN_FILE_PROMPT:   DB 10,13,"   CONTINUE(ENTER)                   CANCEL(ESC)  ",0
	OPEN_MSG		:	DB 10,13,10,13,"   Enter the FILE NAME and press ENTER ",10,13,"   FILE NAME goes here..: ",0
	NO_FILES_TO_OPEN_MSG:	DB 10,13,"    ------------      NO FILES TO OPEN     ------------",0
	FILE_NOT_EXIST	:	DB 10,13,10,13,"   No such FILE exist !" ,10,13,0
	OPEN_V			:	DB 10,13,"   OPEN V1.0",10,13,"   -----------------",0

	HEADER_OF_FILE	:	DB " "
	EXIT_FILE_MSG	:	DB	10,13,"                              EXIT(ESC) ",0
	MIDDLE			:   DB "                          FILE NAME --> ",0
	UNDERLINE		:	DB 10,13,"--------------------------------------------------------------------------------",0

;	APM_NOTFOUND	:	DB 10,13,"APM NOT FOUND",0
	ASK_TO_SHUTDOWN	:	DB 10,13,"         CONTINUE(ENTER)             CANCEL(ESC) ",0
	SHUTTING_DOWN	:	DB 10,13,10,13,"                  THANK YOU FOR USING MAJOR OS  ",10,13,10,13,"             OPERATING SYSTEM : MAJOR IS SHUTTING DOWN .",0
	SHUTTING_DOWN_DOT	:	DB ".",0
	GOODBYE			:	DB  10,13 ,"                               GOOD - BYE  " , 0
	EMICON_I		:	DB ";",0
	EMICON_II		:	DB "-",0
	EMICON_III		:	DB "(",0

  	COPY_MSG		:	DB 10,13,10,13 ,"   Enter the name of the file you want to COPY : ",0
	NO_FILES_COPY_MSG:	DB 10,13,"    ------------      NO FILES TO COPY     ------------",0
	NO_FILES_TO_DELETE_MSG:	DB 10,13,"    ------------     NO FILES TO DELETE    ------------",0
	DEL_MSG			:	DB 10,13,10,13 ,"   Enter the name of the file you want to DELETE : ",0
	times 6144-($-$$) db 0
	DISK_BUFFER	times 1024 DB 0