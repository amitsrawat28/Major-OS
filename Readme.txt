
DATE : 21ST May, 2015 , 9:00 PM

Major OS
---------------------------
V1.0
DEVELOPED BY AMIT SINGH RAWAT

STABLE FEATURE
==================
HELP
DIR
CLEAR
EDIT---->TEXT EDITOR---> SAVES FILE ON DISK---> UPDATE DISK MAP---> FEED FILE INFO IN DIRECTORY TABLE
VERSION
AUTHOR
OPEN
SHUTDOWN
COPY
DELETE

DISK STRUCTURE
==================
SECTOR 1 		-->	BOOTLOADER
SECTOR 2		-->	DISK MAP
SECTOR 3		-->	DIRECTORY
SECTOR 4		-->	KERNEL
SECTOR 5 - 18		-->	SHELL
SECTOR 17 - 255*	-->	USER FILES

*MAX SECTOR ----- DEPENDS ON THE DISK YOU WRITE THIS OS CODE

------------SIZE-------------------
BOOTLOADER  	=	512 BYTES
DISK MAP	= 	512 BYTES
DIRECTORY   	= 	512 BYTES
KERNEL	   	= 	512 BYTES
SHELL	   	= 	7KB (14 SECTORS)
USER FILES  	= 	MAX 1KB

HOW TO RUN
================
For Linux\UNIX 
--------------------------------

1) Open Terminal
 
2) Type the following command to install QEMU 

	sudo apt-get install qemu

3) After Installing the QEMU, directyly run the Major OS with following Command

	qemu-system-i386 MajorOS.bin

4) Enjoy Major OS !!!


For Windows
-----------------------------

1) Install Bochs provided within the CD

2) Run bochsrc(Bochs Configuration File)

3) Enjoy Major OS !!!

				**************************************THANK YOU*****************************************


