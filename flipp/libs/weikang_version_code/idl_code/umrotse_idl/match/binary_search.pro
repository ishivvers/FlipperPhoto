pro binary_search,arr,x,index, round=round, edgedefault=edgedefault
;+
;
; NAME:
;    BINARY_SEARCH
;
; CALLING SEQUENCE:
;    binary_search,arr,x,index [, /round ]
;
; PURPOSE:
;    Perform a binary search on arr, an input array, for the closest match
;    to x.  
;
;    Will give closest element of arr that is _smaller_ than x.  Set /round to 
;    gaurantee you get the closest overall element. -E.S.S.
;    Set /edgedefault to use endpoint if input x is gr arr[n-1] or x is lt arr[0]
;                                                   -E.S.S.
;
; Modification History
;   Author: Dave Johnston.
;   Added round keyword  04/29/00  Erin Scott Sheldon  UofMich
;   Added edgedefault keyword 07-Mar-2001
; 
;-

  if n_params() eq 0 then begin
      print,'syntax- binary_search,arr,x,index'
      return
  endif

  n=n_elements(arr)

  if (x lt arr[0]) or (x gt arr[n-1]) then BEGIN

      IF keyword_set(edgedefault) THEN BEGIN 
          CASE 1 OF
              (x LT arr[0]): index=0L
              (x GT arr[n-1]): index=n-1
          ENDCASE
      ENDIF ELSE index=-1L

      return
  ENDIF

  down=-1L
  up=long(n)

  while up-down gt 1 do begin
      mid=down+(up-down)/2
      if x ge arr(mid) then begin
          down=mid
      endif else begin
          up=mid
      endelse
  ENDWHILE

  index=down

  IF keyword_set(round) AND (index NE n-1) THEN BEGIN
      IF abs(x-arr[index]) GT abs(x-arr[index+1]) THEN index = index+1
  ENDIF 

  return
end	
