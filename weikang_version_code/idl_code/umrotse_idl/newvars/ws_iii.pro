PRO ws_iii, mat, ival, use_flags=use_flags, use_rflags=use_rflags, mn_iter=mn_iter,numdev=numdev,save=save,over=over,dir=dir,nostrip=nostrip,init=init,matname=matname,necobs=necobs,rephase=rephase

IF n_params() GT 0 THEN BEGIN 
    IF NOT keyword_set(use_flags)  THEN use_flags  = [0,0,1,1,1,1,1,1]
    IF NOT keyword_set(use_rflags) THEN use_rflags = [0,0,1,1,0,0,0]
    IF NOT keyword_set(mn_iter) THEN mn_iter = 5
    IF NOT keyword_set(numdev) THEN numdev = 3.0
    IF keyword_set(matname) THEN mat = mrdfits(matname,1) $
    ELSE matname='noname'
    IF NOT keyword_set(necobs) THEN necobs = 10
    

    nobs = mat.nobs
    nobj = mat.nobj
    newi = lindgen(nobj)
        
    IF keyword_set(init) OR datatype(ival) NE 'STC' THEN BEGIN 
        print, 'Initializing ival structure'
        ival = init_ival(mat,use_flags,use_rflags,matname) 
    ENDIF ELSE BEGIN 
        nobj = n_elements(ival)
        newi = ival.index
    ENDELSE 

    IF keyword_set(rephase) THEN ival.freq = 1.0

    FOR iobj=0l,nobj-1l DO BEGIN
        ix = where(ival.index EQ newi[iobj])
        ix = ix[0]
        IF ival[ix].ngd GT necobs AND ival[ix].iflag EQ 0 THEN BEGIN 
            flt = where(ival[ix].good EQ 1)
            mags = mat.m[flt,ix]
            merr = ival[ix].mwholerr[flt]
            ival[ix].iflag = 1
            ival[ix].ival = ivalue3(mags,merr,mn_iter=mn_iter)
        ENDIF
    ENDFOR
        
    idone = where(ival.iflag EQ 1,ndone)
    
    assign_sigma, ival
        
    print, 'Tagging ivalues with values gt ',numdev,'*sigma'
    find_high_ival,ival,numdev
        
    print, 'Eliminating single outliers'
    second_ival_pass,ival,numdev,mn_iter=mn_iter
    find_high_ival,ival,numdev
        
    print, 'Phasing high ivalue light curves'
    top = where(ival.tophase GT 1,ntp)
    FOR it=0,ntp-1 DO BEGIN 
        IF ival[top[it]].freq NE 0.0 THEN BEGIN 
            got = where(ival[top[it]].good EQ 1)
            find_this_phase,mat.jd[got],ival[top[it]].m[got],ival[top[it]].mwholerr[got], f, c
            ival[top[it]].freq = f
            ival[top[it]].chi = c
            calc_phases, ival, top[it], got[0], mat.jd[0:nobs-1]
        ENDIF 
    ENDFOR
        
    IF NOT keyword_set(nostrip) AND ndone GT 0 THEN ival = ival[idone]
    
    IF keyword_set(save) OR keyword_set(over) THEN BEGIN 
        IF keyword_set(dir) THEN outname = dir+'/'+ival[0].name ELSE outname=ival[0].name
        openr, mlun, outname, /get_lun, error=iferr
        IF NOT iferr THEN BEGIN 
            close, mlun
            free_lun, mlun
        ENDIF 
        IF keyword_set(save) AND NOT iferr THEN print, 'Error: file ',outname,' exists.' $
        ELSE BEGIN 
            IF ndone GT 0 THEN BEGIN 
                print, 'Writing file ', outname
                mwrfits, ival, outname, /create
            ENDIF ELSE print, 'No ivalues calculated for ', outname
        ENDELSE    
    ENDIF 
ENDIF ELSE print, 'Syntax: ws_iii, mat, ival, use_flags=use_flags, use_rflags=use_rflags, mn_iter=mn_iter,numdev=numdev,save=save,over=over,dir=dir,nostrip=nostrip,init=init,matname=matname'
END 
