pro buddy,match,index,good_arr,bud,silent=silent
;+
; NAME: BUDDY
;
; PURPOSE: To calculate parameters that can be used to find 
;   objects whose apparent variation is caused by blending
;   with a nearby object or 'buddy'.  
;
; CALLING SEQUENCE: buddy,match,index,good_arr,bud,silent=silent
;
; INPUTS: match - the match structure
;         index - an array of indicies for which the 'buddy' parameters
;                 are to be calculated.
;         good_arr - output array of WS3_GOOD; (nobs,nobj) array
;                  containing a '0' for a bad observations and a '1'
;                  for good observations. 
;
; OPTIONAL INPUTS: /silent - set this to STOP any information from
;                  being printed as the program runs.
;
; OUTPUTS: bud - a structure containing the following tags:
;     .buddy_all:  indicies of three nearest stars (buddies)
;     .ratio_all:  ratio of 'merges' (see notes) to total obs for each buddy.
;     .mean_dif_all: difference in mean magnitude of 'merges' and 
;                    mean magnitude of 'non-merges' for each buddy.
;     .sdev_all: Standard deviation about the mean for 'merges' added
;              in quadrature to the SDEV about the mean for 'non-merges'.
;     .nsdev_all:  mean_dif_all/sdev_all or the number of SDEV's between means.
;     .corr_all: A '0' if the magnitude of this object is correlated (can be 
;                fit to a line with a chi-square < 0.1) to the magnitude of 
;                the 'index' object, and a '1' otherwise.
;     .ind_max: Index of .buddy_all of the maximum mean_dif.
; (the following tags contain each of the above parameters for the .ind_max buddy).
;     .posslg: Set to a 'Y' if the object is a possible long period variable,
;         or if the 'merges' alone can be fit to a line whose slope>0.009 
;         and chisq<0.02. Set to 'N' otherwise.
;
; OPTIONAL OUTPUTS:
;
; NOTES: A 'merge' is an observation for which the magnitude of index(i) 
;     is not -1.0 and the magnitude for the buddy of index(i) is -1.0. A 
;     'non-merge' is when both magnitudes are NOT -1.0. 
;    - If the ratio_all is 0 or 1, all other lower parameters are default (usually -1.0).  
;
; EXAMPLE: To find the buddy parameters for a list of indicies of 
;   possible variables, VARI of the match structure MATCH and good_arr GOOD, do:
;  IDL> buddy,match,vari,good,bud
;
; PROCEDURES CALLED: CLOSE_MATCH, ONE_SEARCH
;
; REVISION HISTORY:
;                Susan Amrose  UM      3/23/99  
;-

; On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
	print,'syntax-buddy,match,index,good_arr,bud,/silent'
	return
endif
buddy_all=replicate(long(-1),n_elements(index),3)
ratio_all=replicate(-1.0,n_elements(index),3)
mean_dif_all=replicate(-1.0,n_elements(index),3)
nsdev_all=replicate(-1.0,n_elements(index),3)
sdev_all=replicate(-1.0,n_elements(index),3)
corr_all=replicate(long(-1),n_elements(index),3)

ind_max=replicate(-1,n_elements(index))
pr=replicate(long(-1),n_elements(index))
corr=replicate(long(-1),n_elements(index))
buddy=replicate(long(-1),n_elements(index))
ratio=replicate(-1.0,n_elements(index))
mean_dif=replicate(-1.0,n_elements(index))
nsdev=replicate(-1.0,n_elements(index))
sdev=replicate(-1.0,n_elements(index))
posslg=replicate('N',n_elements(index))

pair1=indgen(n_elements(match.m(*,0))/2)*2
pair2=pair1+1

for i=0,n_elements(index)-1 do begin
   close_match,match.ra(index(i)),match.dec(index(i)),match.ra,match.dec,m1,m2,0.025,4,/silent
   gd=where(good_arr(*,index(i)) eq 1)
   if n_elements(m2) gt 1 and gd(0) ne -1.0 then begin
       left=where(m2 ne index(i))
       for k=0,n_elements(left)-1 do begin 
	 buddy_all(i,k)=m2(left(k))	
         diff=abs(match.m(gd,index(i))-match.m(gd,buddy_all(i,k)))
         merge=where(diff gt 9.0)
         if merge(0) ne -1.0 then begin
		ratio_all(i,k)=float(n_elements(merge))/n_elements(gd)
                pair=0
                if n_elements(merge) eq 2 then begin
                    one_search,pair1,gd(merge),n1,n2
		    one_search,pair2,gd(merge),n3,n4
	            if n1(0) eq n3(0) then pair=1 else pair=-1
                    if pair eq 1 then pr(i)=index(i)
                endif  
                if n_elements(merge) gt 2 or pair eq -1 then begin
		  mn1=mean(match.m(gd(merge),index(i)))
		  v=moment(match.m(gd(merge),index(i)),sdev=sdev1)
                  nomerge=indgen(n_elements(gd))
                  if n_elements(gd)-n_elements(merge) gt 1 then begin
                        pair=0
		 	remove,merge,nomerge
		 	if n_elements(nomerge) eq 2 then begin 
                          one_search,pair1,gd(nomerge),n1,n2
		          one_search,pair2,gd(nomerge),n3,n4
	                  if n1(0) eq n3(0) then pair=1 else pair=-1
                          if pair eq 1 then pr(i)=index(i)
			endif
                        if n_elements(nomerge) gt 2 or pair eq -1 then begin
				mn2=mean(match.m(gd(nomerge),index(i)))
				v=moment(match.m(gd(nomerge),index(i)),sdev=sdev2)
                                sdev_all(i,k)=sqrt(sdev1^2+sdev2^2)
                                mean_dif_all(i,k)=mn1-mn2 
                                nsdev_all(i,k)=mean_dif_all(i,k)/sdev_all(i,k)
                                if n_elements(merge) gt n_elements(nomerge) then m=merge else $
                                  m=nomerge
                                l=linfit(match.jd(gd(m)),match.m(gd(m),index(i)),chisq=ch)
                                if abs(l(1)) gt 0.009 and ch/n_elements(gd) lt 0.02 then posslg(i)='Y'
                        endif
                  endif 
                endif
         endif else ratio_all(i,k)=0.0
         l=linfit(match.m(gd,index(i)),match.m(gd,buddy_all(i,k)),chisq=chi)
         if abs(l(1)) ge 1.0 and chi/n_elements(gd) le 0.1 then begin 
		corr_all(i,k)=0
         endif 
       endfor
       n=where(mean_dif_all(i,*) ne -1.0)
       if n(0) ne -1.0 then begin
	 ind=n(where(abs(mean_dif_all(i,n)) eq max(abs(mean_dif_all(i,n))))) 
         ind_max(i)=ind(0)
         corr(i)=corr_all(i,ind_max(i))
         buddy(i)=buddy_all(i,ind_max(i))
         mean_dif(i)=mean_dif_all(i,ind_max(i))
         sdev(i)=sdev_all(i,ind_max(i))
         nsdev(i)=nsdev_all(i,ind_max(i))
         ratio(i)=ratio_all(i,ind_max(i))
       endif     
   endif else if not keyword_set(silent) then print,'No buddy found for obj: ',index(i)
endfor

bud=create_struct('buddy_all',buddy_all,'ratio_all',ratio_all,'mean_dif_all',mean_dif_all,$
'sdev_all',sdev_all,'nsdev_all',nsdev_all,'corr_all',corr_all,'ind_max',ind_max,$
'buddy',buddy,'ratio',ratio,'mean_dif',mean_dif,'sdev',sdev,'nsdev',nsdev,$
'pair',pr,'corr',corr,'posslg',posslg)




return
end