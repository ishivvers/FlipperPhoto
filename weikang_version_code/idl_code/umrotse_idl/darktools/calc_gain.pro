pro calc_gain,badpix,drk1,drk2,bd1,bd2,gain

;+
; NAME:	CALC_GAIN
;
; CALLING SEQUENCE:	calc_gain,badpix,drk1,drk2,bd1,bd2,gain
;
; INPUTS:	badpix: a bad pixel structure from find_badpix
;		drk1, drk2: A pair of 80 second darks
;		bd1, bd2: A corresponding pair of 0 second bias darks
;
; OUTPUTS:	gain: the camera gain estimated from these darks
;	
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Calculates the gain by subtracting two 80 second bias-subtracted
;		 darks, and looking at the width of the resulting distribution.
;		 Hot pixels are flagged and not used in the calculation.
;
; REVISION HISTORY:  
;	Eli Rykoff		UM	7/25/00
;					Created
;
;******************************************************************************
;-


if n_params() eq 0 then begin
   print,'syntax-calc_gain,badpix,drk1,drk2,bd1,bd2,gain
   return 
endif

nrows=n_elements(drk1(0,*,0))
ncols=n_elements(drk1(0,0,*))

bad_im=replicate(0,nrows,ncols)
h=where(check_flags(['HOTPIX','NOISYPIX','STRANGEPIX'],badpix.type, $
          type='RFLAGS') gt 0,badct)
if (badct gt 0) then begin
  bad_im(badpix(h).x,badpix(h).y) = 1
endif

goodpix=where(bad_im eq 0)

bdavg = (float(bd1) + float(bd2))/2.
gdbdavg=bdavg(goodpix)
avg = (float(drk1) + float(drk2))/2. - bdavg
gdavg=avg(goodpix)

gddiff=(drk2 - drk1)(goodpix)
gdbddiff=(bd2 - bd1)(goodpix)

minval=50

abovemin=where(gdavg gt minval)

sigbdsub=stddev(gdbddiff(abovemin))

mean_above_min=mean(gdavg(abovemin))
the_width=sqrt(stddev(gddiff(abovemin))^2 - sigbdsub^2)/sqrt(2)

gain=mean_above_min/(the_width^2)

return

end











