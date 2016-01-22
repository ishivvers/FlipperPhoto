PRO aploterr, aspect, x, y, xerr, yerr, _extra=extra

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    APLOTERR
;       
; PURPOSE:
;    Wrapper for PLOTERR that forces a user defined aspect ratio.
;
; CALLING SEQUENCE:
;    aploterr, aspect, [x,] y, [xerr,] yerr, _extra=extra
;
; INPUTS: 
;    aspect: xsize/ysize
;    y: y values
;    yerr: y error values.
;
; OPTIONAL INPUTS:
;    x: optional x values
;    xerr: x error values.
;
; KEYWORD PARAMETERS:
;    _extra:  plotting keywords.
;       
; CALLED ROUTINES:
;    PLOTERR
; 
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    Author: Erin Scott Sheldon  UofMich 11/17/99  
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  On_error,2

  np=n_params()
  IF (np LT 3) OR (np GT 5) THEN BEGIN 
     print,'-Syntax: aploterr, aspect, [x,] y, [xerr,] yerr, _extra=extra'
     print,''
     print,' aspect = xsize/ysize'
     print,'Use doc_library,"aploterr"  for more help.'  
     return
  ENDIF 

  IF !p.multi[1] EQ 0 THEN !p.multi[1] = 1
  IF !p.multi[2] EQ 0 THEN !p.multi[2] = 1

  plot, [0,1], [0,1], /nodata, xstyle=4, ystyle=4
  px = !x.window*!d.x_vsize
  py = !y.window*!d.y_vsize

  xsize = px[1] - px[0]
  ysize = py[1] - py[0]

  CASE 1 OF 
      (aspect EQ 1): IF xsize GT ysize THEN xsize=ysize ELSE ysize = xsize  
      (aspect LT 1): xsize = ysize*aspect
      (aspect GT 1): ysize = xsize/aspect
  ENDCASE 

  px[1] = px[0] + xsize
  py[1] = py[0] + ysize

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; center up the display 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  dcenter, xsize, ysize, px, py

  position = [ [px(0), py(0)], [px(1), py(1)] ]

  CASE np OF                    ;case where x=y, y=yerr
      3: ploterr, x, y, position=position, /device, /noerase, _extra=extra
                                ;case where x=y, y=yerr
      4: ploterr, x, y, xerr, position=position, $
        /device, /noerase,_extra=extra
      5: ploterr, x, y, xerr, yerr, position=position, $
        /device, _extra=extra
      ELSE : print,'What!?!'
  ENDCASE 

return
END 
