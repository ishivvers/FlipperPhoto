PRO rdyanny, file, struct

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    RDYANNY
;       
; PURPOSE:
;    Read in a minimal Brian Yanny parameter file.  The file must have only 
;    one structure definition and one set of data.  
;
;  For more info:  http://www-sdss.fnal.gov:8000/dervish/doc/www/tclP2c.html
;
; CALLING SEQUENCE:
;     rdyanny, file, struct
;
; INPUTS: 
;    file:  The full path filename to the Yanny parameter file.
;
; OPTIONAL INPUTS:
;    None.
;
; KEYWORD PARAMETERS:
;    None.
;       
; OUTPUTS: 
;    struct: An array of structures.  The structure has a tag for each 
;            parameter in the typedef statement at the top of the file.
;
; OPTIONAL OUTPUTS:
;    None.
;
; CALLED ROUTINES:
;    READCOL
; 
; PROCEDURE: 
;    Figure out the tags from the typedef statement.  Then define a structure
;    with these tags.  Read in the data and make an array of the structures, 
;    one element for each line of the file.
;	
;
; REVISION HISTORY:
;    Author: Erin Scott Sheldon  11/19/99   UofMich
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  IF N_params() EQ 0 THEN BEGIN 
     print,'-Syntax: rdyanny, file, struct'
     print,''
     print,'Use doc_library,"rdyanny"  for more help.'  
     return
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Parameters
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  command = 'readcol, file, format=fmt, front '

  maxtag = 25
  types = strarr(maxtag)
  names = strarr(maxtag)

  string=''

  openr, lun, file, /get_lun

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Look for typedef statement at top of file
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  continue=1
  WHILE continue AND (NOT eof(lun) ) DO BEGIN

      readf,lun,string,format='(A100)'

      test = strmid(strcompress(string, /remove_all), 0, 7)

      IF test EQ 'typedef' THEN continue = 0

  ENDWHILE

  IF eof(lun) THEN BEGIN
      print,'typedef statement not found'
      close, lun
      free_lun, lun
      return
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Read in the types
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ntag = 0
  continue = 1
  WHILE continue DO BEGIN

      readf,lun,string,format='(A100)'
      
      test = str_sep( strcompress(string), ' ')
      
      w=where(test NE '', nw)
      IF nw GE 2 THEN BEGIN
          test2 = test(w[0])
          IF test2 EQ '}' THEN BEGIN
              continue = 0 
              structname = ( str_sep( test(w[1]), ';') )[0]
              namelength = strlen(structname)
              fmt = 'A'+ntostr(namelength)
          ENDIF ELSE BEGIN 
              types[ntag] = test2
              names[ntag] = ( str_sep( test(w[1]), ';') )[0]
              ntag = ntag+1
          ENDELSE 
      ENDIF 
  ENDWHILE 

  close, lun
  free_lun, lun

  w=where(types NE '', nw)
  IF nw NE 0 THEN BEGIN
      types = types[w]
      names = names[w]
      ntag = n_elements(types)
  ENDIF ELSE BEGIN
      print,'typedef statement is invalid'
      return
  ENDELSE 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; create a structure that contains all possible TCL types.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  tpstr = create_struct('float', 0., $  ;0
                        'double',0d, $  ;1
                        'long', 0L,  $  ;2
                        'int', 0L,    $ ;3 Make long to be safe.
                        'char', '')     ;4
  tptags = ['float','double','long','int','char'] ;same order!    
  format = ['F',    'D',     'L',   'L',  'A']
                                    ; Make both long

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Create our structure prototype
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  FOR i=0, ntag-1 DO BEGIN
      
      w=where( tptags EQ types[i], nw)
      IF nw EQ 0 THEN BEGIN
          print,types[i],' is not a legal type'
          print,'Defaulting to float'
          w=where(tptags EQ 'float')
          types[i] = 'float'
      ENDIF 

      fmt = fmt+','+format(w[0])

      IF types[i] EQ 'char' THEN BEGIN
          tmp = str_sep(names[i], '[')
          IF n_elements(tmp) EQ 2 THEN BEGIN
              names[i] = tmp[0]
              tmp2 = str_sep(tmp[1], ']')
              fmt = fmt+tmp2[0]
              print,tmp2[0]
          ENDIF 
      ENDIF 
      command = command+','+names[i]

      IF i EQ 0 THEN BEGIN
          str = create_struct( names[i], tpstr.(w[0]) )
      ENDIF ELSE BEGIN
          str = create_struct( str, names[i], tpstr.(w[0]) )
      ENDELSE 

  ENDFOR 

  command = command+',/silent'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; run readcol on the input file
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  result = execute(command)
  IF result NE 1 THEN BEGIN
      print,'Execution failed'
      return
  ENDIF 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Check if it read any lines.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  check='n = n_elements('+names[0]+')'
  result = execute(check)
  IF n EQ 0 THEN BEGIN
      print,'No valid lines read'
      return
  ENDIF ELSE BEGIN
      print,'Number of tags: ',ntostr(ntag)
      print,ntostr(n),' valid lines read'
  ENDELSE
  struct = replicate(str, n)

  FOR i=0, ntag-1 DO BEGIN
      
      cmd = 'struct.(i) = '+names[i]
      result = execute(cmd)

  ENDFOR 


return
END 
      
