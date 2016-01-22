pro plot_rotse3_image,im,rac,decc,kx,ky,ra,dec,title=title,box=box,radius=radius,nolabel=nolabel, $
                      rotate=rotate,lims=lims,skylims=skylims,fail=fail,rarr1=rarr1,darr1=darr1, $
                      rarr2=rarr2,darr2=darr2,jpeg=jpeg,jps=jps,errad=errad,nocolor=nocolor, $
                      number1=number1,number2=number2,caption=caption,alternum=alternum,pixscale=pixscale

if n_params() eq 0 then begin
    print,'syntax- plot_rotse3_image,im,rac,decc,kx,ky,ra,dec,title=title,box=box,radius=radius,nolabel=nolabel, rotate=rotate, skylims=skylims,fail=fail,jpeg=jpeg,jps=jps,errad=errad,nocolor=nocolor,number1=number1,number2=number2,caption=caption,alternum=alternum,pixscale=pixscale'
    print,'   if radius = -1, bars are used'
    return
endif

fail = 0

if n_elements(box) ne 0 then begin
    size = box/2.
endif else begin
    size = 0.1
endelse

if n_elements(radius) eq 0 then begin
    radius = 10
endif

if n_elements(pixscale) eq 0 then pixscale = 1.85/2048.


decliml=dec-size
declimh=dec+size
raliml=ra-(size / cos(dec*0.01745))
ralimh=ra+(size / cos(dec*0.01745))

skylims=fltarr(4)
skylims[0] = raliml
skylims[1] = ralimh
skylims[2] = decliml
skylims[3] = declimh


;;astr_struct_new,1.85,astr
astr_struct_new,pixscale*2048.,astr
astr.crval=[double(rac),double(decc)]
rd2xy,[raliml,ralimh],[decliml,declimh],astr,xc,yc
kmap,xc,yc,xx,yy,kx,ky

rd2xy,ra,dec,astr,xc,yc
kmap,xc,yc,xa,ya,kx,ky
x=xa[0]
y=ya[0]

xlow=min(xx) 
xhigh=max(xx)
ylow=min(yy)
yhigh=max(yy)

if (x gt 2044) then begin
    print,'Position not in image!'
    fail=1
    return
endif
if (y gt 2048) then begin
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
if (xhigh gt 2044) then begin
    xhigh=2044
endif
if (yhigh gt 2048) then begin
    yhigh=2048
endif

lims=fltarr(4)
lims[0] = xlow
lims[1] = xhigh
lims[2] = ylow
lims[3] = yhigh

xx1=0
yy1=0
num1=-1
if n_elements(rarr1) ne 0 then begin
    if n_elements(darr1) eq n_elements(rarr1) then begin
        rd2xy,rarr1,darr1,astr,xc,yc
        kmap,xc,yc,xx1,yy1,kx,ky

        h=where(xx1 gt xlow and xx1 lt xhigh and yy1 gt ylow and yy1 lt yhigh,nmat)
        if (nmat gt 0) then begin
            xx1=xx1[h]
            yy1=yy1[h]
            num1=h
        endif else begin
            xx1=0
            yy1=0
            num1=-1
        endelse
    endif else begin
        print,'Ra1 array has different number of elements as d1 array.'
    endelse
endif

xx2=0
yy2=0
num2=-1
if n_elements(rarr2) ne 0 then begin
   if n_elements(darr2) eq n_elements(rarr2) then begin
        rd2xy,rarr2,darr2,astr,xc,yc
        kmap,xc,yc,xx2,yy2,kx,ky

        h=where(xx2 gt xlow and xx2 lt xhigh and yy2 gt ylow and yy2 lt yhigh,nmat)
        if (nmat gt 0) then begin
            xx2=xx2[h]
            yy2=yy2[h]
            num2=h
        endif else begin
            xx2=0
            yy2=0
            num2=-1
        endelse
    endif else begin
        print,'Ra2 array has different number of elements as d2 array.'
    endelse
endif
 
pim=im
nrow = n_elements(im[0,*])
ncol = n_elements(im[*,0])

if keyword_set(rotate) then begin
;;    stop
 
    ;; find rotation needed
    if ((xx[0] lt xx[1]) and (yy[0] lt yy[1])) then begin
        ;; this is rotse3a-ish (left amp)
        pim=rotate(im,5)

        lims[0] = ncol - 1 - xhigh
        lims[1] = ncol - 1 - xlow
 
        x = ncol - 1 - x
        xx1 = ncol - 1 - xx1
        xx2 = ncol - 1 - xx2
    endif else if ((xx[0] gt xx[1]) and (yy[0] gt yy[1])) then begin
        ;; this is rotse3b-ish (left amp)
        ;; this is also rotse3d-ish (left amp)
        pim = rotate(im,7)
        
        lims[2] = nrow - 1 - yhigh
        lims[3] = nrow - 1 - ylow

        y = nrow - 1 - y
        yy1 = nrow - 1 - yy1
        yy2 = nrow - 1 - yy2
    endif else if ((xx[0] lt xx[1]) and (yy[0] gt yy[1])) then begin
        ;; this is rotse3b-ish (right amp)
        pim = rotate(im,2)

        lims[0] = ncol - 1 - xhigh
        lims[1] = ncol - 1 - xlow
        lims[2] = nrow - 1 - yhigh
        lims[3] = nrow - 1 - ylow

        x = ncol - 1 - x
        xx1 = ncol - 1 - xx1
        xx2 = ncol - 1 - xx2
        y = nrow - 1 - y
        yy1 = nrow - 1 - yy1
        yy2 = nrow - 1 - yy2
;;    endif else if ((xx[0] gt xx[1]) and (yy[0] lt yy[1])) then begin
;;        print,'ROTATION 3D, 90d, LEFT'
;;        stop
        ;; this is rotse3d, rotated, left amp
;;        pim = rotate(im,6)

;;        lims[0] = nrow - 1 - yhigh
;;        lims[1] = nrow - 1 - ylow
;;        lims[2] = ncol - 1 - xhigh
;;        lims[3] = ncol - 1 - xlow

;;        xtemp = x
;;        xx1temp = xx1
;;        xx2temp = xx2
;;        ytemp = y
;;        yy1temp = yy1
;;        yy2temp = yy2

;;        x = nrow - 1 - ytemp
;;        xx1 = nrow - 1 - yy1temp
;;        xx2 = nrow - 1 - yy2temp
;;        y = ncol - 1 - xtemp
;;        yy1 = ncol - 1 - xx1temp
;;        yy2 = ncol - 1 - xx2temp
    endif else if ((xx[0] gt xx[1]) and (yy[0] lt yy[1])) then begin
        ;; no rotation needed

      
    endif else begin
        ;; not supported
        print,'Rotation not being performed; not implemented yet for this configuration'
    endelse
endif


if lims[0] lt 0 then lims[0] = 0
if lims[1] ge ncol then lims[1] = ncol-1
if lims[2] lt 0 then lims[2] = 0
if lims[3] ge nrow then lims[3] = nrow - 1


sky,pim[lims[0]:lims[1],lims[2]:lims[3]],sky,skyerr
slow=sky-skyerr
shigh=sky+skyerr*5
if (not keyword_set(nolabel) and n_elements(title) ne 0) then begin
    !p.title = title
endif

tvim2_scl,pim,lims[0],lims[1],lims[2],lims[3],range=[slow,shigh],max_color=247,noframe=nolabel
;;!p.title=''

if n_elements(caption) ne 0 then begin
    device,set_font='Helvetica Bold', /tt_font
    for i=0l,n_elements(caption)-1 do begin
        xyouts,0.1,0.95-0.05*i,caption[i],/normal,charsize=2
    endfor
    setupplot
endif


if keyword_set(jpeg) then begin
    basepic=tvrd()
    rpic = basepic
    gpic = basepic
    bpic = basepic
endif


if (radius lt 0) then begin
    if keyword_set(jpeg) then tv,basepic

    plots,x,y-30
    plots,x,y-10,/continue,thick=!p.thick*3
    plots,x+10,y
    plots,x+30,y,/continue,thick=!p.thick*3

    if keyword_set(jpeg) then begin
        rpic = tvrd()
        gpic = rpic
        bpic = rpic
    endif

endif else begin
    if keyword_set(jpeg) then tv,basepic

    if (n_elements(errad) gt 0) then begin
        ;; circle the error radius
        tvcircle,errad,x,y,/data,thick=!p.thick*2
    endif else begin
        tvcircle,radius,x,y,/data
    endelse

    if keyword_set(jpeg) then begin
        rpic = tvrd()
        gpic = rpic
        bpic = rpic
    endif
    
    if n_elements(rarr1) gt 0 then begin
;;        if (keyword_set(jpeg)) then tv,basepic

        ;; do the number dance, this could be fun...

        if (n_elements(number1) gt 0) and (num1[0] ne -1) then begin
            if (keyword_set(jpeg)) then begin
                ;; numbers in blue
                for c=0l,2 do begin
                    case c of
                        0: begin
                            tv,rpic
                            col=0
                        end
                        1: begin
                            tv,gpic
                            col=0
                        end
                        2: begin
                            tv,bpic
                            col=255L
                        end
                    endcase

                    for i=0l,n_elements(xx1)-1 do begin
                        xyouts,xx1[i]+radius-2,yy1[i], $
                          string(number1[num1[i]],format='(i5)'), $
                          alignment=0.0,/data,color=col
                    endfor
                    
                    case c of
                        0: rpic = tvrd()
                        1: gpic = tvrd()
                        2: bpic = tvrd()
                    endcase
                endfor
            endif else begin
                xyouts,xx1[i]+radius-2,yy1[i], $
                  string(number1[num1[i]],format='(i5)'), $
                  alignment=0.0,/data,color=!blue
            endelse

            if keyword_set(alternum) then number1=number1[num1]
        endif else if ((num1[0] eq -1) and keyword_set(alternum)) then $
          number1 = [-1]
        
        if keyword_set(jpeg) then begin
            ;; draw in blue
            tv,rpic
            tvcircle,radius,xx1,yy1,/data,thick=2,color=0
            rpic=tvrd()
            tv,gpic
            tvcircle,radius,xx1,yy1,/data,thick=2,color=0
            gpic=tvrd()
            tv,bpic
            tvcircle,radius,xx1,yy1,/data,thick=2
            bpic=tvrd()
        endif else begin
            if not keyword_set(nocolor) then begin
                tvcircle,radius,xx1,yy1,/data,color=!blue
            endif else begin
                tvcircle,radius,xx1,yy1,/data,linestyle=2
            endelse
        endelse
    endif

    if n_elements(rarr2) gt 0 then begin
        if (n_elements(number2) gt 0) and (num2[0] ne -1) then begin
            if (keyword_set(jpeg)) then begin
                ;; numbers in yellow
                for c=0l,2 do begin
                    case c of
                        0: begin
                            tv,rpic
                            col=255L
                        end
                        1: begin
                            tv,gpic
                            col=255L
                        end
                        2: begin
                            tv,bpic
                            col=0
                        end
                    endcase

                    for i=0l,n_elements(xx2)-1 do begin
                        xyouts,xx2[i]+radius-2,yy2[i], $
                          string(number2[num2[i]],format='(i5)'), $
                          alignment=0.0,/data,color=col
                    endfor

                    case c of
                        0: rpic = tvrd()
                        1: gpic = tvrd()
                        2: bpic = tvrd()
                    endcase
                endfor
            endif else begin
                for i=0l,n_elements(xx2)-1 do begin
                    xyouts,xx2[i]+radius-2,yy2[i], $
                      string(number2[num2[i]],format='(i5)'), $
                      alignment=0.0,/data,color=!yellow
                endfor
            endelse
            
            if keyword_set(alternum) then number2=number2[num2]
        endif else if ((num2[0] eq -1) and keyword_set(alternum)) then $
          number2 = [-1]

        if keyword_set(jpeg) then begin
            ;; draw in yellow
            tv,rpic
            tvcircle,radius-2,xx2,yy2,/data,thick=2
            rpic=tvrd()
            tv,gpic
            tvcircle,radius-2,xx2,yy2,/data,thick=2
            gpic=tvrd()
            tv,bpic
            tvcircle,radius-2,xx2,yy2,/data,thick=2,color=0
            bpic=tvrd()
        endif else begin
            if not keyword_set(nocolor) then begin                
                tvcircle,radius-2,xx2,yy2,/data,color=!yellow
            endif else begin
                tvcircle,radius-2,xx2,yy2,/data,linestyle=3
            endelse
        endelse
    endif
        
endelse

!p.title=''

if keyword_set(jpeg) then begin
    dim=size(rpic,/dimensions)
    jps=bytarr(3,dim[0],dim[1])

    jps[0,*,*]=rpic
    jps[1,*,*]=gpic
    jps[2,*,*]=bpic

endif


return
end
