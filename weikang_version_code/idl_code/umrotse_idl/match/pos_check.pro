pro pos_check,filename

;This is a simple function to output the center of the field of 
;a frame which has a "new" header


 if N_params() eq 0 then begin
        print,'Syntax - pos_check,filename'
        return
 endif

 im=mrdfits(filename,0,hdr)
 mntra=sxpar(hdr,'MOUNTRA')
 mntdec=sxpar(hdr,'MOUNTDEC')
 raoff=sxpar(hdr,'OFFSTRA')
 decoff=sxpar(hdr,'OFFSTDEC')
 print,mntra,mntdec,raoff,decoff

 dec=mntdec+decoff
 ra=mntra+raoff/(cos(dec*0.01745329))

 print,ra,dec

 return
 end