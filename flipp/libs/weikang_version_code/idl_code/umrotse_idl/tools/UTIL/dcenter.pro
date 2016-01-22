PRO dcenter, xsize, ysize, px, py, silent=silent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    
;       
; PURPOSE:
;    
;
; CALLING SEQUENCE:
;    
;
; INPUTS: 
;    
;
; OPTIONAL INPUTS:
;    
;
; KEYWORD PARAMETERS:
;    
;       
; OUTPUTS: 
;    
;
; OPTIONAL OUTPUTS:
;    
;
; CALLED ROUTINES:
;    
; 
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF n_params() LT 2 THEN BEGIN
      print,'-Syntax: dcenter, xsize, ysize, px, py'
      print
      print,'xsize,ysize are size of plot
      return
  ENDIF 

  IF NOT keyword_set(silent) THEN silent = 0

  IF !p.multi[1] EQ 0 THEN !p.multi[1] = 1
  IF !p.multi[2] EQ 0 THEN !p.multi[2] = 1

  pmult = !p.multi
  px_num = pmult[1]
  py_num = pmult[2]
  pwhich = (long(px_num)*py_num -1) - pmult[0]
  pz_num = pmult[3]
  porder = pmult[4]


  IF (pz_num EQ 0) THEN BEGIN 

      IF n_elements(px) NE 2 THEN px = fltarr(2)
      IF n_elements(py) NE 2 THEN py = fltarr(2)

      ;; Center x
      ptemp = [0., 1.]/px_num
      IF porder EQ 0 THEN addfac = pwhich - (pwhich/px_num)*px_num
      IF porder EQ 1 THEN addfac = pwhich/py_num
      padd = addfac/float(px_num)
      ptemp = (ptemp + padd)*!d.x_vsize

      ptotx = ptemp[1] - ptemp[0]
      pdelta = ptotx - xsize
      px[0] = ptemp[0] + pdelta/2.
      px[1] = px[0] + xsize

      ;; Center y
      ptemp = [0., 1.]/py_num
      IF porder EQ 0 THEN addfac = pwhich/px_num
      IF porder EQ 1 THEN addfac = pwhich - (pwhich/py_num)*py_num
      addfac = py_num - 1 - addfac
      padd = addfac/float(py_num)
      ptemp = (ptemp + padd)*!d.y_vsize
      ptoty = ptemp[1] - ptemp[0]
      pdelta = ptoty - ysize
      py[0] = ptemp[0] + pdelta/2.
      py[1] = py[0] + ysize

  ENDIF ELSE BEGIN
      IF NOT silent THEN print,'!p.multi[3] not equal to zero.  Not centering
  ENDELSE 

  return 
END 
