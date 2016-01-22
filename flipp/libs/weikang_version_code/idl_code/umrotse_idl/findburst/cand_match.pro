pro cand_match,file,radius,found

; Created:  Bob Kehoe  11-2-00

  cd, './', current=olddir
  list = mrdfits(file,1,hdr)
  nobj = (size(list.date))[1]
  found = bytarr(nobj)

  for k = 0,nobj-1 do begin
     print, 'Candidate: ',k
     piece = fix(strmid(list.date[k],0,4))
     if (piece eq 9912) then begin
	dir = '/data1/spatrol/9912/'
	field = 'sky0001'
	struct = 'match_'+list.cam[k]+'.dat'
     endif else if (piece eq 0004) then begin
	dir = '/data1/spatrol/0004/'
	field = 'sky0001'
	struct = 'match_'+list.cam[k]+'.dat'
     endif else if (list.field[k] eq 1) then begin
	dir = '/data2/spatrol/sky0046/'
	field = 'sky0001'
        struct = '_'+field+'_1'+list.cam[k]+'_match.datc'
     endif else begin
        dir = '/data2/spatrol/sky0091/'
	field = 'sky0002'
        struct = '_'+field+'_1'+list.cam[k]+'_match.datc'
     endelse
     cd, dir
     dates = findfile()
     i = where(dates ne list.date[k], count)
     index = 0
     while (found[k] eq 0 and index lt count) do begin
        date1 = dates[i[index]]
        cd, date1
        newstruct = struct
        if (piece ne 9912 and piece ne 0004) then begin
           newstruct = date1+struct
        endif
        restore, newstruct
        close_match_radec,list.ra[k],list.dec[k],match.ra,match.dec,m1,m2,radius,1.0,miss
	print, '  ',dir,date1
        if (m1[0] ne -1) then found[k] = 1
	index = index + 1
        cd, '../'
     endwhile
  endfor

  cd, olddir
  list.found = found
  spawn, 'rm '+file
  mwrfits,list,file

  return
end
