pro wcsrd2xy,wcsfile,ra,dec,x,y

if n_params() eq 0 then begin
  print,'wcsrd2xy,wcsfile,ra,dec,x,y'
  return
endif

tmpxyfile='tmpwcsxyfile.fit'
tmprdfile='tmpwcsrdfile.fit'

nbt=n_elements(ra)
rdcoord=create_struct('RA',0.0, 'DEC',0.0)
rdcoordall=replicate(rdcoord,nbt)
rdcoordall.RA=ra
rdcoordall.DEC=dec
wsttofile,tmprdfile,rdcoordall

cmd='/usr/local/astrometry/bin/wcs-rd2xy  -w '+wcsfile+' -i '+tmprdfile+' -o '+tmpxyfile
print,cmd
spawn,cmd
sttemp=mrdfits(tmpxyfile,1,/silent)
x=sttemp.X
y=sttemp.Y

print,'Finished!'
cmd='rm -f '+tmpxyfile
spawn,cmd
cmd='rm -f '+tmprdfile
spawn,cmd

end

