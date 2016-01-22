pro photom_local,fnames,ra,dec,lcs,uucat_name=uucat_name,imagepath=imagepath,cobjpath=cobjpath,hpos=hpos,radius=radius,ra_arr=ra_arr,dec_arr=dec_arr

if n_params() eq 0 then begin
    print,'syntax- photom_local,fnames,ra,dec,lcs,uucat_name=uucat_name,imagepath=imagepath,cobjpath=cobjpath,hpos=hpos,radius=radius,ra_arr=ra_arr,dec_arr=dec_arr'
    return
endif

;; to do: - make sure we aren't using variables [how do we mask out?]
;;        - make sure we aren't using the burst to compare to [not a problem
;;          with usno!]

if n_elements(imagepath) eq 0 then imagepath = 'image/'
if n_elements(cobjpath) eq 0 then cobjpath = 'prod/'

if n_elements(radius) eq 0 then radius = 0.1

if n_elements(uucat_name) ne 0 then begin
    print,'Using USNO-1m file: ', uucat_name
    read_usno1m_file,uucat_name,ucat
endif else begin
    print,'Using USNO A2.0 Catalog'
    usnoread2,ra,dec,radius*2,ucat
endelse

nfile = n_elements(fnames)

elt = create_struct('m',fltarr(nfile),'merr',fltarr(nfile),'mjd',dblarr(nfile),'ra',0d,'dec',0d)

;; now, we need to decide which stars to monitor
photom_getstars,ucat,ra,dec,radius,cind

;;if cind[0] eq -1 then begin
if n_elements(cind) lt 3 then begin
    print,'Not enough good stars'
    return
endif

if (n_elements(ra_arr) ne 0 and n_elements(ra_arr) eq n_elements(dec_arr)) then begin
    ;; we have some stars we want to monitor
    close_match_radec,ra_arr,dec_arr,ucat[cind].ra,ucat[cind].dec,m1,m2,0.0009d,1,miss
       
    ;; the following will need to be updated...soon, but I don't have the
    ;; patience right now, and want to write the useful code.
    if (m1[0] eq -1 and miss[0] eq -1) then begin
        print,'Serious problem'
        return
    endif else if (m1[0] eq -1) then begin
        r_arr=ra_arr[miss]
        d_arr=dec_arr[miss]
    endif else if (miss[0] eq -1) then begin
        r_arr=ra_arr[m1]
        d_arr=dec_arr[m1]
    endif else begin
        r_arr=[ra_arr[m1],ra_arr[miss]]
        d_arr=[dec_arr[m1],dec_arr[miss]]
    endelse

endif else begin
    r_arr=ucat[cind].ra
    d_arr=ucat[cind].dec
endelse

r_arr = [ra,r_arr]
d_arr = [dec,d_arr]

nelt = n_elements(r_arr)
lcs=replicate(elt,nelt)

;; hpos keyword add later

for i=0l,nfile-1 do begin
    dirparts = str_sep(fnames[i],"/")
    nparts = n_elements(dirparts)

    parts=str_sep(dirparts[nparts-1],'_')
    
    imname = imagepath + parts[0] + '_' + parts[1] + '_' + parts[2] + '_c.fit'
    cobjname = cobjpath + parts[0] + '_' + parts[1] + '_' + parts[2] + '_cobj.fit'

    im=readfits(imname)
    cal=mrdfits(cobjname,2)

    photom_dostars,im,cal,ra,dec,r_arr,d_arr,ucat,cind,m,merr

    for j=0l,n_elements(m)-1 do begin
        lcs[j].mjd[i] = cal.mjd
        lcs[j].ra = r_arr[j]
        lcs[j].dec = d_arr[j]

        lcs[j].m[i] = m[j]
        lcs[j].merr[i] = merr[j]
    endfor
endfor



return
end
