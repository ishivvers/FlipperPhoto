pro get_votearr,nobjs,stris1,stris2,m1,m2,votearr,objm1,objm2,goodness,prompt=prompt,show=show
;+
; NAME:
;get_votearr
;
; PURPOSE:
;This program is designed to pick out the stars that are really 
;matches from the ones that are just "noise matches". This program 
;loops over all the matched triangles and gives a vote to the vote
;array at every spot where one stars gets matched to another. The 
;collumn index of votearr refers to the index of the stars of the 
;first list and the row index to the second list. The idea behind
;this method is that for real matches the spot will get many votes
;and the false matches will be randomly spread as noise throughout
;the votearr. Then the program decides how many votes are neccesary
;to make the cut and these are then selected as real matches. 
;
; CALLING SEQUENCE:
;get_votearr,nobjs,stris1,stris2,m1,m2,votearr,objm1,objm2,goodness,prompt=prompt
;
; INPUTS:
;nobjs: the number of stars in both lists (individually not total)
;stris1,stris2: the correctly sorted matching star indice list
;               that has come out of find_stars_from_tris
;m1,m2: the indices of the matching triangles that has come out of 
;       close_match
;
; OUTPUTS:
;votearr: the vote array that contains the information of what
;         the real matches are and how many votes each recieved
;objm1,objm2: the indices of the real matching stars
;goodness: the value in the vote arrray for the indices objm1 and objm2
;
; OPTIONAL KEYWORD PARAMETERS:
;prompt: if set then it will prompt you for the cut in the vote array
;instead of deciding itself.
;show : shows the votearr and does some talking
;
; NOTES:
;the current method for deciding the cut is to take "frac" times
;the maximum vote cast. frac is set in the program at about .5
;but this could be handed as a variable if one wished
;this is simple and works well although perhaps there is a better
;way 
;
; PROCEDURES CALLED:
;rem_dup
; REVISION HISTORY:
;David Johnston University of Michigan June 97
;-
 On_error,2                                      ;Return to caller

 if N_params() LT 4 then begin
    print,'Syntax - 
    return
 endif



ntris=n_elements(m1)
votearr=intarr(nobjs,nobjs)
for i=0l,ntris-1l do begin
	tr1=stris1(*,i)
	tr2=stris2(*,i)
	votearr(tr1,tr2)=votearr(tr1,tr2)+1
endfor
if keyword_set(show) then print,strcompress(votearr)

if keyword_set(prompt) then begin
	print,'enter need value'
	read,need
endif else begin
	frac=.4
	max=max(votearr)
	starfrac=.5
	fakenum=starfrac*nobjs
	fakemax=((fakenum-1)*(fakenum-2))/2
	need=(frac*max) > (frac*fakemax) 
endelse
if keyword_set(show) then print,'cut in vote array is ',need

matches=where(votearr gt need,nummat)

if nummat lt 3 then begin
	print,'fewer than three matches found'
	print,'cannot compute transform'
	goodness=-1
	return
endif

objm1=matches mod nobjs
dup=rem_dup(objm1)
if keyword_set(show) then begin
print,n_elements(objm1)-n_elements(dup),' multi matches removed'
endif
objm1=objm1(dup)
nmat=n_elements(objm1)
goodness=intarr(nmat)
objm2=intarr(nmat)
for i=0, nmat-1 do begin
	j=objm1(i)
	goodness(i)=max(votearr(j,*),mind)
	objm2(i)=mind
endfor
if keyword_set(show) then print,n_elements(objm1),' objects matches'
return
end
