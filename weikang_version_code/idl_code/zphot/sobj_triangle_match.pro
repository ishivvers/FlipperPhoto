pro sobj_triangle_match,sobjfile,catalog,outast=outast,show=show,plots=plots,fail=fail

if n_params() eq 0 then begin
  print,'syntax- sobj_triangle_match,sobjfile,catalog'
  return
endif

if not keyword_set(plots) then plots=0

order=1
image_name_trans,sobjfile,imagest
;chdr=headfits(imagest.cimg)
f=findfile(imagest.CIMG)
if f[0] eq '' then begin
  f=findfile(imagest.ROOT+'.fit*')
  if f[0] eq '' then begin
    print,'can not find corresponding _c.fit or .fit to extract informatio'
    fail=1
    return
  endif
endif
extract_head_info,f[0],outinfo=outinfo
sobj=mrdfits(imagest.sobj,1,/silent)
cat=catalog

;;sorting according to mag before matching
ind=sort(sobj.MAG_APER)
sobj=sobj[ind]
ind=sort(cat.MAG)
cat=cat[ind]

nb1=n_elements(sobj)
nb2=n_elements(cat)
if nb1 le 3 then begin
  print,'less than 3 stars in sobj, stop'
  fail=1
  return
endif
if nb2 le 3 then begin
  print,'less than 3 stars in catalog, stop'
  fail=1
  return
endif
;help,nb1,nb2
;;help,sobj.X_IMAGE, sobj.Y_IMAGE
;;help,cat.ra,cat.dec
;;print,nb1,nb2
;;do a cut on stars, make the two set the same size
;;maybe better to move it later, after cut on the edge

minstar=15
if nb1 lt nb2 then begin
  ;;this is backup match array
  sobj_bak=sobj
  cat_bak=cat[0:nb1-1]

  ;;put in dummy stars
  tmp=replicate(sobj[0],nb2-nb1)
  tmp.X_IMAGE=randomu(see,nb2-nb1)*100 ;;not sure what number is good
  tmp.Y_IMAGE=randomu(see,nb2-nb1)*100
  tmp.MAG_APER=30
  sobj=[sobj,tmp]
endif
equalnb=0
if nb1 eq nb2 then equalnb=1
if nb1 gt nb2 then begin
  ;;this is backup match array
  sobj_bak=sobj[0:nb2-1]
  cat_bak=cat

  ;;put in dummy stars
  tmp=replicate(cat[0],nb1-nb2)
  tmp.Ra=tmp.Ra+1.0
  tmp.Dec=tmp.Dec+1.0
  tmp.MAG=30
  cat=[cat,tmp]
endif
;nb1=n_elements(sobj)
;nb2=n_elements(cat)
;help,nb1,nb2

astr=mrdfits('/home/zwk/idl.lib/kait/kait_astr.fit',1,/silent)
astr.crval=[outinfo.rac_raw,outinfo.decc_raw]
;;map catalog radec to a fake center xy coord
rd2xy,cat.ra,cat.dec,astr,xc,yc
;;help,sobj.X_IMAGE, sobj.Y_IMAGE
;;help,xc,yc
triangle_match,sobj.X_IMAGE, sobj.Y_IMAGE, xc, yc, $
               0.002,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky,show=show

if n_elements(kx) le 1 then begin
    if equalnb ne 1 then begin
      ;;try another match
      print,'Tring again'
      sobj=sobj_bak
      cat=cat_bak
      ;nb1=n_elements(sobj)
      ;nb2=n_elements(cat)
      ;help,nb1,nb2
      rd2xy,cat.ra,cat.dec,astr,xc,yc
      triangle_match,sobj.X_IMAGE, sobj.Y_IMAGE, xc, yc, $
                 0.002,1,m1,m2,t1,s1,t2,s2,votearr,order=1,kx=kx,ky=ky,show=show
      if n_elements(kx) le 1 then begin
        print,'Failed to find a match'
        fail = 1
        return
      endif else begin
        print,'we have a good triangle match on second try'
      endelse
    endif else begin
      print,'Failed to find a match'
      fail = 1
      return
    endelse
endif else begin
    ;; we have a good match!
    print,'we have a good triangle match'
endelse

;;map the fake xy coord to real image xy coord
kx(1,1)=0.0
ky(1,1)=0.0
kmap,xc,yc,xx,yy,kx,ky
;print,xx,yy
;;now xx,yy has corresponding ra,dec, they are the transformed xy coord from radec

;;match the transformed real image xy coord to real xy coord from sobj
xim=sobj.x_image-1.0
yim=sobj.y_image-1.0
;;xx,yy also -1 because they are actually maped from xc,yc, not really from rd2xy
xx=xx-1
yy=yy-1 

ebox=2.0
close_match,xim,yim,xx,yy,m1,m2,ebox,1,miss1,/silent
if (n_elements(m1) lt 4) then begin
    print,'After close_match cuts, too few stars matched, need at least 4'
    ;;at least 4, not 3, because the polywarp with order 1 need at least (order +1)^2
    fail=1
    return
endif
;print,'we have a good match'

;;here solve for a better kx,ky, really better?
;;and trans again for faked coordinates
order=1
help,m1,m2
polywarp,xim[m1],yim[m1],xc[m2],yc[m2],order,kx,ky
kx(1,1)=0.0
ky(1,1)=0.0
kmap,xc,yc,xx,yy,kx,ky
xx=xx-1
yy=yy-1 

if (plots eq 1.0) then begin
  rpos_errors,xim,yim,xc,yc,m1,m2,kx,ky
endif

;;print,xim[m1]-xx[m2],yim[m1]-yy[m2]
dist=sqrt((xim[m1]-xx[m2])^2. + $
          (yim[m1]-yy[m2])^2.)
sdev = stddev(dist)
print,'Distance Measure: ',sdev

;;starast only need 3 stars to determine astr
;;tried to use xim3, not good
cat3=cat[m2[0:2]]
xx3=xx[m2[0:2]]
yy3=yy[m2[0:2]]
starast,cat3.ra,cat3.dec,xx3,yy3,cd ;Determine CD matrix
astr.CD=cd
astr.crval = [cat3[0].ra,cat3[0].dec] ;Use Star 0 as reference star
astr.crpix = [xx3[0]+1.0,yy3[0]+1.0] ;FITS is offset 1 pixel from IDL 
fail=0
outast=astr

end

