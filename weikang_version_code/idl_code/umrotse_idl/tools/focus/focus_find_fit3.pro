pro focus_find_fit3,best,result,econst=econst,e2const=e2const,tconst=tconst,e3const=e3const,e4const=e4const
;+
; NAME: focus_find_fit
;
; CALLING SEQUENCE:
; focus_find_fit,best,result,econst=econst,e2const=e2const,tconst=tconst,etconst=etconst,e2tconst=e2tconst
;
; INPUTS:             best: array of best-focus structures
; 
; OUTPUTS:            result: the focus model coefficients
;
; INPUT KEYWORDS:     econst: fixed elevation constant
;                     e2const: fixed elev^2 constant
;                     tconst: fixed temp constant
;                     etconst: fixed elev*temp constant
;                     e2tconst: fixed elev^2*temp constant
;
; PROCEDURE:  This program uses a least-squares fitting to find the focus model
;  from a set of best focus as a function of temperature and elevation
;  measurements.  It then plots the residuals of the best fit.  This program is
;  called by gen_focus_model.
;
; REVISION HISTORY:
;   Eli Rykoff     UM     10/21/03 - First official version
;
;==========================================================================
;-


if n_params() eq 0 then begin
    print,'syntax- focus_find_fit,best,result,econst=econst,e2const=e2const,tconst=tconst,e3const=etconst,e4const=e4const'
    return
endif


h=where(best.best_focus gt 0 and best.error gt 0, ngd)
if ngd lt 3 then begin
    print,'Not enough points for a fit'
    return
endif


matrix = dblarr(6,6)
vec = dblarr(1,6)

one = total((best[h].elevation)^0.,/double)
th = total((best[h].elevation),/double)
th2 = total((best[h].elevation)^2.,/double)
th3 = total((best[h].elevation)^3.,/double)
th4 = total((best[h].elevation)^4.,/double)
th5 = total((best[h].elevation)^5.,/double)
th6 = total((best[h].elevation)^6.,/double)
th7 = total((best[h].elevation)^7.,/double)
th8 = total((best[h].elevation)^8.,/double)
t = total(best[h].temp,/double)
t2 = total((best[h].temp)^2.,/double)
tht = total(best[h].temp * best[h].elevation,/double)
th2t = total(best[h].temp * ((best[h].elevation)^2.),/double)
th3t = total(best[h].temp * ((best[h].elevation)^3.),/double)
th4t = total(best[h].temp * ((best[h].elevation)^4.),/double)

subval = 0
if (n_elements(econst) ne 0) then begin
    subval = subval + econst*best[h].elevation
endif
if (n_elements(e2const) ne 0) then begin
    subval = subval + e2const*best[h].elevation*best[h].elevation
endif
if (n_elements(tconst) ne 0) then begin
    subval = subval + tconst * best[h].temp
endif
if (n_elements(e3const) ne 0) then begin
    subval = subval + e3const * best[h].elevation * best[h].elevation * best[h].elevation
endif
if (n_elements(e4const) ne 0) then begin
    subval = subval + e4const * best[h].elevation * best[h].elevation * best[h].elevation * best[h].elevation
endif



z = total((best[h].best_focus - subval),/double)
thz = total((best[h].best_focus - subval) * best[h].elevation,/double)
th2z = total((best[h].best_focus - subval) * (best[h].elevation^2.),/double)
tz = total((best[h].best_focus - subval) * best[h].temp,/double)
th3z = total((best[h].best_focus - subval) * (best[h].elevation^3.),/double)
th4z = total((best[h].best_focus - subval) * (best[h].elevation^4.),/double)


matrix[0,0] = one
matrix[1,0] = th
matrix[2,0] = th2
matrix[3,0] = t
matrix[4,0] = th3
matrix[5,0] = th4

matrix[0,1] = th
matrix[1,1] = th2
matrix[2,1] = th3
matrix[3,1] = tht
matrix[4,1] = th4
matrix[5,1] = th5
    
matrix[0,2] = th2
matrix[1,2] = th3
matrix[2,2] = th4
matrix[3,2] = th2t
matrix[4,2] = th5
matrix[5,2] = th6
    
matrix[0,3] = t
matrix[1,3] = tht
matrix[2,3] = th2t
matrix[3,3] = t2
matrix[4,3] = th3t
matrix[5,3] = th4t
    
matrix[0,4] = th3
matrix[1,4] = th4
matrix[2,4] = th5
matrix[3,4] = th3t
matrix[4,4] = th6
matrix[5,4] = th7
    
matrix[0,5] = th4
matrix[1,5] = th5
matrix[2,5] = th6
matrix[3,5] = th4t
matrix[4,5] = th7
matrix[5,5] = th8


vec[0] = z
vec[1] = thz
vec[2] = th2z
vec[3] = tz
vec[4] = th3z
vec[5] = th4z

rc = [0]
newres = dblarr(6)
if (n_elements(econst) eq 0) then begin
    rc = [rc,1]
endif else newres[1] = econst
if (n_elements(e2const) eq 0) then begin
    rc = [rc,2]
endif else newres[2] = e2const
if (n_elements(tconst) eq 0) then begin
    rc = [rc,3]
endif else newres[3] = tconst
if (n_elements(e3const) eq 0) then begin
    rc = [rc,4]
endif else newres[4] = e3const
if (n_elements(e4const) eq 0) then begin
    rc = [rc,5]
endif else newres[5] = e4const

m2=matrix[rc,*]
matrix=m2[*,rc]
v2 = vec[0,rc]
vec = v2

;;print,matrix
;;print,vec

matrix_inv = invert(matrix)

; and multiply 'em
result = matrix_inv ## vec

;; and tease out the answer
newres[rc] = result[0,*]


;; output the result
print,''
print,'# Focus model:'
print,''
tab=string(9b)
print,'term' + tab + '1' + tab + string(newres[0],format='(f15.12)')
print,'term' + tab + 'e' + tab + string(newres[1],format='(f15.12)')
print,'term' + tab + 'ee' + tab + string(newres[2],format='(f15.12)')
print,'term' + tab + 't' + tab + string(newres[3],format='(f15.12)')
print,'term' + tab + 'eee' + tab + string(newres[4],format='(f20.17)')
print,'term' + tab + 'eeee' + tab + string(newres[5],format='(f20.17)')

print,''
print,'' 

model_focus = fltarr(n_elements(best))

for i=0l,n_elements(best[h])-1 do begin
    model_focus[i] = newres[0] + newres[1] * best[h[i]].elevation + $
                     newres[2] * (best[h[i]].elevation^2.) + newres[3] * best[h[i]].temp + $
                     newres[4] * (best[h[i]].elevation^3.) + $
                     newres[5] * (best[h[i]].elevation^4.)
endfor



residuals = model_focus - best[h].best_focus


!p.multi=[0,1,2]




ploterror,best[h].temp,residuals,best[h].error,psym=1,xtitle='Temperature',ytitle='Residual', $ 
          title='Residual as a function of Temperature'



ploterror,best[h].elevation,residuals,best[h].error,psym=1,xtitle='Elevation',ytitle='Residual', $
          title='Residual as a function of Elevation'


!p.multi=0


return
end
