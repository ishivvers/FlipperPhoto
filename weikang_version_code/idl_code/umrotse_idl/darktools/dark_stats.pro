pro dark_stats, filestr, xmin, xmax, ymin, ymax, match

;+
;  PURPOSE:  Create a list of pixel values and statistics.
;
;  INPUTS:
;	filestr;	string to search for and run over
;	xmin;	 	subframe minimum x value
;	xmax;		subframe maximum x value
;	ymin;		subframe minimum y value
;	ymax;		subframe maximum y value
;
;  OUTPUTS:
;	match;		structure containing value, stddev, and median 
;				for each pixel in subframe
;
;  Created: 1998-11-30  Bob Kehoe
;-
  On_error, 2			; return to caller

  if N_params() eq 0 then begin
	print, 'Syntax: dark_stats, filestr, xmin, xmax, ymin, ymax, match'
	return
  endif

  print, 'initializing...'
  search_str = '*' + filestr + '*.fit'
  totlist = findfile(search_str, COUNT = ntot)
  num = 0
  oldname = strarr(40)
  once = {pixel, value: intarr(10), nvals: 0, median: 0.0, stddev: 0.0}
  match = replicate(once, 4, xmax-xmin, ymax-ymin)

  for m = 0, ntot-1 do begin
      parts = str_sep(totlist[m], '_')
      trunc_name = parts[0] + '_' + parts[1] + '_' + strmid(parts[2], 0, 2)
      found = 0
      for n = 0, num-1 do begin
          if (trunc_name eq oldname[n]) then begin
              found = 1
          endif
      endfor
      if (found ne 1) then begin
          search_str = '*' + trunc_name + '*.fit'
          list = findfile(search_str, COUNT = nframe)
          if (nframe gt 10) then begin
              nframe = 10
          endif
          vals = intarr(nframe)
          for k = 0, nframe-1 do begin
              print, "Processing image: ", list[k]
              image = mrdfits(list[k], 0, hdr)
              for i = xmin, xmax-1 do begin
                  for j = ymin, ymax-1 do begin
                      match[num, i - xmin, j - ymin].value[k] = image[i, j]
                  endfor
              endfor
          endfor
          print, 'Calculating statistics...'
          for i = 0, xmax-xmin-1 do begin
              for j = 0, ymax-ymin-1 do begin
                  for l = 0, nframe-1 do begin
                      vals[l] = match[num, i, j].value[l]
                  endfor
                  match[num, i, j].nvals = nframe
                  out = sort(vals)
                  halfway = floor((nframe - 1) / 2)
                  remainder = nframe mod 2
                  if (remainder eq 1) then begin
                      match[num, i, j].median = match[num, i, j].value[out[halfway]]
                      offset = floor(0.34 * nframe) + 1
                  endif else begin
                      match[num, i, j].median = (match[num, i, j].value[out[halfway]] + $
                                                 match[num, i, j].value[out[halfway + 1]]) / 2
                      halfway = halfway + 0.5
                      offset = floor(0.34 * nframe) + 0.5
                  endelse
                  match[num, i, j].stddev = (0.34 * k / offset) * $
                                            (match[num, i, j].value[out[halfway + offset]] - $
                                             match[num, i, j].value[out[halfway - offset]])
              endfor
          endfor
          oldname[num] = trunc_name
          num = num + 1
      endif
  endfor

  parts = str_sep(filestr, '*')
  result = size(parts)
  if (result[1] eq 1) then begin
      savefile = filestr + '_stats.idl'
  endif else begin
      savefile = parts[0] + parts[1] + '_stats.idl'
  endelse
  print, 'Saving variables in savefile ', savefile, '...'
  save, match, filename = savefile

  return
end
      
      



