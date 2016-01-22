function wtaverage,ogx,ogxerror

;+
; NAME:
; 	wtaverage
; PURPOSE:
; 	calculates the weighted average
; TYPE:
; 	
; CALLING SEQUENCE:
; 	Result = wtaverage(x,xerror)
; INPUTS:
; 	x --> the vector of values to average
;	xerror --> the error in each measurment
; OPTIONAL INPUTS:
; 	
; KEYWORDS:
; 	
; OUTPUTS:
; 	[wtaverage,error]
; COMMON BLOCKS:
; 	
; SIDE EFFECTS:
; 	
; EXAMPLES:
; 	
; PROCEDURE:
; 	
; MODIFICATION HISTORY:
; 	Written by Robert Quimby '98
;-
x=float(ogx)
xerror=float(ogxerror)

w=where(xerror ne 0 and finite(x) and finite(xerror))
if w[0] eq -1 then return,[0,0]

x=x[w]
xerror=xerror[w]
n_x=n_elements(x)
if n_x le 1 then return,[x,xerror]

tempx=0.0
invsigsq=0.0
for i=0,n_x-1 do begin
   invsigsq=invsigsq+xerror[i]^(-2.0)
   tempx=tempx+x[i]*(xerror[i]^(-2.0))
endfor

xbest=tempx/invsigsq
xsigma=invsigsq^(-.5)

return,[xbest,xsigma]
end
