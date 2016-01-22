FUNCTION compile_list, fst, list=list, namelist=namelist, pair=pair, append=append, sort=sort
; NAME: COMPILE_LIST
;
; This function analyzes either a list file or an array of names (or both) and 
; returns an array of structures that can be used to track the cobj files to be
; used for the match structure.
;
; CALLING SEQUENCE:     compile_list, fst, list=list, namelist=namelist, pair=pair
;
; INPUTS:       list: a file name with list of cobj files
;               namelist: an array of strings with cobj file names 
;
; OUTPUTS:      fst: array of structures containing file names and paths
;               ferr: returns 0 if successful, 1 if file not found,
;                     2 if there is not an even number of cobj files
;                     3 if one or more of the cobj files couldn't be opened.
;
; KEYWORDS:     pair: if pairwise matching is to be performed, check that
;                   the list file contains an even number of cobj files 
;               sort: set this if you want your list resorted
;
; REVISION HISTORY:  
;               Don Smith       UM      10/26/01
;====================================================================================
;-

  ferr = 0
  ntot = 0

  IF keyword_set(namelist) THEN ntot = n_elements(namelist)
  IF keyword_set(list) THEN BEGIN 
      openr, list_lun, list, /get_lun, error=lerr
      IF lerr NE 0 THEN ferr = 1 
  ENDIF 
  IF ferr EQ 0 OR ntot GT 0 THEN BEGIN 
      IF keyword_set(list) THEN BEGIN 
          SPAWN, 'wc '+list, wc_string
          ntot = ntot + long(STRMID(wc_string(0),0,8))
          IF keyword_set(append) THEN ferr = 0 ELSE $
            IF (ntot AND keyword_set(pair)) THEN ferr = 2
      ENDIF 
  ENDIF 
  IF ferr EQ 0 OR ntot GT 0 THEN BEGIN
      inname = ''
      path = strarr(ntot)
      file = strarr(ntot)
      seq = intarr(ntot)
      n = 0
      IF keyword_set(namelist) THEN BEGIN 
          FOR i=0,n_elements(namelist)-1 DO BEGIN 
              file[i] = namelist[i]
              dirs = str_sep(file[i],"/")
              ndir = n_elements(dirs)
              IF (ndir EQ 1) THEN BEGIN 
                  path[i] = './'
              ENDIF ELSE BEGIN
                  file[i] = dirs[ndir-1]
                  path[i] = dirs[0] + '/'
                  IF ndir GT 2 THEN $
                    FOR j=1,ndir-2 DO path[i] = path[i] + dirs[j] + '/'
              ENDELSE 
              n = n + 1
          ENDFOR
      ENDIF 
      IF keyword_set(list) THEN BEGIN 
          FOR i=n,ntot-1 DO BEGIN 
; Read next cobj file name
              readf,list_lun,inname,format='(a100)'
              parts = str_sep(inname," ")
              inname = parts[0]
              
; Check to make sure file exists
              openr, chk_lun, inname, /get_lun, error=cerr
              IF cerr NE 0 THEN BEGIN 
                  ferr = 3
                  print, 'Error: file '+inname+' not found.'
              ENDIF ELSE BEGIN 
                  close, chk_lun
                  free_lun, chk_lun
              ENDELSE
              
; Fill names and paths into arrays
              dirs = str_sep(inname,"/")
              ndir = n_elements(dirs)
              filetypes=(str_sep(dirs[ndir-1],'_'))
              ntypes = n_elements(filetypes)
              IF (filetypes[ntypes-1] eq 'cobj.fit') THEN BEGIN
                  IF (ndir EQ 1) THEN BEGIN 
                      path[n] = './'
                      file[n] = inname
                  ENDIF ELSE BEGIN
                      file[n] = dirs[ndir-1]
                      path[n] = dirs[0] + '/'
                      IF ndir GT 2 THEN $
                        FOR j=1,ndir-2 DO path[n] = path[n] + dirs[j] + '/'
                  ENDELSE 
                  n = n + 1
              ENDIF 
          ENDFOR 
          close, list_lun
          free_lun, list_lun
      ENDIF 

      fst = replicate({filetag, name:'', path:'', file:'', seq:0, date:0, root:''}, n)
      FOR i=0,n-1 DO BEGIN 
          fst[i].file = path[i]+file[i]
          fst[i].path = path[i]
          fst[i].name = file[i]
          nam = str_sep(file[i],"_")
          fst[i].root = nam[1]+'_'+nam[2]
          fst[i].date = nam[0]*1
          seq = strmid(nam[2],2,3)*1
          fst[i].seq = seq
          newdate = 1
          x = n_elements(alldates)
          FOR j=0,x-1 DO BEGIN
              IF fst[i].date EQ alldates[j] THEN newdate = 0
          ENDFOR 
          IF newdate THEN BEGIN 
              ndate = indgen(x+1)
              IF x GT 0 THEN ndate[0:x-1] = alldates
              ndate[x] = fst[i].date
              alldates = ndate
          ENDIF 
      ENDFOR

; Make sure there are no duplicates
      flag = indgen(n)*0
      i = 0
      WHILE i LT n-1 DO BEGIN  
          j = i + 1
          WHILE j LT n DO BEGIN 
              IF fst[i].name EQ fst[j].name THEN BEGIN
                  flag[i] = 1
                  print, 'Eliminating '+fst[i].name+' from list as duplicate.'
                  j = n + 10
              ENDIF
              j = j + 1
          ENDWHILE
          i = i + 1
      ENDWHILE 
      good = where(flag EQ 0, icount)
      IF icount LT n THEN fst = fst[good]

; Now sort list into the proper order, if so desired
      IF keyword_set(sort) THEN BEGIN 
          fst = fst[sort(fst.date)]
          x = n_elements(alldates)
          FOR i=0,x-1 DO BEGIN 
              z = where(fst.date EQ alldates[i])
              q = sort(fst[z].seq)
              fst[z] = fst[z[q]]
          ENDFOR 
      ENDIF 

  ENDIF

  return, ferr
END 
