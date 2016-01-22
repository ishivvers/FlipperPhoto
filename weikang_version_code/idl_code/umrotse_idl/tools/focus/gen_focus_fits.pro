pro gen_focus_fits,filelist,outname,fname=fname,imdir=imdir,sobjdir=sobjdir
;+
; NAME: gen_focus_fits
;
; CALLING SEQUENCE: gen_focus_fits,filelist,outname,fname=fname,imdir=imdir,sobjdir=sobjdir
;
; INPUTS:              filelist: list of focus images
;        
; OUTPUTS:             outname: the output file name
; 
; INPUT KEYWORDS:      imdir: image directory if not './image/'
;                      sobjdir: sobj directory if not './prod/'
;                      fname: the output file name, if not the generated default
;
; PROCEDURE: This program distills the necessary information from a the headers
;  of focus frames and their associated sobj files to put into a convenient
;  portable fitsfile on which to run gen_focus_model.pro.  The imdir and
;  sobjdir default so that this program should be run in the parent directory
;  to the image and sobj files.
;
; REVISION HISTORY:
;     Eli Rykoff     UM     10/21/03 - First official version
;
;===============================================================================
;-



if n_params() eq 0 then begin
    print,'syntax- gen_focus_fits,filelist,outname,fname=fname,imdir=imdir,sobjdir=sobjdir'
    return
endif

if n_elements(imdir) eq 0 then imdir = 'image'
if n_elements(sobjdir) eq 0 then sobjdir = 'prod'

readcol,filelist,files,format='a'
nfile = n_elements(files)

elt = create_struct('filename','', $
                    'elevation', 0.0, $
                    'azimuth', 0.0, $
                    'temp', 0.0, $
                    'focus', 0.0, $
                    'minmag', 0.0, $
                    'maxmag', 0.0, $
                    'ratio', 0.0, $
                    'fwhm', 0.0)

filestr = replicate(elt, nfile)

for i=0l,nfile-1 do begin
    dirparts=str_sep(files[i],'/')
    filename=dirparts[n_elements(dirparts)-1]
    parts=str_sep(filename,'_')

    imname = imdir + '/' + parts[0] + '_' + parts[1] + '_' + parts[2] + '_c.fit'
    if (strpos(filename,'.gz') ne -1) then imname = imname + '.gz'
    sobjname = sobjdir + '/' + parts[0] + '_' + parts[1] + '_' + parts[2] + '_sobj.fit'

    hdr=headfits(imname)
    filestr[i].filename = filename
    filestr[i].elevation = sxpar(hdr, 'ELEV')
    filestr[i].azimuth = sxpar(hdr, 'AZIMUTH')
    filestr[i].temp = sxpar(hdr, 'TEMPOUT')
    filestr[i].focus = sxpar(hdr, 'FOCUS')

    sobj=mrdfits(sobjname,1)
    satmag = -1.0
    maxmag = -1.0
    medratio = -1.0
    medfwhm = -1.0

    if (size(sobj,/type) eq 8) then begin
        h=where((sobj.flags and 4) ne 4, count)
        if (count gt 0) then begin
            satmag = min(sobj[h].mag_aper[0])
            maxmag = satmag + 2.0
            
            k=where(sobj[h].mag_aper[0] gt satmag + 2.0 and $
                    sobj[h].x_image gt 700 and sobj[h].x_image lt 1300 and $
                    sobj[h].y_image gt 700 and sobj[h].y_image lt 1300, gdcount)
            if (gdcount gt 2) then begin
                medfwhm = median(sobj[h[k]].fwhm_image)

                if (n_elements(sobj[0].mag_aper) gt 1) then begin
                    delta_mag = sobj[h[k]].mag_aper[1] - sobj[h[k]].mag_aper[0]
                    ratio = 10.0^(delta_mag / 2.5)
                    medratio = median(ratio)
                endif
            endif
        endif
    endif

    filestr[i].minmag = satmag
    filestr[i].maxmag = maxmag
    filestr[i].ratio = medratio
    filestr[i].fwhm = medfwhm
endfor

if (n_elements(fname) gt 0) then begin
    outname = fname
endif else begin
    dirparts=str_sep(files[0],'/')
    filename=dirparts[n_elements(dirparts)-1]
    parts=str_sep(filename,'_')
    cam=strmid(parts[2],0,2)

    outname = 'focus_' + parts[0] + '_' + cam + '.fit'

endelse

mwrfits, filestr, outname, /create

return
end
