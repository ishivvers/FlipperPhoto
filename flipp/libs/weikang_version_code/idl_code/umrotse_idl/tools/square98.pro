PRO SQUARE98, ra, dec, fsz, magmax, magmin, file

; ra, dec, fsz are all 'strings'
; ra  	     ( hr min sec or  hr.xxxxx)
; dec 	     (deg min sec or deg.xxxxx)
; field size (deg min sec or deg.xxxxx)
; magmax                    (mag.xxxxx)
; magmin                    (mag.xxxxx)
; file is a 'string' containing the filename to be created by square

; the following is the example i was given as it would appear in the
; new format:
;
; IDL> square98,'21 19 41','-38 47 56.0','1.5','5','10','ctio2154-39E.cat'

; SQUARE98 runs the fortran code SQUARE from IDL
; the C code FINDWD is used to handle the UNIX acrobatics

; the new SQUARE fortran code is in
;		 /sdss/data2/rotse/cat/usno_a1.0/reader/temp
; it has been renamed SQUARE98
; & copied into  /sdss/data2/rotse/cat/usno_a1.0

; i'm writting the arguments to file for the fortran program to read in
; because i don't know how to have argments in the execution line

if N_params() ne 6 then begin
        print,'Syntax - square98, ra, dec, fsz, magmax, magmin, file'
	print,'NOTE: all arguments are strings!'
        return
endif


OPENW,  1, 'info.tmp'
PRINTF, 1, FORMAT='(A,/,A,/,A,/,A,/,A,/,A,/)',ra, dec, fsz, magmax, magmin,$
	 file
CLOSE,  1

print,magmax,' ',magmin

; initialize these here strings

command1 = sindgen(1)
command2 = sindgen(1)

; for my first command i will move the executable i need into the current directory

command1 = 'cp /sdss/products/idltools/sdss/analysis/findwd.out'
command1 = command1 + ' findwd.out;'

; finally the file created by square.f will be moved into current directory

command2 = 'mv /sdss/data2/rotse/cat/usno_a1.0/' + file + ' ' + file

; run commands

spawn, command1 + $			; move findwd.out to current directory
       "chmod 755 findwd.out;" + $	; give user permission to manipulate findwd.out
       "./findwd.out;" + $		; run findwd.out
       "rm ./findwd.out;" + $		; way as well not litter
       command2				; move "file" created into current directory

END
