pro ws3_good_setup,param
;+
; NAME: WS3_GOOD_SETUP
;
; PURPOSE: To create a default parameter structure to be used
;     with WS3_GOOD.PRO.
;
; CALLING SEQUENCE: ws3_good_setup,param
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OUTPUTS: param - structure containing default values:
;
;   .MAG_LOW      set to the lowest magnitude for which an observation can be 'good'   
;   .MAG_HIGH     set to the highest magnitude for which an observation can be 'good' 
;   .ONE          set to '1' if an observation should be cut (bad) if flag=1 is set.   
;   .TWO          set to '1' if an observation should be cut (bad) if flag=2 is set   
;   .FOUR         set to '1' if an observation should be cut (bad) if flag=4 is set   
;   .EIGHT        set to '1' if an observation should be cut (bad) if flag=8 is set   
;   .SIXTEEN      set to '1' if an observation should be cut (bad) if flag=16 is set   
;   .THIRTY2      set to '1' if an observation should be cut (bad) if flag=32 is set  
;   .SIXTY4       set to '1' if an observation should be cut (bad) if flag=64 is set   
;   .ONE28        set to '1' if an observation should be cut (bad) if flag=128 is set   
;   .PAIR_SIGMA   set to the minimum number of sigmas (from .merr) the magnitudes 
;                  of a pair can be away from each other before the pair is 
;                  cut (bad).    
; 
;
; OPTIONAL OUTPUTS:
;
; NOTES: For use with WS3_GOOD.PRO
;
; EXAMPLE:
;
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;       Susan Amrose     UM     3/23/99
;-
 On_error,2                                      ;Return to caller

 if N_params() EQ 0 then begin
    print,'Syntax -ws3_good_setup,param'  
    return
 endif

param=create_struct('mag_low',0.0,'mag_high',20.0,'one',1,'two',0,'four',1,$
'eight',1,'sixteen',1,'thirty2',0,'sixty4',0,'one28',0,'pair_sigma',2.5)

return
end
