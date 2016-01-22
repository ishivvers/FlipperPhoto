pro redo_burst_response,root,ra,dec,err,extrachar,fudge=fudge,matchname=matchname,cobjdir=cobjdir,usecoadd=usecoadd,pair=pair,bdir=bdir,maglim=maglim,save=save

;+
; FUNCTION: REDO_BURST_RESPONSE
;
; SYNTAX: redo_burst_response, root, ra, dec, err
;
; INPUTS: root: the tla root structure for the cobj files
;         ra: the ra center of the error box
;         dec: the dec center of the error box
;         err: the radius of the error box (degrees)
;         extrachar: a one-character extension to tlaroot so that a new web
;            page is made
;        
;
; KEYWORDS: fudge: the extra radius to search.  default=1.5
;           matchname: the name of a match structure to use; otherwise one is
;              made
;           cobjdir: a specific directory to find cobj files.  Defaults to
;              search all the standard paths
;           usecoadd: use coadded frames instead of straight framse
;           pair: do pair matching
;           bdir: the burst response directory (for web image outputs)
;           maglim: magnitude limit to search.  Default 17.5
;           save: save the match structure after making it.
;
; PURPOSE: this function creates a binary file for non-usno objects
;          near the burst location, as well as cropped jpegs for each 
;          such source in each image
; 
; REVISION HISTORY:
;     Created:   Don Smith   UM    09/03/03
;     Modified:  Eli Rykoff  UM    01/16/04
;                Eli Rykoff        02/23/04 -- works with new/old match strs
; ===================================================================
;-

if n_params() lt 5 then begin
    print,'syntax- redo_burst_response,root,ra,dec,err,extrachar,fudge=fudge,matchname=matchname,cobjdir=cobjdir,usecoadd=usecoadd,pair=pair,bdir=bdir,maglim=maglim,save=save'
    print,'  extrachar is added to the root to make an independent match structure and web page'
    return
endif

if n_elements(fudge) eq 0 then fudge = 1.5

if n_elements(bdir) eq 0 then bdir = '/rotse/data/pipeline/response'

if (size(extrachar,/type) ne 7) then begin
    print,'extrachar must be a character!'
    return
endif else if strlen(extrachar) gt 1 then begin
    print,'extrachar should just be one character!'
    return
endif

newroot = root + extrachar

limits=dblarr(4)
limits[0] = ra - 1.1 * fudge * err / cos(dec*0.01745)
limits[1] = ra + 1.1 * fudge * err / cos(dec*0.01745)
limits[2] = dec - 1.1 * fudge * err
limits[3] = dec + 1.1 * fudge * err

target=dblarr(4)
target[0] = ra
target[1] = dec
target[2] = err
target[3] = fudge

if n_elements(matchname) gt 0 then begin
    ;; we have a match structure to read in
    mt = mrdfits(matchname,1,status=status)
    if (status ne 0) then begin
        print,matchname+' could not be read.'
        return
    endif
    st = mrdfits(matchname,2,status=status)
    if (status ne 0) then begin
        print,matchname+' stats could not be read.'
        return
    endif
endif else begin
    print,'Looking for files with root: '+root
    cobjfiles = find_rotse3_tlaroot(root,path=cobjdir,fail=fail,usecoadd=usecoadd)
    if (fail) then begin
        print,'Could not find any files with the root: '+root
        return
    endif

    print,cobjfiles
    
    if keyword_set(pair) then begin
        if (n_elements(cobjfiles) mod 2) eq 1 then begin
            cobjfiles=cobjfiles[0:n_elements(cobjfiles)-2]
        endif
    endif

    regmatch3_list,mt,st,namelist=cobjfiles,pair=pair,limits=limits,/crop

    if keyword_set(save) then begin
        save_match,mt,st,/over,altroot=newroot
    endif

endelse

if tag_exist(mt,'nobs') then begin
    nobs = mt.nobs
endif else begin
    nobs = n_elements(mt.jd)
endelse



realtime_match,mt,st,target=target,bdir=bdir,multiple=nobs,/docrop,maglim=maglim,newroot=newroot


return
end
