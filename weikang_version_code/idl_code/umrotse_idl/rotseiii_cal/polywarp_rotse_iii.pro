pro polywarp_rotse_iii, xi, yi, xo, yo, degree, kx, ky, double=doubleIn, status=status

;; this is based on polywarp, except the higher order terms have been squashed.
;; -- it works for the rotse3 telescopes.

compile_opt idl2

on_error,2

if (degree ne 3) then begin
    print,'only works degree = 3'
    return
endif


m = n_elements(xi)		;# of points..
if (m ne n_elements(yi)) or (n_elements(xo) ne n_elements(yo)) $
	or (m ne n_elements(xo)) then begin
		message,'Inconsistent number of elements.'
		endif

typeD = SIZE(1d,/TYPE)
doDouble = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
	(SIZE(xi,/TYPE) eq typeD) or (SIZE(yi,/TYPE) eq typeD) or $
	(SIZE(xo,/TYPE) eq typeD) or (SIZE(yo,/TYPE) eq typeD)

n=degree
n2=(n+1)^2 - 6    ;; we're taking out the six highest-order cross terms
if n2 gt m then message, '# of points must be ge (degree+1)^2.'

x = double([transpose(xi[*]),transpose(yi[*])])
u = double([transpose(xo[*]),transpose(yo[*])])

ut=dblarr(n2,m)
u2i = dblarr(n+1)	;[1,u2i,u2i^2,...]

for i=0L,m-1 do begin
    u2i[0]=1.                   ;init u2i
    zz = u[1,i]
    for j=1,n do u2i[j]=u2i[j-1]*zz
    ut[0,i] = u2i
    ut[4,i] = u[0,i]*u2i[0]
    ut[5,i] = u[0,i]*u2i[1]
    ut[6,i] = u[0,i]*u2i[2]
    ut[7,i] = u[0,i]^2.*u2i[0]
    ut[8,i] = u[0,i]^2.*u2i[1]
    ut[9,i] = u[0,i]^3.*u2i[0]
endfor

uu = ut#transpose(ut)	;big u
kk = invert(uu, status, /DOUBLE)	;find coefficients

if not ARG_PRESENT(status) and (status ne 0) then begin
	case status of
	1: MESSAGE,/INFO, "Singular matrix detected."
	2: MESSAGE,/INFO, "Warning: Invert detected a small pivot element."
	else:
	endcase
endif

kk = TEMPORARY(kk) # TEMPORARY(ut)  ;solve equation

if doDouble then begin
    temp=kk#transpose(x[0,*])
    kx = dblarr(n+1,n+1)
    kx[0,0] = temp[0]
    kx[1,0] = temp[1]
    kx[2,0] = temp[2]
    kx[3,0] = temp[3]
    kx[0,1] = temp[4]
    kx[1,1] = temp[5]
    kx[2,1] = temp[6]
    kx[0,2] = temp[7]
    kx[1,2] = temp[8]
    kx[0,3] = temp[9]
    
    temp=kk#transpose(x[1,*])
    ky = dblarr(n+1,n+1)
    ky[0,0] = temp[0]
    ky[1,0] = temp[1]
    ky[2,0] = temp[2]
    ky[3,0] = temp[3]
    ky[0,1] = temp[4]
    ky[1,1] = temp[5]
    ky[2,1] = temp[6]
    ky[0,2] = temp[7]
    ky[1,2] = temp[8]
    ky[0,3] = temp[9]
    
endif else begin
    temp=kk#transpose(x[0,*])
    kx = fltarr(n+1,n+1)
    kx[0,0] = temp[0]
    kx[1,0] = temp[1]
    kx[2,0] = temp[2]
    kx[3,0] = temp[3]
    kx[0,1] = temp[4]
    kx[1,1] = temp[5]
    kx[2,1] = temp[6]
    kx[0,2] = temp[7]
    kx[1,2] = temp[8]
    kx[0,3] = temp[9]
    
    temp=kk#transpose(x[1,*])
    ky = fltarr(n+1,n+1)
    ky[0,0] = temp[0]
    ky[1,0] = temp[1]
    ky[2,0] = temp[2]
    ky[3,0] = temp[3]
    ky[0,1] = temp[4]
    ky[1,1] = temp[5]
    ky[2,1] = temp[6]
    ky[0,2] = temp[7]
    ky[1,2] = temp[8]
    ky[0,3] = temp[9]
endelse

end
