pro ss_loop_sks,site=site

if n_elements(site) eq 0 then site='3b'

workdir='/rotse/data/sspipeline/'
skydir='/rotse/data/pipeline/'
coadddir='/rotse/data/sspipeline/'
subtractdir='/rotse/data/sspipeline/'
refdir='/rotse/data/sspipeline/reference/'
respdir='/rotse/data/pipeline/response/'
stampfile='/rotse/data/sspipeline/ss_stamp'

catalog=workdir+'sks_cat_'+site+'.fit'
sks_reflist=workdir+'sks_refnames'
reflist=sks_reflist+'_'+site+'.txt'
skylist=workdir+'skylist'
coadd_list=workdir+'coadd_list'
coaddall_list=workdir+'coaddall_list'
sub_sobjlist=workdir+'sub_sobjlist'
cand_list=workdir+'cand_list'
varlist=workdir+'varlist.fit'
thumbfile='/rotse/data/pipeline/thumbcopy'
skynamefile=workdir+'newskys.txt'
oldcanddir=workdir+'oldcand/'
badmap=workdir+'badpixmap_'+site+'.fit'
icereflist=workdir+'ice_refnames_'+site+'.txt'

if n_elements(stampfile) eq 1 then begin
    do_stamp = 1
    ;; and stamp that we've started up
    openw,stamplun,stampfile,/get_lun
    free_lun,stamplun
endif

loop=1
while loop do begin
    ;get new sky image
    skyfind=0
    while skyfind eq 0 do begin
        print,systime()
        ss_update_skylist,skydir=skydir,skylist=skylist,workdir=workdir,tla=['sks','skc','skt','tss','rqa','rqc','ice','nfp-ice','ict','nfp-ict']
        newskys=ss_get_new_sky(skylist,workdir=workdir)
        if strmatch(newskys[0],'*nothing*') eq 0 then skyfind=1 else wait,400
        if (do_stamp) then begin
            openw,stamplun,stampfile,/get_lun
            free_lun,stamplun
        endif
    endwhile

    ti=systime(1)
    newskys=newskys[sort(newskys)]

    if (strmatch(newskys[0],'*nothing*') eq 0) and $
      (strmatch(newskys[0],'*3?009_*') eq 0) $
      and (strmatch(newskys[0],'*ic*') eq 0) then begin
        dirparts=strsplit(newskys[0],'/',/extract)
        parts=strsplit(dirparts[n_elements(dirparts)-1],'_',/extract)
        namebase=parts[0]+'_'+parts[1]+'_'+strmid(parts[2],0,2)
        openw,units,skynamefile,/get_lun,/append
        printf,units,namebase+','+string(n_elements(newskys),format='(i2)')
        close,units
        free_lun,units
        
        tstref=ss_find_ref_files(newskys[0],refdir=refdir,reflist=reflist,fail=rfail)
        if rfail eq 0 then begin
            ss_coadd_new,newskys,coadddir=coadddir,coadd_list=coadd_list,badmap=badmap
        endif
    endif else begin        
        if (strmatch(newskys[0],'*ic*') eq 1) then begin
            tstref=ss_find_ref_files(newskys[0],refdir=refdir,reflist=icereflist,fail=rfail)
            if rfail eq 0 then begin
                ss_coadd_new,newskys,coadddir=coadddir,coadd_list=coadd_list,badmap=badmap
            endif else begin
                ;make reference with first ice images
                ss_coadd_ref,newskys,refdir=refdir,reflist=icereflist,badmap=badmap 
            endelse
        endif
endelse
    
    newcoadds=ss_get_new(coadd_list,3,/discard_less)
    if newcoadds[0] eq "nothing" then print,'no new coadd files.'
    if strmatch(newcoadds[0],'*ic*') eq 0 then begin
        ss_subtract_new,newcoadds,subdir=subtractdir,subs_list=sub_sobjlist,reflist=reflist,refdir=refdir,subsize=200l
    endif else begin
        ss_subtract_new,newcoadds,subdir=subtractdir,subs_list=sub_sobjlist,reflist=icereflist,refdir=refdir,subsize=200l
    endelse
        
    newsubs=ss_get_new(sub_sobjlist,3,/discard_less)
    if newsubs[0] eq "nothing" then print,'no new subtracted files.'    
    if strmatch(newsubs[0],'*ic*') eq 0 then begin
        ss_detect_and_plot,newsubs,coadddir=coadddir,respdir=respdir,thumbfile=thumbfile,catalog=catalog,varlist=varlist,cand_list=cand_list,reflist=reflist,refdir=refdir,oldcanddir=oldcanddir,/subrefsky
    endif else begin
        ss_detect_and_plot_ice,newsubs,coadddir=coadddir,respdir=respdir,thumbfile=thumbfile,cand_list=cand_list,reflist=icereflist,refdir=refdir,oldcanddir=oldcanddir,/subrefsky,varlist=varlist
    endelse
    tottime=systime(1)-ti
    print,'computing time for this loop (minutes):',tottime/60.
    
    if (do_stamp) then begin
        openw,stamplun,stampfile,/get_lun
        free_lun,stamplun
    endif
endwhile

end
