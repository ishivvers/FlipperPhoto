function make_rotse_name, rain, decin, tele=tele

; Purpose:	To construct IAU sanctioned name for a source at the input
;	coordinates.
;
; Inputs:
;	rain = input RA
;	decin = input declination
;
; Return Value:  string containing name of source
;
; Created: Tim McKay
; Modified: Bob Kehoe  08-20-00  convert to a function, give 'tele' keyword to
;				 allow for different telescopes

if n_params() eq 0 then begin
  print,'syntax-make_rotse_name,rain,decin,ns'
  return,-1
endif
ra=sixty(rain/15.0)
dec=sixty(decin)
ras=strtrim(string(ra),2)
if (ra(0) lt 10.0) then begin
  ras(0)='0'+strmid(ras(0),0,1)
endif else begin
  ras(0)=strmid(ras(0),0,2)
endelse
if (ra(1) lt 10.0) then begin
  ras(1)='0'+strmid(ras(1),0,1)
endif else begin
  ras(1)=strmid(ras(1),0,2)
endelse
if (ra(2) lt 10.0) then begin
  ras(2)='0'+strmid(ras(2),0,4)
endif else begin
  ras(2)=strmid(ras(2),0,5)
endelse
if (decin lt 0.0) then begin
  sign='-'
endif else begin
  sign='+'
endelse
dec=abs(dec)
decs=strtrim(string(dec),2)
if (dec(0) lt 10.0) then begin
  decs(0)='0'+strmid(decs(0),0,1)
endif else begin
  decs(0)=strmid(decs(0),0,2)
endelse
if (dec(1) lt 10.0) then begin
  decs(1)='0'+strmid(decs(1),0,1)
endif else begin
  decs(1)=strmid(decs(1),0,2)
endelse
if (dec(2) lt 10.0) then begin
  decs(2)='0'+strmid(decs(2),0,3)
endif else begin
  decs(2)=strmid(decs(2),0,4)
endelse

startstr = 'ROTSE1'
if keyword_set(tele) then startstr = tele
ns = startstr+' J'+ras(0)+ras(1)+ras(2)+sign+decs(0)+decs(1)+decs(2)

return, ns
end
