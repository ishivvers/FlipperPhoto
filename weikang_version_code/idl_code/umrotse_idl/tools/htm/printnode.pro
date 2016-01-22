PRO printnode, node

  IF ptr_valid( (*node).sub1) THEN BEGIN
      print,'sub1'
      tmp = (*node).sub1
      help,(*tmp),/str
      printnode,tmp
      print
  ENDIF 

  IF ptr_valid( (*node).sub2) THEN BEGIN
      print,'sub2'
      tmp = (*node).sub2
      help,(*tmp),/str
      printnode,tmp
      print
  ENDIF 

  IF ptr_valid( (*node).sub3) THEN BEGIN
      print,'sub3'
      tmp = (*node).sub3
      help,(*tmp),/str
      printnode,tmp
      print
  ENDIF 

  IF ptr_valid( (*node).sub4) THEN BEGIN
      print,'sub4'
      tmp = (*node).sub4
      help,(*tmp),/str
      printnode,tmp
      print
  ENDIF 

END 
