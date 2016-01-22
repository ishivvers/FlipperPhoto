function check_flags, flagstr, flagword, type=type
;+
; NAME: check_flags
;
; CALLING SEQUENCE:     check_flags,flagstr,flagword,type
;
; INPUTS:       flagstr: list of flags, or flag mask
; 		flagword: word to check
;
; Keywords:	type: type of flags to consult ('EFLAGS' or 'RFLAGS')
;
; Return Value: new word indicating which bits were on.
;
; Created:  5-26-00  Bob Kehoe
;******************************************************************************

if N_params() lt 2 then begin
   print, 'Syntax check_flags, flagstr, flagword, type=type'
   return, -1
endif

  if not keyword_set(type) then begin
     print, 'Flag type not set.'
     return, -1
  endif

  val = set_flags(flagstr, type=type) and flagword

  return, val
end