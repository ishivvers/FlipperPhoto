pro aphot_dat_res_format,datafile,outst

if n_params() eq 0 then begin
  print,'Syntax- aphot_dat_res_forat,datafile,outst'
  print,'        data format: time filter mag magerr'
  return
endif

sttmp={time:0d0, etime:0d0, mag:0.0, emag:0.0, emag_plus:0.0, emag_minus:0.0, mag_limit:0.0, filter:'', imname:'',fd:0d0, fderr:0d0}

readcol,datafile,time,filter,mag,magerr,format='(a,a,a,a)',comment=';',/silent
tnb=n_elements(time)
photst=replicate(sttmp,tnb)

photst.time=double(time)
photst.filter=strtrim(filter,2)

mag=strtrim(mag,2)
magerr=strtrim(magerr,2)
for i=0,tnb-1 do begin
  if mag[i] eq 'NaN' then begin
    ;;what if mag_limit is also NaN, need to update it.
    photst[i].mag=float(mag_limit[i])
    photst[i].mag_limit=float(mag_limit[i])
    photst[i].emag=99.9
    photst[i].emag_plus=99.9
    photst[i].emag_minus=99.9
  endif else begin
    photst[i].mag=float(mag[i])
    photst[i].emag=float(magerr[i])
  endelse
  mag2fd,photst[i].mag,photst[i].filter,err=photst[i].emag,outflux=outflux,/silent
  photst[i].fd=outflux.FLUX
  photst[i].fderr=outflux.FLUXERR
  ;print,photst[i].(0),photst[i].(1),photst[i].(2),photst[i].(3),photst[i].(4),photst[i].(5),photst[i].(6),photst[i].(7),photst[i].(8)
endfor
outst=photst

end
