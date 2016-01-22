function get_hdr_jd, imhdr

; Created:  00-05-16  Bob Kehoe

  jd = sxpar(imhdr,'mjd')
  if (jd eq 0) then jd = sxpar(imhdr,'jd')
  if (!err ne 0) then begin
	time = sxpar(imhdr2,"GMTTIME")
	ts = str_sep(time,' ')
	t = float(ts)
	juldate,[t(0),t(1),t(2),t(4),(t(5)+t(6)/60.0)], jd
	!err=0
  endif

  return, jd
end