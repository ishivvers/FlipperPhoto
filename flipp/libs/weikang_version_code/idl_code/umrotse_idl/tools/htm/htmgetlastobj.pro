FUNCTION htmGetLastObj, firstobj, nobj

  current = firstobj
  FOR i=1L, nobj-1 DO BEGIN 
      next = (*current).nextobj
      current = next
  ENDFOR 
  return,current
END 
