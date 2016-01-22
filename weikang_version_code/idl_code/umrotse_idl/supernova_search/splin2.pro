pro splin2,x1a,x2a,ya,y2a,m,n,x1,x2,y
;+
;			splin2
;
; Given X1A, X2A, YA, M, N as described in SPLIE2.PRO and Y2A as produced by
; that routine, and given a desired interpolating point X1, X2, this routine
; returns an interpolated function value Y by bicubic spline interpolation.
;
; SOURCE:
;	Numerical Recipes, 1986. (page 101)
; 
; CALLING SEQUENCE:
;	splin2,x1a,x2a,ya,y2a,m,n,x1,x2,y
;
; INPUTS:
;	x1a - independent variable vector (first dimension)
;	x2a - independent variable vector (second dimension)
;	ya  - dependent variable array
;	y2a - second derivative array (as produced by SPLIE2.PRO)
;	m   - length of first dimension
;	n   - length of second dimension
;	x1  - first coordinate of interpolating point
;	x2  - second coordinate of interpolating point
;
; OUTPUTS:
;	y   - bicubic spline interpolated function value
;
; HISTORY:
;	converted to IDL, D. Neill, October, 1991
;-
ytmp = fltarr(n)
;y2tmp = fltarr(n)
;yytmp = fltarr(n)
outm=n_elements(x1)
outn=n_elements(x2)
yytmp=fltarr(m,outn)
y=fltarr(outm,outn)
;
; Perform N evaluations of the row splines constructed by SPLIE2.PRO, using
; the one-dimensional spline evaluator SPLINT.
;
for j=0,m-1 do begin
;	for k=0,n-1 do begin
;		ytmp(k) = ya(j,k)
;		y2tmp(k) = y2a(j,k)
;	endfor
;	splint,x2a,ytmp,y2tmp,n,x2,yyt
;	yytmp(j)=yyt
ytmp=ya[j,*]
y2tmp=y2a[j,*]
yyt=spl_interp(x2a,ytmp,y2tmp,x2)
yytmp[j,*]=yyt
endfor
;
; Construct the one-dimensional column spline and evaluate it.
;
;splinf,x1a,yytmp,m,1.e30,1.e30,y2tmp
;splint,x1a,yytmp,y2tmp,m,x1,y
for k=0,outn-1 do begin
y2tmp=spl_init(x1a,yytmp[*,k])
yyt2=spl_interp(x1a,yytmp[*,k],y2tmp,x1)
y[*,k]=yyt2
endfor

;
return
end	; splin2.pro
