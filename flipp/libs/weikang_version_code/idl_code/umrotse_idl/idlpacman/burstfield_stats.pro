function burstfield_stats,ra,dec,mjd

 if n_params() eq 0 then begin
     print,'syntax- stats = burstfield_stats(ra,dec,mjd)'
     return,-1
 endif

 ;; this can be expanded as needed

 stats=create_struct('g_long',0d,'g_lat',0d,'e_long',0d,'e_lat',0d,'extinction',0.0)

 jd = mjd + 2400000.5d
 daycnv,jd,yr,mn,day,hr
 dy = ymd2dn(yr,mn,day)
 year = double(yr) + (double(dy) + hr/24d)/365d  ;; hmmm

 glactc,ra,dec,year,gl,gb,1,/degree
 stats.g_long = gl
 stats.g_lat = gb

 ecliptc,ra,dec,el,eb,1,jd=jd,/degree
 stats.e_long = el
 stats.e_lat = eb

 return,stats
end
