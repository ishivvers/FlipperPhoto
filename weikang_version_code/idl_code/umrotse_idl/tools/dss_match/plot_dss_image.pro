pro plot_dss_image,im,hdr,ra,dec,title=title,box=box,radius=radius, $
                   rarr1=rarr1,darr1=darr1, rarr2=rarr2, $
                   darr2=darr2,rarr3=rarr3,darr3=darr3, $
                   nolabel=nolabel,errad=errad, $
                   jpegname=jpegname,dim=dim, $
                   number1=number1, number2=number2, number3=number3

if n_params() eq 0 then begin
    print,'syntax- plot_dss_image,im,hdr,ra,dec,title=title,box=box,radius=radius,rarr1=rarr1,darr1=darr1,rarr2=rarr2,darr2=darr2,rarr3=rarr3,darr3=darr3,nolabel=nolabel,errad=errad,jpegname=jpegname,dim=dim,number1=number1,number2=number2,number3=number3'
    return
endif

if n_elements(jpegname) ne 0 then begin
    dev=!d.name

    set_plot,'z'
    if n_elements(dim) ne 2 then dim = [1024,1024]
    device,set_resolution=dim
    jpeg=1
endif

setupplot

fail = 0

if n_elements(box) ne 0 then begin
    size = box/2.
endif else begin
    size = 0.1
endelse

if n_elements(radius) eq 0 then begin
    radius = 10
endif

nx = n_elements(im[*,0])
ny = n_elements(im[0,*])

decliml=dec-size
declimh=dec+size
raliml=ra-(size / cos(dec*0.01745))
ralimh=ra+(size / cos(dec*0.01745))

;;gsssadxy,astr,ra,dec,x,y
;;gsssadxy,astr,[raliml,ralimh],[decliml,declimh],xx,yy
adxy,hdr,ra,dec,x,y
adxy,hdr,[raliml,ralimh],[decliml,declimh],xx,yy

xlow=min(xx) 
xhigh=max(xx)
ylow=min(yy)
yhigh=max(yy)

if (x ge nx) then begin
    print,'position not in image!'
    fail=1
    return
endif
if (y ge ny) then begin
    print,'position not in image!'
    fail=1
    return
endif
if (x lt 1) then begin
    print,'position not in image!'
    fail=1
    return
endif
if (y lt 1) then begin
    print,'position not in image!'
    fail=1
    return
endif

if (xlow lt 0) then begin
    xlow=0
endif
if (ylow lt 0) then begin
    ylow=0
endif
if (xhigh ge nx) then begin
    xhigh=nx-1
endif
if (yhigh ge ny) then begin
    yhigh=ny-1
endif

lims=fltarr(4)
lims[0] = xlow
lims[1] = xhigh
lims[2] = ylow
lims[3] = yhigh


;; do array 1
xx1=0
yy1=0
num1=-1
if n_elements(rarr1) ne 0 then begin
    if n_elements(darr1) eq n_elements(rarr1) then begin
        ;;gsssadxy,astr,rarr1,darr1,xx1,yy1
        adxy,hdr,rarr1,darr1,xx1,yy1

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


;; do array 2
xx2=0
yy2=0
num2=-1
if n_elements(rarr2) ne 0 then begin
   if n_elements(darr2) eq n_elements(rarr2) then begin
       ;;gsssadxy,astr,rarr2,darr2,xx2,yy2
       adxy,hdr,rarr2,darr2,xx2,yy2
       
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


;; do array 3
xx3=0
yy3=0
num3=-1
if n_elements(rarr3) ne 0 then begin
   if n_elements(darr3) eq n_elements(rarr3) then begin
       ;;gsssadxy,astr,rarr2,darr2,xx2,yy2
       adxy,hdr,rarr3,darr3,xx3,yy3
       
       h=where(xx3 gt xlow and xx3 lt xhigh and yy3 gt ylow and yy3 lt yhigh,nmat)
       if (nmat gt 0) then begin
           xx3=xx3[h]
           yy3=yy3[h]
           num3=h
       endif else begin
           xx3=0
           yy3=0
           num3=-1
       endelse
   endif else begin
       print,'Ra3 array has different number of elements as d3 array.'
   endelse
endif



;; and plot
sky,im[lims[0]:lims[1],lims[2]:lims[3]],sky,skyerr
slow=sky-skyerr
shigh=sky+skyerr*5
if (not keyword_set(nolabel) and n_elements(title) ne 0) then begin
    !p.title = title
endif

tvim2_scl,im,lims[0],lims[1],lims[2],lims[3],range=[slow,shigh],max_color=247,noframe=nolabel

if keyword_set(jpeg) then begin
    basepic = tvrd()
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
    if (keyword_set(jpeg)) then tv,basepic

    if (n_elements(errad) gt 0) then begin
        ;; circle the error radius
        tvcircle,errad,x,y,/data
    endif else begin
        tvcircle,radius,x,y,/data
    endelse

    if keyword_set(jpeg) then begin
        rpic = tvrd()
        gpic = rpic
        bpic = rpic
    endif
    
    if n_elements(rarr1) gt 0 then begin

        ;; do the number dance
        if (n_elements(number1) eq n_elements(rarr1)) and (num1[0] ne -1) then begin
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
                          string(number1[num1[i]],format='(i4)'), $
                          alignment=0.0,/data,color=col
                    endfor

                    case c of
                        0: rpic = tvrd()
                        1: gpic = tvrd()
                        2: bpic = tvrd()
                    endcase
                endfor
            endif else begin
                for i=0l,n_elements(xx1)-1 do begin
                    xyouts,xx1[i]+radius-2,yy1[i], $
                      string(number1[num1[i]],format='(i4)'), $
                      alignment=0.0,/data,color=!blue
                endfor
            endelse
        endif

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
            tvcircle,radius,xx1,yy1,/data,color=!blue
        endelse
    endif

    if n_elements(rarr2) gt 0 then begin
        ;; do the number dance
        if (n_elements(number2) eq n_elements(rarr2)) and (num2[0] ne -1) then begin
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
                          string(number2[num2[i]],format='(i4)'), $
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
                      string(number2[num2[i]],format='(i4)'), $
                      alignment=0.0,/data,color=!yellow
                endfor
            endelse
        endif




        if keyword_set(jpeg) then begin
  
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
            tvcircle,radius-2,xx2,yy2,/data,color=!yellow
        endelse
    endif
        
    if n_elements(rarr3) gt 0 then begin
       ;; do the number dance
        if (n_elements(number3) eq n_elements(rarr3)) and (num3[0] ne -1) then begin
            if (keyword_set(jpeg)) then begin
                ;; numbers in red
                for c=0l,2 do begin
                    case c of
                        0: begin
                            tv,rpic
                            col=255L
                        end
                        1: begin
                            tv,gpic
                            col=0
                        end
                        2: begin
                            tv,bpic
                            col=0
                        end
                    endcase

                    for i=0l,n_elements(xx3)-1 do begin
                        xyouts,xx3[i]+radius-2,yy3[i], $
                          string(number3[num3[i]],format='(i4)'), $
                          alignment=0.0,/data,color=col
                    endfor

                    case c of
                        0: rpic = tvrd()
                        1: gpic = tvrd()
                        2: bpic = tvrd()
                    endcase
                endfor
            endif else begin
                for i=0l,n_elements(xx3)-1 do begin
                    xyouts,xx3[i]+radius-2,yy3[i], $
                      string(number3[num3[i]],format='(i4)'), $
                      alignment=0.0,/data,color=!red
                endfor
            endelse
        endif




        if keyword_set(jpeg) then begin
;;            tv,basepic
;;            tvcircle,radius-3,xx3,yy3,/data,thick=2
;;            newpic = tvrd()

;;            draw=where(newpic ne basepic,ct)
            ;; draw in red
;;            if (ct gt 0) then begin
;;                rpic[draw] = newpic[draw]
;;                gpic[draw] = 0
;;                bpic[draw] = 0
            ;;endif      endif
            tv,rpic
            tvcircle,radius-3,xx3,yy3,/data,thick=2
            rpic = tvrd()
            tv,gpic
            tvcircle,radius-3,xx3,yy3,/data,thick=2,color=0
            gpic = tvrd()
            tv,bpic
            tvcircle,radius-3,xx3,yy3,/data,thick=2,color=0
            bpic = tvrd()


        endif else begin
            tvcircle,radius-3,xx3,yy3,/data,color=!red
        endelse
    endif
endelse

if keyword_set(jpeg) then begin
    jps=bytarr(3,dim[0],dim[1])
    jps[0,*,*] = rpic
    jps[1,*,*] = gpic
    jps[2,*,*] = bpic

    write_jpeg,jpegname,jps,/true,quality=90

    set_plot,dev
endif



return
end
