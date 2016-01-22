pro tychocal_goodlist, file, fileout
;+
; NAME:	TYCHOCAL_GOODLIST
;
; CALLING SEQUENCE:	tychocal_goodlist, file, stats_all, headerstruct
;
; INPUTS:	file: list of "stats" files from tychocal_list
;
; OUTPUTS:	
;		stats_all: collated structure of them all....
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	reads in individual stats files and collates them
;
; REVISION HISTORY:  
;	Tim McKay		UM	11/14/98
;		created
;******************************************************************************

  if N_params() eq 0 then begin
        print,'Syntax - tychocal_goodlist, file, fileout'
        return
  endif

  openr,1,file
  n=0
  name=''
  name1=''
  name2=''
  while not eof(1) do begin
    readf,1,name,format='(a60)'
    n=n+1
    print,name,n
  endwhile
  ntot=n
  close,1  
  
  openr,1,file
  openw,2,fileout
  
  n=0

  while not eof(1) do begin

    readf,1,name1,format='(a60)'
    readf,1,name2,format='(a60)'
    info=str_sep(name1," ")
    name1=info(0)
    stats1=mrdfits(name1,1,hdr)
    info=str_sep(name2," ")
    name2=info(0)
    stats2=mrdfits(name2,1,hdr)
    print, "Processing files:",name1,name2
    print,stats1.m_lim,stats2.m_lim
    if (stats1.m_lim    gt 14 and stats2.m_lim    gt 14) then begin
        hdr=headfits(name1)
        fname1=sxpar(hdr,'filename')
        ns=str_sep(fname1,'/')
        t=n_elements(ns)
        fname1=ns(t-1)
	ns=str_sep(fname1,'.fit')
	fname1=ns(0)+'_cobj.fit'
        hdr=headfits(name2)
        fname2=sxpar(hdr,'filename')
        ns=str_sep(fname2,'/')
        t=n_elements(ns)
        fname2=ns(t-1)
	ns=str_sep(fname2,'.fit')
	fname2=ns(0)+'_cobj.fit'
	printf,2,fname1
	printf,2,fname2
    endif

  endwhile

  close,1
  close,2

  return
  end
