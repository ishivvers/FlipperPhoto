pro check_rotse3a_doughnuts,conf,stat,chi_th=chi_th

if n_params() eq 0 then begin
    print,'syntax- check_rotse3a_doughnuts,conf,stat,chi_th=chi_th'
    return
endif

if (n_elements(chi_th) eq 0) then chi_th = 5.0

im=readfits(conf.cimg)
cal=mrdfits(conf.cobj,2)

sub_sky,im,cal.sky,newim
ctr=[1020,1025]

;; take 512x512 central subregion
sub=newim[ctr[0]-256:ctr[0]+255,ctr[1]-256:ctr[1]+255]


;; do the fft's
pow1=fltarr(n_elements(sub[0,*]))

for i=0l,n_elements(pow1)-1 do begin
    ft=fft(sub[i,*],-1)
    pow1=pow1+abs(ft)
endfor

pow2=fltarr(n_elements(sub[*,0]))
for i=0l,n_elements(pow2)-1 do begin
    ft=fft(sub[*,i],-1)
    pow2=pow2+abs(ft)
endfor


xvals=findgen(n_elements(pow1))

yvals1=alog10(pow1)
yerrs1=0.05*yvals1
fit1=linfit(xvals[2:99],yvals1[2:99],measure_errors=yerrs1[2:99],chisq=chisq1,/double)

yvals2=alog10(pow2)
yerrs2=0.05*yvals2
fit2=linfit(xvals[2:99],yvals2[2:99],measure_errors=yerrs2[2:99],chisq=chisq2,/double)

if (chisq1 gt chi_th and chisq2 gt chi_th) then begin
    ;; this is a doughnut image
    print,'Doughnuts observed.  Creating flag file'

    cmd = 'touch '+conf.workdir+'/DOUGHNUT_FLAG'
    spawn,cmd
endif



return
end
