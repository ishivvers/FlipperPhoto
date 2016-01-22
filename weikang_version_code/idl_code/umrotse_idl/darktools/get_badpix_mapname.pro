function get_badpix_mapname,imhdr, badpixfile=badpixfile

;+
; Purpose:  obtain name of hot pixel map file 
;
; Input:    imhdr:  the FITS header of the image
;
; Kewords:  badpixfile: the name of a specific bad pixel file to look for.
;
; Return Value:
;	"" if no pixel map is found, otherwise a string containing the name
;	of the best matching pixel map file.
;
; Created: 08-16-00  Bob Kehoe
;-

 bp_dir = getenv('ROTSE_BPDIR')
 if (bp_dir eq "") then bp_dir = '.'

 if not keyword_set(badpixfile) then begin
   camsn = sxpar(imhdr, 'CAMSN')
   camtype = sxpar(imhdr, 'CAMTYPE')
   info = strtrim(string(camsn),1)
   camsn = info[0]
   camtype = sxpar(imhdr,'CAMTYPE')
   if (camtype eq 'Apogee-Instruments AP-10') then begin
      cam_t = 'ap10'
   endif else begin
      cam_t = 'unknown'
   endelse
   bpfile = bp_dir+'/??????_pix' +camsn+'_' +cam_t+'.fit'
 endif else begin
   bpfile=badpixfile
 endelse

 whichbpfile = findfile(bpfile, count=fcount)
 if (fcount eq 0) then begin
    print, '*****WARNING*******'
    print, 'There is no valid bad pixel map here.  Bad pixels will not be flagged.'
    badpix = ""
 endif else begin
    print, 'Using bad pixel map: ', whichbpfile[0]
    badpix = whichbpfile[0]
 endelse

 return, badpix
end

