pro tychocal_all, file=file, logfile=logfile
;+
; NAME:	TYCHOCAL_ALL
;
; CALLING SEQUENCE:	tychocal_all
;
; INPUTS:	
;
; OUTPUTS:	
;	
; INPUT KEYWORDS:
;			file: filename for list of frames to do...
;			logfile: filename for processing log
;			
; PROCEDURE:	calibrates via tycho everything in a directory
;
; REVISION HISTORY:  
;	Tim McKay		UM	11/24/98
;		Created
;******************************************************************************

;First read in the tycho catalog
tcat=mrdfits('/home/products/tycho/tycho.fit',1,hdr)

if not keyword_set(file) then begin
	;Now generate a list of all the sobj files here
	spawn,'ls *_sobj.fit > total_list.txt'
	file='total_list.txt'
endif

if not keyword_set(logfile) then begin
	logfile = 'tychocal_time.log'
endif

;Now actually do it:
tychocal_list, tcat, file, logfile=logfile

$rm total_list.txt
return

end




