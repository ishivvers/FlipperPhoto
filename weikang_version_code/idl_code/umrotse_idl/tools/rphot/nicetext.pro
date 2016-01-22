function nicetext,ognum,ogdlen

;+
; NAME:
; 	nicetext
; PURPOSE:
; 	turns a float into a string rounding to a specified decimal place
; TYPE:
; 	
; CALLING SEQUENCE:
; 	Result = nicetext(num,dlen)
; INPUTS:
; 	num --> then number to convert
;	dlen --> then number of decmial places to keep
; OPTIONAL INPUTS:
; 	
; KEYWORDS:
; 	
; OUTPUTS:
; 	'123.4568'  (or similar)
; COMMON BLOCKS:
; 	
; SIDE EFFECTS:
; 	
; EXAMPLES:
; 	
; PROCEDURE:
; 	
; MODIFICATION HISTORY:
; 	Written by Robert Quimby '98
;-
num=ognum
if n_elements(ogdlen) ne 0 then dlen=ogdlen else dlen=3
n_num=n_elements(num)
n_dlen=n_elements(dlen)
if n_num eq 0 then begin
    num=0.0
    n_num=1
endif
if n_dlen eq 0 then begin
    dlen=3
    n_dlen=1
endif

;; ***** round the number to the appropiate palce ****
num=(double(num))*10.0^float(dlen)
temp=round(num)
temp=temp/10.0^float(dlen)
numstr=strcompress(temp,/remove_all)

;; ***** find out where the decimal is *****
for j=0,n_num-1 do begin
    for i=0,strlen(numstr[j])-1 do begin
        temp=strmid(numstr[j],i,1)
        if temp eq '.' then dind=i
    endfor
    
    ;; ***** add any 0's if necessary *****
    if n_elements(dind) eq 0 then begin
        numstr=numstr+'.'
        dind=strlen(numstr)
    endif
    pad='0000000000000000000000000000000000000'
endfor

if dlen le 0 then return,strmid(numstr+pad,0,dind+dlen)
return,strmid(numstr+pad,0,dind+dlen+1)
end
