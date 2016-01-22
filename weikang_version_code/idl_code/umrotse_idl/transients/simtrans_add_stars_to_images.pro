pro simtrans_add_stars_to_images,imnames,nburst,ofile,addstars,timerange=timerange,pkrange=pkrange,alpharange=alpharange,simtransdir=simtransdir,templatedir=templatedir

if n_params() eq 0 then begin
    print,'syntax- simtrans_add_stars_to_images,imnames,nburst,ofile,addstars,timerange=timerange,pkrange=pkrange,alpharange=alpharange,templatedir=templatedir'
    return
endif

if n_elements(simtransdir) eq 0 then simtransdir = '.'
if n_elements(templatedir) eq 0 then templatedir = '.'
;;if n_elements(timerange) ne 2 then timerange = [60., 3600.0]
if n_elements(timerange) ne 2 then timerange = [60.,1800.0]
if n_elements(pkrange) ne 2 then pkrange = [11.0, 15.1]
if n_elements(alpharange) ne 2 then alpharange = [0.5,1.5]

test=findfile('-d '+simtransdir,count=ct)
if (ct eq 0) then begin
    print,'simtransdir '+simtransdir+' does not exist.  Exiting.'
    return
endif

elt = create_struct('ra', 0d, $
                    'dec', 0d, $
                    'dtime', 0.0, $
                    'pk', 0.0, $
                    'alpha', 0.0, $
                    'fnames', strarr(n_elements(imnames)), $
                    'mags', strarr(n_elements(imnames)), $
                    'm_lim', fltarr(n_elements(imnames)), $
                    'found', -1)

addstars=replicate(elt,nburst)

hdr=headfits(imnames[0])
ramin=sxpar(hdr,'CRVAL1')-0.8
ramax=ramin+0.85*2.
decmin=sxpar(hdr,'CRVAL2')-0.8
decmax=decmin+0.85*2.

seed = long(systime(/seconds))
dtime = randomu(seed,nburst) * (timerange[1]-timerange[0]) + timerange[0]
pks = randomu(seed,nburst) * (pkrange[1] - pkrange[0]) + pkrange[0]
alphas = randomu(seed,nburst) * (alpharange[1] - alpharange[0]) + alpharange[0]

;;ras=randomu(seed,nburst) * (ramax - ramin) + ramin
;;decs=randomu(seed,nburst) * (decmax - decmin) + decmin

;; generate Ra/dec pairs that don't match objects already there
;; (we'll take this inefficiency out of the overall area coverage)

parts=strsplit(imnames[0],'_',/extract)
histname = templatedir + '/history/' + parts[1] + '_' + strmid(parts[2],0,2) + '_history.fit'
hstr=mrdfits(histname,1,hhdr,status=status)
if (status ne 0) then begin
    print,'no history for this frame...well, we will not find any transients that is for sure...'
    print,'just adding stars, what the hell.'
    ras=randomu(seed,nburst) * (ramax - ramin) + ramin
    decs=randomu(seed,nburst) * (decmax - decmin) + decmin
endif else begin
    ;; find nburst ra/decs that don't match the history (or the match
    ;; structure?)
    ras = dblarr(nburst)
    decs = dblarr(nburst)
    i=0
    ctr = 0
    while (i lt nburst and ctr lt 1000) do begin
        testra=randomu(seed,1) * (ramax - ramin) + ramin
        testdec=randomu(seed,1) * (decmax - decmin) + decmin
        
        close_match_radec,testra,testdec,hstr.ra,hstr.dec,m1,m2,0.0009d*5d,1,/silent
        if (m1[0] eq -1) then begin
            ;; we have a miss
            ras[i] = testra
            decs[i] = testdec
            i = i+1
        endif
        ctr=ctr+1
    endwhile
    
    if (ctr eq 1000) then begin
        print,'We have a serious problem, people.'
        return
    endif
endelse


mjds=dblarr(n_elements(imnames))
times=fltarr(n_elements(imnames))

for i=0l,n_elements(imnames)-1 do begin
    hdr=headfits(imnames[i])
    mjds[i] = sxpar(hdr,'MJD')
endfor

times = (mjds - min(mjds))*24.*60.*60.

allmags=fltarr(nburst,n_elements(imnames))

for i=0l,nburst-1 do begin

    simtrans_calc_mags,times+dtime[i],pks[i],mags,alpha=alphas[i]
    allmags[i,*] = mags

    ;; stuff the structure
    addstars[i].ra = ras[i]
    addstars[i].dec = decs[i]
    addstars[i].dtime = dtime[i]
    addstars[i].pk = pks[i]
    addstars[i].alpha = alphas[i]
    addstars[i].mags = mags

endfor

for j=0l,n_elements(imnames)-1 do begin
    simtrans_add_stars,imnames[j],ras,decs,allmags[*,j],outname_root,m_lim,simtransdir=simtransdir
    addstars[*].fnames[j] = outname_root + '_c.fit'
    addstars[*].m_lim[j] = m_lim
endfor

parts=strsplit(outname_root,'_',/extract)
ofile = simtransdir + '/' + parts[0] + '_' + parts[1] + '_addstars.fit'

;; write out the fits with the information
mwrfits,addstars,ofile,/create


return
end
