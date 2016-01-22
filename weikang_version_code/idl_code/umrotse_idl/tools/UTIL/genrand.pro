PRO genrand, prob, xvals , nrand, rand, cumul=cumul, plt=plt, bin=bin, $
             double=double

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:  
;    GENRAND
;       
; PURPOSE:  
;    output random numbers from probability function
;	
;
; CALLING SEQUENCE:
;      genrand, prob, xvals , nrand, [, rand, cumul=cumul, plt=plt, bin=bin])
;                 
;
; INPUTS: 
;    prob: input probablility function.  
;    xvals: abscissae
;    nrand: How many points to generate from the probability function.
;
; KEYWORD PARAMETERS:
;         /cumul: tells the program that prob is the cumulative 
;	         probablility.  Using this option saves processing time.
;         /plt: plot histogram if requested
;         bin: how to bin the histogram (irrelevent if not /plt )
;       
; OUTPUTS: 
;    rand:  an array of random numbers generated from prob. size nrand
; 
; PROCEDURE: 
;  Generates random numbers from the input distribution by inverting
;  the cumulative probability function.  Performs linear interpolation.
;	
;
; REVISION HISTORY:
;	Author: Erin Scott Sheldon  UofM  1/??/99
;       
;                                      
;-                                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if N_params() LT 3 then begin
	print,'Syntax: genrand, prob, xvals , nrand [, rand, cumul=cumul, '+$
          'seed=seed, plt=plt,bin=bin, double=double] )'
        print,'Outputs rand, set of random numbers generated from prob.'
        print,'Use doc_library, "genrand" for more help'
	return
  endif

  nx = n_elements(xvals)
  if (nx ne n_elements(prob)) then begin
	print,'prob and xvals must be of same size'
	return
  endif
  IF NOT keyword_set(double) THEN double = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;  If prob is not a cumulative probability function 
;;;;  we need to generate one from prob
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if not keyword_set(cumul)  then begin
	IF double THEN intfunc,double(prob), xvals, cumul $
        ELSE intfunc,float(prob), xvals, cumul
  endif else begin
	cumul=prob
  endelse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Normalize probability function 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
  norm = cumul(nx-1)
  cumul = cumul/norm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; generate a set of uniform random numbers from 0 to 1. Store in
;;;; the array testrand
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  testrand=fltarr(nrand)
  COMMON seed,seed
  testrand = randomu(seed,nrand)
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; generate numbers from distribution prob 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  rand = fltarr(nrand)
  lastj=1
  for i=0L, nrand-1 do begin
    j = 1
    checki = (i GT 0)*(i-1)
    j = (testrand[i] GE testrand[checki])*(lastj -1) + 1
    
    while (j le nx-1 ) do BEGIN

      if(cumul[j] ge testrand[i]) then BEGIN
        ;;; perform linear interpolation
        yin = testrand[i]
        y2=cumul[j]
        y1=cumul[j-1]
        x2=xvals[j]
        x1=xvals[j-1]
        m = (y2-y1)/(x2-x1)
        rand[i] = x2 - (y2-yin)/m

        lastj = j
        j=nx-1
      endif
      j=j+1
    endwhile
  endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; plot the results
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if keyword_set(plt) then begin
     if (not keyword_set(bin) ) then bin=xvals(1) - xvals(0)
     plothist,rand, bin=bin, peak=1
     if (not keyword_set(cumulative) ) then begin
	   oplot,xvals,float(prob)/max(prob)
     endif
  endif

return
end









