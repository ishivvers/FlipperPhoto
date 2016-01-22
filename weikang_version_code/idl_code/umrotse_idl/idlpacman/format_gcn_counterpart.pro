pro format_gcn_counterpart,fname,obsmjd,ra,dec,mag,magerr,trignum,confidence,test=test

if n_params() eq 0 then begin
    print,'syntax- format_gcn_counterpart,fname,obsmjd,ra,dec,mag,magerr,trignum,confidence,test=test'
    return
endif

;; make the strings
curjd=systime(/utc,/julian)
caldat,curjd,cmon,cday,cyear,chour,cmin,csec
notice_date=string(cmon,format='(i2.2)')+'/'+$
  string(cday,format='(i2.2)')+'/'+$
  string(cyear-2000,format='(i2.2)')+' '+$
  string(chour,format='(i2.2)')+':'+$
  string(cmin,format='(i2.2)')+':'+$
  string(csec,format='(i2.2)')+' GMT'

caldat,obsmjd+2400000.5d,mon,day,year,hour,min,sec
grb_date=string(year-2000,format='(i2.2)')+'/'+$
  string(mon,format='(i2.2)')+'/'+$
  string(day,format='(i2.2)')

obs_start=grb_date+' '+$
  string(hour,format='(i2.2)')+':'+$
  string(min,format='(i2.2)')+':'+$
  string(fix(sec),format='(i2.2)')

bits=sixty(ra/15.)
argh=string(round(bits[2]*10.),format='(i3.3)')
trans_ra=strtrim(string(ra,format='(f10.6)'),2)+' {'+$
  string(fix(bits[0]),format='(i2.2)')+'h '+$
  string(fix(bits[1]),format='(i2.2)')+'m '+$
  strmid(argh,0,2)+'.'+strmid(argh,2,1)+'s} (J2000)'

sign=1
decsign='+'
if (dec lt 0.0) then begin 
    sign=-1
    decsign='-'
endif
dec=dec*sign

bits=sixty(dec)
argh=string(round(bits[2]*10.),format='(i3.3)')
trans_dec=strtrim(string(dec*sign,format='(f10.6)'),2)+' {'+$
  decsign+string(fix(bits[0]),format='(i2.2)')+'d '+$
  string(fix(bits[1]),format='(i2.2)')+"' "+$
  strmid(argh,0,2)+'.'+strmid(argh,2,1)+'"} (J2000)'

test=0

spawn,'hostname',result
if (strpos(result,'3a') gt 0) then begin
    tel='ROTSE-IIIa'
endif else if (strpos(result,'3b') gt 0) then begin
    tel='ROTSE-IIIb'
endif else if (strpos(result,'3c') gt 0) then begin
    tel='ROTSE-IIIc'
endif else if (strpos(result,'3d') gt 0) then begin
    tel='ROTSE-IIId'
endif else begin
    tel='ROTSE-TEST'
    test=1
endelse

openw,lun,fname,/get_lun

printf,lun,'TITLE:                  GRB COUNTERPART NOTICE'
printf,lun,'NOTICE_DATE:            '+notice_date
printf,lun,'NOTICE_TYPE:            Optical'
printf,lun,'GRB_DATE:               '+grb_date
printf,lun,'TRIGGER_REF_NUM:        '+strtrim(string(trignum),2)
printf,lun,'CNTRPART_RA:            '+trans_ra
printf,lun,'CNTRPART_DEC:           '+trans_dec
printf,lun,'ERROR_BOX:              1.0 [arcsec]'
printf,lun,'OBSERVATION_START:      '+obs_start+' UT'
printf,lun,'OBSERVATION_DURATION:   5.00 [sec]'
printf,lun,'ID_CONF:                '+strtrim(string(confidence,format='(f5.2)'),2)+' [%]'
printf,lun,'MAG:                    '+strtrim(string(mag,format='(f5.2)'),2)+' [mag]'
printf,lun,'UNCERTAINTY:            '+strtrim(string(magerr,format='(f4.2)'),2)+' [mag]'
printf,lun,'FILTER:                 clear'
printf,lun,'TELESCOPE:              '+tel
printf,lun,'COMMENTS:               Automatically generated ROTSE notice'

free_lun,lun



return
end
