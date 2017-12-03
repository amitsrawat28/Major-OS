!Best viewed as RAW
#DATE : 21ST May, 2015 , 9:00 PM

	##Major OS
---------------------------
	V1.0 (NO WORDS ABOUT FUTURE UPDATES AT THIS MOMENT)
	DEVELOPED BY AMIT SINGH RAWAT

		------------------------------------------	STABLE FEATURE	------------------------------------------------------

*HELP
*DIR
*CLEAR
*EDIT---->TEXT EDITOR---> SAVES FILE ON DISK---> UPDATE DISK MAP---> FEED FILE INFO IN DIRECTORY TABLE
*VERSION
*AUTHOR
*OPEN
*SHUTDOWN
*COPY
*DELETE

-------------------------------------------------------DISK STRUCTURE------------------------------------------------------------------------------------------


_________________________________________________________________________________________________________________________________________________
|  	 		 |			|			|			|												|												|
| BOOTLOADER | DISK MAP	| DIRECTORY	|  KERNEL	|                      SHELL                   	|				USER FILES						|
|____________|__________|___________|___________|_______________________________________________|_______________________________________________|
   SECTOR 1    SECTOR 2   SECTOR 3    SECTOR 4       	  SECTOR 5  -----  SECTOR 18                     SECTOR 17    -----    #MAX SECTOR(255)

# MAX SECTOR ----- DEPENDS ON THE DISK YOU WRITE THIS OS CODE

------------SIZE-------------------
   BOOTLOADER  = 512 BYTES
   DISK MAP	   = 512 BYTES
   DIRECTORY   = 512 BYTES
   KERNEL	   = 512 BYTES
   SHELL	   = 7KB (14 SECTORS)
   USER FILES  = MAX 1KB




