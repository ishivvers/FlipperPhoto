pro update_sky_history,templatedir,matchname,mingood=mingood

if n_params() eq 0 then begin
    print,'syntax- update_sky_history,templatedir,matchname,mingood=mingood'
    return
endif

if n_elements(mingood) eq 0 then mingood = 8

test=findfile(matchname,count=ct)
if (ct eq 0) then begin
    print,'Matchfile not found'
    return
endif

;; read in match structure
mt=mrdfits(matchname,1)

dirparts=strsplit(matchname,'/',/extract)
parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)

histname = templatedir + '/history/' + parts[0] + '_' + parts[1] + '_history.fit'

test=findfile(histname,count=ct)

elt=create_struct('ra',0d, $
                  'dec', 0d, $
                  'mavg', 0.0, $
                  'mstd', 0.0, $
                  'ngood', 0l)

rewrite_history = 0

if (ct eq 0) then begin
    ;; we do not have a history file
    rewrite_history = 1

    ;; we can use the ngood because it's defined as the flags =0,2 and mag > 0
    ;; and mag < 30.  This is sufficient if the match structure is made with
    ;; good pos_sigma observations and other quality cuts

    newobj = where(mt.ngood ge mingood,newct)

    print,'new:', newct

    norig = 0
    m1 = -1

    sxaddpar,hhdr,'LASTMJD',max(mt.jd)+0.5  ;; add half day cushion
    sxaddpar,hhdr,'MATNAME',matchname
    sxaddpar,hhdr,'RA_LOW',0d
    sxaddpar,hhdr,'RA_HIGH',0d
    sxaddpar,hhdr,'DEC_LOW',0d
    sxaddpar,hhdr,'DEC_HIGH',0d
    sxaddpar,hhdr,'M_LIM',0.0

endif else begin
    ;; we already have a history file

    hstr_orig = mrdfits(histname,1,hhdr)
    last_mjd = sxpar(hhdr,'LASTMJD')
    sxaddpar,hhdr,'LASTMJD',max(mt.jd)+0.5  ;; add half day cushion


    close_match_radec,mt.ra[0:mt.nobj-1],mt.dec[0:mt.nobj-1], $
      hstr_orig.ra,hstr_orig.dec,mm1,mm2,0.0009d,5,miss

    close_match_radec,hstr_orig.ra,hstr_orig.dec,mt.ra[0:mt.nobj-1], $
      mt.dec[0:mt.nobj-1],m1,m2,0.0009d,1

    norig=n_elements(hstr_orig)

    newct = 0
    if (miss[0] ne -1) then begin
        newobjtemp = where(mt.ngood[miss] ge mingood,newct)
        if (newct gt 0) then newobj = miss[newobjtemp]
    endif
    print,'new: ',newct
endelse
ctr=0

if ((newct eq 0) and (norig eq 0)) then begin
   print,'No history, and not enough in the match structure to build one.'
   return
endif

;; now deal with appends/news
if (newct gt 0) then begin
    nnew = norig + newct
 
    hstr_temp = replicate(elt,nnew)
    huse_arr = bytarr(nnew)

    if (norig gt 0) then begin
        hstr_temp[0:norig-1] = hstr_orig
        huse_arr[0:norig-1] = 1
    endif

    for i=0l,newct-1 do begin
        mobj = newobj[i]
        hobj = norig + i

        newgd=where(((mt.flags[*,mobj] eq 0) or $
                     (mt.flags[*,mobj] eq 2)) and $
                    (mt.m[*,mobj] gt 0.0) and $
                    (mt.m[*,mobj] lt 30.0), nct)

        if (nct gt 0) then begin
            ra=total(double(mt.dra[newgd,mobj])/1000000.0d,/double)/nct
            dec=total(double(mt.ddec[newgd,mobj])/1000000.0d,/double)/nct

            check=where(huse_arr eq 1,ncheck)
            if (ncheck gt 0) then begin
                close_match_radec,ra,dec,hstr_temp[check].ra,hstr_temp[check].dec,mm1,mm2,0.0009d,1,/silent
            endif else begin
                ;; it's like a non-match
                mm1 = -1
            endelse
            if (mm1 eq -1) then begin
                rewrite_history = 1

                hstr_temp[hobj].ra = ra
                hstr_temp[hobj].dec = dec
                hstr_temp[hobj].mavg = total(mt.m[newgd,mobj])/nct
                hstr_temp[hobj].mstd = stddev(mt.m[newgd,mobj])
                hstr_temp[hobj].ngood = nct

                huse_arr[hobj] = 1
            endif else begin
                print,'object ',mobj,' matches item in list'
                ctr=ctr+1
            endelse
        endif else begin
            ;; this is no longer a problem
            print,'bad object'
        endelse


    endfor
endif else if (norig gt 0) then begin
    hstr_temp = hstr_orig

    huse_arr = bytarr(n_elements(hstr_temp))
    huse_arr[*] = 1
endif

use=where(huse_arr eq 1,uct)
if (uct eq 0) then begin
    print,'no objects?'
    return
endif
hstr=hstr_temp[use]
print,'matched: ', ctr
print,'total: ',uct
test = 1
if (test eq 1) then begin

if ((norig gt 0) and (m1[0] ne -1)) then begin
    ;; matched objects-- update the numbers
    for i=0l,n_elements(m1)-1 do begin
        hobj = m1[i]
        mobj = m2[i]
        newgd=where(((mt.flags[*,mobj] eq 0) or $
                     (mt.flags[*,mobj] eq 2)) and $
                    (mt.m[*,mobj] gt 0.0) and $
                    (mt.m[*,mobj] lt 30.0) and $
                    (mt.jd[*] gt last_mjd),nct)
        if (nct gt 0) then begin
            rewrite_history = 1

            nobs_orig = hstr_orig[hobj].ngood
            nobs_new = nobs_orig + nct
            
            hstr[hobj].ra = (hstr_orig[hobj].ra * nobs_orig + $
                             total(double(mt.dra[newgd,mobj])/1000000.0d,/double))/nobs_new
            hstr[hobj].dec = (hstr_orig[hobj].dec * nobs_orig + $
                              total(double(mt.ddec[newgd,mobj])/1000000.0d,/double))/nobs_new
            hstr[hobj].mavg = (hstr_orig[hobj].mavg * nobs_orig + $
                               total(mt.m[newgd,mobj]))/nobs_new
            hstr[hobj].mstd = sqrt((nobs_orig * (hstr_orig[hobj].mstd^2.) + $
                                    total((mt.m[newgd,mobj]-hstr[hobj].mavg)^2.))/nobs_new)
            hstr[hobj].ngood = nobs_new
        endif
    endfor
endif

endif


;; rewrite the history structure if we need to
if (rewrite_history) then begin
    print,'Updating header values'

    ra_low=min(hstr.ra)
    ra_high=max(hstr.ra)
    dec_low=min(hstr.dec)
    dec_high=max(hstr.dec)

    smag=hstr[sort(hstr.mavg)].mavg
    h=where(smag lt 25 and smag gt 5, n)
    m_lim = smag[h[n*0.9]]

    sxaddpar,hhdr,'RA_LOW',ra_low
    sxaddpar,hhdr,'RA_HIGH',ra_high
    sxaddpar,hhdr,'DEC_LOW',dec_low
    sxaddpar,hhdr,'DEC_HIGH',dec_high
    sxaddpar,hhdr,'M_LIM',m_lim

    print,'Re-writing history'
    mwrfits,hstr,histname,hhdr,/create
endif


return
end

