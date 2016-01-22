FUNCTION check_in_fov, n, m, s, obj, count=count
;+
; NAME: CHECK_IN_FOV
;
; CALLING SEQUENCE: check_in_fov, n, m, s
;
; INPUTS:       n: the observation index number
;               m: a match structure
;               s: the array of stats structures
;               obj: the objects to check
;
; OUTPUT:       nout: indices of sources outside the FOV of observation n
;               count: number of sources outside the FOV
;
; REVISION HISTORY:  
;       Don Smith    UM      11/26/01
;       Eli Rykoff           02/23/04 -- now only checks a given list of objects
;================================================================================
;-

if n_params() lt 4 then begin
    print,'syntax- check_in_fov, n, m, s, obj, count=count'
    return,-1
endif

; First, convert all the ra/dec values to x and y values
  astr_struct_new,1.85,astr
  astr.crval=[double(m.rac[n]),double(m.decc[n])]

  rd2xy,m.ra[obj],m.dec[obj],astr,x1,y1
  kx = reform(m.kx[n,*,*])
  ky = reform(m.ky[n,*,*])
  kmap,x1,y1,x,y,kx,ky

; Now flag anything outside of the pixel limits
  nout_temp = where(x LT 2 OR x GT (s[n].naxis1 - 2) OR $
                    y LT 2 OR y GT (s[n].naxis2 - 2) ,count)
  if (count gt 0) then nout = obj[nout_temp] else nout = -1
  return, nout
END
