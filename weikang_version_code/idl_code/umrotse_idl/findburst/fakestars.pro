PRO fakestars,imagename,flux,seed,xmin,xmax,ymin,ymax,listxy,img1

;+
;  PURPOSE:  Add 100 fake stars to an image and write it out.
;
;  INPUTS: 
;     imagename = filename for input images
;     flux = total pixel flux of star (central 5x5 region)
;        350 is approx. 12th Rmag 
;     sig  = sigma of Gaussian used for fake star
;         0.7 is a very good focus (used for grb980527)
;     seed = integer value for random seed.  The same integer should result 
;	 in the same pseudo-random sequence
;     xmin,xmax,ymin,ymax -- range of image to insert stars into
;
; OUTPUTS:
;     listxy = lists of x (= 0) and y (= 1) locations of inserted stars
;     img1 = the image with fake stars added
;
;  Created: 1998-10-02 Brian Lee
;  Updated: 1998-12-22 Bob Kehoe -- several mods, incl. adding syntax printout, 
;  				    write out new image
;-
  On_error, 2                   ; return to caller

  if N_params() eq 0 then begin
        print, 'Syntax: fakestars,imagename,flux,seed,xmin,xmax,ymin,ymax,listxy,img1'
        return
  endif

; INITIALIZATION of variables

seed = long(seed)
iter = 5
numgen = 100
index = 0
sig = 0.8
listxy = fltarr(iter*numgen, 3)
image = imagename + '_c.fit'
img1 = mrdfits(image)
outfile = imagename + '_fake_c.fit'
datfile = imagename + '_fake_c.dat'
xrange = float(xmax-xmin)
yrange = float(ymax-ymin)

for k = 0,iter-1 do begin
   print, 'Running with flux = ', flux
   for i = 0,numgen-1 do begin
      x = (randomu(seed) * xrange) + xmin
      y = (randomu(seed) * yrange) + ymin
      xo = x - fix(x)
      yo = y - fix(y)
      gstar,xo,yo,sig,flux,star
      img1(fix(x)-5:fix(x)+5,fix(y)-5:fix(y)+5) = $
         img1(fix(x)-5:fix(x)+5,fix(y)-5:fix(y)+5) + star
      listxy(index, 0) = x
      listxy(index, 1) = y
      listxy(index, 2) = flux
      index = index + 1
   endfor
   flux = flux + 75
endfor

hdr = headfits(image)
writefits, outfile, img1, hdr
save, listxy, filename = datfile
print, outfile, ', .dat made'

END



