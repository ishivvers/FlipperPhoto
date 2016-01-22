pro close_match,t1,s1,t2,s2,m1,m2,ep,allow,miss1,silent=silent,circle=circle
;+
; NAME:
; close_match
;
; PURPOSE:
; this will find close matches between 2 sets of points (t1,s1)
; and (t2,s2) (note t1,t2,s1,s2 are all arrays) in a 2 dimentional space.
; differnt then close_match in that it gives the 'allow' CLOSEST matches
; CALLING SEQUENCE:
; close_match,t1,s1,t2,s2,m1,m2,ep,allow,miss1
;
; INPUTS:
; t1,s1: the coordinates of the first set
; t2,s2: the coordinates of the second set
; ep:  this is the error which defines a close match. A pair is considered
; a match if |t1-t2| AND |s1-s2| are both less than ep. This is faster
; than doing a euclidean measure on the innermost loop of the program
; and just as good.
; allow: how many matches in the (t2,s2) space will you allow for
; each (t1,s1)
;
; OUTPUTS:
; m1,m2: the indices of the matches in each space. That is  
; (t1(m1),s1(m1)) matches (t2(m2),s2(m2))
; miss1: this gives the index of the things in x1 NOT found to match (optional)
;
; OPTIONAL KEYWORD PARAMETERS:
; silent: don't print output
; circle: truncate the match to match within an aperture of radius ep
;
; NOTES:
; It sorts the t2 list so that it can do a binary search for each t1.
; It then carves out the sublist of t2 where it is off by less than ep.
; It then only searches that sublist for points where s1 and s2 differ
; by less than ep. 
; PROCEDURES CALLED:
; binary_search, rem_dup
; REVISION HISTORY:
; written by David Johnston -University of Michigan June 97
;
;   Tim McKay August 97
; 	bug fixed, matcharr extended to "long" to accomodate ROTSE I images
;   Tim McKay July 99
;	bug fixed to correctly handle the first object in list 2, and 
;	especially the case with a single object in list 2
;   Eli Rykoff Mat '00
;	added /circle option to match within a circle at the end.
;-
; On_error,2                                      ;Return to caller

 if N_params() LT 8 then begin
    print,'Syntax - close_match,t1,s1,t2,s2,m1,m2,ep,allow,miss1,silent=silent,circle=circle'
    return
 endif


n1=n_elements(t1)
n2=n_elements(t2)
matcharr=lonarr(n1,allow)	;the main book-keeping device for 
matcharr(*,*)=-1		;matches -initialized to -1
ind=lindgen(n2)
sor=sort(t2)  			;sort t2
t2s=t2(sor)
s2s=s2(sor)
ind=ind(sor)			;keep track of index
runi=0
endt=t2s(n2-1)
for i=0l , n1-1l do begin		;the main top level loop over t1
	t=t1(i)
	tm=t-ep			;sets the range of good ones
	tp=t+ep
	binary_search,t2s,tm,in1 
	;searched for the first good one 
	if in1 eq -1 then if tm lt endt then in1=0
	;in case tm smaller than all t2 but still may be some matches
	if in1 ne -1 then begin	
		in1=in1+1
		in2=in1-1
		jj=in2+1
		while jj lt n2 do begin
			if t2s(in2+1) lt tp then begin
				in2=in2+1 & jj=jj+1 
			endif else jj=n2
		endwhile
		if (n2 eq 1) then in2 = 1
		;while loop carved out sublist to check
		;a little tricky,be careful
		if in1 le in2 then begin
			if (n2 ne 1) then begin
			  check=s2s(in1:in2) ;the sublist to check
			  tcheck=t2s(in1:in2)
			endif else begin
			  check=s2s(0)
			  tcheck=t2s(0)
			endelse
			s=s1(i)
			t=t1(i)
			offby=abs(check-s)
			toffby=abs(tcheck-t)
			;good=(where(check gt sm and check lt sp,ngood))+in1
			good=where(offby lt ep and toffby lt ep,ngood)+in1
			;the selection made here
			if ngood ne 0 then begin
				if ngood gt allow then begin
					offby=offby(good-in1)
					toffby=toffby(good-in1)
					dist=sqrt(offby^2+toffby^2)
					good=good(sort(dist))
					;sorts by closeness
					ngood=allow
				;not more than you are allowed by 'allow'
				endif	 
				good=good(0:ngood-1)
				matcharr(i,0:ngood-1)=good
				;finally the matches are entered in 
                        	runi=runi+ngood  ;a running total
			endif 
		endif
	endif
endfor
if not keyword_set(silent) then print,'total put in bytarr',runi
matches=where(matcharr ne -1,this)
if this eq 0 then begin
	if not keyword_set(silent) then $
	print,'no matches found'
	m1=-1 & m2=-1
	return
endif
m1=matches mod n1	;a neat trick to extract them correctly 
m2=matcharr(matches)    ;from the matcharr matrix
m2=ind(m2) 	;remember, must unsort

if keyword_set(circle) then begin
	dist=sqrt((t1(m1) - t2(m2))^2 + (s1(m1) - s2(m2))^2)
        truematch=where(dist lt ep,tcount)
        if (tcount gt 0) then begin
	   m1=m1(truematch)
	   m2=m2(truematch)
	endif
endif

if not keyword_set(silent) then $
print,n_elements(m1),' matches'
dif=m1(uniq(m1,sort(m1)))
if not keyword_set(silent) then $
print,n_elements(dif),' different matches'
if n_params() eq 9 then begin
	if n_elements(m1) lt n1 then begin
		miss1=lindgen(n1)
		remove,dif,miss1
		if not keyword_set(silent) then $
		print,n_elements(miss1),'  misses'
	endif else begin
		miss1=-1  
	        if not keyword_set(silent) then $
		print,'no misses'
	endelse 
endif


return
end



