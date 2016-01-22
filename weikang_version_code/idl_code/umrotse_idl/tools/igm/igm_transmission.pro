pro igm_transmission,z,wavelength,trans,file=file,plot=plot

if n_params() eq 0 then begin
    print,'syntax- igm_transmission,z,wavelength,trans,file=file,plot=plot'
    return
endif

;; update this
;;if n_elements(file) eq 0 then
;;file='/home/erykoff/idl.lib/igm_transmission/igm_transmission.fit'
if n_elements(file) eq 0 then file='/products/idltools/umrotse_idl/tools/igm/igm_transmission.fit'

igm=mrdfits(file,1)

nlam=n_elements(igm.wavelength)
wavelength=igm.wavelength

if (z lt min(igm.z)) then begin
    print,'No loss'
    trans=fltarr(nlam)+1.0
    return
endif

test=igm.z-z
use=where(test gt 0)

mind=use[0]
;;print,igm.z[mind]

;; find the features
t1=reform(igm.trans[mind,0:nlam-2])
t2=shift(t1,1)
delta=t2-t1
;; a feature is where there's inflection and the change is > 1%
feat=where(delta lt 0 and abs(delta)/t1 gt 0.05,nfeat)

trans=fltarr(nlam)



offsetlo=(1.+igm.z[mind-1])/(1.+z)
offsethi=(1.+igm.z[mind])/(1.+z)

bad=bytarr(nlam)

for i=0l,nlam-1 do begin
    w=wavelength[i]
    wlo=long(w*offsetlo)
    whi=long(w*offsethi)
    
    lo=where(wlo eq wavelength,nlo)
    hi=where(whi eq wavelength,nhi)
    if (nlo eq 0) then begin
        ;; check this
;;        trans[i] = 0.0
        bad[i] = 1
    endif else if (nhi eq 0) then begin
        trans[i] = 1.0
    endif else begin
        m=(igm.trans[mind-1,lo]-igm.trans[mind,hi])/(wlo-whi)
        trans[i]=igm.trans[mind-1,lo]+m*(wavelength[i]-w*offsetlo)
    endelse
endfor

h=where(bad eq 1,nbad)
if (nbad gt 0) then begin
    gd=where(bad eq 0)
    trans[h] = trans[gd[0]]
endif

;; extra
if (keyword_set(plot)) then begin
    plot,igm.wavelength,igm.trans[mind-1,*]
    oplot,igm.wavelength,igm.trans[mind,*],color=255L
    
    oplot,wavelength,trans,color=255l*256L
endif


return
end
