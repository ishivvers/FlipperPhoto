pro matchtodao,mtname,ra,dec,mingood=mingood,ir=ir

if n_params() lt 3 then begin
    print,'syntax- matchtodao,mtname,ra,dec,mingood=mingood,ir=ir'
    return
endif

if n_elements(mingood) eq 0 then mingood = 1

mt=mrdfits(mtname,1)
st=mrdfits(mtname,2)

thisobj = 0

;;if n_elements(ra) eq 1 and n_elements(dec) eq 1 then begin
    ;; first check if it's in the match structure
    close_match_radec,ra,dec,mt.ra,mt.dec,m1,m2,0.0009d,1

    if m2[0] eq -1 then begin
        thisobj=mt.nobj

        mt.nobj=mt.nobj+1
        mt.ra[thisobj] = ra
        mt.dec[thisobj] = dec
        mt.m[0:mt.nobs-1,thisobj] = 20.0
        mt.merr[0:mt.nobs-1,thisobj] = 0.2
        mt.flags[0:mt.nobs-1,thisobj] = 0
        mt.rflags[0:mt.nobs-1,thisobj] = 0
        mt.mavg[thisobj] = 20.0
        mt.mstd[thisobj] = 0.1
        mt.ngood[thisobj] = mingood
    endif else begin
        ;; make sure it gets operated on
        if (mt.ngood[m2] lt mingood) then mt.ngood[m2] = mingood
        thisobj = m2[0]
    endelse
;;endif


nmt=mt

ras=mt.ra[0:mt.nobj-1]
decs=mt.dec[0:mt.nobj-1]

used=where(mt.ngood[0:mt.nobj-1] ge mingood)
use=bytarr(mt.nobj)
use[used]=1

for i=0l,mt.nobs-1 do begin
    imname=mt.imagename[i]

;;    daotest4,imname,ras,decs,ms,merrs

    if (n_elements(thisobj) eq 1) then tnum=thisobj else tnum = 0

    rotse_dao,imname,ras,decs,use,ms,merrs,thisobj,ir=ir

;;    if (keyword_set(ir)) then begin
;;        rotse_dao_ir,imname,ras,decs,use,ms,merrs,thisobj
;;    endif else begin
;;        rotse_dao,imname,ras,decs,use,ms,merrs,thisobj
;;    endelse

    ;; now, alter the match structure
    nmt.m[i,0:mt.nobj-1] = ms
    nmt.merr[i,0:mt.nobj-1] = merrs

    ;; use merr to set h (b/c target limit)
    h=where(merrs gt 0,nh)
    if (nh gt 0) then $
      nmt.flags[i,h] = 0
    h2=where(merrs lt 0,nh2)
    if (nh2 gt 0) then $
      nmt.flags[i,h2] = -1

endfor


;;recalculate statistics for the match structure

calc_diag_parms,nmt
save_match,nmt,st,/over



return
end
