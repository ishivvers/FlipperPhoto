pro data_sens,folder

; Created:  Bob Kehoe   UM    11-1-00

  cd, folder, current=olddir
  dates=findfile()
  ndates = (size(dates))[1]

  for k = 0,ndates-1 do begin
     mnames = findfile(dates[k]+'/*match*dat*')
     nmatches = (size(mnames))[1]
     for l = 0,nmatches-1 do begin
	info = str_sep(mnames[l],'_')
	field = info[1]
        camera = info[2]
	restore, mnames[l]
	nobj = (size(match.ra))[1]
	j = where(strpos(match.imagename,'-') ne -1)
	mlim = median(match.stat[j].m_lim)
	nobs = (size(match.jd))[1]
	low = intarr(5)
  	high = intarr(5)
	nlow = intarr(5)
	nhigh = intarr(5)
	dur = fltarr(5)
	chunk = 0
	olddate = 0
        for m = 0,nobs-1 do begin
	   info1 = str_sep(match.imagename[m],'.')
	   info2 = str_sep(info1[0],'_')
	   date = fix(info2[0])
	   nflo = fix(strmid(info2[2],2,3))
	   nfhi = nflo
	   if (strpos(info2[2],'-') ne -1) then nfhi = fix(strmid(info2[2],6,3))
           if ((nflo gt (high[chunk]+3)) or (high[chunk] eq 0) or (date ne olddate)) then begin
	      if (dur[chunk] gt 0.02) then chunk = chunk + 1
	      low[chunk] = nflo
	      high[chunk] = nfhi
	      nlow[chunk] = m
	      nhigh[chunk] = m
	      dur[chunk] = 0.0
	      olddate = date
	   endif else begin
	      high[chunk] = nfhi
	      nhigh[chunk] = m
	      dur[chunk] = match.jd[m] - match.jd[nlow[chunk]]
	   endelse
	endfor
	dwell = total(dur)
	q=where(low ne 0)
	ilow = min(low[q])
	ihigh = max(high)
	print, dates[k],' ',camera,' ',dwell,' ',mlim,' ',field,' ',ilow,' ',ihigh,' ',nobj
     endfor
  endfor

  cd, olddir
;  create_struct('date',dates
  return
end
