pro cal_sdss_dat2fit,sdss_datfilename

if n_params() eq 0 then begin
  print,'Syntax- cal_sdss_dat2fit,sdss_datfilename'
  return
endif

datfilename=sdss_datfilename
outstfitfile=datfilename

print,'working on',datfilename
readcolst,datfilename,sdssst
tnb=n_elements(sdssst)

stars=gen_star_mags(tnb,mag=0.0,merr=0.01)

stars.ra=sdssst.ra
stars.dec=sdssst.dec
stars.SU=sdssst.u
stars.SG=sdssst.g
stars.SR=sdssst.r
stars.SI=sdssst.i
stars.SZ=sdssst.z
stars.C=sdssst.r
stars.CLEAR=sdssst.r
mag_sdss_jc,1,stars
stars.C=stars.R
stars.CLEAR=stars.R

strreplace,outstfitfile,'.dat','_Landolt_standard.fit'
wsttofile,outstfitfile,stars

cal_landolt2natural,outstfitfile

end
