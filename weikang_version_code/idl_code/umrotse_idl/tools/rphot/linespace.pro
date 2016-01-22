function linespace,start,stop,size,step=step

;+
; NAME:
;       linespace
; PURPOSE:
;       creates a vector of floats over a given interval, and with a given number of elements
; TYPE:
; 	
; CALLING SEQUENCE:
;       Result = linespace(start,stop,size)
; INPUTS:
;       start --> the first element in the desired array
;       stop --> the last element in the desired array
;       size --> the number of elements in the array
; OPTIONAL INPUTS:
; 	
; KEYWORDS:
;       step --> use to create an array from start to stop with
;                neighboring elements seperated by step value
; 
; OUTPUTS:
;       [fltarr]
; COMMON BLOCKS:
; 	
; SIDE EFFECTS:
; 	
; EXAMPLES:
;       Result=linespace(0,1,100)  --> returns a 100 element array with
;       values ranging from 0 to 1 linearly
; PROCEDURE:
; 	
; MODIFICATION HISTORY:
;       Written by Robert Quimby '98
;-
if keyword_set(step) then size=abs( float(stop[0])-float(start[0]) )/float(step[0])+1
if size eq 1 then return,start[0]

x=temporary( findgen(float(size[0]))/(float(size[0])-1) )
x=temporary( x*(float(stop[0])-float(start[0])) )
x=temporary( x+float(start[0]) )

return,x
end
