pro coadd_names,names,imtot,outname,nofirst=nofirst
;+
; NAME:	COADD_NAMES
;
; CALLING SEQUENCE: coadd_names,names,imtot
;
; INPUTS:	names; array containing list of images to use
;
; OUTPUTS:	imtot: sum of all images, weighted to total exposure length
;			
; PROCEDURE:	Warps the images into coordinates of first image, including 
;			handling the missing regions with a weight
;
; Created: 06-13-00 Bob Kehoe -- based on coadd_radec_ref by Tim McKay
; Updated: 07-18-00 Bob Kehoe
; Updated: 08-14-00 Bob Kehoe
; Updated: 10-12-00 Bob Kehoe -- patched for RA=360 problem, will need a more 
;				 sophisticated approach later

 if N_params() eq 0 then begin
    print,'Syntax - coadd_names,names,imtot,outname'
    return
 endif

; Initialization

 totobs = (size(names))[1]
 totexptime = 0.0
 tot_satlvl = 0.0

; Obtain first image calibrated object list.  If nofirst isn't set, 
; acquire first image and correct hot pixels.

 name = (str_sep(names[0], " "))[0]
 info = str_sep(name, '_1')
 imname = (str_sep(name,'_cobj'))[0] + '_c.fit'
 lref = mrdfits(name, 1, hdr)
 sref = mrdfits(name, 2, sdr)
 imn = readfits(imname, hdr)
 nx = (size(imn))[1]
 ny = (size(imn))[2]
 weight = make_array(nx, ny, /FLOAT, value=0.0)
 imtot = make_array(nx, ny, /FLOAT, value=0.0)
 badpix_name = get_badpix_mapname(hdr)
 print, 'badpix_name ',badpix_name
 if (badpix_name ne "") then pix = mrdfits(badpix_name, 1)
 if (not keyword_set(nofirst)) then begin
    imhdr = hdr
    if (badpix_name ne "") then fix_hotpix, pix, imn
    sky, imn, sky, skyerr
    imn = imn - sky
    imtot = imn
    exptime = sxpar(hdr, 'exptime')
    weight[*,*] = exptime
    totexptime = exptime
    stat = mrdfits(name, 2, hdr)
    tot_satlvl = stat.sexsatlv - sky - skyerr 
 endif

; Accrue coadded image array.  Remove sky from each image so all regions
; are on same footing.  Then map to original frame and add the warped image.

 for k = 1,totobs-1 do begin
    namenew = (str_sep(names[k], " "))[0]
    info = str_sep(namenew, '_1')
    nframe = strmid(info[1], 1, 3)
    imnamenew = (str_sep(namenew,'_cobj'))[0] + '_c.fit'
    ln = mrdfits(namenew, 1, hdr)
    stat = mrdfits(namenew, 2, hdr)
    diff = sref.rac - stat.rac
    if (abs(diff) gt 350.0 and abs(diff) lt 370.0) then begin
       if (diff lt 0) then ln.ra = ln.ra - 360.0 
       if (diff gt 0) then ln.ra = ln.ra + 360.0
    endif
    imn = readfits(imnamenew, hdr)
    if (badpix_name ne "") then fix_hotpix, pix, imn
    sky, imn, sky, skyerr
    imn = imn - sky
    exptime = sxpar(hdr, 'exptime')
    wn = imn
    wn[*,*] = exptime
    totexptime = totexptime + exptime
    tot_satlvl = tot_satlvl + (stat.sexsatlv - sky - skyerr)
    close_match_radec,lref.ra,lref.dec,ln.ra,ln.dec,m1,m2,0.005,1.0,miss1,/silent
    nobj = n_elements(m1)
    if (nobj eq 1) then begin
       print,'close_match_radec failed to return a match on ', imnamenew
       return
    endif
    print, 'Number of matched objects is: ' + string(nobj)
    print, '   Adding frame: ', names[k]
    nl = fix(nobj*0.1)
    nh = fix(nobj*0.5)
    polywarp,ln[m2[nl:nh]].x,ln[m2[nl:nh]].y,lref[m1[nl:nh]].x,lref[m1[nl:nh]].y,2,kx,ky
    imn = poly_2d(imn, kx, ky, 1, missing=0.0)
    wn = poly_2d(wn, kx, ky, 1, missing=0.0)
    imtot = imtot + imn
    weight = weight + wn
 endfor

; Make underflow bin out of lowest few weighted pixels

 j = where(weight ne 0.0, count)
 imtot[j] = imtot[j]*(totexptime/weight[j])
 minval = min(imtot[j], iobj)
 if (minval lt 0.0) then begin
    nlow = 1
    minval2 = minval
    m2 = iobj
    while (nlow le 12) do begin
       minval = minval2
       m = m2
       minval2 = minval2 + 100.0    
       m2 = where(imtot[j] lt minval2, nlow)
    endwhile
    imtot[j[m]] = minval
 endif

; Construct output filename and header.  Write out image.

 info=str_sep(imname, '_c')
 outname = info(0) + '-' + nframe + '_c.fit'
 sxaddpar, imhdr, 'exptime', totexptime
 sxaddpar, imhdr, 'satlevl', tot_satlvl
 sxaddpar, imhdr, 'ncoadd', totobs
 tstart = sxpar(imhdr, 'obstime')
 tstop = sxpar(hdr, 'obstime')
 efftime = tstop + exptime - tstart
 sxaddpar, imhdr, 'efftime', efftime
 lowest = min(imtot)
 highest = max(imtot)
 bscale = (highest - lowest)/65535.0
 bzero = 0.5*(highest + lowest + bscale)
 sxaddpar, imhdr, 'bzero', bzero
 sxaddpar, imhdr, 'bscale', bscale
 new_im = fix(round(imtot - bzero)/bscale)
 writefits, outname, new_im, imhdr

 return
end


