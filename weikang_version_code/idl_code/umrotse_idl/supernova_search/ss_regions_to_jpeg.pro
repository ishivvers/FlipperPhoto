pro ss_regions_to_jpeg,image,xim=xim,yim=yim,box=box,color=color,jpegname=jpegname,dim=dim,quality=quality

if n_params() eq 0 then begin
    print,'syntax - ss_regions_to_jpeg,image,xim=xim,yim=yim,box=box,color=color,jpegname=jpegname,dim=dim,quality=quality'
    return
endif

if n_elements(box) ne 1 then box=150
if n_elements(color) ne 1 then color='green'
if n_elements(jpegname) ne 1 then jpegname = 'image_regions.jpg'
if n_elements(dim) ne 2 then dim = [1024,1024]
if n_elements(quality) ne 1 then quality=75

rad=box/2
color_list=['red','green','blue']
color_indx=where(color_list eq color,n)
if n eq 0 then begin
    print,'wrong color, available colors are:',color_list
    return
endif

dname=!D.NAME
set_plot,'z'
device,set_resolution=dim
;setupplot

sky,image,sky,skyerr,/silent
slow=sky-skyerr
shigh=sky+skyerr*5

tvim2,image,range=[slow,shigh],max_color=247,/nolables,/noframe

basepic=tvrd()
imdim=size(basepic,/dimensions)
jps=bytarr(3,imdim[0],imdim[1])

jps[0,*,*]=basepic
jps[1,*,*]=basepic
jps[2,*,*]=basepic

nx=n_elements(xim)
ny=n_elements(yim)
if nx gt 0 and nx eq ny then begin
    tv,jps[color_indx,*,*]
    for i=0,nx-1 do begin
        xl=xim[i]-rad
        xh=xim[i]+rad
        yl=yim[i]-rad
        yh=yim[i]+rad
        xyouts,xim[i],yim[i]-rad/3,string(i+1,format='(i2)'),/data,alignment=0.5
        plots,xl,yl
        plots,xl,yh,/continue,thick=!p.thick*1.5
        plots,xh,yh,/continue,thick=!p.thick*1.5
        plots,xh,yl,/continue,thick=!p.thick*1.5
        plots,xl,yl,/continue,thick=!p.thick*1.5
    endfor
    jps[color_indx,*,*]=tvrd()
endif
write_jpeg,jpegname,jps,/true,quality=quality

set_plot,dname
end
