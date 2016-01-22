pro moonplots,filename
;+
; NAME:	MOONPLOTS
;
; CALLING SEQUENCE:	moonplots,filename
;
; INPUTS:	filename for moon data logfile
;		
;
; OUTPUTS:	Plots
;
; INPUT KEYWORDS:
;			
; PROCEDURE:	Plots of reduced sky
;
; REVISION HISTORY:  
;	Tim McKay		UM		10/30/97	
;******************************************************************************

 if N_params() eq 0 then begin
        print,'Syntax - moonplots, filename'
        return
 endif

 openr, 1, filename

 name=''
 type=''
 string=''
 n=1
 !p.multi=[0,2,2]
 !p.title="Sky plot"
 while not eof(1) do begin

	readf,1,string, format='(A60)'
        info=str_sep(string,' ')
	name=strtrim(info(0))
	type=strtrim(info(1))
	if (type eq 'sky') then begin
	    print, ""
	    print, "Processing file:",name,"   Number:",n
	    namearray=str_sep(name,'.')
	    skyfile=namearray(0)+"_sky.fit"
	    print, "Reading in sky file:",skyfile
 	    !p.title=skyfile
	    skyim=mrdfits(skyfile,0,hdr)
	    sky,skyim,sval,serr
	    string="sky="+strtrim(string(sval))+", sigma="+strtrim(string(serr))
	    tvim2,skyim,range=[sval-serr,sval+5*serr],scale=1
	    xyouts,5,5,strcompress(string)
        endif

endwhile
!p.multi=[0,1,1]
!p.title=""
!x.title=""
!y.title=""

close,1
return

end
