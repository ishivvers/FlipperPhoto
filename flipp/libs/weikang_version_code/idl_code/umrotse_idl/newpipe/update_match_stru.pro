pro update_match_stru,lstr,mstr

tl = tag_names(lstr)
tn = n_elements(tl) - 1
tmsys = 0
FOR i=0,tn DO BEGIN 
    IF (tl[i] EQ 'MSYS200') THEN tmsys = 1
ENDFOR
IF (tmsys EQ 0) THEN BEGIN
  nel = n_elements(lstr)
  ad1st = create_struct('MSYS200',2,'RFLAGS',0)
  ad2st = replicate(ad1st,nel)
  combine_structs, lstr,ad2st,ad3st
  lstr = ad3st
ENDIF
 
tl = tag_names(mstr)
tn = n_elements(tl) - 1
tf = 0
FOR i=0,tn DO BEGIN 
  IF (tl[i] EQ 'RAC') THEN tf = 1
ENDFOR
IF (tf ne 1) THEN BEGIN
  newrac=(mstr.ra_low + mstr.ra_high)/2.0     
  newdecc=(mstr.dec_low + mstr.dec_high)/2.0
  convert2xy,lstr.ra,lstr.dec,xc,yc,rac=newrac,decc=newdecc
  polywarp,xc,yc,lstr.x,lstr.y,3,kx,ky
  mstr = create_struct(mstr,'RAC',newrac,'DECC',newdecc,'KX',kx,'KY',ky)
ENDIF

end
