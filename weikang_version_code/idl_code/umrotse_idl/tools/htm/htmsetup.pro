PRO htmsetup

  COMMON htmcomm, node, object, base

  base = ulong(2)

  IF n_elements(node) EQ 0 THEN BEGIN 
      node = create_struct('id', ulong(0), $
                           'nobj',ulong(0),$
                           'obj',  ptr_new(), $
                           'sub1', ptr_new(), $
                           'sub2', ptr_new(), $
                           'sub3', ptr_new(), $
                           'sub4', ptr_new() )
      
      object = create_struct('index', -1L, $
                             'nextobj', ptr_new() )
  ENDIF 

  return
END 
