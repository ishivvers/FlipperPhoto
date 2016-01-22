pro rextract, param_struct, filename, bin_dir=bin_dir
;+
; NAME:
;       REXTRACT
; PURPOSE:
;	Run sextractor on an image using the parameters passed in param_struct
;
; CALLING SEQUENCE:
;       rextract, param_struct, filename
;
; INPUTS:
;	param_struct: a structure containing all the parameters needed
;		      to run sextractor
;	filename: image to be processed
;       
; OUTPUTS:
;	
;
; OPTIONAL OUTPUT ARRAYS:
;
; INPUT KEYWORD PARAMETERS:
; 
; PROCEDURE: This processes an image on disk using the parameters provided.
;	
;
; REVISION HISTORY:
;	Tim McKay	UM	1/8/98
;	Tim McKay	UM	3/7/98  
;		Added check for environment variables 
;			EXTRACT_BIN, and EXTRACT_PAR
;	Tim McKay	UM	11/3/98
;		Altered for proper use of sextractor 2.0.15
;-
 On_error,2              ;Return to caller

 if N_params() ne 2 then begin
        print,'Syntax - rextract, param_struct, filename, bin_dir=bin_dir
        return
 endif

 if not keyword_set(bin_dir) then begin
   bin_dir=getenv('EXTRACT_BIN')
   if (bin_dir eq "") then begin
	bin_dir='/home/products/sextractor2.0.15/source'
   endif
 endif
 par_dir=getenv('EXTRACT_PAR')
 if (par_dir eq "") then begin
	par_dir='/home/products/idltools/rotse/rotse_idl/pipeline'
 endif

 tags=tag_names(param_struct) 
 tagsize=size(tags)
 
 if tagsize(1) ne 33 then begin
	print, 'These are not valid parameters!!!'
	return
 endif
 
 cmd_string = bin_dir+'/sex '+filename+' -c '+par_dir+'/rotse.sex '
 
 for i = 0,32,1 do begin
  	tag = tags(i)
	val=string(param_struct.(i))
	cmd_string = cmd_string+'-'+tag+' '+val+' '
 endfor
   
 print, cmd_string
 spawn, cmd_string

 return

 end


