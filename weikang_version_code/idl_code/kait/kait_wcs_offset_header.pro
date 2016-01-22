pro kait_wcs_offset_header,filename,knownfilename,offset=offset,sobj=sobj

if n_params() eq 0 then begin
    print,'kait_wcs_offset_header,filename,knownfilename,offset=offset,sobj=sobj'
    return
endif

if not keyword_set(offset) then offset=[0.0,0.0]

hdok=headfits(knownfilename)

hd=headfits(filename)

help,hdok
ind=where(strmatch(hdok,'CTYPE1*') eq 1)
if ind eq -1 then begin
  print,'can not find wcs, doing nothing'
  return
endif

wcshd=hdok[ind:ind+37]
crpix1=sxpar(wcshd,'CRPIX1')
print,crpix1
crpix1=crpix1+offset[0]
print,crpix1
crpix2=sxpar(wcshd,'CRPIX2')
print,crpix2
crpix2=crpix2+offset[1]
print,crpix2
sxdelpar,wcshd,['CRPIX1']
sxaddpar,wcshd,'CRPIX1',crpix1,'X reference pixel',before='CRPIX2'
sxdelpar,wcshd,['CRPIX2']
sxaddpar,wcshd,'CRPIX2',crpix2,'Y reference pixel',after='CRPIX1'

;print,wcshd

ind=where(strmatch(hd,'WCSDIM*') eq 1)
if ind eq -1 then begin
  print,'can not find wcs, doing nothing'
  return
endif
;print,ind
hd=hd[0:ind]
sxdelpar,hd,['CRPIX1','CRPIX2','CTYPE1','CTYPE2','CRVAL1','CRVAL2','CROTA1','CSOURCE']

finalhd=[hd,wcshd]
;print,finalhd
data=mrdfits(filename,0,hdtmp)
writefits,filename,data,finalhd

if not keyword_set(sobj) then return

image_name_trans,filename,imagest
image_name_trans,knownfilename,imageokst

print,imagest.sobj,imageokst.sobj
sobjst=mrdfits(imagest.sobj,1,header)
sobjokst=mrdfits(imageokst.sobj,1)
sobjokst.X_IMAGE=sobjokst.X_IMAGE+offset[0]
sobjokst.Y_IMAGE=sobjokst.Y_IMAGE+offset[1]
writefits,imagest.sobj,''
mwrfits,sobjokst,imagest.sobj,header

end
