function ss_cross_convolve_spline,im1_conv,im2_conv,mask,r4_weight,sopath=sopath,n_convolve=n_convolve,ikernels=ikernels,coeff1=coeff1,coeff2=coeff2

if n_elements(n_convolve) eq 0 then n_convolve=9l
nch=long(n_convolve)/2l
nc=2l*nch+1l
nc2=n_convolve^2

if n_elements(sopath) eq 0 then sopath="./"

w_image=(size(im1_conv))[1]
h_image=(size(im1_conv))[2]

mask[0:nch-1,0:h_image-1]=0b
mask[w_image-nch:w_image-1,0:h_image-1]=0b
mask[0:w_image-1,0:nch-1]=0b
mask[0:w_image-1,h_image-nch:h_image-1]=0b

if n_elements(ikernels) eq 0 then begin
    ikernels=ss_make_spline_kernels_2()
endif

nk=(size(ikernels))[3]

xoff=(reform(lindgen(nc2),nc,nc) mod nc)-nch
yoff=reform(lindgen(nc2),nc,nc)/nc-nch

;fill the matrix
matrix11=dblarr(nk,nk)
matrix22=dblarr(nk,nk)
matrix21=dblarr(nk,nk)
indmask=where(mask eq 1,nmask)

;call C module to fill the half matrix.
tst=findfile(sopath+'/smhmatrix.so',count=nso)
if nso lt 1 then begin
    make_dll,'smhmatrix','smhmatrix','smhmatrix',/verbose,compile_directory=sopath
endif
s=call_external(sopath+'/smhmatrix.so','smhmatrix', double(im1_conv), $
                double(im2_conv),long(indmask),long(nmask),long(n_convolve), $
                double(r4_weight),long(w_image),long(h_image),long(nk), $
                long(xoff),long(yoff),double(ikernels),matrix11,matrix22, $
                matrix21)

matrix12=transpose(matrix21)
s1=dblarr(nk-1)
s2=dblarr(nk-1)

;       Apply unitarity condition to both convolutions.

totvec=fltarr(nk)
for itv=0,nk-1 do totvec[itv]=total(ikernels[*,*,itv])

for j=1,nk-1 do begin
    matrix11[*,j]=matrix11[*,j]-matrix11[*,0]*totvec[j]/totvec[0]
    matrix21[*,j]=matrix21[*,j]-matrix21[*,0]*totvec[j]/totvec[0]
    matrix12[*,j]=matrix12[*,j]-matrix12[*,0]*totvec[j]/totvec[0]
    matrix22[*,j]=matrix22[*,j]-matrix22[*,0]*totvec[j]/totvec[0]
endfor
for j=1,nk-1 do begin
    matrix11[j,*]=matrix11[j,*]-matrix11[0,*]*totvec[j]/totvec[0]
    matrix21[j,*]=matrix21[j,*]-matrix21[0,*]*totvec[j]/totvec[0]
    matrix12[j,*]=matrix12[j,*]-matrix12[0,*]*totvec[j]/totvec[0]
    matrix22[j,*]=matrix22[j,*]-matrix22[0,*]*totvec[j]/totvec[0]

    s1[j-1]=-matrix11[0,j]/totvec[0]-matrix21[0,j]/totvec[0]
    s2[j-1]=-matrix12[0,j]/totvec[0]-matrix22[0,j]/totvec[0]
endfor

matrix11=matrix11[1:nk-1,1:nk-1]
matrix22=matrix22[1:nk-1,1:nk-1]
matrix21=matrix21[1:nk-1,1:nk-1]
matrix12=matrix12[1:nk-1,1:nk-1]


matrix=[[matrix11,matrix21],[matrix12,matrix22]]
s=[s1,s2]

svdc,matrix,w,u,v,/double
cond_number=max(abs(w))/min(abs(w))
t=svsol(u,w,v,s,/double)

co1=(1d0-total(totvec[1:nk-1]*t[0:nk-2]))/totvec[0]
co2=(1d0-total(totvec[1:nk-1]*t[nk-1:nk*2-3]))/totvec[0]

coeff1=[co1,t[0:nk-2]]
coeff2=[co2,t[nk-1:nk*2-3]]


return,cond_number

end
