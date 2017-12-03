;--------------------------------------3).directory.asmn----------------------------------
;		SIZE 	=	512 BYTES
;		It contains 32 16-Byte entries
;		________________________________________________________________________________
;		|____:____:____:____:____:____:____:____:____:____:____:____:____:____|____|____|      ------> 32 Entries of 16 BYTES
;	      1	   2	 3	  4   5    6     7    8    9   10   11   12   13   14   15   16

;		First 14 bytes contains the file name and last two bytes contain the Sector number in which the file resides

;		1-14 ------> FILE NAME
;		15   ------> START SECTOR NUMBER
;		16   ------> END SECTOR NUMBER

;---------------Restrictions in File system--------------------

;		**File name can't be more that 6-bytes.
;		**File name less than 14 bytes will be padded with zeroes, succeeding the sum of letters of file name
;		**File name can't start with ZERO
;		**16-Bytes entry starting with zero indicates the availability for new file entry.
DB "SHELL",5,0,0,0,0,0,0,0,0,5,18
TIMES 31 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0