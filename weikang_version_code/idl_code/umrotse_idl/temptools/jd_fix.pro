pro jd_fix,struct,njd

 if N_params() eq 0 then begin
        print,'Syntax - jd_fix,struct,njd'
        return
 endif

 n=size(struct.jd)
 nim=n(1)-1
 njd=dindgen(n(1))

 for i=1,nim,1 do begin
	hdr=headfits(struct.imagename(i))
	jd=sxpar(hdr,'mjd')
	if (jd eq 0) then begin
		time=sxpar(hdr,"GMTTIME")
		ts=str_sep(time,' ')
		t=float(ts)
		juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], jd
		print,jd,format='(f15.8)'
	endif
	njd(i)=jd
	print,struct.imagename(i),i
 endfor
 njd(0)=njd(1)

 return
 end