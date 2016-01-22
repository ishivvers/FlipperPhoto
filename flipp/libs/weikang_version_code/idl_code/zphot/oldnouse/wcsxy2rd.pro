pro wcsxy2rd,wcsfile,x,y,ra,dec

if n_params() eq 0 then begin
  print,'wcsxy2rdk,wcsfile,x,y,ra,dec'
  return
endif

tmpxyfile='tmpwcsxyfile.fit'
tmprdfile='tmpwcsrdfile.fit'

nbt=n_elements(x)
xycoord=create_struct('X',0.0, 'Y',0.0)
xycoordall=replicate(xycoord,nbt)
xycoordall.X=x
xycoordall.Y=y
wsttofile,tmpxyfile,xycoordall

cmd='/usr/local/astrometry/bin/wcs-xy2rd  -w '+wcsfile+' -i '+tmpxyfile+' -o '+tmprdfile
print,cmd
spawn,cmd
sttemp=mrdfits(tmprdfile,1,/silent)
ra=sttemp.ra
dec=sttemp.dec

print,'Finished!'
cmd='rm -f '+tmpxyfile
spawn,cmd
cmd='rm -f '+tmprdfile
spawn,cmd

end

