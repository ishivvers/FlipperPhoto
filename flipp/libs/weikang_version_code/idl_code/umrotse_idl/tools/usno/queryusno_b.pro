function Queryusno_b, ra, dec, dis

  if N_params() LT 2 then begin
      print,'syntax- ubcat = queryusno_b(ra, dec, dis)'
      print,'  [RA (Degrees), Dec (degrees)] -- search coordinates of center'
      print,'  dis -- search box side'
      return,-1
  endif


  if N_elements(dis) EQ 0 then dis = 10
 
 sign = '%2B'
 if (dec lt 0) then sign = '-'


QueryURL = 'http://webviz.u-strasbg.fr/viz-bin/VizieR?-source=USNO-B1&-c='+string(ra,format='(f0.5)')+'+'+sign+string(abs(dec),format='(f0.5)')+'&-c.eq=J2000&-c.r='+string(dis,format='(f0.1)')+'&-c.u=arcmin&-c.geom=r&-out.max=unlimited&-out.form=ascii+999%27filled'
  

QueryURL = QueryURL + '&-out=USNO-B1.0&USNO-B1.0=&-out=RAJ2000&RAJ2000=&-out=DEJ2000&DEJ2000=&-out=e_RAJ2000&e_RAJ2000=&-out=e_DEJ2000&e_DEJ2000=&-out=Epoch&Epoch=&-out=pmRA&pmRA=&-out=pmDE&pmDE=&-out=Ndet&Ndet=&-out=B1mag&B1mag=&-out=R1mag&R1mag=&-out=B2mag&B2mag=&-out=R2mag&R2mag=&-out=Imag&Imag=&-file=.&-meta=2'


;; print,QueryURL
  Result = webget(QueryURL)

  t = result.text
  n = n_elements(t)

  started = 0
  n_stars = 0
  for i=0l,n-1 do begin
      if (not started) then begin
          ;; check where to start
          if (strmid(t[i],0,4) eq '<HR>') then begin
              started = 1
              ind_start = i+1
          endif
      endif else begin
          if (strmid(t[i],0,4) eq '<HR>') then begin
              started = 0
              ind_end = i-1
          endif else begin
              if (strlen(t[i]) ne 0) then n_stars=n_stars+1
          endelse
      endelse
  endfor

  if n_stars eq 0 then begin
      print,'No objects returned by server'
      return,-1
  endif
  
  elt = create_struct('ID', '', $
                      'RAJ2000', 0d, $
                      'DEJ2000', 0d, $
                      'e_RA', 0, $
                      'e_DE', 0, $
                      'Epoch', 0., $
                      'pmRA', 0, $
                      'pmDE', 0, $
                      'Ndet', 0, $
                      'B1mag', 0.0, $
                      'R1mag', 0.0, $
                      'B2mag', 0.0, $
                      'R2mag', 0.0, $
                      'Imag', 0.0)
  
  ubcat=replicate(elt,n_stars)

  this_star = 0
  for i=ind_start,ind_end do begin
      if (strlen(t[i]) ne 0) then begin
          temp=strsplit(t[i],/extract)
          ubcat[this_star].ID = temp[0]
          ubcat[this_star].RAJ2000 = temp[1]
          ubcat[this_star].DEJ2000 = temp[2]
          ubcat[this_star].e_RA = temp[3]
          ubcat[this_star].e_DE = temp[4]
          ubcat[this_star].Epoch = temp[5]
          ubcat[this_star].pmRA = temp[6]
          ubcat[this_star].pmDE = temp[7]
          ubcat[this_star].Ndet = temp[8]
          ubcat[this_star].B1mag = temp[9]
          ubcat[this_star].R1mag = temp[10]
          ubcat[this_star].B2mag = temp[11]
          ubcat[this_star].R2mag = temp[12]
          ubcat[this_star].Imag = temp[13]
          this_star=this_star+1
      endif
  endfor


  return,ubcat
END 
  
