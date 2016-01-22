pro gcvsread_str, filename, structure
;+
; NAME:
;       GCVSREAD_STR
; PURPOSE:
;	Read in the GCVS4 catalog and changes eqinox of RA and Dec from 1950 to 2000
;
; CALLING SEQUENCE:
;       gcvsread_str, filename, structure
;
; INPUTS:
;       filename: gcvs formatted file to read
;       
; OUTPUTS
;	
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
; 
; PROCEDURE: This just reads in the formatted information from the GCVS file
;	
;
; REVISION HISTORY:
;	Tim McKay	UM	6/19/97
;-      Susan Amrose    UM      8/19/97  added varitype
 On_error,2              ;Return to caller

 if N_params() ne 2 then begin
        print,'Syntax - gcvsread_str, filename, structure'
        return
 endif
 print
 
  i=0
 spawn,'wc '+filename,results
 tmp1=lonarr(3)
 reads,results,tmp1
 nlines=tmp1(0)
 starid=strarr(nlines)
 starid(*)='  '
 gallong=findgen(nlines)
 gallong(*)=0.0
 gallat=findgen(nlines)
 gallat(*)=0.0
 maxx=findgen(nlines)
 maxx(*)=0.0
 minn=findgen(nlines)
 minn(*)=0.0
 ref1=strarr(nlines)
 ref1(*)=' '
 ref2=strarr(nlines)
 ref2(*)=' '
 type=strarr(nlines)
 type(*)='  '
 ra=findgen(nlines)
 ra(*)=0.0
 dec=findgen(nlines)
 dec(*)=0.0
 period=strarr(nlines)
 period(*)=' '
 duration=strarr(nlines)
 duration(*)=' '
 v1=''
 
openr, 1, filename
 while not eof(1) do begin
   
   readf, 1, v1
   starid1=strmid(v1,7,8)
   rah=strmid(v1,16,2)
   ram=strmid(v1,18,2)
   ras=strmid(v1,20,2)
   decd=strmid(v1,22,3)
   decm=strmid(v1,25,4)
   galon=strmid(v1,42,6)
   galat=strmid(v1,48,6)
   refer1=strmid(v1,54,5)
   refer2=strmid(v1,59,5)
   varitype1=strmid(v1,64,8)
   mmax=strmid(v1,75,5)
   mmin=strmid(v1,83,5)
   period1=strmid(v1,116,15)
   duratn=strmid(v1,135,5)
  
   if (rah eq "  ") then rah=0.0
   if (ram eq "  ") then ram=0.0
   if (ras eq "  ") then ras=0.0
   if (decd eq "   ") then decd=0.0
   if (decm eq "    ") then decm=0.0
   ra(i)=(float(rah)+(float(ram)/60.0)+(float(ras)/3600.0))
   dec(i)=float(decd)+(float(decm)/60.0)
   if (mmax ne "     ") then begin
      maxx(i)=float(mmax)
   endif else begin
      maxx(i)=-1.0
   endelse
   if (mmin ne "     ") then begin
      minn(i)=float(mmin)
   endif else begin
      minn(i)=-1.0
   endelse
      type(i)=varitype1
   if (galon ne "      ") then begin
      gallong(i)=float(galon)
   endif else begin
      gallong(i)=-1.0
   endelse
   if (galat ne "      ") then begin
      gallat(i)=float(galat)
   endif else begin
      gallat(i)=-1.0
   endelse
   if (period1 ne "               ") then begin
      period(i)=period1
   endif 
   if (duratn ne "     ") then begin
      duration(i)=duratn
   endif 
   ref1(i)=refer1
   ref2(i)=refer2
   if (starid1 ne "        ") then begin 
      starid(i)=starid1
   endif else begin
      starid(i)='none    '
   endelse
	
   

;print,rah," ",ram," ",ras," ",decd," ",decm," ",mmax," ",mmin," ",varitype
   i=i+1
  
 end
 close, 1
ra1=ra
dec1=dec
   precess,ra1,dec1,1950,2000    ;converting equinox of ra and dec from 1950 to 2000

structure=create_struct('ra',fltarr(nlines),'dec',fltarr(nlines),'gallong',fltarr(nlines), $
'gallat', fltarr(nlines),'ref1',strarr(nlines),'ref2',strarr(nlines),'type',strarr(nlines), $
'max',fltarr(nlines),'min',fltarr(nlines),'period',strarr(nlines),'duration',strarr(nlines))


structure.ra=ra1
structure.dec=dec1
structure.gallong=gallong
structure.gallat=gallat
structure.ref1=ref1
structure.ref2=ref2
structure.type=type
structure.max=maxx
structure.min=minn
structure.period=period
structure.duration=duration 
 
 return
 end
