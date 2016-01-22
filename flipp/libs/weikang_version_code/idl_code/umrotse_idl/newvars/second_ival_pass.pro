PRO second_ival_pass, iv, nsig, mn_iter=mn_iter

chk = where(iv.iflag EQ 1, nc)

IF nc GT 0 THEN BEGIN 
    FOR i=0,nc-1 DO BEGIN 
        ix = chk[i]
        g = where(iv[ix].good EQ 1, ng)
        IF ng GT 0 THEN BEGIN
            mags = iv[ix].m[g]
            merr = iv[ix].mwholerr[g]
            pair1=indgen(n_elements(mags)/2.0)*2.0
            pair2=pair1+1
            devsq = (mags - iv[ix].mavg)^2
            bigdev = max(devsq,imax)
            
            y = where(pair1 NE imax,ny)
            IF ny EQ n_elements(pair1) THEN y = where(pair2 NE imax,ny)
            z = [pair1[y],pair2[y]]
            zz = sort(z)
            z = z[zz]
            mags = mags[z]
            merr = merr[z]
            
            iv[ix].ival = ivalue3(mags,merr,mn_iter=mn_iter)
        ENDIF 
    ENDFOR 
ENDIF 

END
