pro coadd_list,listfile,every=every,outlist=outlist,offset=offset
;+
; NAME:	COADD_LIST
;
; CALLING SEQUENCE: coadd_list,listfile,every=every
;
; INPUTS:	listfile; file containing list of images to use
;
; INPUT KEYWORDS:
;	every = number of frames to group coadds by.  If not
;		specified, all in listfile are coadded
;	outlist = list in which to put output filenames
;	offset = frame number to begin counting groups from.
;
; PROCEDURE:	Parses list of input object lists to group by amount
;		specified and sends these sublists to coadd_names to
;		perform the coadding.
;
; Created:  6-16-00  Bob Kehoe
; Updated:  7-18-00  Bob Kehoe

 if N_params() eq 0 then begin
    print,'Syntax - coadd_list,listfile,every=every,outlist=outlist,offset=offset'
    return
 endif
 if not keyword_set(offset) then offset = 1

; Initialize

 total = 0
 openr,f,listfile,/get_lun
 while not eof(f) do begin
   name=''
   readf,f,name,format='(a60)'
   total = total + 1
 endwhile
 close,f
 if not keyword_set(every) then every = total
 names = strarr(total)
 openr,f,listfile
 for k = 0,total-1 do begin
    readf,f,name,format='(a60)'
    names[k] = name
 endfor
 close,f
 free_lun,f

; Determine epoch grouping

 index = make_array(total, every, /integer, value=-1)
 nframe = intarr(total)
 date = strarr(total)
 field = strarr(total)
 flags = intarr(total)
 camera = strarr(total)
 for k = 0,total-1 do begin
    if (flags[k] ne -1) then begin
       info = str_sep(names[k], '_')
       date[k] = info[0]
       field[k] = info[1]
       nframe[k] = fix(strmid(info[2], 2, 3))
       camera[k] = strmid(info[2], 0, 2)
       rem = (nframe[k] - offset) mod every
       nframe_start = nframe[k] - rem
       tmp = indgen(every)
       tmp = tmp + nframe_start
       for l = 0,every-1 do begin
          if (l ne rem) then begin
             tmp_nframe = '000' + strtrim(string(tmp[l]),2)
             tmp_str = camera[k] + strmid(tmp_nframe, strlen(tmp_nframe)-3, 3)
	     tmp_str = date[k] + '_' + field[k] + '_' + tmp_str
             i = where(strpos(names, tmp_str) ne -1, count)
	     if (count eq 1) then begin
		index[k,l] = i
		flags[i] = -1
	     endif
          endif else begin
	     index[k,l] = k
          endelse
       endfor
    endif
    i = where(index[k,*] eq -1, nmiss)
    if (nmiss gt 0) then index[k,0] = -1 
 endfor

; Filter grouped epochs into sublists to coadd

 i = where(index[*,0] ne -1, iter)
 if (iter eq 0) then return
 outfiles = strarr(iter) 
 for k = 0,iter-1 do begin
    isort = sort(names[index[i[k],*]])
    newnames = reform(names[index[i[k],isort]])
    coadd_names,newnames,imtot,outfile
    outfiles[k] = outfile
 endfor
 if (keyword_set(outlist)) then begin
    get_lun,f
    openw, f, outlist
    for k = 0,iter-1 do printf, f, outfiles[k]
    close, f
    free_lun,f
 endif

end
