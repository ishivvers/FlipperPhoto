pro plot_vari2,all_struct,vnum,g_st=g_st,wait=wait,multi_off=multi_off,$
              phase=phase,unphase=unphase,type=type

if n_params() eq 0 then begin
  print,'syntax-plot_vari,all_struct,vnum,wait=wait'
  return
endif

num=n_elements(vnum)

if not keyword_set(wait) then wait=0

if keyword_set(phase) or keyword_set(unphase) then multi_off=1
if not keyword_set(multi_off) then !p.multi=[0,0,2]


cd,'/sdss3/products/idltools_old/rotse/spline_sample/dat_files'

for j=0,num-1 do begin
  ; get datfile name from all_struct
  fieldpos=strpos(all_struct(vnum(j)).file,'field')
  fnum=strmid(all_struct(vnum(j)).file,fieldpos+5,2)
  fieldpos2=strpos(all_struct(vnum(j)).file,'field',fieldpos+5)
  cam=strmid(all_struct(vnum(j)).file,fieldpos2+8,1)
  datfile=strcompress('lc'+fnum+cam+'_'+string(all_struct(vnum(j)).ind),/remove_all)

 GET_LUN, UNIT
 TMP=FINDGEN(32)*(!PI*2/32)
 USERSYM, 0.7*COS(TMP), 0.7*SIN(TMP), /FILL
 NAME=STRLOWCASE(datfile)
 make_rotse_name_pro,all_struct(vnum(j)).ra,all_struct(vnum(j)).dec,oname
 FILE_STRING=NAME + ".txt"
 OPENR, UNIT, FILE_STRING, ERROR=IO_STATUS
 IF (IO_STATUS NE 0) THEN BEGIN
   PRINT, !ERR_STRING
 ENDIF ELSE BEGIN
   UPNAME=STRUPCASE(oname)
   N=1
   READF, UNIT, N
   X=FLTARR(N)
   Y=FLTARR(N)
   DY=FLTARR(N)
   XLO=0.0 & XHI=1.0 & YLO=0.0 & YHI=1.0
   READF, UNIT, XLO, XHI, YHI, YLO
   YLO=YLO*(-1.0)
   YHI=YHI*(-1.0)
   TMP=FLTARR(3)
   FOR I = 0, N-1 DO BEGIN
     READF, UNIT, TMP
     X(I)=TMP(0)
     Y(I)=TMP(1)
     DY(I)=TMP(2)
   ENDFOR
   Y=Y*(-1.0)  
 
   if keyword_set(type) then typestr=type else typestr=''
   if not keyword_set(phase) then begin
     if keyword_set(g_st) then $
       title=strcompress(g_st.gcvs_type(0),/remove_all)+$
       '    Mean: '+strcompress(string(all_struct(vnum(j)).mean), $
                                /remove_all)+ $
       '    P_GCVS: '+strcompress(string(g_st.gcvs_per(0)),/remove_all) $
       else title='Mean: '+strcompress(string(all_struct(vnum(j)).mean),$
                                       /remove_all)
     
     PLOT, X, Y, PSYM=8, /XSTYLE, /YSTYLE, XRANGE=[XLO, XHI],        $
       YRANGE=[YLO, YHI], CHARSIZE=1.0, FONT=-1,                 $
       XTITLE="!5"+UPNAME+" observation time (days)",            $
       YTITLE="!5Amplitude", title=title
     PLOTBARS, X, (XHI-XLO)/200.0, Y, DY
       
     title='Chisq: '+strcompress(string(all_struct(vnum(j)).chisq),$
                                   /remove_all)+ $
      '   '+typestr+'   P: '+ $
      strcompress(string(all_struct(vnum(j)).per),/remove_all) 
     
   endif else begin
     if keyword_set(g_st) then $
       title='Chisq: '+strcompress(string(all_struct(vnum(j)).chisq),$
                                   /remove_all)+ $
       '  '+strcompress(g_st.gcvs_type(0),/remove_all)+ $
       '   Mean: '+strcompress(string(all_struct(vnum(j)).mean), $
                                 /remove_all)+ $
       '   P_G: '+strcompress(string(g_st.gcvs_per(0)),/remove_all)+ $
       '   P: '+strcompress(string(all_struct(vnum(j)).per),/remove_all) $
       else title='Chisq: '+strcompress(string(all_struct(vnum(j)).chisq),$
                                   /remove_all)+ $
       '  '+typestr+'  Mean: '+ $
       strcompress(string(all_struct(vnum(j)).mean), $
                   /remove_all)+ '    P: '+ $
       strcompress(string(all_struct(vnum(j)).per),/remove_all)
   endelse 
        
   READF, UNIT, N
   X1=FLTARR(N)
   Y1=FLTARR(N)
   DY1=FLTARR(N)
   READF, UNIT, XLO, XHI, YHI, YLO
   YHI=YHI*(-1.0)
   YLO=YLO*(-1.0)
   READF, UNIT, F, N_INTERVALS
   TMP=FLTARR(3)
   FOR I = 0, N-1 DO BEGIN
     READF, UNIT, TMP
     X1(I)=TMP(0)
     Y1(I)=TMP(1)
     DY1(I)=TMP(2)
   ENDFOR
   Y1=Y1*(-1.0)
   if not keyword_set(unphase) then begin
     PLOT, X1, Y1, PSYM=8, /XSTYLE, /YSTYLE, XRANGE=[XLO, XHI],   $
       YRANGE=[YLO, YHI], CHARSIZE=1.0, FONT=-1,                 $
       XTITLE="!5Light curve for "+UPNAME,                       $
       YTITLE="!5Amplitude",title=title
     PLOTBARS, X1, (XHI-XLO)/200.0, Y1, DY1
                  
     READF, UNIT, N
     X=FLTARR(N)
     Y=FLTARR(N)
     TMP=FLTARR(2)
     FOR I = 0, N-1 DO BEGIN
       READF, UNIT, TMP
       X(I)=TMP(0)
       Y(I)=TMP(1)
     ENDFOR
     Y=Y*(-1.0)
     OPLOT, X, Y
   endif

   CLOSE, UNIT

 ENDELSE

 if not keyword_set(multi_off) then !P.MULTI=0
 FREE_LUN, UNIT
 
 
endfor
 
return
end
