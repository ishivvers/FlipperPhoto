PRO htmFill2Leaf, bnode, level, leafid

  IF n_params() LT 3 THEN BEGIN 
      print,'-Syntax: htmFill2Leaf, node, level, leafid'
      return
  ENDIF 

  COMMON htmcomm, node, object, base
  IF n_elements(node) EQ 0 THEN htmsetup

  id = (*bnode).id
  nextlevel = level-1
  bit2level = nextlevel-1

  ;; figure out which way to go
  sub1id = id
  sub2id = id + base^bit2level
  sub3id = id + base^nextlevel
  sub4id = sub3id + base^bit2level
  
  IF level NE 0 THEN BEGIN 
      CASE 1 OF 
          (leafid GE sub4id): BEGIN 
              (*bnode).sub4 = htmAddNode(leafid, sub4id, bit2level)
          END
          (leafid GE sub3id): BEGIN 
              (*bnode).sub3 = htmAddNode(leafid, sub3id, bit2level)
          END 
          (leafid GE sub2id): BEGIN
              (*bnode).sub2 = htmAddNode(leafid, sub2id, bit2level)
          END 
          ELSE: BEGIN 
              (*bnode).sub1 = htmAddNode(leafid, sub1id, bit2level)
          END 
      ENDCASE 
  ENDIF 

END 
