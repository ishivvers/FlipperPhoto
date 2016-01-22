pro usnoreadb,ra,dec,size,cat,save=save,fname=fname,rphot=rphot,maglim=maglim,fail=fail

if n_params() eq 0 then begin
    print,'syntax- usnoreadb,ra,dec,size,cat,save=save,fname=fname,rphot=rphot,maglim=maglim,fail=fail'
    return
endif

if keyword_set(rphot) then save = 1
if n_elements(maglim) eq 0 then maglim=30.0   ;; crop 99's

fail=0

tilesize=0.17  ;; this is 10 arcminutes per chunk
ratilesize=tilesize/cos(dec*0.01745)

if n_elements(fname) eq 0 then begin
    fname = 'usnob_'
    
    ras=sixty(ra/15.0)
    fname = fname + string(fix(ras[0]),format='(i2.2)') + string(fix(ras[1]),format='(i2.2)')
    
    sign = '+'
    if (dec lt 0) then sign = '-'
    decs=sixty(abs(dec))
    fname = fname + sign + string(fix(decs[0]),format='(i2.2)') + string(fix(decs[1]),format='(i2.2)')
    
    if (keyword_set(rphot)) then fname=fname+'.dat' else fname=fname+'.fit'

endif

if (not keyword_set(rphot)) then begin
    test=findfile(fname,count=ct)
    if ct gt 0 then begin
        print,'Catalog found: '+test[0]
        cat=mrdfits(test[0],1)
        
        ;; then, we'll need to check if it's big enough...otherwise, start from scratch
        decrange = max(cat.dej2000)-min(cat.dej2000)
        if (decrange gt size * 2) then begin
            return
        endif else begin
            print,'Current catalog not large enough.  Extracting larger catalog'
        endelse
    endif
endif


decliml=dec-size
declimh=dec+size
raliml=ra-(size/cos(dec*0.01745))
ralimh=ra+(size/cos(dec*0.01745))

nratiles=ceil((ralimh-raliml)/ratilesize)
ndectiles=ceil((declimh-decliml)/tilesize)


if nratiles eq 1 then begin
    ratiles=[ra]
endif else begin
    nrts = (ralimh-raliml)/nratiles
    ratiles=(findgen(nratiles)/(nratiles-1))*(ralimh-raliml-nrts)+raliml+nrts/2.
endelse

if ndectiles eq 1 then begin
    dectiles=[dec]
endif else begin
    ndts = (declimh-decliml)/ndectiles
    dectiles=(findgen(ndectiles)/(ndectiles-1))*(declimh-decliml-ndts)+decliml+ndts/2.
endelse

started = 0
for i=0l,n_elements(ratiles)-1 do begin
    for j=0l,n_elements(dectiles)-1 do begin
        this_ubcat = queryusno_b(ratiles[i],dectiles[j],tilesize*60.)
        ;print,'read stars:', n_elements(this_ubcat)
        if (not started) then begin
            ubcat = this_ubcat
            started = 1
        endif else begin
            ubcat = [ubcat,this_ubcat]
        endelse
    endfor
endfor

;; remove duplicates
if (size(ubcat,/type) ne 8) then begin
    ;; we didn't get a structure back
    fail=1
    return
endif

ids=ubcat.id
s=uniq(ids,sort(ids))
cat=ubcat[s]

if n_elements(maglim) gt 0 then begin
    h=where(cat.r2mag lt maglim,nh)
    if (nh gt 0) then begin
        cat=cat[h]
    endif else begin
        print,'no stars pass limit cut.  Using all stars.'
    endelse
endif

;; finally, save it if necessary

if keyword_set(save) then begin
    if keyword_set(rphot) then begin
        openw,lun,fname,/get_lun
        printf,lun,';;R2'
        printf,lun,';;      RA        DEC    Rmag   emag'
        for i=0l,n_elements(cat)-1 do begin
            printf,lun,cat[i].raj2000,cat[i].dej2000,cat[i].r2mag,0.01,0.0, $
              format='(d,d,f,f,f)'
        endfor
        free_lun,lun
    endif else begin
        ;; normal fits file
        mwrfits,cat,fname,/create
    endelse
endif



return
end
