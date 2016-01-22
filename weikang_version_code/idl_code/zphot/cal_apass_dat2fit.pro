pro cal_apass_dat2fit,apass_datfilename

if n_params() eq 0 then begin
  print,'Syntax- ,cal_apass_dat2fit,apass_datfilename'
  return
endif

datfilename=apass_datfilename
outstfitfile=datfilename

print,'working on',datfilename
readcolst,datfilename,apassst
tnb=n_elements(apassst)

stars=gen_star_mags(tnb,mag=0.0,merr=0.01)

stars.ra=apassst.ra
stars.dec=apassst.dec
stars.B=apassst.B
stars.V=apassst.V
stars.SG=apassst.g
stars.SR=apassst.r
stars.SI=apassst.i
stars.C=apassst.r
stars.CLEAR=apassst.r
mag_sdss_jc,1,stars,/gri
stars.C=stars.R
stars.CLEAR=stars.R

strreplace,outstfitfile,'.dat','_Landolt_standard.fit'
wsttofile,outstfitfile,stars

cal_landolt2natural,outstfitfile

end
