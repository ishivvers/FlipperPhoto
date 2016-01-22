pro lcplot2,struct,index,obj,gdobj=gdobj,good=good,err=err,syserr=syserr,oplot=oplot,offset=offset,emask=emask,rmask=rmask,flagbadobs=flagbadobs,nowait=nowait,_extra=e

;+
; NAME:	LCPLOT2
;
; CALLING SEQUENCE:	lcplot2,struct,index,obj
;
; INPUTS:	struct: a new type match structure
;		index: the indices of the observations to plot
;		obj: a single object or an array of objects
;
; OUTPUTS:	
;	
; INPUT KEYWORDS:
;		gdobj: array of good objects, marked by a 'y' keypress.
;		good: plot "good" observations (don't plot -1's)
;		err: plot the statistical error on the observations
;		syserr: plot the statistical + systematic error (in quadrature)
;		oplot: plot over a previous plot
;		offset: Set this to the zero-time offset, or use /offset to set
;			it to the time of the first observation
;		emask: a mask for which SExtractor flags are "bad". Default = 0
;		rmask: a mask for which rotse rflags are "bad". Default = 0
;		flagbadobs: plot all observations but put x's on bad ones.
;               nowait: plot all, without waiting for a keypress.
;			
; PROCEDURE:	Plots the light curves of many objects
;
; REVISION HISTORY:
;	Created:	Tim McKay
;	Eli Rykoff		UM	7/25/00
;					Updated from Tim's old "temptool"
;******************************************************************************
;-

if N_params() eq 0 then begin
	print,'Syntax: lcplot2,struct,index,obj,gdobj=gdobj,good=good,err=err,syserr=syserr,oplot=oplot,offset=offset,emask=emask,rmask=rmask,flagbadobs=flagbadobs,/nowait'
	print,'If you specify /offset (or offset=1), then struct.jd(0) is used.'
	print,'To filter out all bad rflags and eflags use emask=28, rmask=63'
 	return
 endif

 n=size(obj)
 if (n(0) eq 0) then begin
	n=1
 endif else begin
	n=n(1)
 	print,'Examining light curves for ',n,' objects'
 endelse

 o=lindgen(n)
 o(*)=obj

 if not keyword_set(offset) then begin
	offset=0.0
 endif

 if not keyword_set(wait) then begin
	twait=1.0
 endif else begin
	twait=wait
 endelse

 if (offset eq 1) then begin
	offset=struct.jd(0)
 endif

 if keyword_set(syserr) then begin
   the_err = sqrt(struct.merr^2 + (float(struct.msys)/200.)^2)
   err=1
 endif else begin
   the_err = struct.merr
 endelse

 if not keyword_set(rmask) then begin
   rmask = 0
 endif
 if not keyword_set(emask) then begin
   emask = 0
 endif

 nbad=0

 ; Check if we have an EFFTIME defined; if not use EXPTIME to get bar width
 exp_time=0
 stat_names=tag_names(struct.stat(0))
 h=where(stat_names eq 'EFFTIME', efcount)
 if (efcount eq 1) then begin
   exp_time=struct.stat(0).efftime
 endif else begin
   exp_time=struct.stat(0).exptime
 endelse

 bar_width=(float(exp_time)/(24.*60.*60.))/2.
 gdobj = 0

 for k=0,n-1,1 do begin 

   i=index

   the_name = make_rotse_name(struct.ra(o(k)),struct.dec(o(k)))
   !p.title='object='+string(o(k),format='(i6)')+', Designation: '+the_name
   if keyword_set(good) then begin
     j=where(struct.m(i,o(k)) gt 0 and struct.m(i,o(k)) lt 30 and $
         ((struct.rflags(i,o(k)) and rmask) eq 0) and $
         ((struct.flags(i,o(k)) and emask) eq 0), ngood)
     if (ngood gt 1) then begin
       i=i(j)
     endif else begin
       print,"********No good observations!!!!!"
       print,"Plotting all observations..."
     endelse
   endif

   if keyword_set(flagbadobs) then begin
     badobs=where(((struct.rflags and rmask) ne 0) $
       or ((struct.flags and emask) ne 0),nbad) 
   endif

   minmag = min(struct.m(i,o(k))-the_err(i,o(k)))
   maxmag = max(struct.m(i,o(k))+the_err(i,o(k)))

   if keyword_set(flagbadobs) then begin
      intobs = where(struct.m(index,o(k)) gt 0)
      minmag = min(struct.m(index(intobs),o(k))-the_err(index(intobs),o(k)))
      maxmag = max(struct.m(index(intobs),o(k))+the_err(index(intobs),o(k)))
   endif

   if keyword_set(err) then begin
	if not keyword_set(oplot) then begin
          plot,struct.jd(i)-offset,struct.m(i,o(k)),psym=1,yrange=[maxmag,minmag]   
	  plotbars,struct.jd(i)-offset,bar_width,struct.m(i,o(k)),the_err(i,o(k))  
	  
	  if (keyword_set(flagbadobs) and (nbad gt 0)) then begin
	     oplot,struct.jd(index(badobs))-offset,struct.m(index(badobs),o(k)),psym=7
	     plotbars,struct.jd(index(badobs))-offset,0,struct.m(index(badobs),o(k)), $
                 the_err(index(badobs),o(k))
	  endif
	  if not keyword_set(nowait) then begin
	    print,'Press "y" to mark this object'
            r = get_kbrd(10)
            if ((r eq 'y') or (r eq 'Y')) then begin
               gdobj=[gdobj,o(k)]
            endif
	  endif
	endif else begin
	  oplot,struct.jd(i)-offset,struct.m(i,o(k)),psym=7
	  plotbars,struct.jd(i)-offset,bar_width,struct.m(i,o(k)),the_err(i,o(k))
	  print,'Press "y" to mark this object'
          r = get_kbrd(10)
          if ((r eq 'y') or (r eq 'Y')) then begin
             gdobj=[gdobj,o(k)]
          endif
	endelse
	print,'Done with '+string(k)
   endif else begin
	if not keyword_set(oplot) then begin
	   plot,struct.jd(i)-offset,struct.m(i,o(k)),psym=1,yrange=[maxmag,minmag],_extra=e
	   if not keyword_set(nowait) then begin
	     print,'Press "y" to mark this object'
             r = get_kbrd(10)
             if ((r eq 'y') or (r eq 'Y')) then begin
                gdobj=[gdobj,o(k)]
             endif
           endif
	endif else begin
	   oplot,struct.jd(i)-offset,struct.m(i,o(k)),psym=7,_extra=e
	   if not keyword_set(nowait) then begin 
	      print,'Press "y" to mark this object'
              r = get_kbrd(10)
              if ((r eq 'y') or (r eq 'Y')) then begin
                gdobj=[gdobj,o(k)]
              endif
           endif
	endelse
   endelse

 endfor

 if (n_elements(gdobj) gt 1) then begin
    gdobj = gdobj[1:(n_elements(gdobj)-1)]
 endif

 !p.title=''

 return
 end

 




