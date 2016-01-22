FUNCTION init_ival, m, uf, urf, matnam

nobs = m.nobs
nobj = m.nobj
parts = str_sep(m.imagename[0],'_')
name = parts[1]+'_'+strmid(parts[2],0,2)+'_ival.fit'

i = create_struct('index',0l,'mavg',0.0,'m',fltarr(nobs),'msig',0.0,'siglim',0.0, $
                  'good',bytarr(nobs),'ival',0.0,'iflag',byte(0),'ngd',0, $
                  'freq',1.0,'tophase',byte(0),'mwholerr',fltarr(nobs),'name',name,$
                  'phase',dblarr(nobs), 'tzero',double(0.0),'n',intarr(nobs),$
                  'ra', 0.0, 'dec', 0.0, 'matname', matnam,'chi',0.0)
iv = replicate(i,nobj)

FOR iobj=0l,nobj-1l DO BEGIN
    iv[iobj].index = iobj
    iv[iobj].ra = m.ra[iobj]
    iv[iobj].dec = m.dec[iobj]
    iv[iobj].m = m.m[0:nobs-1,iobj]
    iv[iobj].tzero = m.jd[0]
    iv[iobj].mwholerr=sqrt(m.merr[0:nobs-1,iobj]^2 + (float(m.msys[0:nobs-1,iobj])/200.)^2)
    iv[iobj].good = good_robs(m, iobj, uf, urf)
    ifilt = where(iv[iobj].good NE 0, n)
    IF n GT 0 THEN BEGIN 
        iv[iobj].ngd = n
        iv[iobj].mavg = weight_mean(iv[iobj].m[ifilt],iv[iobj].mwholerr[ifilt])
        iv[iobj].msig = find_sigma(iv[iobj].m[ifilt], iv[iobj].mavg)
    ENDIF 
    calc_phases, iv, iobj, 0, m.jd[0:nobs-1]
ENDFOR 
return, iv
END
