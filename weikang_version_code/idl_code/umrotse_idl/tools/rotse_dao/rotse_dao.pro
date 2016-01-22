pro rotse_dao,fname,ras,decs,use,ms,merrs,tnum,ir=ir

if n_params() eq 0 then begin
    print,'syntax- rotse_dao,fname,ras,decs,use,ms,merrs,tnum,ir=ir'
    return
endif


imname=find_rotse3_image(fname,path='image')
cobjname=find_rotse3_cobj(fname,path='prod')

im=readfits(imname)
c=mrdfits(cobjname,1)
cal=mrdfits(cobjname,2)


;; subtract sextractor sky, to get rid of gradients, etc.
if not keyword_set(ir) then begin
    sub_sky,im,cal.sky,newim
    im=newim
endif else begin
    ;; read in the weight image
    parts=strsplit(imname,'c.fit',/extract,/regex)
    wimname=parts[0]+'w.fit'
    wim=readfits(wimname)

    h=where(wim eq 0.0,nh)
    if (nh gt 0) then wim[h]=0.001
endelse

if keyword_set(ir) then begin
;;    phpadu=1./10.5
    phpadu = 10.4
endif else begin
;;    phpadu=0.33333
    phpadu=3.0
endelse

ms=fltarr(n_elements(ras)) - 1.0
merrs=ms

if (tag_exist(cal,'fwhm')) then begin
    use_fwhm=cal.fwhm
endif else begin
    print,'Does not work on this old cal structure'
    return
endelse

if keyword_set(ir) then begin
    ;; set the fwhm: don't trust sextractor
    use_fwhm=2.5  
endif

;; don't use find... just do each of the desired stars with gcntrd
;;astr_struct_new,1.85,astr
pixscale=cal.cdelt1
astr_struct_new,pixscale*2048,astr
astr.crval=[double(cal.rac),double(cal.decc)]
rd2xy,ras,decs,astr,xc,yc
kmap,xc,yc,xx,yy,cal.kx,cal.ky

targ_x=xx[tnum]
targ_y=yy[tnum]

x=[0.0]
y=[0.0]

if tag_exist(cal,'satcnts') then begin
    satcnts=cal.satcnts
endif else satcnts=100000.0

for i=0l,n_elements(xx)-1 do begin
    if (xx[i] gt 10 and xx[i] lt cal.naxis1-10 and $
        yy[i] gt 10 and yy[i] lt cal.naxis2-10 and use[i] eq 1) then begin
        gcntrd,im,xx[i],yy[i],xcen,ycen,use_fwhm,maxgood=satcnts
        if (xcen ne -1.0 and ycen ne -1.0) then begin
            dist=sqrt((xcen-xx[i])^2.+(ycen-yy[i])^2.)
            if (dist lt 2.) then begin
                ;; this is okay
                x=[x,xcen]
                y=[y,ycen]
            endif
        endif
    endif
endfor

if n_elements(x) eq 1 then begin
    print,'no stars found:',fname
    return
endif

x=x[1:n_elements(x)-1]
y=y[1:n_elements(y)-1]

;; get intial aperture magnitudes

ids=lindgen(n_elements(x))

aper,im,x,y,mags,errap,sky,skyerr,phpadu,3.5,[3.5,10],[-100000,satcnts],/silent

close_match,x,y,c.x,c.y,m1,m2,1.0,1

h=where(c[m2].flags eq 0 and c[m2].m gt cal.sat_mag+1.0 and $ 
        c[m2].m lt 18.0 and mags[m1] lt 90.0)

if n_elements(h) gt 100 then h=h[0:99]

useids = ids[m1[h]]

psfrad = use_fwhm * 1.5


;; get the psf; it's saved to psftest.fit tempfile

if (tag_exist(cal,'bstddev')) then begin
    bstddev = cal.bstddev
endif else bstddev = 1.0

getpsf_rotse,im,x,y,mags,sky,bstddev,phpadu,gauss,psf,useids, $
  psfrad, use_fwhm, 'psftest.fit',weightim=wim

;;print,imname
;;ans=' '
;;read,ans,prompt='continue?'

;; group the stars together

group,x,y,psfrad+use_fwhm,ngroup

newids=ids
newx=x
newy=y
newmags=mags

;; nstar does the actual psf fitting

nstar_rotse,im,newids,newx,newy,newmags,sky,ngroup,phpadu, $
  bstddev,'psftest.fit',magerr,/silent,/keepfaint,weightim=wim


;; match stars and go back to ~ the original magnitude system.  In the end,
;; the match structure will be recalibrated against some standard stars.

close_match,newx,newy,c.x,c.y,mm1,mm2,2.0,1


;; this makes me nervous: should it be back to usno?
offset=median(c[mm2].m-newmags[mm1])
newmags=newmags+offset

;; check if target acquired, find limit otherwise
close_match,targ_x,targ_y,newx,newy,tm1,tm2,2.0,1
if (tm2[0] eq -1) then begin
    ;; target not acquired: calculate limiting mag

    rotse_dao_lim,im,'psftest.fit',satcnts,targ_x,targ_y,x,y,offset,lim

    ;; now, put the limit in, but with a -1 on merr...
    ;; (matchtodao will put -1 on flag as well, I hope)
    close_match,targ_x,targ_y,xx,yy,tm1,tm2,2.0,1
    if (tm2[0] eq -1) then begin
        print,'Serious problem.'
        stop
    endif
    ms[tm2[0]] = lim
    merrs[tm2[0]] = -1.0
    
endif


print,imname
;;ans=' '
;;read,ans,prompt='continue?'






;; and match these back in.  All the misses now get -1's
used=where(use eq 1)
close_match,xx[used],yy[used],newx,newy,mmm1,mmm2,2.0,1


if (mmm1[0] ne -1) then begin
    if n_elements(magerr) eq 0 then begin
        ;; ??
        ms[used[mmm1]] = -1.0
        merrs[used[mmm1]] = -1.0
    endif else begin
        ms[used[mmm1]] = newmags[mmm2]
        merrs[used[mmm1]] = magerr[mmm2]
    endelse
endif


;;if septarg then begin
;;    ms[tnum]=tmag+offset
;;    merrs[tnum]=(tmagp-tmagm)/2.
;;endif

return
end
