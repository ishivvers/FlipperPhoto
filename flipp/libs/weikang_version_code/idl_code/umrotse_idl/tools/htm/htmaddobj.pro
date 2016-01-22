
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    htmAddObj
;       
; PURPOSE:
;    Add objects to a HTM tree leaf (hierarchical triangular mesh).
;    Currently objects consist of a simple structure containing
;    only an index and a pointer to the next object.
;  
;    HTM = hierarchical triangular mesh see http://www.sdss.jhu.edu/
;
; CALLING SEQUENCE:
;    htmAddObj, id, indices, tree
;
; INPUTS: 
;    id: the leaf node id.
;    indices: the indices of objects. e.g. indices in a structure
;             containing ra,dec
;    tree: the HTM tree, as build by htmBuildTree
;
; OPTIONAL INPUTS:
;    NONE
;
; KEYWORD PARAMETERS:
;    NONE
;       
; OUTPUTS: 
;    the augmented tree.
;
; OPTIONAL OUTPUTS:
;    NONE
;
; COMMON BLOCKS:
;     COMMON htmcomm, node, object, base
;
; CALLED ROUTINES:
;    htmGetIdNode
;    htmGetLastObj
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

PRO htmAddObj, id, tree, depth, indices

  IF n_params() LT 4 THEN BEGIN 
      print,'-Syntax: htmAddObj, id, tree, depth, indices'
      print
      print,'Use doc_library,"htmAddObj" for more help.'
      return
  ENDIF 

  COMMON htmcomm, node, object, base
  IF n_elements(node) EQ 0 THEN htmsetup

  nind = n_elements(indices)
  starti = 0L

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; get the node for this leaf id
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  idnode = htmGetIdNode(id, tree, depth, level, /fromtop)

  ;; Did we get to the leaf?
  IF level NE 0 THEN BEGIN 
      ;; Filling out the tree to required depth
      htmFill2Leaf, idnode, level, id
      temp = idnode
      idnode = htmGetIdNode(id, tree, depth, level, /fromtop)
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; we got the node, now check if there are already objects
  ;; at this node. If not, create the first object and point 
  ;; it at the first object in the indices array. Either way, 
  ;; set the pointer current to the last object.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  nobj = (*idnode).nobj
  IF nobj NE 0 THEN BEGIN
      current = htmGetLastObj( (*idnode).obj, nobj )
  ENDIF ELSE BEGIN  
      (*idnode).obj = ptr_new(object)
      current = (*idnode).obj    
      (*current).index = indices[0]
      starti = starti + 1L
  ENDELSE 
  (*idnode).nobj = nobj+nind

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Now loop over objects and dynamically create the linked 
  ;; list until we are out of objects
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  next = ptr_new(object)
  FOR i=starti, nind-1 DO BEGIN 
      (*current).nextobj = next

      tmp = (*current).nextobj
      (*tmp).index = indices[i]
      IF i NE nind-1 THEN BEGIN 
          next = ptr_new(object)
          current = tmp
      ENDIF 
  ENDFOR 


END 
