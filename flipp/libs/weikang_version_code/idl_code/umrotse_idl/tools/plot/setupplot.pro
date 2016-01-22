PRO setupplot, type, help=help, test=test, true=true, invbw=invbw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    SETUPPLOT
;       
; PURPOSE:
;    Set up default plotting parameters. Parameters are taken from
;    the !pslayout system variable, created by the pslayout procedure.
;    The user should put a copy of pslayout in their path and change
;    the defaults to suit them. Note pslayout tags are mainly for use
;    by begplot; setupplot only implements things that are different
;    for X or POSTSCRIPTS
;
;    Also runs simpctable, to create a set of colors, and defsymbols
;    to define the system variables !tsym for true-type font symbols
;    and !vsym for vector drawn font symbols.
;
; CALLING SEQUENCE:
;    setupplot [, type, help=help, test=test, true=true, /invbw]
;
; INPUTS: 
;    NONE
;
; OPTIONAL INPUTS:
;    type: 'x' or 'ps'. This is usually unnecessary since setupplot
;          can figure out which device is in use, but the user
;          can put a names variable here and it will return
;          the device.
;
; KEYWORD PARAMETERS:
;    /true: Can set /true to use true-type fonts. Can be used to override
;           the true tag in !pslayout
;    /test: run a test showing all the symbols created by defsymbols.pro
;    /help: print simple syntax/help.
;    /invbw: flip colors
;       
; OUTPUTS: 
;    None unless /test, in which case some plots are made.
;
; OPTIONAL OUTPUTS:
;    None
;
; CALLED ROUTINES:
;    PSLAYOUT
;    SIMPCTABLE
;    DEFSYMBOLS
; 
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    19-Mar-2001 Erin Scott Sheldon UofMich
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF keyword_set(help) THEN BEGIN 
     print,'-Syntax: setupplot [dtype, type, help=help, test=test]'
     print,''
     print,' Will setup plotting parameters; sets system variables'
     print,' for various plotting symbols. '
     print,' use type="ps" for postscript "x" for x-window'
     print,' If type is not given, then it is determined from the !d.flags'
     print,'Use doc_library,"msetupplot"  for more help.'  
     return
  ENDIF 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Check input device type (optional)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF n_elements(type) NE 0 THEN BEGIN 
      IF datatype(type) NE 'STR' THEN BEGIN
          print,'type must be a string "ps" or "x"'
          return
      ENDIF 
  ENDIF ELSE BEGIN 
     ;; IF (!d.flags AND 1) EQ 0 THEN type='X' ELSE type='PS'
      if (!d.name eq 'X') then begin 
          type = 'X'
      endif else if (!d.name eq 'Z') then begin
          type = 'Z'
      endif else if (!d.name eq 'PS') then begin
          type = 'PS'
      endif else begin
          print,'device type must be "ps", "x" or "z"'
      endelse
  ENDELSE 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; run pslayout. Will define !pslayout (if not already defined)
  ;; which contains defaults for postscript output and other stuff,
  ;; including whether or not we should use true-type fonts (or 
  ;; postscript fonts if device is 'ps')
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  pslayout
  IF n_elements(true) EQ 0 THEN BEGIN
      IF !pslayout.true EQ 1 THEN true=1 ELSE true=0
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; set up a simple color table
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  simpctable

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; set default background to white if requested
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  IF !pslayout.invbw THEN BEGIN 
;      !p.background=!white
;      !p.color = !black
;  ENDIF 

  IF keyword_set(invbw) THEN BEGIN 
      !p.background=!white
      !p.color = !black
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; set system variables in device dependent way
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  CASE strupcase(type) OF
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Defaults for the postscript output
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      'PS': BEGIN 
          !p.thick = !pslayout.ps_thick
          !x.thick = !pslayout.ps_xthick
          !y.thick = !pslayout.ps_ythick
          !p.charsize = !pslayout.ps_charsize
          !p.charthick = !pslayout.ps_charthick

          ;; symbols/font defined same way for true and postscript fonts
          IF keyword_set(true) THEN !p.font=0

      END
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Defaults for the X-windows display
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      'X': BEGIN
          !p.thick = !pslayout.x_thick
          !x.thick = !pslayout.x_xthick
          !y.thick = !pslayout.x_ythick
          !p.charsize = !pslayout.x_charsize
          !p.charthick= !pslayout.x_charthick

          ;; use true-type fonts in X?
          IF keyword_set(true) THEN BEGIN
              !p.font = 1 

              ;; set the default font
              ;; make a dummy window
              window,/free,/pixmap,xsize=1,ysize=1
              fset=!pslayout.font
              IF !pslayout.bold THEN fset=fset+' bold'
              IF !pslayout.italic THEN fset=fset+' italic'
              device,set_font=fset,/tt_font
              wdelete,!d.window

          ENDIF ELSE BEGIN
              !p.font=-1
          ENDELSE 

      END 
      'Z': begin
          !p.thick = !pslayout.x_thick
          !x.thick = !pslayout.x_xthick
          !y.thick = !pslayout.x_ythick
          !p.charsize = !pslayout.x_charsize
          !p.charthick= !pslayout.x_charthick

          ;; use true-type fonts in Z?
          IF keyword_set(true) THEN BEGIN
              !p.font = 1 

              ;; set the default font
              ;;fset=!pslayout.font
              fset='helvetica bold'
              IF !pslayout.italic THEN fset=fset+' italic'
              ;;print,fset
              device,set_font=fset,set_character_size=[7,7]

          ENDIF ELSE BEGIN
              !p.font=-1
          ENDELSE 
      end
      ELSE: message,'type '+type+' unknown'
  ENDCASE 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Define new system variables to aid plotting 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; golden ratio: send to aplot
  defsysv,'!gratio', exists=exists
  IF NOT exists THEN defsysv,'!gratio',1.36603

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; define the plotting symbols (both true and vector)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  defsymbols

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; demonstrate the symbols if requested 
  ;; go 3 columns per page
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  dopage = 1
  column = 1
  IF keyword_set(test) THEN BEGIN 
      
      IF type EQ 'PS' THEN size=0.85 ELSE size=1.5

      IF keyword_set(true) THEN BEGIN
          print,'Testing true type fonts: switching to times'
          sym=!TSYM 
          symtags = tag_names(sym)
          symtags = '!!TSYM.' + symtags
          firstmess='Symbols defined in !!TSYM system variable'
      ENDIF ELSE BEGIN
          print,'Testing vector drawn fonts: simplex roman'
          sym=!VSYM
          symtags = tag_names(sym)
          symtags = '!!VSYM.' + symtags
          firstmess='Symbols defined in !!VSYM system variable'
      ENDELSE 
      
      ntags = n_elements(symtags)

      plot,[0],/nodata,ystyle=4,xstyle=4
      xyouts,0,1,firstmess

      xstep = .35
      ystep = .1

      ystart = 0.9
      y=ystart
      x = 0.0
      FOR i=0, ntags-1 DO BEGIN 

          IF ( (i+1) MOD 10) EQ 0 THEN BEGIN

              column=column+1
              IF (column EQ 4) OR (i EQ 0)  THEN BEGIN
                  column=1
                  x = 0
                  IF strupcase(type) EQ 'X' THEN key=get_kbrd(1)
                  plot,[0],/nodata,ystyle=4,xstyle=4
              ENDIF ELSE  x = x + xstep
              y = ystart
             
              xyouts, x, y, symtags[i]+'  '+SYM.(i),charsize=size
          ENDIF ELSE BEGIN
              IF i NE 0 THEN y = y - ystep
              xyouts, x, y, symtags[i]+'  '+SYM.(i),charsize=size
          ENDELSE 
      ENDFOR 

  ENDIF 

  return 
END 
