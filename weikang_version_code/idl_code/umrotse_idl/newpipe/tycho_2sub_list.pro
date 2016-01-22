pro tycho_2sub_list, file
;+
; NAME:	TYCHO_2SUB_LIST
;
; CALLING SEQUENCE:	tycho_2sub_list, file
;
; INPUTS:	file: list of cobj structures
;
; OUTPUTS:	
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Does subtracti
;
; REVISION HISTORY:  
;	Tim McKay		UM	2/8/99
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax -tycho_2sub_list, file'
        return
 endif


  openr,1,file
  n=1
  name=''
  while not eof(1) do begin

    readf,1,name,format='(a60)'
    info=str_sep(name," ")
    name1=info(0)
    name2=info(1)
    print, ""
    print, "Processing file:",name1," ",name2,"   Number:",n

    tycho_2sub,name1,name2,imdiff,/write
    rdis_setup,imdiff,pls
    rdis,imdiff,pls,xmn=900,xmx=1100,ymn=900,ymx=1100
    n=n+1

  endwhile

  close,1
  return
  end








