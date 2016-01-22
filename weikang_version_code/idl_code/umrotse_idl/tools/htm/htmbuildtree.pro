PRO htmBuildTree, depth, ra, dec, tree, uniqleafid=uniqleafid

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


  IF N_params() LT 3 THEN BEGIN 
     print,'-Syntax: htmBuildTree, depth, ra, dec, tree, uniqleafid=uniqleafid'
     print,''
     print,'Use doc_library,""  for more help.'  
     return
  ENDIF 

  IF n_elements(tree) EQ 0 THEN BEGIN 
      htmNewTree, depth, tree
  ENDIF 

  htmLookupRadec, ra, dec, depth, leafids

  uniqleafid = leafids[ rem_dup(leafids) ]
  nuniq = n_elements(uniqleafid)

  FOR i=0L, nuniq-1 DO BEGIN 
      id = uniqleafid[i]
      w=where(leafids EQ id, nobj)
      
      htmAddObj, id, tree, depth, w
      IF ( (i+1) MOD 100 ) EQ 0 THEN print,ntostr(i+1)+'/'+ntostr(nuniq)+$
        ' leafid: '+ntostr(id)+' nobj: '+ntostr(nobj)
  ENDFOR 

  return 
END 

