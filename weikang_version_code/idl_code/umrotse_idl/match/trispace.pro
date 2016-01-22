pro trispace, x, y,td1,td2,trindex,tris,hyp
;+
;NAME
;	trispace
;PURPOSE 
;	it takes the x,y positions of objects and constructs a list
;	of triangles "tris" and then it calculates the length of the 3
;	sides and determines the two ratios of the biggest side to the 
; 	other 2 sides. So from a 2 dimentional
;       position space it creates a 2 dimentional triangle space 
;       it also returns some indexing information linking the 
;       triangle space to the star space.
;CALLING SEQUENCE trispace,x,y,td1,td2,trindex,tris,hyp
;
;INPUTS 
;x=x positions (x and y arrays)
;y=y positions
;OUTPUTS
;td1,td2: the two triangle sides (normalized by hyp) and sorted in 
;         that order ,td1 smaller
;tris: this is a (3,numtris) array such that tris(3,i) is a list 
;      of the indices of the 3 stars in the ith triangle
;trindex: this (3,numtris) array gives the order by size of the 
;         sides for the ith triangle. The sides are as follows:
;         [0 to 1,1 to 2,2 to 0] where 0,1,2 refer to the indices
;         of the triangles in tris. This order is crucial to programs 
;         like find_stars_from_tris which match stars once triangles
;         been matched.	
;hyp: the hypotenuse can be returned for scale information
;     but is optional
;
;INPUT KEYWORD PARAMETERS
;none
;
;PROCEDURES CALLED:
;combinations_of3
;
;REVISION HISTORY
;	David Johnston UM may 97
;-
On_error,2	;Return to caller
if n_params() lt 6 then begin
print, 'syntax-trispace, x, y,td1,td2,trindex,tris,hyp'
return
endif


combinations_of3,n_elements(x),tris	;the triangle indices straight 
				        ;from combinatorics

tposx=[x(tris(0,*)),x(tris(1,*)),x(tris(2,*))]
tposy=[y(tris(0,*)),y(tris(1,*)),y(tris(2,*))]	
; the x and y arrays of the triangle positions

dis=[abs(complex(tposx(0,*)-tposx(1,*),tposy(0,*)-tposy(1,*))), $
abs(complex(tposx(1,*)-tposx(2,*),tposy(1,*)-tposy(2,*))), $
abs(complex(tposx(2,*)-tposx(0,*),tposy(2,*)-tposy(0,*)))]
;the array of the three lengths , messy but effective

si=size(tris)
trindex=intarr(3,si(2))
sdis=fltarr(3,si(2))
stris=intarr(3,si(2))

for i = 0l,(si(2)-1l) do begin

	ci=dis(*,i)
	trindex(*,i)=sort(ci)
 	sdis(*,i)=ci(trindex(*,i))
endfor

hyp=sdis(2,*)
td1=sdis(0,*)/hyp
td2=sdis(1,*)/hyp
side=1.0
keep=where(td1 gt .1 and td1+td2 gt side)
td1=td1(keep)
td2=td2(keep)
hyp=hyp(keep)
tris=tris(*,keep)
trindex=trindex(*,keep)
return
end



















