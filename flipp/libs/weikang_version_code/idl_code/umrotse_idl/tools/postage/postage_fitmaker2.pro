pro postage_fitmaker2,fitname,mat,obj,obs,force_create=force_create,boxwidth=boxwidth

if n_params() eq 0 then begin
    print,'syntax- postage_fitmaker2,fitname,mat,obj,obs,force_create=force_create,boxwidth=boxwidth'
    return
endif


get_subimage,mat.imagename[obs],mat.ra[obj],mat.dec[obj],mat.rac[obs],mat.decc[obs], $
             reform(mat.kx[obs,*,*]),reform(mat.ky[obs,*,*]),subim,fail=fail,boxwidth=boxwidth
    
if (fail eq 1) then begin
    print,'get_subimage failed in postage_fitmaker2'
    return
endif

fn = findfile(fitname,count=count)
if ((count eq 0) or keyword_set(force_create)) then begin
    ;; create a new file
    create_postage_header,subim,sc_im,hdr,mat.jd[obs],mat.m[obs,obj],mat.merr[obs,obj],obs
    writefits,fitname,sc_im,hdr
endif else begin
    create_postage_header,subim,sc_im,hdr,mat.jd[obs],mat.m[obs,obj],mat.merr[obs,obj],obs,/xt
    writefits,fitname,sc_im,hdr,/append
endelse


return
end
