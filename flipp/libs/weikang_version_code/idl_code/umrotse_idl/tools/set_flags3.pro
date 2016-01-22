function set_flags3, tmpflags, type=type, old=old
;+
; NAME: set_flags
;
; CALLING SEQUENCE:     set_flags,flaglist,type,oldword
;
; INPUTS:       tmpflags: list of flags, or flag mask
;
; Keywords:	type: type of flags to consult ('EFLAGS' or 'RFLAGS')
;		old: input word in which to set bits
;
; Return Value: new word with requested bits set
;
; Created:  5-26-00  Bob Kehoe
; Modified: 11-16-01 Eli Rykoff  - rotse3 flags; array support for "old"
;******************************************************************************

if N_params() lt 1 then begin
   print, 'Syntax set_flags3, flaglist, type=type, old=old'
   return, -1
endif

; Initialization

  if not keyword_set(type) then begin
     print, 'Flag type not set.'
     return, -1
  endif
  refs = define_flags3(type)
  nrefs = (size(refs))[1]
  val = [0]
  if (n_elements(old) ne 0) then val = old

; Determine which mode running in.  If mask is input, calc.
; new flag word and return.  Otherwise continue.

  tmp = size(tmpflags)
  if (tmp[0] eq 0) then begin
     if (tmp[1] eq 7) then begin
        flags = strarr(1)
        flags[0] = tmpflags
     endif else if (tmp[1] eq 2) then begin
        tmp2 = val and tmpflags
        tmpflags = tmpflags - tmp2
        val = val + tmpflags
        if (n_elements(val) eq 1) then return,val[0] else return,val
     endif
  endif else flags = tmpflags

; loop over input list of flag names and set new bits.

  nstring = (size(flags))[1]
  for k = 0l, nrefs-1 do begin
     tmp2 = val and 2^k
     for i=0l,n_elements(tmp2)-1 do begin
         if (tmp2[i] eq 0) then begin
             for l = 0l, nstring-1 do begin
                 if (strpos(flags[l], refs[k]) ne -1) then val[i] = 2^k + val[i]
             endfor
         endif
     endfor
  endfor
        
  if (n_elements(val) eq 1) then return,val[0] else return,val
end
