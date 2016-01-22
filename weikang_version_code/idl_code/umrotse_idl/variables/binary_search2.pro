pro binary_search2,arr,x,index
;+
; NAME: BINARY_SEARCH2
;
; PURPOSE: To quickly search an array for an element.
;
; CALLING SEQUENCE: BINARY_SEARCH2,ARR,X,INDEX
;
; INPUTS: arr - the array to search
;         x - the element to find in 'arr'
;
; OPTIONAL INPUTS:
;
; OUTPUTS: index - The index in 'arr' of the element 'x'
;
; OPTIONAL OUTPUTS:
;
; NOTES: 'arr' must be sorted in ascending order.
;  Binary_search2 is different from BINARY_SEARCH only
;     in the correction of a bug. In BINARY_SEARCH, if the value of 
;     an element is gt the largest value in 'arr' and lt the lowest,
;     but NOT in 'arr', index is returned as 0. In BINARY_SEARCH2,
;     such an index is returned as -1.          
;
; EXAMPLE: Find the index of 8 in arr=[3,4,6,7,8,9]
;       IDL> binary_search2,arr,8,index
;       IDL>print,index
;               4
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;               Susan Amrose       UM      11/15/98    fixed bug
;-
 On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
  print,'syntax- binary_search2,arr,x,index'
  return
endif

n=n_elements(arr)
if (x lt arr(0)) or (x gt arr(n-1)) then begin
	index=-1
	return
endif
down=-1
up=n
while up-down gt 1 do begin
	mid=down+(up-down)/2
	if x ge arr(mid) then begin
		down=mid
	endif else begin
		up=mid
	endelse
endwhile
if arr(down) ne x then index=-1 else index=down
return
end	
