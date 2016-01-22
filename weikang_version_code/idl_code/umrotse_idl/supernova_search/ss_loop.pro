pro ss_loop,site=site

if n_elements(site) eq 0 then site='3b'

workdir='/rotse/data/sspipeline/'
skydir='/rotse/data/pipeline/'
coadddir='/rotse/data/sspipeline/coadd/'
subtractdir='/rotse/data/sspipeline/subtracted/'
refdir='/rotse/data/sspipeline/reference/'
respdir='/rotse/data/pipeline/response/'

sky_cat=workdir+'sky_cat.fit'
sks_cat=workdir+'sks_cat.fit'
varlist=workdir+'variable.fit'
sky_reflist=workdir+'sky_refnames'
sks_reflist=workdir+'sks_refnames'
skylist=workdir+'skylist'
coadd_list=workdir+'coadd_list'
coaddall_list=workdir+'coaddall_list'
sub_sobjlist=workdir+'sub_sobjlist'
cand_list=workdir+'cand_list'
thumbfile='/rotse/data/pipeline/thumbcopy'

loop=1
while loop do begin
    ;get new sky image
    ss_update_skylist,skydir=skydir,skylist=skylist,workdir=workdir

    ti=systime(1)

    newskys=ss_get_new_sky(skylist,workdir=workdir)
    if strmatch(newskys[0],'*_sky*') then begin
        reflist=sky_reflist+'_'+site+'.txt'
        catalog=sky_cat
    endif else begin
        reflist=sks_reflist+'_'+site+'.txt'
        catalog=sks_cat
    endelse
    
    ss_coadd_new,newskys,coadddir=coadddir,coadd_list=coadd_list,coaddall_list=coaddall_list
    
    ;check if the coaddall image is good as a reference
    newcoaddall=ss_get_new_single(coaddall_list)
    ss_update_candref,newcoaddall,refdir=refdir,reflist=reflist
    ;ss_update_reflist,,refdir=refdir,reflist=reflist ;every week
        
    newcoadds=ss_get_new_pair(coadd_list)    
    ss_subtract_new,newcoadds,subdir=subtractdir,subs_list=sub_sobjlist,reflist=reflist,refdir=refdir
    
    newsubs=ss_get_new_pair(sub_sobjlist)
    ss_detect_and_plot,newsubs,coadddir=coadddir,respdir=respdir,thumbfile=thumbfile,catalog=catalog,varlist=varlist,cand_list=cand_list,reflist=reflist,refdir=refdir
    
    tottime=systime(1)-ti
    print,'computing time for this loop (minutes):',(systime(1)-ti)/60.

    if tottime lt 300 then wait,300-(tottime>1)
endwhile

end
