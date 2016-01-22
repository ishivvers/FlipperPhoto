
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    htmNewTree
;       
; PURPOSE:
;    Build the root node and north/south nodes of an HTM tree with
;    the specified depth.
;    HTM = hierarchical triangular mesh. see http://www.sdss.jhu.edu/
;
; CALLING SEQUENCE:
;    htmNewTree, depth, tree
;
; INPUTS: 
;    depth: The depth of the tree. 0th level splits the sphere into 8 
;           triangles. Each triangle is split into 4 at level 1, and
;           each of these is split into 4 at the next level, etc.
;           Limit is level 14 which is ~4 square arcseconds/triangle.
;
; OPTIONAL INPUTS:
;    NONE
;
; KEYWORD PARAMETERS:
;    NONE
;       
; OUTPUTS: 
;    tree: an HTM tree to specified depth.
;
; OPTIONAL OUTPUTS:
;    NONE
;
; COMMON BLOCKS:
;     COMMON htmcomm, node, object, base
;
; CALLED ROUTINES:
;    htmAddNode (recursive)
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

PRO htmNewTree, depth, tree

  IF n_params() LT 1 THEN BEGIN 
      print,'-Syntax: htmNewTree, depth, tree'
      print,''
      print,'Use doc_library,"htmNewTree"  for more help.'  
      return
  ENDIF 

  COMMON htmcomm, node, object, base

  IF n_elements(node) EQ 0 THEN htmsetup

  ;; set up bottom level
  bottom_level = htmBottomLevel(depth)
  nextlevel = bottom_level-1
  bottomid = base^bottom_level
  maxid = base^(bottom_level+1)-1
  print,'--------------------------------------
  print,' Initializing tree'
  print,' bottom level',bottom_level
  print,' bottom id = ',bottomid
  print,' maxid = ',maxid
  print,' nextlevel = ',nextlevel
  print,'--------------------------------------

  IF n_elements(tree) NE 0 THEN htmDelTree,tree
  tree = ptr_new(node)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; root is a special node, must build separately
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; north
  (*tree).sub4 = ptr_new(node)
  (  *((*tree).sub4) ).id = bottomid + base^nextlevel
  ;; south
  (*tree).sub3 = ptr_new(node)
  (  *((*tree).sub3) ).id = bottomid

END 
