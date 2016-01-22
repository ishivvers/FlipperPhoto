PRO intfunc, fi, xi, intfi, plot=plot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    INTFUNC
;       
; PURPOSE: 
;    Make a cumulative integral function.  Basically just tabulate
;    the integral up to each xi
;	
;
; CALLING SEQUENCE:
;   intfunc,f, x [, intfi, plot=plot]
;
; INPUTS: 
;    f: the function
;    x: the abcissae
;
; KEYWORD PARAMETERS:
;         /plot: make a plot of the output function
;       
; OUTPUTS: 
;    the integrated function.
;
; CALLED ROUTINES: 
;          INT_TABULATED
; 
;
; REVISION HISTORY:
;	Author: Erin Scott Sheldon UofM  1/??/99
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


if n_params() LT 2 then begin
	print,'-Syntax: intfunc, f, x [, intf, plot=plot]'
	print,' Make a new function, intf, which has the integral of f to each point x'
        print,'Use doc_library,"intfunc" for more help'
	return

endif

n = n_elements(xi)

intfi = fltarr(n)
intfi[0] = 0.0

for i=1, n-1 do begin

	tmpxi = xi[0:i]
	tmpfi = fi[0:i]
	intfi[i] = int_tabulated(tmpxi, tmpfi) 
endfor

if keyword_set(plot) then begin
	plot,xi,intfi,psym=1
endif

return
end

