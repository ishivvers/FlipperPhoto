FUNCTION mags2jy, mags, sloan=sloan, filters=filters

filset = ['R','r','B','V','I','J','H','K','g','i','z']

nuset = [ 4.68e14, 4.825e14, 6.87e14, 5.50e14, 3.76e14, 2.457e14, 1.839e14, 1.368e14, 6.316e14, 3.93e14, 3.306e14]
;; BVRI from Bessell (1979), JHK probably Bessell&Brett(1988)

zptB = 4.26e3
zptV = 3.64e3
zptR = 3.08e3
zptI = 2.55e3
zptJ = 1.57e3
zptH = 1.02e3
zptK = 6.36e2
zptsdss=3631.
zpset = [zptR, zptsdss, zptB, zptV, zptI, zptJ, zptH, zptK, zptsdss, zptsdss, zptsdss]

nset=n_elements(zpset)

;;      Zpts converted to Jy, from Bessell(1979) &
;;      Bessell&Brett(1988) for BVRIJHK

;; all Sloan from the SDSS website and Smith et al 2002

if N_params() lt 1 then begin
    print, "syntax: mags2jy(mags, sloan=sloan, filters=filters)"
print, "  it returns a matrix of (Jansky,effective freqency)"
    print, "  /sloan does all as sloan r, filters must give a vector of BVRIJHKgriz tags, and nothing gives Bessell R"
    return, 0
end

nmag=n_elements(mags)
dat = fltarr(nmag,2) -99.

if not(keyword_set(sloan)) then begin

;; if /sloan ALL sloan r, else check for filters


    if n_elements(filters) NE nmag then begin

;; if no override vactor of filters, ALL are Bessell R

        print, "doing the default - all at Bessell R"

        dat[*,1] = nuset[0]
        dat[*,0] = zpset[0]*10.^(-0.4*mags)

        return, dat

    endif else begin

        print, "doing by the input filters"

        for i=0, nmag-1 do begin
            for j=0, nset-1 do begin
                if (strcmp(filters[i],filset[j])) then begin
                    dat[i,1] = nuset[j]
                    dat[i,0] = zpset[j]*10.^(-0.4*mags[i])
                endif
            endfor
        endfor

        return, dat

    endelse

endif else begin

    print, "doing all as sloan r"

    dat[*,1] = nuset[1]
    dat[*,0] = zpset[1]*10.^(-0.4*mags)

    return, dat

endelse

return, -1

end

