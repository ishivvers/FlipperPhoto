PRO simpctable, rdct, grct, blct, help=help, bits=bits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    SIMPCTABLE
;       
; PURPOSE:
;    Create and load a simple 8-color color table
;
; CALLING SEQUENCE:
;    simpctable, red_ct, green_ct, blue_ct, bits=bits, help=help
;
; SIDE EFFECTS: Loads new color table. Sets these system variables:
;
;       !black
;       !white
;       !red
;       !green
;       !blue
;       !yellow
;       !cyan or !lightblue
;       !magenta
;
;     These can be sent to plotting procedures
;
; INPUTS: 
;    None
;
; OPTIONAL INPUTS:
;    bits=bits: input the bits/pixel.  Must be either 8 or 24.
;               If not set, simpctable will
;               determine it from the number of available colors.
;
; KEYWORD PARAMETERS:
;    /help: if set, a help message is printed showing the 
;           the system variables set by SIMPCTABLE
;       
; OUTPUTS: 
;    None
;
; OPTIONAL OUTPUTS:
;     red_ct, green_ct, blue_ct: The red, green, and blue color arrays
;     loaded for 8-bit devices
;     Useful for writing gif files from the plotting window. This only
;     makes sense on 8-bit devices
; CALLED ROUTINES:
;    TVLCT
; 
; EXAMPLE:
;    IDL> simpctable
;    IDL> plot, [0], /nodata, yrange=[-1.2,1.2],xrange=[0,2.*!pi], $
;    IDL>    color=!black, background=!white, xstyle=1
;    IDL> x = findgen(300)/299.*2.*!pi
;    IDL> y = sin(x) + randomn(seed,300)/5.
;    IDL> oplot, x, y, color=!blue
;    IDL> oplot, x, sin(x), color=!red
;    
;	
;
; REVISION HISTORY:
;    Written May 09 2000, Erin Scott Sheldon, U. of Michigan
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; set up colors
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF !d.name EQ 'X' AND !d.window EQ -1 THEN BEGIN ;Uninitialized?
;       If so, make a dummy window to determine the # of colors available.
      window,/free,/pixmap,xs=4, ys=4
      wdelete, !d.window
  ENDIF 

  IF n_elements(bits) EQ 0 THEN BEGIN 
      IF !d.n_colors LE 256 THEN bitsperpixel=8$
      ELSE bitsperpixel=24
  ENDIF ELSE BEGIN 
      IF (bits[0] EQ 8) OR (bits[0] EQ 24) THEN bitsperpixel=bits $
      ELSE message,'bits value of '+strmid( strtrim(string(bits[0]),2),0,1000)+' is invalid. Must be 8 or 24'
  ENDELSE 

  IF bitsperpixel EQ 8 THEN BEGIN 
      ;; this makes a list of colors when put together
      ;; [black, white, red, green, blue, yellow]
      redtmp =    [0L, 1L, 1L, 0L, 0L, 1L, 0L, 1L]
      greentmp =  [0L, 1L, 0L, 1L, 0L, 1L, 1L, 0L]
      bluetmp =   [0L, 1L, 0L, 0L, 1L, 0L, 1L, 1L]

      rdct = 255*redtmp
      grct = 255*greentmp
      blct = 255*bluetmp

      tvlct, rdct, grct, blct

      black=0L
      white = 1L
      red=2L
      green=3L
      blue=4L
      yellow=5L
      lightblue=6L
      cyan=6L
      magenta=7L

  ENDIF ELSE BEGIN 
      R=0L & G=0L & B=0L
      black = R + 256L*(G+256L*B)

      R=255L & G=255L & B=255L
      white = R + 256L*(G+256L*B)

      R=255L & G=0L & B=0L
      red = R + 256L*(G+256L*B)

      R=0L & G=255L & B=0L
      green = R + 256L*(G+256L*B)

      R=0L & G=0L & B=255L
      blue = R + 256L*(G+256L*B)

      R=255L & G=255L & B=0L
      yellow = R + 256L*(G+256L*B)

      R=0L & G=255L & B=255L
      cyan = R + 256L*(G+256L*B)
      lightblue=cyan

      R=255L & G=0L & B=255L
      magenta = R + 256L*(G+256L*B)

  ENDELSE 

  defsysv, '!black', black
  defsysv, '!white', white
  defsysv, '!red', red
  defsysv, '!green', green
  defsysv, '!blue', blue
  defsysv, '!yellow', yellow
  defsysv, '!lightblue', lightblue & defsysv, '!cyan', cyan
  defsysv, '!magenta',magenta


  IF keyword_set(help) THEN BEGIN 
      print,'-Syntax: simpctable, red_ct, green_ct, blue_ct, bits=bits, help=help'
      print
      print,'These system variables set'
      print
      print,'   !black'
      print,'   !white'
      print,'   !red'
      print,'   !green'
      print,'   !blue'
      print,'   !yellow'
      print,'   !cyan or !lightblue'
      print,'   !magenta'
      print
      print,'For 8-bit, you can get back to black and white with loadct,0'
  ENDIF 

END 
