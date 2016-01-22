FUNCTION htmAddNode, leafid, nodeid, level

  COMMON htmcomm, node, object, base

  tmp = ptr_new(node)
  (*tmp).id = nodeid

  IF level NE 0 THEN BEGIN 

      nextlevel = level-1
      bit2level = nextlevel-1

      ;; figure out which way to go
      sub1id = nodeid
      sub2id = nodeid + base^bit2level
      sub3id = nodeid + base^nextlevel
      sub4id = sub3id + base^bit2level

      CASE 1 OF 
          (leafid GE sub4id): BEGIN 
              (*tmp).sub4 = htmAddNode(leafid, sub4id, bit2level)
          END
          (leafid GE sub3id): BEGIN 
              (*tmp).sub3 = htmAddNode(leafid, sub3id, bit2level)
          END 
          (leafid GE sub2id): BEGIN
              (*tmp).sub2 = htmAddNode(leafid, sub2id, bit2level)
          END 
          ELSE: BEGIN
              (*tmp).sub1 = htmAddNode(leafid, sub1id, bit2level)
          END 
      ENDCASE 
  ENDIF
  return,tmp

END 
