;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    htmIntersectRadec
;       
; PURPOSE:
;    Find htm triangles that are within angle of input (ra,dec) position.
;    Some triangles may only partially intersect.
;
; CALLING SEQUENCE:
;    htmIntersectRadec, ra, dec, angle, depth, leaflist, linux=linux
;
; INPUTS: 
;    ra,dec: double precision position, must be scalar.
;
; OPTIONAL INPUTS:
;    NONE
;
; KEYWORD PARAMETERS:
;    /linux: use sofile made under linux
;       
; OUTPUTS: 
;    leaflist: the leaf id's for the (ra,dec) pairs.
;
; OPTIONAL OUTPUTS:
;    NONE
;
; CALLED ROUTINES:
;    DATATYPE
;    ISARRAY
;    htmIntersectRadec.so (shared object library)
;
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    ??-NOV-2000 Erin Scott Sheldon UofMich
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PRO htmIntersectRadec, ra, dec, angle, depth, leaflist, linux=linux

  IF n_params() LT 4 THEN BEGIN 
      print,'-Syntax: htmIntersectRadec, ra, dec, angle, depth, leaflist'
      print
      print,' ra,dec,angle must be double precision'
      print,' ra,dec in degrees'
      print,' angle in degrees'
      print,'Use doc_library,"htmIntersectRadec"'
      return
  ENDIF 

  time=systime(1)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; do some type checking
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF (datatype(ra) NE 'DOU') OR $
     (datatype(dec) NE 'DOU') OR $
     (datatype(angle) NE 'DOU')THEN $
    message,'ra,dec,angle must be of type double'

  IF isarray(ra) OR isarray(dec) OR isarray(angle) THEN $
    message,'ra,dec,angle must be scalars'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; check for bad values
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF (ra LT 0.) THEN message,'ra < 0'
  IF (ra GT 360.) THEN message,'ra > 360.'
  IF (dec LT -90.) THEN message,'dec < -90.'
  IF (dec GT 90.) THEN message,'dec > 90.'

  depth = long(depth)           ;Make sure long for C program
  d = cos( angle * (!dpi/180d) )              ;C-program takes in cos(angle)
  numdefault = 10000            ;default # of values in leaflist
  leaflist = replicate( ulong(0), numdefault )


  rotse_setup
  sofile = !sofile_path + '/htmIntersectRadec.so'
  entry = 'main'


  tmp = call_external(value=[0B,0B,0B,0B,0B], sofile, entry,$
                      depth, ra, dec, d, leaflist)

  w=where(leaflist NE 0,nw)
  IF nw NE 0 THEN leaflist=leaflist[w] ELSE leaflist = -1


END 
