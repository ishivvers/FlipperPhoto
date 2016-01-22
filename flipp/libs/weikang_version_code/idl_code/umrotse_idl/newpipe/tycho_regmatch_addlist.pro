pro tycho_regmatch_addlist, match, file, pair=pair
;+
; NAME:	TYCHO_REGMATCH_ADDLIST	
;
; CALLING SEQUENCE:	tycho_regmatch_addlist, match, file, pair=pair
;
; INPUTS:	match: input object structure from tycho_regmatch etc..
;		file: list of tycho calibrated object structures
;
; OUTPUTS:	
;	
;
; INPUT KEYWORDS:
;		pair: set this if you want pair matching!
;			
; PROCEDURE:	
;
; REVISION HISTORY:  
;		Tim McKay	UM	10/30/98
;		Tim McKay	UM	11/6/98
;			Altered to do it all from 1 list.....
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - tycho_regmatch_addlist, match, file, pair=pair'
        return
 endif

  openr,1,file
  n=2
  name=''

  while not eof(1) do begin

   if keyword_set(pair) then begin
    	readf,1,name,format='(a60)'
    	info=str_sep(name," ")
    	name1=info(0)
    	readf,1,name,format='(a60)'
    	info=str_sep(name," ")
    	name2=info(0)
	print,"Adding a pair:"
	print,"             ",name1,"  ",name2
	tycho_regmatch_addpair,match,name1,name2,nmatch
	n=n+2
    endif else begin
    	readf,1,name,format='(a60)'
    	info=str_sep(name," ")
    	name1=info(0)
	print,'Adding a single image:"
	print,"             ",name1
    	tycho_regmatch_add,match,name1,nmatch
	n=n+1
    endelse

    print, ""
    print, "number = ",n

    match=nmatch
    
  endwhile

  fail=0
  close,1
  return
  end














