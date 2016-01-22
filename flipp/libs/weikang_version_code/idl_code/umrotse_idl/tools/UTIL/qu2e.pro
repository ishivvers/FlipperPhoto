PRO qu2e, q, u, e1, e2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME: 
;    qu2e
;       
; PURPOSE: 
;    Convert Robert Luptons q and u shape parameters to ellipticity
;    parameters as measured by unweighted moments and Gary Bernstein's
;    adaptive moments.
;	
;
; CALLING SEQUENCE: 
;    qu2e, q, u, e1, e2
;      
; INPUTS: 
;    q: Shape parameter corresponding to 'e1'
;    u: Shape parameter corresponding to 'e2'
;
;
; OUTPUTS: 
;    e1 and e2.  ellipticity parameters.
;
; 
; PROCEDURE: 
;    Robert's scheme uses a 1/r weighting scheme for measuring 
;        
;          (ixx - iyy)/(ixx + iyy)   and  2ixy/(ixx + iyy)
;
;    For his method, these are equal to:
; 
;        q = ( 1-r )/( 1+r )*cos(2*theta)
;        u = ( 1-r )/( 1+r )*sin(2*theta)
;
;   Where r=axis ratio of object and theta=position angle from x axis
;
;   For unweighted and adaptive schemes, the formulae the same with 
;          
;        r -> r^2
;	
;
; REVISION HISTORY:
;	
;   Author: Erin Scott Sheldon  UofM  6/1/99
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if N_params() LT 2 then begin
     print,'-Syntax: qu2e, q, u, e1, e2'
     print,''
     print,'Use doc_library,"qu2e"  for more help.'  
     return
  endif

  nu=n_elements(u)
  n=n_elements(q)
  IF nu NE n THEN BEGIN
    print,'q and u must be same size'
    return
  ENDIF 

  t=q[0]
  t[0]=0
  e1=replicate(t, n)
  e2=e1
  eL=e1
  f=e1

; Check the 3 cases

  w=where(q EQ 0 AND u NE 0, nw)

  IF nw NE 0 THEN BEGIN
  
    eL[w] = abs(u[w])
    f[w] = ( (1-eL[w])/(1+eL[w]) )^2
    e2[w] = (1-f[w])/(1+f[w])
  ENDIF

  w=where(q NE 0 AND u EQ 0, nw)

  IF nw NE 0 THEN BEGIN
  
    eL[w] = abs(q[w])
    f[w] = ( (1-eL[w])/(1+eL[w]) )^2
    e1[w] = (1-f[w])/(1+f[w])
  ENDIF

  w=where(q NE 0 AND u NE 0, nw)

  IF nw NE 0 THEN BEGIN
  
    cos2theta = q[w]/sqrt(q[w]^2 + u[w]^2)
    eL[w] = q[w]/cos2theta
    f[w] = ( (1-eL[w])/(1+eL[w]) )^2
    e1[w] = (1-f[w])/(1+f[w])*cos2theta
    e2[w] = (u[w]/q[w])*e1[w]
    
  ENDIF

return
END
