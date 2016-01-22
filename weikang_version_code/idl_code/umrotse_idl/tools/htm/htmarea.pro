FUNCTION htmarea, depth

  IF n_params() EQ 0 THEN BEGIN 
      print,'-Syntax: area=htmArea(depth)'
      print
      print,'returns mean area at that depth in square arcminutes'
      return,-1
  ENDIF 

  ;; returns mean area of level 
  ;; in square arcminutes

  area0=4d*!dpi/8d
  areadiv = 4d^depth
  return,area0/areadiv*(180d/!dpi)^2*60d^2

END 
        
