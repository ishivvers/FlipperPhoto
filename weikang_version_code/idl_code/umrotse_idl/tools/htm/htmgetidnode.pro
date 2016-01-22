FUNCTION htmGetIdNode, id, tree, depth, level, fromtop=fromtop

  IF n_params() LT 3 THEN BEGIN
      message,'incorrect # of args',/cont
      message,'-Syntax: node=htmGetIdNode(id, tree, depth, level, fromtop=fromtop)'
  ENDIF 

  COMMON htmcomm, node, object, base
  IF n_elements(node) EQ 0 THEN htmsetup

  blevel = htmBottomLevel(depth)
  minid = base^blevel
  maxid = base^(blevel+1)-1

  IF (id LT minid) OR (id GT maxid) THEN BEGIN
      message,'invalid id '+ntostr(id),/cont
      message,ntostr(minid)+' < id < '+ntostr(maxid)+' for depth='+ntostr(depth)
  ENDIF 

  IF keyword_set(fromtop) OR (n_elements(level) EQ 0) THEN BEGIN
      level=blevel              ;top node is special case
  ENDIF ELSE IF (level EQ blevel) THEN BEGIN 
      level = level-1           ;also, increment after first node is special
      pow1 = level-1            ;first bit
      pow2 = level-2            ;second bit
  ENDIF ELSE BEGIN 
      level=level-2
      pow1 = level-1
      pow2 = level-2
  ENDELSE 
  ;; we have reached the leaf
  IF level EQ 0 THEN return,tree


  ;; if level is not zero, we should check if the lower level exists
  sub1id = (*tree).id
  IF sub1id EQ 0 THEN BEGIN     ; top node gets treated differently
      sub1id = -1 
      sub2id = -1
      sub3id = minid
      sub4id = sub3id + base^(level-1)
  ENDIF ELSE BEGIN 
      IF (sub1id GT maxid) OR (sub1id LT minid) THEN $
        message,'depth '+ntostr(depth)+' does not match tree depth'
      sub2id = sub1id + base^pow2
      sub3id = sub1id + base^pow1
      sub4id = sub3id + base^pow2
  ENDELSE 

  IF id GE sub4id THEN BEGIN 
      tmp = (*tree).sub4
      IF ptr_valid(tmp) THEN return,htmGetIdNode(id,tmp,depth,level)$
      ELSE BEGIN
          return,tree
      ENDELSE 
  ENDIF 
  IF id GE sub3id THEN BEGIN
      tmp = (*tree).sub3
      IF ptr_valid(tmp) THEN return,htmGetIdNode(id,tmp,depth,level)$
      ELSE BEGIN
          return,tree
      ENDELSE 
  ENDIF 
  IF id GE sub2id THEN BEGIN
      tmp = (*tree).sub2
      IF ptr_valid(tmp) THEN return,htmGetIdNode(id,tmp,depth,level)$
      ELSE BEGIN
          return,tree
      ENDELSE 
  ENDIF 
  IF id GE sub1id THEN BEGIN
      tmp = (*tree).sub1
      IF ptr_valid(tmp) THEN return,htmGetIdNode(id,tmp,depth,level)$
      ELSE BEGIN
          return,tree
      ENDELSE 
  ENDIF 

END 
