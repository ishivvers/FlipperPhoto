pro extract_head_info,fitfile,tel=tel,outinfo=outinfo

if n_params() eq 0 then begin
  print,'syntax- extract_head_info,fitfile,tel=tel,outinfo=outinfo'
  print,'tel options : KAIT, LOT, SP104 (104cm Sampur. Tel), Nickel'
  return
endif

;make image names st
image_name_trans,fitfile,imagest

;read in the head from cimage
imhdr=headfits(fitfile)

info={tel:'', pixscale:0.0, exptime:0.0, efftime:0.0, mjd:0d0, filter:'', rac_raw:1000.0, decc_raw:-180.0, epoch:0.0}
;;dummy initiation
rac_raw=1000.0
decc_raw=-180.0

if not keyword_set(tel) then begin
  telescope=sxpar(imhdr,'TELESCOP')
  if (byte(telescope))[0] eq 0 then telescope=sxpar(imhdr,'VERSION')
  if (byte(telescope))[0] eq 0 then telescope=sxpar(imhdr,'INSTRUME')
  if (byte(telescope))[0] ne 0 then begin
  telescope=strtrim(telescope,2)
  print,telescope
    case telescope of 
    'K.A.I.T.': begin
      tel='KAIT'
      end
    'nickel_direct': begin
      tel='Nickel'
      end
    'P48': begin
      tel='P48'
      end
    'BITRAN-CCD Imaging System': begin
      tel='Koichi'
      end
    endcase
    print,'Telescope is: ',tel
  endif else begin
    print,'not find telescope in header'
    print,'assuming it is KAIT in default'
    tel='unknown'
  endelse
endif

info.tel=tel

; Check if "mjd" or "jd" was in the image header...and make sure 'mjd' is not = 0.
mjd = sxpar(imhdr,'mjd')
if (mjd eq 0) then jd = sxpar(imhdr,'jd')
;;if (!err ne 0) then begin
  ;add by zwk for kait
  case tel of 
  'KAIT': begin
    pixscale=0.7965

    ;get date time information for kait 
    date=sxpar(imhdr,'DATE-OBS')
    uttime=sxpar(imhdr,'UT')
    day=strmid(date,0,2)
    month=strmid(date,3,2)
    year=strmid(date,6,4)
    hour=strmid(uttime,0,2)
    minute=strmid(uttime,3,2)
    second=strmid(uttime,6,2)
    exptime=sxpar(imhdr,'EXPTIME')
    filter=sxpar(imhdr,'FILTERS')
    rac_raw=ten(sxpar(imhdr,'RA'))*double(15)
    decc_raw=ten(sxpar(imhdr,'DEC'))
    end
  'LOT': begin
    pixscale=0.86136

    ;print,'processing LOT mjd'
    ;DATE-OBS= '2012-02-11T11:57:33' /YYYY-MM-DDThh:mm:ss observation start, UT
    date=sxpar(imhdr,'DATE-OBS')
    year=strmid(date,0,4)
    month=strmid(date,5,2)
    day=strmid(date,8,2)
    hour=strmid(date,11,2)
    minute=strmid(date,14,2)
    second=strmid(date,17,2)
    exptime=sxpar(imhdr,'EXPOSURE')
    filter=sxpar(imhdr,'FILTER')
    end
  'SP104' : begin
    pixscale=0.75743

    ;get date time information for SP104
    date=sxpar(imhdr,'DATE-OBS')
    uttime=sxpar(imhdr,'TIME-BEG')
    year=strmid(date,0,4)
    month=strmid(date,5,2)
    day=strmid(date,8,2)
    hour=strmid(uttime,0,2)
    minute=strmid(uttime,3,2)
    second=strmid(uttime,6,2)
    exptime=sxpar(imhdr,'EXPOSURE')
    filter=sxpar(imhdr,'FILTER')
    end
  'Nickel' : begin
    pixscale=0.37000

    ;get date time information for Nickel
    date=sxpar(imhdr,'DATE-STA')
    uttime=sxpar(imhdr,'DATE-STA')
    ;;CCD header seems changed, noted on Aug. 12, 2015
    if date eq 0 then begin 
      date=sxpar(imhdr,'DATE-BEG')
      uttime=sxpar(imhdr,'DATE-BEG')
    endif
    year=strmid(date,0,4)
    month=strmid(date,5,2)
    day=strmid(date,8,2)
    hour=strmid(uttime,11,2)
    minute=strmid(uttime,14,2)
    second=strmid(uttime,17,2)
    exptime=sxpar(imhdr,'EXPTIME')
    filter=sxpar(imhdr,'FILTNAM')
    rac_raw=ten(sxpar(imhdr,'RA'))*double(15)
    decc_raw=ten(sxpar(imhdr,'DEC'))
    end
  'Koichi': begin
    pixscale=1.44588

    ;get date time information for kait 
    date=sxpar(imhdr,'DATE-OBS')
    uttime=sxpar(imhdr,'UT')
    day=strmid(date,8,2)
    month=strmid(date,5,2)
    year=strmid(date,0,4)
    hour=strmid(uttime,0,2)
    minute=strmid(uttime,3,2)
    second=strmid(uttime,6,2)
    exptime=sxpar(imhdr,'EXPTIME')
    filter='clear'
    end
  'P48': begin
    pixscale=1.01214

    ;get date time information for kait 
    date=sxpar(imhdr,'DATE-OBS')
    uttime=sxpar(imhdr,'DATE-OBS')
    day=strmid(date,8,2)
    month=strmid(date,5,2)
    year=strmid(date,0,4)
    hour=strmid(uttime,11,2)
    minute=strmid(uttime,14,2)
    second=strmid(uttime,17,4)
    exptime=sxpar(imhdr,'EXPTIME')
    filter=sxpar(imhdr,'FILTER')
    rac_raw=ten(sxpar(imhdr,'OBJRA'))*double(15)
    decc_raw=ten(sxpar(imhdr,'OBJDEC'))
    end
  else : begin
    print,'Warining : unknown telescope!'
    filter='clear'
    year=2000
    month=1
    day=1
    hour=0
    minute=0
    second=0
    pixscale=1.0
    exptime=0
    end
  endcase

  ;;now here calculate some time
  print,year,month,day,hour,minute,second
  ;;; Note by zwk on 130510, here the mjd get from juldate is actually RJD, need to 
  ;;; minus 0.5 more to get real MJD
  juldate,[float(year),float(month),float(day),float(hour),float(minute),float(second)],mjd
  mjd=mjd-0.5d
  epoch_current=year+ymd2dn(year,month,day)/365.0
;;endif

info.mjd=mjd
info.filter=strtrim(filter,2)
info.pixscale=pixscale
info.exptime=exptime
;;equinox transformation
;;print,rac_raw,decc_raw
precess,rac_raw,decc_raw,epoch_current,2000.0;;,/print
info.epoch=2000.0
info.rac_raw=rac_raw
info.decc_raw=decc_raw
efftime = sxpar(imhdr,'efftime')
if (efftime eq 0) then begin
  efftime=exptime
endif
info.efftime=efftime
;;help,info

outinfo=info
end
