pro phot_dat_res_group,time,mag,filter,magerr=magerr,outst=outst

if n_params() eq 0 then begin
  print,'Syntax- zphot_dat_res_group,datafile,outst'
  return
endif

number=n_elements(time)
if (number ne n_elements(mag) or number ne n_elements(filter) ) then begin
    print,"Element number in parament not matching or is zero! Doing nothing"
    return
endif

if n_elements(magerr) ne 0 then begin
  withmagerr=1
endif
if n_elements(magerr) eq 1 then begin
  magerr=replicate(magerr,number)
endif

allfilters=phot_filter_unique(filter)
mjd=time
groups=fltarr(number)
filternumber=n_elements(allfilters)
filtergroups=fltarr(number)

;;set the filter groups
for i=0,filternumber-1 do begin
  ind=where(filter eq allfilters[i], nff)
  if nff gt 0 then filtergroups[ind]=i+1
endfor

groups[0]=1
currentgroup=1
;;criterion to judge the same group or not
judgetime=0.4 ;;days
for i=1,number-1 do begin
  ;;only check left items that haven't been assigned the groups
  left=where(groups eq 0,nf)
  if nf gt 0 then begin
    ind=where(abs(mjd[i]-mjd[left]) le judgetime, nfg)
    if nfg ne 0 then begin
      groups[left[ind]]=currentgroup
      ;;now need to check in one group, is there many filters?
      ;;if yes, split it into more groups
      maxsubgroup=1
      onegroup=left[ind]
      for j=0,filternumber-1 do begin
        ind=where(filter[onegroup] eq allfilters[j], nff)
        if nff gt 1 then begin
          if nff gt maxsubgroup then maxsubgroup=nff
          for k=1,nff-1 do begin
            groups[onegroup[ind[k]]]=currentgroup+k
          endfor
        endif
      endfor
      currentgroup=currentgroup+maxsubgroup
    endif
  endif
endfor
totalgroups=currentgroup-1
print,'total groups',totalgroups

;;create a structure to fomat the output
tmpst={group:0,mjd:!values.d_nan,star:-1}
for i=0,filternumber-1 do begin
  tmpst=create_struct(tmpst,allfilters[i],!values.d_nan,string('e',allfilters[i],format='(a1,a)'),!values.d_nan)
endfor

nobj=1  ;;this is because we only have target, no reference stars
out_magst=replicate(tmpst,totalgroups*nobj)
tagnames=strtrim(tag_names(out_magst),2)
for i=0,totalgroups-1 do begin
  out_magst[i*nobj:(i+1)*nobj-1].group=i+1
  ;;find this group items
  ind=where(groups eq i+1, nffl)
  if nffl eq 0 then continue
  out_magst[i*nobj:(i+1)*nobj-1].mjd=mean(mjd[ind])
  ;;for different filters
  for j=0,nffl-1 do begin
    tagind=where(tagnames eq strupcase(filter[ind[j]]))
    ;;for different targets/reference stars
    for k=0,nobj-1 do begin
      out_magst[i*nobj+k].star=k
      out_magst[i*nobj+k].(tagind)=mag[ind[j],k]
      if withmagerr then begin
        out_magst[i*nobj+k].(tagind+1)=magerr[ind[j],k]
      endif else begin
        out_magst[i*nobj+k].(tagind+1)=0.0
      endelse
    endfor
  endfor
endfor
outst=out_magst

;;print out tags, this need update, casue different filter numbers have diffferent number of tag names
;;this is for 4 filters
print,tagnames[0],tagnames[1],tagnames[2],tagnames[3],tagnames[4],tagnames[5],tagnames[6],tagnames[7],tagnames[8],tagnames[9],tagnames[10],format='(a6,a9,a6,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5)'
;;this is for 5 filters
;print,tagnames[0],tagnames[1],tagnames[2],tagnames[3],tagnames[4],tagnames[5],tagnames[6],tagnames[7],tagnames[8],tagnames[9],tagnames[10],tagnames[11],tagnames[12],format='(a6,a9,a6,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5)'
for i=0,n_elements(out_magst)-1 do begin
;;this is for 4 filters
  print,out_magst[i].(0),out_magst[i].(1),out_magst[i].(2),out_magst[i].(3),out_magst[i].(4),out_magst[i].(5),out_magst[i].(6),out_magst[i].(7),out_magst[i].(8),out_magst[i].(9),out_magst[i].(10),format='(i5,f11.4,i5,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2)'
;;this is for 5 filters
; print,out_magst[i].(0),out_magst[i].(1),out_magst[i].(2),out_magst[i].(3),out_magst[i].(4),out_magst[i].(5),out_magst[i].(6),out_magst[i].(7),out_magst[i].(8),out_magst[i].(9),out_magst[i].(10),out_magst[i].(11),out_magst[i].(12),format='(i5,f11.4,i5,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2)'
endfor

end
