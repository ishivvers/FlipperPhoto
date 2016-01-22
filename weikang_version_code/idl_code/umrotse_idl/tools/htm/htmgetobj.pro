
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    htmGetObj
;       
; PURPOSE:
;    Get the objects from an htm tree leaf, labeled by leafid
;    (or array of leaf id's).
;    Currently objects consist of a simple structure containing
;    only an index and a pointer to the next object. This procedure 
;    returns the index of all objects (Note this index is not the
;    same as the htm leaf node index...
; 
;    HTM = hierarchical triangular mesh see http://www.sdss.jhu.edu/
;
; CALLING SEQUENCE:
;    htmGetObj, leafid, tree, depth, indices, count
;
; INPUTS: 
;    id: the leaf node id (can be an array)
;    tree: the HTM tree, as build by htmBuildTree
;
; OPTIONAL INPUTS:
;    NONE
;
; KEYWORD PARAMETERS:
;    NONE
;       
; OUTPUTS: 
;    The objects (only indices for now)
;
; OPTIONAL OUTPUTS:
;    count: the total number of objects found
;    leafempty: has an element corresponding to each input leafid.
;           if no objects were found for a leaf id then it will be
;           set to 1 else to 0.
;
; CALLED ROUTINES:
;    htmGetIdNode
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


PRO htmGetObj, leafid, tree, depth, indices, count, leafempty

  IF n_params() LT 3 THEN BEGIN 
      print,'-Syntax: htmGetObj, leafid, tree, depth, indices, [, count, leafempty]'
      print,'leafid can be an array'
      print,'Use doc_library,"htmGetObj"  for more help.'  
      return
  ENDIF 

  IF n_elements(indices) NE 0 THEN delvarx,indices

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; see how many leaf leafids have been entered. Then loop over
  ;; them, returning the objects.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  numid = n_elements(leafid)
  IF numid EQ 1 THEN leafempty = 0b ELSE leafempty = replicate(0b,numid)

  numlist = lonarr(numid)
  ptrlist = ptrarr(numid)
  count = 0L
  
  FOR ii=0L, numid-1 DO BEGIN 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; get the node for this leafid
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      tmpid = leafid[ii]
      idnode = htmGetIdNode(tmpid, tree, depth)
      tcount = (*idnode).nobj
      IF tcount NE 0 THEN BEGIN 

          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          ;; Loop through the object linked list and return the
          ;; indices
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          tindices = replicate(ulong(0), tcount)
          tmp = (*idnode).obj
          tindices[0] = (*tmp).index
          next = (*tmp).nextobj
          FOR i=1L, tcount-1 DO BEGIN 
              tmp = next
              tindices[i] = (*tmp).index
              next = (*tmp).nextobj
          ENDFOR 

          numlist[ii] = tcount
          count = count+tcount
          ptrlist[ii] = ptr_new(tindices)

      ENDIF ELSE leafempty[ii] = 0b
  ENDFOR 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; see if we found any objects
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF count EQ 0 THEN BEGIN
      indices = -1
      return
  ENDIF 

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; make a larger set of indices
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  indices = replicate(0L, count )
  beg=0L
  FOR ii=0L, numid-1 DO BEGIN 
      nlist = numlist[ii]
      IF nlist NE 0 THEN BEGIN 
          indices[ beg:beg+nlist-1 ] = *ptrlist[ii]
          ptr_free, ptrlist[ii]
          beg = beg + nlist
      ENDIF 
  ENDFOR 

  return

END 
