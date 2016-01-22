pro auto_star_psf,fname,psname

if n_params() lt 2 then begin
    print,'syntax- auto_star_psf,fname,psname'
    return
endif

im = readfits(fname)

im=im[50:2000,50:2000]
;;im=im[500:1500,500:1500]

nx = n_elements(im[*,0])
ny = n_elements(im[0,*])

m=max(im,msub)
mx = msub mod nx
my = long(msub / nx)

sub=im[(mx-10):(mx+10),(my-10):(my+10)]

begplot,name=psname,/landscape,/color

star_psf,sub,fwhm,/plot

endplot

pslandfix,psname

end
