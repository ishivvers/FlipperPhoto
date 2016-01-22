pro henden_list,file,filter,outfile,satmag=satmag,tol=tol
COMPILE_OPT IDL2

;; this procedure takes the photometry file supplied by Henden, and
;; converts it into something RPHOT can use.

if n_elements(satmag) eq 0 then satmag=13.5
if n_elements(tol) eq 0 then tol=0.002


if N_params() ne 3 then begin
    print,'Syntax - henden_list,infile,filter,outfile
    return
endif

;; assumed format of Henden file:
;;
;;#  Name    RA(J2000)   raerr  DEC(J2000)  decerr  nobs   V     B-V     U-B     V-R     R-I     Errors
;;GRB030723  327.264770  0.014 -27.697215  0.025    2 17.135  0.995 99.999  0.640  0.459  0.018  0.023  9.999  0.012  0.01

readcol,file,name,ra,era,dec,edec,nobs,vmag,bmv,umb,vmr,rmi,evmag,ebmv,eumb,evmr,ermi,format='(a,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d)',/silent

case filter of
    'U': begin
        print,"can't do U band yet"
    end
    'V': begin
        w=where(vmag lt 99 and evmag lt 9,nw)
        mag=vmag[w]
        emag=abs(evmag[w])
    end
    'B': begin
        w=where(vmag lt 99 and evmag lt 9 and bmv lt 99 and ebmv lt 9,nw)
        mag=vmag[w]+bmv[w]
        emag=sqrt(evmag[w]^2.0 + ebmv[w]^2.0)
    end
    'R': begin
        w=where(vmag lt 99 and evmag lt 9 and vmr lt 99 and evmr lt 9,nw)
        mag=vmag[w]-vmr[w]
        emag=sqrt(evmag[w]^2.0 + evmr[w]^2.0)
    end
    'I': begin
        print,"can't do I band yet"
    end
endcase
ra=ra[w]
dec=dec[w]

temp={ ra: 0d, dec:0d, mag:0.0, emag:0.0, vmr: 0.0 }
n=n_elements(ra)
calibs=replicate(temp,n)
calibs.ra=ra
calibs.dec=dec
calibs.mag=mag
calibs.emag=emag
calibs.vmr=vmr
wkeep=intarr(n)
for i=0,n-1 do begin
    ;; remove saturated stars and ROTSE blends
    dist=sqrt((ra-ra[i])^2.0 + (dec-dec[i])^2.0)
    w=where(dist ne 0 and dist lt tol,nw)
    if nw eq 0 and calibs[i].mag gt satmag then wkeep[i]=1
endfor
w=where(wkeep eq 1,nw)
calibs=calibs[w]

;;stop

;; write the output
openw,lun,outfile,/get_lun
printf,lun,filter
printf,lun,'V-R'
printf,lun,'RA','DEC',strtrim(filter,2)+'mag','emag','V-R',format='(a10,a12,a8,a7,a8)'
for i=0,nw-1 do begin
    printf,lun,calibs[i].ra,calibs[i].dec,calibs[i].mag,calibs[i].emag,calibs[i].vmr,format='(d10.6,d12.6,d8.3,d7.3,f8.3)'
endfor
close,lun
free_lun,lun

end


