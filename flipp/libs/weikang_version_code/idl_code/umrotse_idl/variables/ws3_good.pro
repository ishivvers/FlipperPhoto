pro ws3_good,match,good_arr,ind,setup=setup,param=param,sim=sim
;+
; NAME: WS3_GOOD
;
; PURPOSE: To create a (nobs,nobj) array for a match structure with a '0' for
;     each bad observation and a '1' for each good observation. Good and Bad 
;     observations are defined by a parameter structure made in WS3_GOOD_SETUP. 
;
; CALLING SEQUENCE: ws3_good,match,good_arr,param,setup=setup
;
; INPUTS: match - match structure for which good and bad observations
;                 are to be found.
; 
; OPTIONAL INPUTS: param - result of WS3_GOOD_SETUP, param structure describing 
;                  what makes a good or bad observation.
;                 /setup - set this to use the default param structure. (No need 
;                  to call WS3_GOOD_SETUP in this case) 
;          NOTE: either param OR setup must be set!
;                 /sim - set this if the match structure is simulated (no flags)
;                 
; OUTPUTS: good_arr - an array containing a '0' for each bad observation and
;            a '1' for each good observation. 
;
; OPTIONAL OUTPUTS:
;
; NOTES:
;
; EXAMPLE: To create a GOOD_ARR with the default values, run:
;      IDL> ws3_good,match,good,/setup
;   To change default values and make a GOOD_ARR, do:
;      IDL> ws3_good_setup,param
;      IDL> ws3_good,match,good_arr,param=param
;
; PROCEDURES CALLED: REMOVE
;
; REVISION HISTORY:
;       Susan Amrose        UM    3/23/99
;-
 On_error,2                                      ;Return to caller

if n_params() eq 0 then begin
	print,'syntax-ws3_good,match,good_arr,param,setup=setup'
	return
endif

if keyword_set(setup) then ws3_good_setup,param
if keyword_set(param) then param=param else if not keyword_set(setup) then $
       print,'Must set EITHER param or setup!'

nobj=n_elements(match.m(0,*))
nobs=n_elements(match.m(*,0))

good_arr=intarr(nobs,nobj)
good_arr(*,*)=1

pair1=indgen(nobs/2)*2
pair2=pair1+1
n=n_elements(pair1)

ind=replicate(-1,nobj)
for i=long(0),long(nobj-1) do begin
        bad=-1.0
	bad=[bad,where(match.m(pair1,i) lt param.mag_low $
		or match.m(pair1,i) gt param.mag_high or $
                match.m(pair2,i) lt param.mag_low or $
		match.m(pair2,i) gt param.mag_high)]
       
        if not keyword_set(sim) then begin
         if param.one eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 1) ne 0 or $
                    (match.flags(pair2,i) and 1) ne 0)]

       	 if param.four eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 4) ne 0 or $
                     (match.flags(pair2,i) and 4) ne 0)]

         if param.eight eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 8) ne 0 or $
		    (match.flags(pair2,i) and 8) ne 0)]

         if param.sixteen eq 1 then $
		 bad=[bad,where((match.flags(pair1,i) and 16) ne 0 or $
                      (match.flags(pair2,i) and 16) ne 0)]
	
         if param.thirty2 eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 32) ne 0 or $
		     (match.flags(pair2,i) and 32) ne 0)]
		
	 if param.sixty4 eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 64) ne 0 or $
		     (match.flags(pair2,i) and 64) ne 0)]
		
         if param.one28 eq 1 then $
		bad=[bad,where((match.flags(pair1,i) and 128) ne 0 or $
		     (match.flags(pair2,i) and 128) ne 0)]
	endif
        bad1=n_elements(bad)
        bad=[bad,where(abs(match.m(pair1,i)- $
		match.m(pair2,i)) gt $
      		param.pair_sigma*sqrt(match.merr(pair1,i)^2+0.05^2))]
        if bad(bad1) ne -1.0 then ind(i)=i
	
        neg=where(bad eq -1.0)
        if n_elements(neg) ne n_elements(bad) then remove,neg,bad else bad=-1.0
        bad=bad(sort(bad))
        bad=bad(uniq(bad))
	
        if bad(0) ne -1.0 then begin
		 good_arr(pair1(bad),i)=0
		 good_arr(pair2(bad),i)=0
        endif
endfor

ng=where(ind eq -1.0)
if ng(0) ne -1.0 then remove, ng, ind
return
end
