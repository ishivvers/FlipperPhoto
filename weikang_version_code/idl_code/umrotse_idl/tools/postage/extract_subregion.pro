pro extract_subregion,im,xmin,xmax,ymin,ymax,subim

if n_params() lt 6 then begin
    print,'syntax- extract_subregion,im,xmin,xmax,ymin,ymax,subim'
    return
endif

numx = xmax - xmin + 1
numy = ymax - ymin + 1


subim = fltarr(numx,numy)


;;need to ensure that it is a valid range...
s=size(im)

x_offset = 0
y_offset = 0
real_xmin = xmin
real_ymin = ymin
real_xmax = xmax
real_ymax = ymax

if (xmin lt 0) then begin
    real_xmin = 0
    x_offset = real_xmin - xmin
endif

if (ymin lt 0) then begin
    real_ymin = 0
    y_offset = real_ymin - ymin
endif

if (xmax ge s[1]) then begin
    real_xmax = s[1] - 1
endif

if (ymax ge s[2]) then begin
    real_ymax = s[2] - 1
endif

real_numx = real_xmax - real_xmin + 1
real_numy = real_ymax - real_ymin + 1

subim[x_offset:(x_offset+real_numx-1),y_offset:(y_offset+real_numy-1)] = $
  im[real_xmin:real_xmax,real_ymin:real_ymax]


return
end
