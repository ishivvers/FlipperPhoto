pro triangle_match,x1,y1,x2,y2,ep,allow,objm1,objm2,t1,s1,t2,s2,$
votearr,order=order,kx=kx,ky=ky,show=show
;+
; NAME:
; triangle_match
;
; PURPOSE:
; given two sets of coordinate pairs in a two dimentional space
; (like star positions) it will match them and return a transformation
; between them. The transformation can be as general as:
;		x1 = A*x2 + B*y2 + C*x2*y2 + D
;		y1 = E*x2 + F*y2 + G*x2*y2 + H
; This includes rotation, scale change in 2 independent directions,inversion,
; a fixed offset and also a cross term x*y which would corespond to a 
; deviation from a pure rectangle to rectangle transformation (usually
; this is not needed but rather used as a check of goodness).
; This is done by finding similar triangles as is done in 
; FOCAS astronomical software.
;
; CALLING SEQUENCE:
; triangle_match,x1,y1,x2,y2,ep,allow,trans [,objm1,objm2,t1,s1,t2,s2,
; votearr,kx,ky]
;
; INPUTS:
; x1,y1: arrays of the coordinates of the first set of stars (points)
; x2,y2: arrays of the coordinates of the second set of stars (points)
; ep: the maximum that |t1-t2| AND |s1-s2| can be to 
;     still be considered a match in triangle space. Note this is faster
;     than using a euclidean metric on 2-space on the innermost
;     loop of the program. .002 is a good number to use for matching 
;     stars to a catalog
; allow: how many matches in the t2,s2 triangle space list will you
;	 allow for each point in the t1,s1 triangle space. This depends on 
;        how crowded triangle space is (ie. number of stars used.)
;
; OUTPUTS: 
; objm1,objm2: these are the indices of the two lists where matches 
; 	       were found, that is x1(objm1) matches x2(objm2) etc.
;              This is an optional return.
;
; t1,s1,t2,s2: these are the coordinates in triangle space. t1 s1 are the 
;              triangle space coordinates of x1,y1 etc. Also an
;              optional return.
;
; votearr: This is the vote array used to decide if stars are really 
;          matches. For a description see get_votearr.pro. Also an
;          optional return. 
;
; kx,ky THE way of returning the transformation
; 	this is the natural output of the function polywarp
;       and is used by poly_2d to warp images
;       if kx,ky present then output will be returned like this
;	if no match is found it returns kx=ky=-1
;	then x2,y2 maps to x1,y1 coord system with 'kmap' procedure
;	kmap,x2,y2,x3,y3,kx,ky
; show : this does some plots for debuging or visualization
;
; OPTIONAL KEYWORD PARAMETERS:
; order: this is the order of the tranformation , default is 1 ie. linear
;
; NOTES:
; This basically follows the algoritm used in the FOCAS software Valdes et al.
; don't use too many stars. Number of triangles in each triangle space 
; goes like cube of number of stars and time of program goes like square of
; num of triangles.
; 20 or 30 stars in each list is good if you know at least half are common to both 
;

; PROCEDURES CALLED:
; trispace, close_match, find_stars_from_tris, get_votearr, find_trans_clip
;
; REVISION HISTORY:
; written by David Johnston and Dan Kocevski - University of Michigan June 97
;-
 On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
	print,' syntax- triangle_match,x1,y1,x2,y2,ep,allow,[,objm1,objm2,t1,s1,t2,s2,votearr],order=order,kx=kx,ky=ky'
	return
endif
numkept=n_elements(x1)
if n_elements(y1) ne numkept or n_elements(x2) ne numkept or $ 
n_elements(y2) ne numkept then begin
	print," sizes of x1 y1 x2 y2 don't agree"
	return
endif  
if n_elements(order) eq 0 then order=1
trispace,x1,y1,t1,s1,trindex1,tris1	;makes triangle space for x1,y1
trispace,x2,y2,t2,s2,trindex2,tris2	;makes triangle space for x2,y2

silent=1-keyword_set(show)
close_match,t1,s1,t2,s2,m1,m2,ep,allow,silent=silent
 				          ;matches points in triangle space
					  ;the real workhorse of the program
if n_elements(m1) eq 1 then begin
print,'no triangles matched'
print,"TRIANGLE_MATCH CAN'T FIND A MATCH"
return
endif

find_stars_from_tris,trindex1,tris1,trindex2,tris2,m1,m2
; knowing which triangles sides match still leaves an ambigity to which stars 
; match which. This solves the ambiguity.

get_votearr,numkept,tris1,tris2,m1,m2,votearr,objm1,objm2,goodness,show=show
; this forms the vote array to seperate the real
; matches from the 'noise' matches.
 if n_elements(goodness) eq 1 then begin
	kx=-1
	ky=-1
	print,"TRIANGLE_MATCH CAN'T FIND A MATCH"
	return
 endif

find_trans_clip,x1(objm1),y1(objm1),x2(objm2),y2(objm2),goodness,$
kx,ky,1.8,order=order,show=show
; this does a sigma clipping algorithm to find the best transformation

return
end











