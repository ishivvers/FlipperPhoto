
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    htmDelTree
;       
; PURPOSE:
;    Free the memory used by an HTM tree. htmDelTree is used recursively.
;
;    HTM = hierarchical triangular mesh see http://www.sdss.jhu.edu/
;
; CALLING SEQUENCE:
;    htmDelTree, tree
;
; INPUTS: 
;    tree: an htm tree as made by htmBuildTree
;
; OPTIONAL INPUTS:
;    NONE
;
; KEYWORD PARAMETERS:
;    NONE
;       
; OUTPUTS: 
;    NONE
;
; OPTIONAL OUTPUTS:
;    NONE
;
; CALLED ROUTINES:
;    htmDelObjList (recursive)
; 
; PROCEDURE: 
;    
;	
;
; REVISION HISTORY:
;    11-DEC-2000 Creation Erin Scott Sheldon UofMich
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRO htmDelTree, tree

  IF n_params() LT 1 THEN BEGIN 
      print,'-Syntax: htmDelTree, tree'
      print
      print,'use doc_library,"htmDelTree" for more help'
      return
  ENDIF 

  IF NOT ptr_valid(tree) THEN return

  htmDelObjList, (*tree).obj
  IF ptr_valid( (*tree).sub4 ) THEN htmDelTree, (*tree).sub4
  IF ptr_valid( (*tree).sub3 ) THEN htmDelTree, (*tree).sub3
  IF ptr_valid( (*tree).sub2 ) THEN htmDelTree, (*tree).sub2
  IF ptr_valid( (*tree).sub1 ) THEN htmDelTree, (*tree).sub1
  ptr_free, (*tree).sub4
  ptr_free, (*tree).sub3
  ptr_free, (*tree).sub2
  ptr_free, (*tree).sub1
  ptr_free, tree

END 
