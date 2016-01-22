pro rm_struct,match,newmatch,rmobs=rmobs,rmind=rmind,rr=rr
;+
; NAME: RM_STRUCT
;
; PURPOSE: To remove either observations, indicies, or both from a
;       match structure. Match need only have a .M tag which is (nobs,nobj),
;       all other tags are copied from the original and the observations or
;       indicies are removed only if the number of elements is NOBS or NOBJ.
;
; CALLING SEQUENCE: rm_struct,match,newmatch,rmobs=rmobs,rmind=rmind
;
; INPUTS: match - match structure to remove indicies or observations from. 
;
; OPTIONAL INPUTS: rmobs - array of observation indicies to remove.
;                  rmind - array of object indicies to remove.
;
; OUTPUTS: newmatch - Same as MATCH, but with required observations or
;                     indicies removed. 
;
; OPTIONAL OUTPUTS:
;
; NOTES: Either the RMOBS or RMIND keyword must be set to run. 
;
; EXAMPLE: To remove the indices ind=[9,88,555] and the 
;     observations obs=[0,1,2] from 'match' do:
;  IDL> rm_struct,match,newmatch,rmobs=obs,rmind=ind
;
; PROCEDURES CALLED: REMOVE
;
; REVISION HISTORY:
;          Susan Amrose      UM        3/23/99
;-
; On_error,2                                      ;Return to caller


if n_params() eq 0 then begin
	print,'syntax-rm_struct,match,newmatch,rmobs=rmobs,rmind=rmind'
	return
endif

names=tag_names(match)

if not keyword_set(rmobs) and not keyword_set(rmind) then begin
	print,'Must give either indicies to remove OR observations to remove'
	return
endif

IF keyword_set(rr) THEN BEGIN
  nobj=n_elements(match.(0)) 
  nobs=1
ENDIF ELSE BEGIN
  nobs=n_elements(match.m(*,0))
  nobj=n_elements(match.m(0,*))
ENDELSE

newobs=indgen(nobs)
newind=lindgen(nobj)
if keyword_set(rmobs) then begin
  remove,rmobs,newobs
  stg='newmatch=create_struct('
  for i=0,n_tags(match)-1 do begin
          test=size(match.(i))
          if test(0) eq 0 then $
            if i lt n_tags(match)-1 then $
              stg=stg+'"'+names(i)+'"'+		$
              ',temporary(match.('+strtrim(string(i),1)+')),' $
              else stg=stg+'"'+names(i)+'"'+	$
                ',temporary(match.('+strtrim(string(i),1)+'))' else begin
                stg=stg+'"'+names(i)+'"'+	$
                ',temporary(match.('+strtrim(string(i),1)+')('
                for k=0,test(0)-1 do begin
                  if test(k+1) eq nobs then nind='newobs' else nind='*'
                  if k lt test(0)-1 then stg=stg+nind+',' else $
                     if i lt n_tags(match)-1 then stg=stg+nind+')),' $
                       else stg=stg+nind+'))'
                endfor
              endelse
  endfor
  stg=stg+')'
  rn=execute(stg)
endif else newmatch=match

if keyword_set(rmind) then begin
  remove,rmind,newind
  stg='newmatch=create_struct('
  for i=0,n_tags(newmatch)-1 do begin
          test=size(newmatch.(i))
          if test(0) eq 0 then $
            if i lt n_tags(newmatch)-1 then $
              stg=stg+'"'+names(i)+'"'+		$
               ',temporary(newmatch.('+strtrim(string(i),1)+')),' $
              else stg=stg+names(i)+		$
              ',temporary(newmatch.('+strtrim(string(i),1)+'))' else begin
                stg=stg+'"'+names(i)+'"'+	$
                ',temporary(newmatch.('+strtrim(string(i),1)+')('
                for k=0,test(0)-1 do begin
                  if test(k+1) eq nobj then nind='newind' else nind='*'
                  if k lt test(0)-1 then stg=stg+nind+',' else $
                     if i lt n_tags(newmatch)-1 then stg=stg+nind+')),' else stg=stg+nind+'))'
                endfor
              endelse
  endfor
  stg=stg+')'

  rn=execute(stg)

endif  

return
end


