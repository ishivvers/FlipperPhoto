pro plot_finding_chart,imname,target=target,refstar=refstar,box=box,radius=radius,jpegname=jpegname,dim=dim,noaxis=noaxis,quality=quality,invbw=invbw,mark=mark,refmark=refmark,objname=objname,innerdis=innerdis,sigmal=sigmal,sigmah=sigmah,rular=rular,roffset=roffset

if n_params() eq 0 then begin
    print,'plot_finding_chart,imname,target=target,refstar=refstar,box=box,radius=radius,jpegname=jpegname,dim=dim,noaxis=noaxis,quality=quality,invbw=invbw,mark=mark,refmark=refmark,objname=objname,innerdis=innerdis,sigmal=sigmal,sigmah=sigmah,rular=rular,roffset=roffse'
    return
endif

if n_elements(quality) eq 0 then quality = 75
dname = !d.name

if not keyword_set(innerdis) then innerdis=9.0
if not keyword_set(radius) then radius=9.0
if not keyword_set(sigmal) then sigmal=1.0
if not keyword_set(sigmah) then sigmah=10.0
if not keyword_set(box) then box=150  ;; half of the whole box
if not keyword_set(objname) then objname='Target'
if not keyword_set(jpegname) then jpegname=objname+'_findingchart.jpg'
if not keyword_set(rular) then rular=30  ;;in unit of "
if not keyword_set(roffset) then roffset=10 

rularscale=float(rular)/3600.0 

;;readin image, find center, astrst
image=readfits(imname,head,/silent)
naxis1=sxpar(head,'NAXIS1')
naxis2=sxpar(head,'NAXIS2')
centX=float(naxis1)/2.0
centY=float(naxis2)/2.0
targetRa=target[0]
targetDec=target[1]
refRa=refstar[0,*]
refDec=refstar[1,*]
extast,head,astr
xy2ad,centX,centY,astr,centRa,centDec
ad2xy,targetRa,targetDec,astr,targetX,targetY
ad2xy,refRa,refDec,astr,refX,refY
;; find rular point of North and East
centNRa=centRa
centNDec=centDec+rularscale
centERa=centRa+rularscale/cos(centDec*!pi/180.0)
centEDec=centDec
ad2xy,centNRa,centNDec,astr,centNX,centNY
ad2xy,centERa,centEDec,astr,centEX,centEY

if targetX gt naxis1 or targetX lt 0 or targetY gt naxis2 or targetY lt 0 then begin
  print,'Target not in the image, doing nothing!'
  return
endif

;print,centX,centY
;print,targetX,targetY
;print,refX,refY
;print,centNX,centNY
;print,centEX,centEY
;
;print,centRa,centDec
;print,targetRa,targetDec
;print,refRa,refDec
;print,centNRa,centNDec
;print,centERa,centEDec

;; find out the right region to plot
xl=floor(targetX-box)
xh=floor(targetX+box)
if (xl le 0) then begin
  xl=0
  xh=min([floor(box*2.0),naxis1])-1
endif
if (xh ge naxis1) then begin
  xh=naxis1-1
  xl=max([0,floor(naxis1-box*2.0)])
endif
yl=floor(targetY-box)
yh=floor(targetY+box)
if (yl le 0) then begin
  yl=0
  yh=min([floor(box*2.0),naxis2])-1
endif
if (yh ge naxis2) then begin
  yh=naxis2-1
  yl=max([0,floor(naxis2-box*2.0)])
endif
;print,xl,xh
;print,yl,yh

;lims=[0,naxis1-1,0,naxis2-1]
lims=[xl,xh,yl,yh]
;find skylim region
print,'XY Lims:',lims
xy2ad,lims[0],lims[2],astr,ra0,dec1
xy2ad,lims[1],lims[3],astr,ra2,dec3
skylims=[ra2,ra0,dec1,dec3]
print,'RaDec Lims:',skylims

;;do the rotation for kait, flip Y
;print,centNY,centY,centEX,centX
if centNY lt centY and centEX le centX then begin
  ;pim=image
  pim = rotate(image,7)
  print,'rotating: flip Y'
  lims[2] = naxis2 - 1 - yh
  lims[3] = naxis2 - 1 - yl

  centY = naxis2 - 1 - centY
  targetY = naxis2 - 1 - targetY
  refY = naxis2 - 1 - refY
  centNY = naxis2 - 1 - centNY
  centEY = naxis2 - 1 - centEY
  dectmp=skylims[2]
  skylims[2]=skylims[3]
  skylims[3]=dectmp

endif else begin
  print,'this rotation has not been defined, please add it, now doing no rotation'
  pim=image
endelse


;preparing for plot
if n_elements(jpegname) ne 0 then begin
    set_plot,'z'
    if n_elements(dim) ne 2 then dim = [1024,1240]
    device,set_resolution=dim
    jpeg=1
endif

if keyword_set(invbw) then begin
    !p.color=0
    !p.background=255
endif

setupplot

;plot_rotse3_sn_image,thisimage,rac,decc,kx,ky,ra,dec,box=box,radius=radius, $
;  lims=lims,skylims=skylims,fail=fail,jpeg=jpeg,rarr1=rarr1,darr1=darr1, $
;  jps=jps,pixscale=pixscale,invbw=invbw,fullscreen=fullscreen,mark=mark, $
;  refmark=refmark,innerdis=innerdis

sky,pim[lims[0]:lims[1],lims[2]:lims[3]],sky,skyerr,/silent
slow=sky-skyerr*sigmal
shigh=sky+skyerr*sigmah
    
tvim2_scl,pim,lims[0],lims[1],lims[2],lims[3],range=[slow,shigh],max_color=247,noframe=1,invbw=invbw;,/fullscreen
    
if keyword_set(jpeg) then begin
    basepic=tvrd() 
    rpic = basepic
    gpic = basepic 
    bpic = basepic 
endif
    
clr=255 
if n_elements(invbw) ne 0 then if invbw eq 1 then clr=0

if keyword_set(jpeg) then tv,basepic

if strmatch(mark,'*t*') then begin
    plots,targetX,targetY+innerdis+radius,color=clr
    plots,targetX,targetY+innerdis,/continue,thick=!p.thick*3,color=clr
endif
if strmatch(mark,'*b*') then begin
    plots,targetX,targetY-innerdis-radius,color=clr
    plots,targetX,targetY-innerdis,/continue,thick=!p.thick*3,color=clr
endif
if strmatch(mark,'*l*') then begin
    plots,targetX-innerdis,targetY,color=clr
    plots,targetX-innerdis-radius,targetY,/continue,thick=!p.thick*3,color=clr
endif
if strmatch(mark,'*r*') then begin
    plots,targetX+innerdis,targetY,color=clr
    plots,targetX+innerdis+radius,targetY,/continue,thick=!p.thick*3,color=clr
endif

;plot ruler
shiftx=lims[1]-roffset-centX
shifty=lims[2]+roffset-centY
;print,shiftx,shifty
rulerX=lims[1]-roffset
rulerY=lims[2]+roffset
rulerNX=centNX+shiftx
rulerNY=centNY+shifty
rulerEX=centEX+shiftx
rulerEY=centEY+shifty
;print,rulerX,rulerY
;print,rulerNX,rulerNY
;print,rulerEX,rulerEY
plots,rulerX,rulerY,color=clr
plots,rulerNX,rulerNY,/continue,thick=!p.thick*3,color=clr
plots,rulerX+2,rulerNY-2,color=clr
plots,rulerNX,rulerNY,/continue,thick=!p.thick*3,color=clr
plots,rulerX-2,rulerNY-2,color=clr
plots,rulerNX,rulerNY,/continue,thick=!p.thick*3,color=clr
plots,rulerX,rulerY,color=clr
plots,rulerEX,rulerEY,/continue,thick=!p.thick*3,color=clr
plots,rulerEX+2,rulerEY+2,color=clr
plots,rulerEX,rulerEY,/continue,thick=!p.thick*3,color=clr
plots,rulerEX+2,rulerEY-2,color=clr
plots,rulerEX,rulerEY,/continue,thick=!p.thick*3,color=clr
xyouts,rulerNX+2,rulerNY+3,'N',alignment=1.0,/data,color=clr,charsize=2.0
xyouts,rulerEX-3,rulerEY-2,'E',alignment=1.0,/data,color=clr,charsize=2.0
xyouts,rulerX-10,rulerY+10,string(rular,'"',format='(i3,a1)'),alignment=1.0,/data,color=clr,charsize=3.0

nref=n_elements(refX)
if nref gt 0 then begin

    for i=0,nref-1 do begin
        if strmatch(refmark[i],'*t*') then begin
            plots,refX[i],refY[i]+innerdis+radius,color=clr
            plots,refX[i],refY[i]+innerdis,/continue,thick=!p.thick*3,color=clr
            xyouts,refX[i],refY[i]+innerdis*2.+radius,'S'+string(i+1,format='(i1)'),alignment=0.5,/data,color=clr,charsize=2.0
        endif
        if strmatch(refmark[i],'*b*') then begin
            plots,refX[i],refY[i]-innerdis-radius,color=clr
            plots,refX[i],refY[i]-innerdis,/continue,thick=!p.thick*3,color=clr
            xyouts,refX[i],refY[i]-innerdis*2.-radius-1.25,'S'+string(i+1,format='(i1)'),alignment=0.5,/data,color=clr,charsize=2.0
        endif
        if strmatch(refmark[i],'*l*') then begin
            plots,refX[i]-innerdis,refY[i],color=clr
            plots,refX[i]-innerdis-radius,refY[i],/continue,thick=!p.thick*3,color=clr
            xyouts,refX[i]-innerdis*2.-radius,refY[i]-1.25,'S'+string(i+1,format='(i1)'),alignment=1.0,/data,color=clr,charsize=2.0
        endif
        if strmatch(refmark[i],'*r*') then begin
            plots,refX[i]+innerdis,refY[i],color=clr
            plots,refX[i]+innerdis+radius,refY[i],/continue,thick=!p.thick*3,color=clr
            xyouts,refX[i]+innerdis*2.+radius,refY[i]-1.25,'S'+string(i+1,format='(i1)'),alignment=0.0,/data,color=clr,charsize=2.0
        endif
    endfor
endif

if keyword_set(jpeg) then begin
    rpic = tvrd()
    gpic = rpic
    bpic = rpic
endif

!p.title=''

if keyword_set(jpeg) then begin
    dim=size(rpic,/dimensions)
    jps=bytarr(3,dim[0],dim[1])

    jps[0,*,*]=rpic
    jps[1,*,*]=gpic
    jps[2,*,*]=bpic

endif

fail=0
if (fail eq 0) then begin
    rac=centRa
    decc=centDec
    ra=targetRa
    dec=targetDec
    rarr1=refRa
    darr1=refDec
    
    if (keyword_set(jpeg)) then begin
        tv,jps[0,*,*]
        annotate_sn_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,dim=dim,rarr1=rarr1,darr1=darr1,objname=objname,noaxis=noaxis
        jps[0,*,*] = tvrd()
        tv,jps[1,*,*]
        annotate_sn_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,dim=dim,rarr1=rarr1,darr1=darr1,objname=objname,noaxis=noaxis
        jps[1,*,*] = tvrd()
        tv,jps[2,*,*]
        annotate_sn_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,dim=dim,rarr1=rarr1,darr1=darr1,objname=objname,noaxis=noaxis
        jps[2,*,*] = tvrd()
    endif else begin
        annotate_sn_finding_chart,rac,decc,kx,ky,lims,skylims,ra,dec,rarr1=rarr1,darr1=darr1,objname=objname,noaxis=noaxis
    endelse
    
endif else begin
    print,'plot failed'
end

if n_elements(jpegname) ne 0 and fail eq 0 then begin
    write_jpeg,jpegname,jps,/true,quality=quality
endif

set_plot,dname
return
end
