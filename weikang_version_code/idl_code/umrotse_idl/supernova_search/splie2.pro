pro splie2,x1a,x2a,ya,m,n,y2a
;+
;			splie2
;
; Given an M by N tabulated function YA, and tabulated independent variables
; X1A (M values) and X2A (N values), this routine constructs one-dimensional
; natural cubic splines of the rows of YA and returns the second derivatives
; in the array Y2A.
;
; SOURCE:
;	Numerical Recipes, 1986. (page 100)
; 
; CALLING SEQUENCE:
;	splie2,x1a,x2a,ya,m,n,y2a
;
; INPUTS:
;	x1a - independent variable vector (first dimension)
;	x2a - independent variable vector (second dimension)
;	ya  - dependent variable array
;	m   - length of first dimension
;	n   - length of second dimension
;
; OUTPUTS:
;	y2a- second derivative array
;
; HISTORY:
;	converted to IDL, D. Neill, October, 1991
;-
y2a = fltarr(m,n)
ytmp = fltarr(n)
y2tmp = fltarr(n)

;
for j=0,m-1 do begin
;	for k=0,n-1 do ytmp(k) = ya(j,k)
;	splinf,x2a,ytmp,n,1.e30,1.e30,y2tmp  ; Vals. 1.e30 signal natural spline	
;       for k=0,n-1 do y2a(j,k) = y2tmp(k)
        ytemp=ya[j,*]
        y2tmp=spl_init(x2a,ytemp)
        y2a[j,*]=y2tmp
endfor
;
return
end	; splie2.pro
