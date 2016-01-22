pro plot_kait_subimage,im,x,y,box=box,radius=radius,nolabel=nolabel, lims=lims,fail=fail, jpegname=jpegname,errad=errad,nocolor=nocolor, number1=number1,number2=number2,caption=caption,alternum=alternum,invbw=invbw,fullscreen=fullscreen,quality=quality,mps=mps

if n_params() eq 0 then begin
    print,'im,x,y,box=box,radius=radius,nolabel=nolabel, lims=lims,fail=fail, jpegname=jpegname,errad=errad,nocolor=nocolor, number1=number1,number2=number2,caption=caption,alternum=alternum,invbw=invbw,fullscreen=fullscreen,quality=quality'
    print,'   if radius = -1, bars are used'
    return
endif

fail = 0

xmin=0
ymin=0
arrsize=size(im)
xmax=arrsize[1]
ymax=arrsize[2]

if not keyword_set (quality) then quality=75

dname = !d.name

if n_elements(jpegname) ne 0 then begin
    set_plot,'z'
    if n_elements(dim) ne 2 then dim = [xmax,ymax]
    device,set_resolution=dim
endif

if keyword_set(invbw) then begin
    !p.color=0
    !p.background=255
endif
setupplot

if n_elements(box) ne 0 then begin
    size = box/2.
endif else begin
    size = 70
endelse

if n_elements(radius) eq 0 then begin
    radius = 10
endif

xlow=x-size
xhigh=x+size
ylow=y-size
yhigh=y+size

if keyword_set(fullscreen) then begin
    if (xhigh-xlow) gt (yhigh-ylow) then xhigh=xlow+yhigh-ylow
    if (yhigh-ylow) gt (xhigh-xlow) then yhigh=ylow+xhigh-xlow
endif
if (x gt xmax) then begin
    print,'Position not in image!'
    fail=1
    return
endif
if (y gt ymax) then begin
    fail=1
    print,'Position not in image!'
    return
endif
if (x lt 1) then begin
    fail = 1
    print,'Position not in image!'
    return
endif
if (y lt 1) then begin
    fail = 1
    print,'Position not in image!'
    return
endif

if (xlow lt 0) then begin
    xlow=0
endif
if (ylow lt 0) then begin
    ylow=0
endif
if (xhigh gt xmax) then begin
    xhigh=xmax
endif
if (yhigh gt ymax) then begin
    yhigh=ymax
endif

lims=fltarr(4)
lims[0] = xlow
lims[1] = xhigh
lims[2] = ylow
lims[3] = yhigh

pim=im
nrow = n_elements(im[0,*])
ncol = n_elements(im[*,0])

if lims[0] lt 0 then lims[0] = 0
if lims[1] ge ncol then lims[1] = ncol-1
if lims[2] lt 0 then lims[2] = 0
if lims[3] ge nrow then lims[3] = nrow - 1


sky,pim[lims[0]:lims[1],lims[2]:lims[3]],sky,skyerr
slow=sky-skyerr
shigh=sky+skyerr*10

tvim2_scl,pim,lims[0],lims[1],lims[2],lims[3],range=[slow,shigh],max_color=247,noframe=nolabel,invbw=invbw,fullscreen=fullscreen

if n_elements(caption) ne 0 then begin
    device,set_font='Helvetica Bold', /tt_font
    for i=0l,n_elements(caption)-1 do begin
        xyouts,0.1,0.95-0.05*i,caption[i],/normal,charsize=2
    endfor
    setupplot
endif


if keyword_set(jpegname) then begin
    basepic=tvrd()
    rpic = basepic
    gpic = basepic
    bpic = basepic
endif

clr=255
if n_elements(invbw) ne 0 then if invbw eq 1 then clr=0

if (radius lt 0) then begin
    if keyword_set(jpegname) then tv,basepic

    plots,x,y-30,color=clr
    plots,x,y-10,/continue,thick=!p.thick*3,color=clr
    plots,x+10,y,color=clr
    plots,x+30,y,/continue,thick=!p.thick*3,color=clr

    if keyword_set(jpegname) then begin
        rpic = tvrd()
        gpic = rpic
        bpic = rpic
    endif

endif else begin
    if keyword_set(jpegname) then tv,basepic

    if (n_elements(errad) gt 0) then begin
        ;; circle the error radius
        tvcircle,errad,x,y,/data,thick=!p.thick*2,color=clr
    endif else begin
        tvcircle,radius,x,y,/data,color=clr

        ;;This is for marking the minor planet (asteroid)
        ;;Updated by zwk on 131114
        if n_elements(mps) gt 0 then begin
          for i=0,n_elements(mps[0,*])-1 do begin
            tvcircle,radius+5.0,mps[0,i],mps[1,i],/data,color=120
            xyouts,mps[0,i]-12.0,mps[1,i]+20.0,string('mp ',mps[2,i],format='(a3,f4.1)'),/data;,alignment=0.5
          endfor
        endif
        ;;End of updating ---------------------
    endelse

    if keyword_set(jpegname) then begin
        rpic = tvrd()
        gpic = rpic
        bpic = rpic
    endif
    
endelse

!p.title=''

if keyword_set(jpegname) then begin
    dim=size(rpic,/dimensions)
    jps=bytarr(3,dim[0],dim[1])

    jps[0,*,*]=rpic
    jps[1,*,*]=gpic
    jps[2,*,*]=bpic

            tv,jps[0,*,*]
            jps[0,*,*] = tvrd()
            tv,jps[1,*,*]
            jps[1,*,*] = tvrd()
            tv,jps[2,*,*]
            jps[2,*,*] = tvrd()
    write_jpeg,jpegname,jps,/true,quality=quality

endif

set_plot,dname

return
end
