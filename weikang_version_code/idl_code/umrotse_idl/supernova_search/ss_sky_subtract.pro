function ss_sky_subtract,image,skyvec,sky=sky

;interpolate skyvec
;subtract from image

if n_params() ne 2 then begin
  print,'syntax- result=ss_sky_subtract(image,skyvec)'
  return,''
endif

w_image=(size(image))[1]
h_image=(size(image))[2]
sky=dblarr(w_image,h_image)

nxsky=(size(skyvec))[1]
nysky=(size(skyvec))[2]
x1a=lindgen(nxsky)*32+16
x2a=lindgen(nysky)*32+16
splie2,x1a,x2a,skyvec,nxsky,nysky,y2a
splin2,x1a,x2a,skyvec,y2a,nxsky,nysky,findgen(w_image),findgen(h_image),sky
newimage=image-sky

return,newimage

end
