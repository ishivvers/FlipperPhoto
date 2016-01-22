PRO htmDelObjList, obj

  IF ptr_valid(obj) THEN BEGIN
      htmdelobjlist, (*obj).nextobj
      ptr_free, obj
  ENDIF ELSE BEGIN 
      ptr_free,obj
  ENDELSE 

END 
