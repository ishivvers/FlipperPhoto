pro find_good,st,minimum=minimum,mode=mode,usecoadds=usecoadds,field=field

; Created:  9-1-00  Bob Kehoe

; Determine whether look at coadds, and whether to match or just determine stats.

if not keyword_set(minimum) then minimum = 1	; require only one good frame at a time
if not keyword_set(mode) then mode = 0		; do no matching is default
if not keyword_set(usecoadds) then usecoadds = 0	; not using coadds is default
if not keyword_set(field) then field = '*' 	; field not specified by default
if (usecoadds ge 1) then begin
   frames = '*-*'
   piece = 'c'
endif else begin
   frames = '????'
   piece = ''
endelse
lsttot = 'all_cobjs.lst'+piece
getlist = 'ls *'+field+'*_1'+frames+'_cobj.fit > '+lsttot
if (usecoadds eq 2) then begin
   extras = ' ? *'+field+'*_1???5_cobj.fit ? *'+field+'*_1???6_cobj.fit'
   getlist = 'ls *'+field+'*_1'+frames+'_cobj.fit'+extras+'  > '+lsttot
endif
spawn, getlist
lsta = 'all_good_cobjs_a.lst'+piece
lstb = 'all_good_cobjs_b.lst'+piece
lstc = 'all_good_cobjs_c.lst'+piece
lstd = 'all_good_cobjs_d.lst'+piece

; Find good observations

tychocal_statslist, lsttot, st
i = where(st.pos_sigma le 0.15 and st.m_lim gt 14.75, count)
openw, 1, lsta
openw, 2, lstb
openw, 3, lstc
openw, 4, lstd
na = 0
nb = 0
nc = 0
nd = 0
for k = 0, count-1 do begin
   j = where(st[i].nframe eq st[i[k]].nframe, count2)
   if (count2 ge minimum) then begin
      info = str_sep(st[i[k]].filename, '_c.fit')
      name = info[0] + '_cobj.fit'
      n = 0
      if (strpos(name, '_1a') ne -1) then begin
	 n = 1
	 na = na + 1
      endif else if (strpos(name, '_1b') ne -1) then begin
	 n = 2
	 nb = nb + 1
      endif else if (strpos(name, '_1c') ne -1) then begin
	 n = 3
	 nc = nc + 1
      endif else if (strpos(name, '_1d') ne -1) then begin
	 n = 4
	 nd = nd + 1
      endif
      if (n ne 0) then printf, n, name
   endif
endfor
close,1
close,2
close,3
close,4
name = str_sep(info[0],'_')
name = name[0] + '_' + name[1]
statfile = name + '_r1_stat.dat'+piece
save, st, filename=statfile
diag_plots, st, fileonly=1

; Produce matched object lists...

if (mode ne 0) then begin
   matcha = name + '_1a_match.dat'+piece
   matchb = name + '_1b_match.dat'+piece
   matchc = name + '_1c_match.dat'+piece
   matchd = name + '_1d_match.dat'+piece
   if (na gt 0) then begin
      if (mode eq 2) then begin 
	 print, 'Pair matching...'
	 tycho_regmatch_list,oldmatch,lsta,pair=1
      endif else begin
	 print, 'Consecutive matching...'
	 tycho_regmatch_list,oldmatch,lsta,consec=1
      endelse
      relphot,oldmatch,match
      save,match,file=matcha
   endif else spawn, 'rm '+lsta
   if (nb gt 0) then begin
      if (mode eq 2) then begin 
	 print, 'Pair matching...'
	 tycho_regmatch_list,oldmatch,lstb,pair=1
      endif else begin
	 print, 'Consecutive matching...'
	 tycho_regmatch_list,oldmatch,lstb,consec=1
      endelse
      relphot,oldmatch,match
      save,match,file=matchb
   endif else spawn, 'rm '+lstb
   if (nc gt 0) then begin
      if (mode eq 2) then begin 
	 print, 'Pair matching...'
	 tycho_regmatch_list,oldmatch,lstc,pair=1
      endif else begin
	 print, 'Consecutive matching...'
	 tycho_regmatch_list,oldmatch,lstc,consec=1
      endelse
      relphot,oldmatch,match
      save,match,file=matchc
   endif else spawn, 'rm '+lstc
   if (nd gt 0) then begin
      if (mode eq 2) then begin 
	 print, 'Pair matching...'
	 tycho_regmatch_list,oldmatch,lstd,pair=1
      endif else begin
	 print, 'Consecutive matching...'
	 tycho_regmatch_list,oldmatch,lstd,consec=1
      endelse
      relphot,oldmatch,match
      save,match,file=matchd
   endif else spawn, 'rm '+lstd
endif

end




































