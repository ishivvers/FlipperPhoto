pro scanimages, field, outfile=outfile, inlist=inlist

  if N_params() eq 0 then begin
	print,'syntax: scanimages, field, outfile=outfile, inlist=inlist'
	return
  endif
  
  if not keyword_set(outfile) then begin
	outfile = 'outlist.txt'
  endif
  bits=str_sep(outfile,'.')
  goodfile=bits(0)+'_good.txt'
  listfile=bits(0)+'_list.txt'
  

; This is designed for quick hand scanning of a lot of images

  if not keyword_set(inlist) then begin

; First build a list

  if (field lt 100) then begin
	string='ls *sky00'+strtrim(string(field),2)+'_1?001* *sky00'+$
		strtrim(string(field),2)+'_1?003* > '+listfile
  endif else begin
	string='ls *sky0'+strtrim(string(field),2)+'_1?001* *sky00'+$
		strtrim(string(field),2)+'_1?003* > '+listfile
  endelse

  print,string
  spawn,string

  inlist=listfile

  endif

  spawn,'hostname',host
  
  print,host
  ; read in a default flat.....
  if (host(0) eq "rotse2.physics.lsa.umich.edu") then begin
    flat=readfits('/data0/cals/flats/990321/990321_skyflat_1a001.fit',hdr)
  endif else begin
    flat=readfits('/rotse2/data0/cals/flats/990321/990321_skyflat_1a001.fit',$
		hdr)
  endelse
  j=where(flat lt 0.1)
  flat(j)=1.0

  openr,1,inlist
  n=1
  name=''
  openw,2,outfile
  openw,3,goodfile
  while not eof(1) do begin

    readf,1,name,format='(a60)'
    info=str_sep(name," ")
    name=info(0)
    print, ""
    print, "Processing file:",name,"   Number:",n
    im=readfits(name,hdr)
    if (n eq 1) then begin
	rdis_setup,im,pls
    endif
    !p.title=name
    print,'Good choices are g,s,h,c,n,b (good, shutter, haze, clouds, noise, bright)'
    rdis,im/flat,pls,/full
    result=get_kbrd(30)
    print,'You Chose:',result
    gooda=0
    if (result eq 'g' or result eq 'G') then begin
	printf,2,name+' good'
	printf,3,name
	gooda=1
    endif 
    if (result eq 's' or result eq 'S') then begin
	printf,2,name+' shutter'
	gooda=1
    endif
    if (result eq 'h' or result eq 'H') then begin
 	printf,2,name+' hazy'
	gooda=1
    endif
    if (result eq 'c' or result eq 'C') then begin
 	printf,2,name+' cloudy'
	gooda=1
    endif
    if (result eq 'n' or result eq 'N') then begin
 	printf,2,name+' noisy'
	gooda=1
    endif
    if (result eq 'b' or result eq 'B') then begin
 	printf,2,name+' bright'
	gooda=1
    endif
    if (gooda eq 0) then begin
	print,'I dont understand the answer: '+result
	printf,2,name+' unknown'
    endif    

    n=n+1

  endwhile
  close,1
  close,2
  close,3

  return
  end







