pro find_stars_from_tris,trindex1,tris1,trindex2,tris2,m1,m2
;+
; NAME:
; find_stars_from_stars
;
; PURPOSE:
; Once you have matched the two sets of triangles you would like to 
; say which stars in one triangle match up to which stars in the other 
; triangle. By just looking at sides individually there is a two-fold
; ambiguity of which star goes to which. But star i in the first 
; triangle will be in two sides namely i-j and i-k and these two sides
; will match up with sides b-a and a-c. This means that i must
; correspond to a because a is in both sides that the i sides 
; match with. This program just does a little routine to sort
; out this ambiguity and re-sorts tris1 and tris2 so that stars 
; match up correctly.
;
; CALLING SEQUENCE:
;find_stars_from_tris,trindex1,tris1,trindex2,tris2,m1,m2
;
; INPUTS:
;trindex1,trindex2,: these are the (3,numtris) arrays that have the 
;                    indices of the stars in tris1,tris2 sorted by
;                    triangle side distance 
;tris1,tris2: the (3,numtris) arrays that contain the                 
;             indices of the stars in each triangle
;m1,m2: these are the indices of the triangles that have been
;       found to match from close_match
;
; OUTPUTS:
;tris1,tris2: just like tris1,tris2 were before 
;             but sorted to remove this ambiguity described above
;
; PROCEDURE:
; For every matching triangle it makes a 3x3 vote array
; "arr" and goes through 3 times
; and gives four votes every time to the spots where there is 
; a corrolation. When done the matrix "arr" has three spots with 2 
; and the rest of the spots with ones. The spots with twos are the 
; real matches. It picks these out and re-sorts tris1 and tris2
;
; REVISION HISTORY:
;David Johnston -University of Michigan June 97
;-
 On_error,2                                      ;Return to caller

 if N_params() LT 6 then begin
    print,'Syntax - find_stars_from_tris,trindex1,tris1,trindex2,tris2,m1,m2'
    return
 endif


nmatch=n_elements(m1)
arr=intarr(3,3)
stris1=intarr(3,nmatch)
stris2=intarr(3,nmatch)
for i=0l ,nmatch-1l do begin
	arr(*,*)=0
	ri1=trindex1(*,m1(i))
	ri2=trindex2(*,m2(i))
	arr(ri1,ri2)=arr(ri1,ri2)+1
	arr((ri1+1) mod 3,ri2)=arr((ri1+1) mod 3,ri2)+1
	arr(ri1,(ri2+1) mod 3)=arr(ri1,(ri2+1) mod 3)+1
	arr((ri1+1) mod 3,(ri2+1) mod 3)=arr((ri1+1) mod 3,(ri2+1) mod 3)+1
	wh=where(arr eq 2)
	stris1(*,i)=tris1((wh mod 3),m1(i))
	stris2(*,i)=tris2((wh/3),m2(i))
endfor
tris1=stris1
tris2=stris2
return
end



