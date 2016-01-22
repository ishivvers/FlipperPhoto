pro sub_sky,im,sky,new,gridsize=gridsize,xsub=xsub,ysub=ysub

if n_params() eq 0 then begin
    print,'syntax- sub_sky,im,sky,new,gridsize=gridsize,xsub=xsub,ysub=ysub'
    return
endif

if (n_elements(gridsize) eq 0) then begin
    gridsize=32.
endif

if ((n_elements(xsub) ne 0) and (n_elements(xsub) ne 2) and $
    (n_elements(ysub) ne 0) and (n_elements(ysub) ne 2) and $
    (n_elements(xsub) ne n_elements(ysub))) then begin
    print,'must have xsub,ysub or none; returning image'
    new=im
    return
endif

if (n_elements(xsub) eq 0) then begin
    sz=size(im)
    nx=sz[1]
    ny=sz[2]

    fullsky=interpolate(sky,findgen(nx)/gridsize,findgen(ny)/gridsize,/grid)

    new=im-fullsky
endif else begin
    ;; tricky-- need full size
    nx = 2045
    ny = 2049
    
    fullsky=interpolate(sky,findgen(nx)/gridsize,findgen(ny)/gridsize,/grid)
    new = im - fullsky[xsub[0]:xsub[1],ysub[0]:ysub[1]]

endelse


return
end
