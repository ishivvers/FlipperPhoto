pro rotse_igm_absorption,z,frac,magoffset,responsefile=responsefile,igmfile=igmfile,beta=beta,plot=plot

if n_params() eq 0 then begin
    print,'syntax- rotse_igm_absorption,z,frac,magoffset,responsefile=responsefile,igmfile=igmfile,beta=beta,plot=plot'
    return
endif

;; uses data from Meiksin A., 2005, MNRAS, 365, 807 in any publications using these results.


;;update this
;;if n_elements(responsefile) eq 0 then
;;responsefile='/home/erykoff/idl.lib/ccd_response/rotse_response.dat'
if n_elements(responsefile) eq 0 then responsefile='/products/idltools/umrotse_idl/tools/igm/rotse_response.dat'

if n_elements(beta) eq 0 then beta=-0.75

readcol,responsefile,respwavelength,resp,/silent
respwavelength=respwavelength*10.

igm_transmission,z,wavelength,trans,file=igmfile

wavelength=[wavelength,10000.]
trans=[trans,1.0]

linterp,respwavelength,resp,wavelength,newresp

respigm=newresp*trans

if keyword_set(plot) then begin
    plot,wavelength,trans,xrange=[2000,10000]
    oplot,wavelength,newresp
    oplot,wavelength,respigm,color=255L

endif


nu=3e8/(wavelength*1e-10)

fd=nu^beta
fd=fd/max(fd)

tempnu=nu
tempfd=fd
tempresp=newresp
all=int_tabulated(tempnu,tempfd*tempresp,/double,/sort)

tempnu=nu
tempfd=fd
tempresp=respigm
some=int_tabulated(tempnu,tempfd*tempresp,/double,/sort)

frac=some/all

magoffset=2.5*alog10(frac)


return
end
