pro varmonitor_update_struct,m,iobs=iobs,site=site,dir=dir,varfile=varfile


;+
; NAME: UPDATE_CVS
;
; CALLING SEQUENCE: 
;     varmonitor_update_struct,m,iobs=iobs,append=append,site=site,dir=dir 
;
; INPUTS:       m: match structure.      
;
; OUTPUTS:      Updated variable monitor structures are saved.
;       
; INPUT KEYWORDS:
;               iobs: number of observations in match structure.
;               site: for which telescope, such as 'a'.
;               dir: directory for the cv fits files. 
;        
; PROCEDURE:   This program will update the varmon fits files with a given 
;              match structure. 
;
;       
;==========================================================================
;-

if n_params() eq 0 then begin
    print,'syntax- varmonitor_update_struct,m,iobs=iobs,site=site,dir=dir,varfile=varfile'
    return
endif

if n_elements(dir) eq 0 then dir='/rotse/data/pipeline/templates/varmonitor/'
if n_elements(site) eq 0 then begin
    dirparts=strsplit(m.imagename[0],'/',/extract)
    parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
    site = strmid(parts[2],1,1)
endif
if n_elements(varfile) eq 0 then varfile = dir+'varmonitor_list.fit'


;; read in the variable list
varlist=mrdfits(varfile,1,status=status)
if (status lt 0) then begin
    print,'Variable file '+varfile+' not found.'
    return
endif

n_var = n_elements(varlist.name)

;; are there any of the variables in this field?
index=where(varlist.rad gt m.ral and varlist.rad lt m.rah and $
        varlist.decd gt m.decl and varlist.decd lt m.dech,nm)

if (nm gt 0) then begin
    ;; we have at least one variable in the field
    for i=0,nm-1 do begin
        varfname = dir + 'vm_' + varlist[index[i]].filename + '_3' + site + '.fit'
        varfile = findfile(varfname,count=ct)

        if (ct eq 1) then begin
            ;; the file exists
            varstr=mrdfits(varfile[0],1)
            n_obs = varstr.nobs
        endif else begin
            ;; it doesn't exist, and we need to create one...
            varmonitor_init_struct,varlist[index[i]],site,dir=dir
            varstr=mrdfits(varfname,1)           
            n_obs = 0
        endelse


        ;; if iobs is specified, those observations will be added even if
        ;; they already exist
        if (n_elements(iobs) eq 0) then begin
            if (n_obs eq 0) then begin
                iobs = where(m.jd gt 0,nnew)
            endif else begin
                ljd = max(varstr.jd)
                iobs=where(m.jd gt ljd,nnew)
            endelse
        endif else begin
            nnew = n_elements(iobs)
        endelse

        if (nnew gt 0) then begin
            new_nobs = n_obs + nnew
            new_varstr = varmonitor_make_struct(new_nobs,old=varstr)
            
            close_match_radec,varstr.ra,varstr.dec,m.ra,m.dec,m1,m2,0.0009d,1
            if (m2[0] ne -1) then begin                       
                new_varstr.nobs=new_nobs
                new_varstr.jd[n_obs:new_nobs-1]=m.jd[iobs]
                new_varstr.imagename[n_obs:new_nobs-1]=m.imagename[iobs]
                new_varstr.iobj[n_obs:new_nobs-1]=m2[0]
                new_varstr.m[n_obs:new_nobs-1]=m.m[iobs,m2[0]]
                new_varstr.merr[n_obs:new_nobs-1]=m.merr[iobs,m2[0]]
                new_varstr.flags[n_obs:new_nobs-1]=m.flags[iobs,m2[0]]
                new_varstr.rflags[n_obs:new_nobs-1]=m.rflags[iobs,m2[0]]
                new_varstr.msys[n_obs:new_nobs-1]=m.msys[iobs,m2[0]]
                new_varstr.m_lim[n_obs:new_nobs-1]=m.m_lim[iobs]
            endif else begin
                print,'new observations not found: adding limits'
                new_varstr.nobs=new_nobs
                new_varstr.jd[n_obs:new_nobs-1]=m.jd[iobs]
                new_varstr.imagename[n_obs:new_nobs-1]=m.imagename[iobs]
                new_varstr.iobj[n_obs:new_nobs-1]=-1
                new_varstr.m_lim[n_obs:new_nobs-1]=m.m_lim[iobs]
            endelse
            
            ;; save the updated structure
            mwrfits,new_varstr,varfname,/create
            print,'Updated: ',varfname            
        endif else begin
            print,'No updates for: ',varfname
        endelse           
    endfor
endif else begin
    print,'No variables to monitor in the field.'
endelse

return
end
