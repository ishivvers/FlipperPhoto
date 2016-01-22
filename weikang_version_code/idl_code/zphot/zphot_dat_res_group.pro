pro zphot_dat_res_group,datafile,outst

if n_params() eq 0 then begin
  print,'Syntax- zphot_dat_res_group,datafile,outst'
  return
endif

zphot_dat_res_format,datafile,photst
ind=where(photst.emag le 10.0,fb)
if fb lt 0 then begin
  print,'No good data, doing nothing'
  return
endif

photst=photst[ind]

phot_dat_res_group,photst.time,photst.mag,photst.filter,magerr=photst.emag,outst=outst

end
