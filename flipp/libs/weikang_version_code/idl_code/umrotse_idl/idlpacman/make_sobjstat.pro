PRO make_sobjstat, c, imhdr, ustat

; program to make a stat structure for an sobj file, similar to the
; cobj one, by using the header info and dummy variables. Expected
; only for cases when cobj FAILS to generate, NOT to be a substitute
; for the cobj stats!

; input: 
; imhdr, image header as in: hdr = headfits(conf.cimg)
; c - the conf file structure

; output: ustat, a stat structure to allow update_stats to work

sobjhdr = headfits(c.sobj)

;Get the elevation for the stats file
elev=sxpar(imhdr,'elev')
if (!err ne 0) then begin
    elev=0.0
endif


nbin=1
magdiff_matrix = -99.0

stats=create_struct("nmatch",-1,"offset_x",-99,"offset_y",-99,$
                    "pos_sigma",100.0,"ra_low",-99.0,"ra_high",-99.0,$
                    "dec_low",-99.0,"dec_high",-99.0,"zp_offset",magdiff_matrix,$
                    "zp_sigma",100.0,"m_lim",-99.0,"fname",'', "fwhm", 0.0)

; Extract the header variables into a structure. Start with the first one...
i=1
varname=strtrim(strmid(imhdr(i),0,8))
varval=sxpar(imhdr,varname)
if (size(varval,/type) eq 4) then varval=double(varval)
head_struct=create_struct(varname,varval)
;We will loop over the header to the last variable
i=2
while (i lt n_elements(imhdr) and strtrim(strmid(imhdr(i),0,8)) ne 'END') do begin
    varname=strtrim(strmid(imhdr(i),0,8))
    if ((varname ne 'MJD') and (varname ne 'COMMENT')) then begin
        varval=sxpar(imhdr,varname)
        if (varname eq 'DATE-OBS') then varname = 'DATE_OBS'
        if (size(varval,/type) eq 4) then varval=double(varval) ;convert any floats to doubles 
        head_struct=create_struct(head_struct,varname,varval)
    endif
    i=i+1
endwhile


mjd = sxpar(imhdr,'mjd')
if (mjd eq 0) then jd = sxpar(imhdr,'jd')
if (!err ne 0) then begin
    time = sxpar(imhdr,"GMTTIME")
    ts = str_sep(time,' ')
    t = float(ts)
    juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], mjd
    !err=0
endif

head_struct=create_struct(head_struct,'mjd',double(mjd))

; Get a few SExtractor parameters out of the sobj header
sex_head_struct=create_struct('SEXGAIN',0.0,'SEXBKGND',0.0,'SEXBKDEV',0.0,'SEXBKTHD',0.0, $
                              'SEXSATLV',0.0,'SEXMGZPT',0.0,'SEXNDET',0.0,'SEXNFIN',0.0, $
                              'BADPIXFILE','')
sex_head_struct.sexgain=sxpar(sobjhdr,'SEXGAIN')
sex_head_struct.sexbkgnd=sxpar(sobjhdr,'SEXBKGND')
sex_head_struct.sexbkdev=sxpar(sobjhdr,'SEXBKDEV')
sex_head_struct.sexbkthd=sxpar(sobjhdr,'SEXBKTHD')
sex_head_struct.sexsatlv=sxpar(sobjhdr,'SEXSATLV')
sex_head_struct.sexmgzpt=sxpar(sobjhdr,'SEXMGZPT')
sex_head_struct.sexndet=sxpar(sobjhdr,'SEXNDET')
sex_head_struct.sexnfin=sxpar(sobjhdr,'SEXNFIN')
;  sex_head_struct.badpixfile=whichbpfile(0)
sex_head_struct.badpixfile='no_badpixel_file'

      ; Put these structures together
stats_and_header=create_struct(head_struct,sex_head_struct,stats)
      ;update the 'elev' data:
stats_and_header.elev=elev

skyc=c.sobjdir+'/'+c.root+'_sky.fit'
sky=readfits(skyc)
if (sky(0,0) eq -1) then begin ; the file does not exist, create a dummy array of -1s
    print,"Non-fatal error: The sky file is unavailable."
    sky=replicate(-1,64,64)
ENDIF  

tmpmatrix=dblarr(4,4)-99.0d

stats_and_header=create_struct(stats_and_header,'RAC',-99.0d,'DECC',-99.0d,'KX',tmpmatrix,'KY',tmpmatrix)
stats_and_header=create_struct(stats_and_header,'SAT_MAG',-99.0,'NOBJ_BADPIX', 0)
stats_and_header=create_struct(stats_and_header,'sky',sky)
; Now put the stats and the header variables in extension 2...
stats_and_header.fname=c.root+'_c.fit'

ustat = stats_and_header

END
