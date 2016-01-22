FUNCTION set_limits, fudge, name
;+
; NAME:	GET_LIMITS	
;
; CALLING SEQUENCE:	 set_limits, fudge, name
;
; INPUTS:	name: name of cobj file
;
; OUTPUTS:	lims: returns four-element vector of ra and dec limits
;
; REVISION HISTORY:  
;		Don Smith	UM	10/19/01
;====================================================================================
;-

  lims = dblarr(4)
  inf = mrdfits(name,1)
  lims[0]=min(inf.ra)-fudge
  lims[1]=max(inf.ra)+fudge
  lims[2]=min(inf.dec)-fudge
  lims[3]=max(inf.dec)+fudge
  return, lims
END
