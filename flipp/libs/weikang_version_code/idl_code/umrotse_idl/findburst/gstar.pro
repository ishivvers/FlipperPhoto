PRO gstar,x,y,sigma,flux,star,r

; Created:  98-10-02  Brian Lee

; This routine returns (star) an 11x11 array with a Gaussian centered 
; at 5.0+x,5.0+y of the given sigma and total central flux.

; INPUT:
; x = x offset from 5 (center of array) for star centroid
; y = y offset from 5 (center of array) for star centroid
; sigma specified in pixels
; flux = flux pixel count in 5x5 central array
; OUTPUT:
; star = Gaussian pseudo-star
; r = coordinate array (output for debugging)

star = dblarr(11,11)
r = dblarr(11,11,3) ; 0 = radial distance, 1,2 = x and y coordinates
a = 1.0 / (2.0 * !pi * sigma * sigma)

x = x + 5.0
y = y + 5.0

for i=0,10 do begin
   for j = 0,10 do begin
      r(i,j,0) = double(((float(i) - x)^2 + (float(j) - y)^2 )^0.5 )
      ; center at x,y
      ; r(*,*,0) = radial dist from center point
      r(i,j,1) = double(i)-x
      r(i,j,2) = double(j)-y
      ; these two are arrays of x and y
   endfor
endfor

star = double(a * exp(-1.0*double(0.5*(r(*,*,0)/sigma)^2)))

t = total(star(3:7,3:7)) ; total flux in 5x5 central part

star = star * flux/t

END
