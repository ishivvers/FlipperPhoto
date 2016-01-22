pro tycho_regmatch_list, match, file, pair=pair, consec=consec, ral=ral, $
		rah=rah, decl=decl,dech=dech
;+
; NAME:	TYCHO_REGMATCH_LIST	
;
; CALLING SEQUENCE:	tycho_regmatch_list, match, file, pair=pair
;
; INPUTS:	match: input object structure from tycho_regmatch etc..
;		file: list of tycho calibrated object structures
;
; OUTPUTS:	
;
; INPUT KEYWORDS:
;		pair: set this if you want pair matching!
;		consec: set this if you want >= 1 consecutive pair of detections
;			
; PROCEDURE:
;
; REVISION HISTORY:  
;		Tim McKay	UM	10/30/98
;		Tim McKay	UM	11/6/98  -- Altered to do it all from 1 list...
;		00-04-10 Bob Kehoe -- added consec filtering for objects occurring at 
;				      least once in two consecutive epochs
;		06-05-00 Bob Kehoe -- sped up consecutive filtering, flagged out-of-frame
;				      observations, added several variables and stats to 
;				      match structure
;		06-22-00 Eli Rykoff-- Now the pixel scale is determined from the header
;		08-16-00 Bob Kehoe -- fix pair matching bug when odd # frames in list
;******************************************************************************
;-

  if N_params() lt 2 then begin
     print,'Syntax - tycho_regmatch_list, match, file, pair=pair, consec=consec, ral=ral, rah=rah, decl=decl,dech=dech'
     return
  endif

  tychocal_statslist,file,stat
  lun = 2
  openr,lun,file
  n=2
  name=''
  readf,lun,name,format='(a60)'
  info=str_sep(name," ")
  name1=info(0)
  readf,lun,name,format='(a60)'
  info=str_sep(name," ")
  name2=info(0)
 
  if not keyword_set(ral) then begin
     print,'Determining ra,dec limits from first image'
     l1=mrdfits(name1,1,hdr)
     ral=min(l1.ra)
     rah=max(l1.ra)
     decl=min(l1.dec)
     dech=max(l1.dec)
  endif

  if keyword_set(pair) then begin
     tycho_regmatch_begin,name1,name2,ral,rah,decl,dech,match,pair=1
  endif else begin
     tycho_regmatch_begin,name1,name2,ral,rah,decl,dech,match,stat
  endelse

  while not eof(lun) do begin
     if keyword_set(pair) then begin
    	readf,lun,name,format='(a60)'
    	info=str_sep(name," ")
    	name1=info(0)
        if not eof(lun) then begin
	   readf,lun,name,format='(a60)'
    	   info=str_sep(name," ")
    	   name2=info(0)
	   print,"Adding a pair:"
	   print,"             ",name1,"  ",name2
	   tycho_regmatch_addpair,match,name1,name2,nmatch
	   n=n+2
           print, ""
           print, "Number of observations = ",n
           match=nmatch
	endif
     endif else begin
    	readf,lun,name,format='(a60)'
    	info=str_sep(name," ")
    	name1=info(0)
	print,'Adding a single image:"
	print,"             ",name1
    	tycho_regmatch_add,match,name1,stat,nmatch
	n=n+1
        print, ""
        print, "Number of observations = ",n
        match=nmatch
     endelse
  endwhile
  close,lun

; Perform filtering for consecutive observations of each object.

  nobs = (size(match.imagename))[1]
  if keyword_set(consec) then begin
     print, 'Filtering for objects with consecutive detections...'
     for k = 0,nobs-1 do begin
        find_consec,match.jd[k],match.jd,iconsec
        num_consec = (size(iconsec))[1]
        if ((size(iconsec))[0] ne 0 and num_consec gt 0) then begin
           try_consec = where(match.consec eq 0 and match.m[k,*] gt -1.0 , count)
	   if (count gt 0) then begin
	      for l = 0,num_consec-1 do begin
		 index = where(match.m[iconsec[l],try_consec] gt -1.0, count)
		 if (count gt 0) then match.consec[try_consec[index]] = 1
              endfor
	   endif
        endif
     endfor
     goodobj = where(match.consec eq 1, count)
     if (count gt 0) then match = make_match_struct((size(match.jd))[1],$
			goodobj, old=match, extended=1)
     print, '   # object chosen = ', count
  endif

; Re-average the positions for objects with final tally.

   print, 'Calculating RA/DEC offsets, shrinking, and stuffing status data.'
   cdelt = stat[0].cdelt1
   match = make_match_struct(shorten=match,cdelt=cdelt)

;  Get header info. for observations which made it into match struct.

   iobs = match_names(match.imagename, stat.filename)
   match = create_struct(match, 'stat', stat[iobs])

;  Set mag. to -2.0 when object is unobservable.

   for k = 0,nobs-1 do begin
      badobs = where(match.m[k,*] le -1.0,count)
      if (count gt 0) then begin
         convert2xy,match.ra[badobs],match.dec[badobs],xc,yc,rac=match.rac[k],$
			decc=match.decc[k]
         kx = reform(match.kx[k,*,*])
         ky = reform(match.ky[k,*,*])
         kmap,xc,yc,x,y,kx,ky
         overedge = where(x lt 5 or x gt (stat[k].naxis1-5) or y lt 5 or $
			  y gt (stat[k].naxis2-5), count)
	 if (count gt 0) then match.m[k,badobs[overedge]] = -2.0
      endif
   endfor

   return
end
