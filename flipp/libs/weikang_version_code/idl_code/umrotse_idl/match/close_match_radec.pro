pro close_match_radec,ra1,dec1,ra2,dec2,m1,m2,ep,allow,miss1,silent=silent,box=box
;+
; NAME:
; close_match_radec
;
; PURPOSE:
; this will find close matches between 2 sets of points (ra1,dec1)
; and (ra2,dec2) (note ra1,ra2,dec1,dec2 are all arrays) in ra dec space.
; 
; CALLING SEQUENCE:
; close_match_radec,ra1,dec1,ra2,dec2,m1,m2,ep,allow,miss1,/silent,/box
;
; INPUTS:
; ra1,dec1: the ra dec of the first set
; ra2,dec2: the ra dec of the second set
; ep:  this is the error which defines a close match. A pair is considered
; a match if their spherical separation is <= ep.
; allow: how many matches in the (ra2,dec2) space will you allow for
; each (ra1,dec1)
;
; OUTPUTS:
; m1,m2: the indices of the matches in each space. That is  
; (ra1(m1),dec1(m1)) matches (ra2(m2),dec2(m2))
; miss1: this gives the index of the things in x1 NOT found to match (optional)
;
; OPTIONAL KEYWORD PARAMETERS:
; silent: no printed output
; box: old square box matching instead of new circular matching
;
; NOTES:
; It sorts the ra2 list so that it can do a binary search for each ra1.
; It then carves out the sublist of ra2 where it is off by less than ep.
; It then only searches that sublist for points where dec1 and dec2 differ
; by less than ep. 
; PROCEDURES CALLED:
; binary_search, rem_dup
; REVISION HISTORY:
; written by David Johnston -University of Michigan June 97
;
;   Tim McKay August 97
; 	bug fixed, matcharr extended to "long" to accomodate ROTSE I images
;   Tim McKay 6/23/98
;	Altered to be an ra dec match, with appropriate scaling of ra range...
;   Tim McKay 7/8/99
;	Altered to order matches by distance, rather than just ra dec distance
;   Erin Scott Sheldon 08-Mar-2001
;       Made code human readable. Fixed bug where miss1 was not returned
;       when no matches found.
;   E.S.S.  Fixed bug where some matches could be returned outside of the
;           requested distance cut.  10-June-2004
;-
 On_error,2                                      ;Return to caller

 if N_params() LT 8 then begin
     print,'Syntax - close_match,ra1,dec1,ra2,dec2,m1,m2,ep,allow,miss1,silent=silent'
     return
 endif
 
; first sort out the allowed errors in ra and dec.....
 
 epdec=ep
 
 n1=n_elements(ra1)
 n2=n_elements(ra2)

 matcharr=lonarr(n1,allow)	;the main book-keeping device for 
 matcharr(*,*)=-1		;matches -initialized to -1
 ind=lindgen(n2)
 sor=sort(ra2)  			;sort ra2
 ra2sort=ra2[sor]
 dec2sort=dec2[sor]
 ind=ind[sor]			;keep track of index
 runi=0L
 endra2=ra2sort[n2-1]
 FOR i=0l , n1-1l DO BEGIN       ;the main top level loop over ra1
     
     epra=ep/cos(dec1[i]*0.01745329d)
     ra1minus = ra1[i]-epra     ;sets the range of good ones
     ra1plus  = ra1[i]+epra
     binary_search,ra2sort,ra1minus,in1 
                                ;searched for the first good one
     IF in1 EQ -1 THEN IF ra1minus LT endra2 THEN in1=0L
                                ;in case ra1minus smaller than all ra2 
                                ;but still may be some matches

     IF in1 NE -1 THEN BEGIN 

         ;; OK, we have the first match in the sorted list. Look at 
         ;; objects that come after until we find no more matches

         in2 = in1
         jj = in2+1
         WHILE jj LT n2 DO BEGIN 
             IF ra2sort[in2+1] LT ra1plus THEN BEGIN 
                 in2=in2+1 & jj=jj+1
             ENDIF ELSE jj=n2
         ENDWHILE 
         IF (n2 EQ 1) THEN in2=0

         ;; while loop carved out sublist to check

         IF in1 LE in2 THEN BEGIN 
             dec2check=dec2sort[in1:in2] ;the sublist to check
             ra2check=ra2sort[in1:in2]

             ;; look in box
             decoffby=abs(dec2check-dec1[i])
             raoffby=abs(ra2check-ra1[i])
             good=where( (decoffby LT epdec) AND $
                         (raoffby LT epra),ngood) + in1
                                ;the selection made here
             IF ngood NE 0 THEN BEGIN 

                 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                 ;; Above was only a square cut
                 ;; Get those that are actually within the
                 ;; requested radius. E.S.S. 10-June-2004
                 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                 if (not keyword_set(box)) then begin
                     offby=sphdist(ra1[i],dec1[i],$
                                   ra2sort[good],dec2sort[good],$
                                   /degrees)
                     good_offby = where(offby LE ep, ngood)
                 endif else begin
                     good_offby = lindgen(ngood)
                     offby = raoffby
                     ;; ngood is the same
                 endelse

                 IF ngood NE 0 THEN BEGIN 

                     good = good[good_offby]
                     offby = offby[good_offby]
                     IF ngood GT allow THEN BEGIN 

                         ;; Sort by closeness
                         good=good[sort(offby)] 

                         ;; not more than you are allowed by 'allow' 
                         ngood=allow 

                         good=good[0:allow-1]                         

                     ENDIF 

                     matcharr[i,0:ngood-1]=good
                                ;finally the matches are entered in 
                     runi=runi+ngood ;a running total    
                     
                 ENDIF ;; Spherical distance cut
             ENDIF ;; end if on ngood ne 0
         ENDIF ;; end if on in1 le in2
     ENDIF ;; end if on in1 matches (unnecessary!)
 ENDFOR ;; loop over array 1

 if not keyword_set(silent) then print,'total put in bytarr',runi
 matches=where(matcharr ne -1,this)
 if this eq 0 then begin
     if not keyword_set(silent) then $
       print,'no matches found'
     miss1=lindgen(n1)
     m1=-1 & m2=-1
     return
 endif
 m1=matches mod n1              ;a neat trick to extract them correctly 
 m2=matcharr[matches]           ;from the matcharr matrix
 if not keyword_set(silent) then $
   print,n_elements(m1),' matches'
 m2=ind[m2]                     ;remember, must unsort
 dif=m1[uniq(m1,sort(m1))]
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





