PRO pslayout

  defsysv,'!pslayout',exist=exist

  IF NOT exist THEN BEGIN 
      
      pslayout = {runsetup:1,$  ;should begplot/endplot run setupplot?
                  name:'ps', $
                  bits_per_pixel:4, $
                  bold:1, $
                  book:0, $
                  close_file:0, $
                  color:0, $
                  demi:0, $
                  Encapsulated:0, $
                  filename:'idl.ps', $
                  font:'times', $ ;the default true-type or postscript font
                  true: 1, $    ;use true-type fonts?
                  font_index:0, $
                  font_size:12, $
                  italic:0, $
                  inches:1, $
                  landscape:0, $
                  light:0, $
                  medium:0, $
                  narrow:0, $
                  oblique:0, $
                  output:'', $
                  portrait:1, $
                  preview:1, $
                  scale_factor:1.0, $
                  xoffset:0.75, $
                  xsize:7.0, $
                  yoffset:1.0, $
                  ysize:9.0,$
                  invbw:1,$
                  $             ; default plotting parameters for 'ps' device
                  ps_thick:5, $
                  ps_xthick:5, $
                  ps_ythick:5, $
                  ps_charsize:1.3,$
                  ps_charthick:4,$ ;charthick only has meaning for true=0 above
                  $             ; default plotting parameters for 'x' device
                  x_thick:1, $
                  x_xthick:1, $
                  x_ythick:1, $
                  x_charsize:1.5,$
                  x_charthick:1}

      defsysv,'!pslayout',pslayout

  ENDIF
  

END 
