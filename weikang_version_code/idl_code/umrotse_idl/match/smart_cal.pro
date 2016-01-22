pro smart_cal,cal,match1,match_cal

;
;  calibrates galaxy magnitudes using the data in the cal struct
;
;
;
;
;
;

if N_params() eq 0 then begin
	print,' lcrs_cal,cal,match,matchc '
endif
num=n_elements(match1.m(1,*))

k=cal.k
zp=cal.zp
kc=cal.kc
zpc=cal.zpc
ns=num
matchc=create_struct( $
	"kx",findgen(6,4,4),"ky",findgen(6,4,4),$
	"filter",sindgen(6),"exptime",findgen(6),$
	"airmass",findgen(6),$
	"imagename",sindgen(6),$
	"rac",findgen(1),"decc",findgen(1),$
	"x",findgen(6,ns),"y",findgen(6,ns),$
	"m",findgen(6,ns),$
	"merr",findgen(6,ns),$
	"fwhm",findgen(6,ns),$
	"ra",findgen(ns),$
	"dec",findgen(ns),$
	"rmag",findgen(ns),$
	"bmag",findgen(ns),$
	"ug",findgen(ns),$
	"gr",findgen(ns),$
	"ri",findgen(ns),$
	"iz",findgen(ns))

matchc.kx=match1.kx
matchc.ky=match1.ky
matchc.filter=match1.filter
matchc.exptime=match1.exptime
matchc.airmass=match1.airmass
matchc.imagename=match1.imagename
matchc.rac=match1.rac
matchc.decc=match1.decc
matchc.x=match1.x
matchc.y=match1.y
matchc.m=match1.m
matchc.merr=match1.merr
matchc.fwhm=match1.fwhm
matchc.ra=match1.ra
matchc.dec=match1.dec
matchc.rmag=match1.rmag
matchc.bmag=match1.bmag
matchc.ug(*)=match1.m(3,*)-match1.m(2,*)
matchc.gr(*)=match1.m(2,*)-match1.m(1,*)
matchc.ri(*)=match1.m(1,*)-match1.m(4,*)
matchc.iz(*)=match1.m(4,*)-match1.m(5,*)
match1=matchc


ma=findgen(5)
ma(1)=(match1.airmass(3)+match1.airmass(2))/2
ma(2)=(match1.airmass(2)+match1.airmass(1))/2
ma(3)=(match1.airmass(1)+match1.airmass(4))/2
ma(4)=(match1.airmass(4)+match1.airmass(5))/2

c2=findgen(5,num)
c2(2,*)=match1.gr(*)+2.5*alog10(match1.exptime(2)/match1.exptime(1))
c2(1,*)=match1.ug(*)+2.5*alog10(match1.exptime(3)/match1.exptime(2))
c2(3,*)=match1.ri(*)+2.5*alog10(match1.exptime(1)/match1.exptime(4))
c2(4,*)=match1.iz(*)+2.5*alog10(match1.exptime(4)/match1.exptime(5))



match_cal=match1
cug=where(match_cal.m(3,*) ne -1 and match_cal.m(2,*) ne -1)
dug=where(match_cal.m(3,*) eq -1 or match_cal.m(2,*) eq -1)

cgr=where(match_cal.m(2,*) ne -1 and match_cal.m(1,*) ne -1)
dgr=where(match_cal.m(2,*) eq -1 or match_cal.m(1,*) eq -1)

cr=where(match_cal.m(1,*) ne -1)
cri=where(match_cal.m(4,*) ne -1 and match_cal.m(1,*) ne -1)
dri=where(match_cal.m(4,*) eq -1 or match_cal.m(1,*) eq -1)

ciz=where(match_cal.m(5,*) ne -1 and match_cal.m(4,*) ne -1)
diz=where(match_cal.m(5,*) eq -1 or match_cal.m(4,*) eq -1)
dr=where(match_cal.m(1,*) eq -1)


	match_cal.m(1,cr)=match_cal.m(1,cr)-20-k(1)*match_cal.airmass(1)+2.5*alog10(match_cal.exptime(1))-zp(1)-zpc(1)-kc(1)*(c2(2,cr)-zp(3)-k(3)*ma(2)) 
if dr(0) ne -1 then begin
	match_cal.m(1,dr)=-1	
endif
	match_cal.ug(cug)=c2(1,cug)-k(2)*ma(1)-zp(2)-zpc(2)-kc(2)*(c2(1,cug)-zp(2)-k(2)*ma(1))
if dug(0) ne -1 then begin
	match_cal.ug(dug)=-1
endif
	match_cal.gr(cgr)=c2(2,cgr)-k(3)*ma(2)-zp(3)-zpc(3)-kc(3)*(c2(2,cgr)-zp(3)-k(3)*ma(2))
if dgr(0) ne -1 then begin
	match_cal.gr(dgr)=-1
endif
	match_cal.ri(cri)=c2(3,cri)-k(4)*ma(3)-zp(4)-zpc(4)-kc(4)*(c2(3,cri)-zp(4)-k(4)*ma(3))
if dri(0) ne -1 then begin
	match_cal.ri(dri)=-1
endif
	match_cal.iz(ciz)=c2(4,ciz)-k(5)*ma(4)-zp(5)-zpc(5)-kc(5)*(c2(4,ciz)-zp(5)-k(5)*ma(4))
if diz(0) ne -1 then begin
	match_cal.iz(diz)=-1
endif
return
end
