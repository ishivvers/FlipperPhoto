
pro do_cel_to_tel, matrix, the_ra, the_dec, mjd, enc_ha, enc_dec, rconv=rconv,dconv=dconv,norotate=norotate,lon=lon


  k = 1.0027379
  g = 180.0 / !dpi


  daycnv,mjd+2400000.5d,the_year,the_mon,the_day,the_hour

  ct2lst,gst0,0,0,0,the_day,the_mon,the_year


  if not keyword_set(norotate) then begin
      the_ha = k * the_hour + gst0 - the_ra / 15.0 + lon / 15.0
      the_ha = (the_ha * 15.0) mod 360.
  endif else begin
      the_ha = the_ra
  endelse

  
  cel_vec = [0d,0d,0d]
  cel_vec[0] = cos(the_dec / g) * cos(the_ha / g)
  cel_vec[1] = cos(the_dec / g ) * sin(the_ha/g)
  cel_vec[2] = sin(the_dec/g)     
  
 ; print,cel_vec
  tel_vec = matrix ## cel_vec
  ;print,tel_vec

  ; Convert back

   new_dec = asin(tel_vec[2]) * g
     if (tel_vec[1] ge 0) then begin
        new_ha = acos(tel_vec[0]/sqrt(tel_vec[0]^2 + tel_vec[1]^2)) * g
     endif else begin
        new_ha = 360.0 - acos(tel_vec[0]/sqrt(tel_vec[0]^2 + tel_vec[1]^2)) *g
     endelse

     enc_ha = new_ha * rconv
     enc_dec = new_dec * dconv

 ;    print,'Initial solution: ra =  ',enc_ha
 ;    print,'                  dec = ',enc_dec

     ha_max = 0
     ha_min = -185   ; what to do?


     if (new_ha gt ha_max) then begin
         print,'Need to rotate the solution'
         new_ha = new_ha - 180
         new_dec = 180 - new_dec
         enc_ha = new_ha * rconv
         enc_dec = new_dec * dconv
     endif
     if (new_ha gt ha_max) then begin
         print,'Need to rotate the solution again!'
         new_ha = new_ha - 180
         new_dec = 180 - new_dec
         enc_ha = new_ha * rconv
         enc_dec = new_dec * dconv
     endif
     if (new_ha gt ha_max) then begin
         print,'Need to rotate the solution yet again!'
         new_ha = new_ha - 180
         new_dec = 180 - new_dec
         enc_ha = new_ha * rconv
         enc_dec = new_dec * dconv
     endif

     if (new_ha lt ha_min) then begin
         print,'The star is not visible'
     endif





return
end



pro do_tel_to_cel, matrix, enc_ha, enc_dec, mjd, new_ra, new_dec, rconv=rconv,dconv=dconv,norotate=norotate,lon=lon



  k = 1.0027379
  g = 180.0 / !dpi


  
     the_ha = enc_ha / rconv
     the_dec = enc_dec / dconv

     daycnv,mjd+2400000.5d,the_year,the_mon,the_day,the_hour
     print,'Time: ',the_year, the_mon, the_day, the_hour
     ct2lst,gst0,0,0,0,the_day,the_mon,the_year


     tel_vec = [0d,0d,0d]
     tel_vec[0] = cos(the_dec / g) * cos(the_ha / g)
     tel_vec[1] = cos(the_dec / g ) * sin(the_ha/g)
     tel_vec[2] = sin(the_dec/g)     

     print,tel_vec
     cel_vec = matrix ## tel_vec
     print,cel_vec

     new_dec = asin(cel_vec[2]) * g
     if (cel_vec[1] ge 0) then begin
        new_ha = acos(cel_vec[0]/sqrt(cel_vec[0]^2 + cel_vec[1]^2)) * g
     endif else begin
        new_ha = 360.0 - acos(cel_vec[0]/sqrt(cel_vec[0]^2 + cel_vec[1]^2)) *g
     endelse

     if not keyword_set(norotate) then begin
         new_ra = k * the_hour + gst0 - new_ha / 15.0 + lon / 15.0
         new_ra = (new_ra * 15.0) mod 360.
     endif else begin
         new_ra = new_ha
     endelse


return

end





pro twostartp,starfile,rconv=rconv,dconv=dconv,lon=lon,the_offset=the_offset,datfile=datfile,append=append

if (n_params() eq 0) then begin
   print,'syntax - twostartp,starfile,rconv=rconv,dconv=dconv,append=append,lon=lon,the_offset=the_offset'
   print,'   Reads in tpoint formatted files'
   return
endif

;Read in starfile

star1 = ""
real_ra1 = 0d
real_dec1 = 0d
enc_ha1 = 0d
mjd1 = 0d
star2= ""
real_ra2 = 0d
real_dec2 = 0d
enc_ha2 = 0d
mjd2 = 0d

openr,lun,starfile,/get_lun

line = ' '
found_lat = 0
star = 1
while (not eof(lun)) do begin
    readf,lun,line,'(a100)'
  ;  print,line
    char = strmid(line,0,1)
    if (strnumber(char) or (char eq '+') or (char eq '-') or (char eq ' ')) then begin
        print,line
        if (not found_lat) then begin
            reads,line,deg,min,sec,yr,mon,day
            lat = ten(deg,min,sec)
            found_lat = 1
        endif else begin
            reads,line,st_rhr,st_rmin,st_rsec,st_ddeg,st_dmin,st_dsec, $
              enc_rhr,enc_rmin,enc_rsec,enc_ddeg,enc_dmin,enc_dsec,hr,min
          ;  print,line
            if (star eq 1) then begin
                st1_ra = ten(st_rhr,st_rmin,st_rsec) * 15d
                st1_dec = ten(st_ddeg,st_dmin,st_dsec)
                enc1_ra = ten(enc_rhr,enc_rmin,enc_rsec) * 15d
                enc1_dec = ten(enc_ddeg,enc_dmin,enc_dsec)
                lmst1 = ten(hr,min)
                star = star + 1
                print,'inc star to ',star
            endif else if (star eq 2) then begin
                print,'star eq 2'
                st2_ra = ten(st_rhr,st_rmin,st_rsec) * 15d
                st2_dec = ten(st_ddeg,st_dmin,st_dsec)
                enc2_ra = ten(enc_rhr,enc_rmin,enc_rsec) * 15d
                enc2_dec = ten(enc_ddeg,enc_dmin,enc_dsec)
                lmst2 = ten(hr,min)
                star = star + 1
            endif else begin
                print,'Two stars are the limit!'
                return
            endelse
        endelse
    endif
endwhile

free_lun,lun


k = 1.0027379
g = 180.0 / !dpi
sidrate  = 360.0d/86636.55d

if not keyword_set(rconv) then begin
  rconv = 24382.0
endif

if not keyword_set(dconv) then begin
  dconv = 19395.0
endif

if n_elements(lon) eq 0 then begin
    lon = -106.25361
endif

if n_elements(the_offset) eq 0 then begin
    the_offset = -3.8
endif

if not keyword_set(datfile) then begin
    datfile = 'default.dat'
endif


if keyword_set(append) then begin
    ;; open datfile
    openw,datlun,datfile,/get_lun
endif

; Put everything in ha space

now1 = yr + mon/12.0 + day/365. + lmst1/(365.*24.)
now2 = yr + mon/12.0 + day/265. + lmst2/(365.*24.)

;print,'Precessing ', st1_ra, st1_dec,'from 2000.0 to ',now1
;precess,st1_ra,st1_dec,2000.0,now1
;print,'Precessing ', st2_ra, st2_dec,'from 2000.0 to ',now2
;precess,st2_ra,st2_dec,2000.0,now2
star_ha1 = lmst1 - st1_ra / 15.0
star_ha1 = (star_ha1 * 15d) mod 360.
star_dec1 = st1_dec
star_ha2 = lmst2 - st2_ra / 15.0
star_ha2 = (star_ha2 * 15d) mod 360.
star_dec2 = st2_dec

ha1 = lmst1 * 15d - enc1_ra
dec1 = enc1_dec   ; check this
ha2 = lmst2 * 15d - enc2_ra
dec2 = enc2_dec   ; and this

; Convert encoder to degrees
;ha1 = enc_ha1 / rconv
;dec1 = (4000000 - enc_dec1) / dconv
;dec1 = enc_dec1 / dconv
;ha2 = enc_ha2 / rconv
;dec2 = (4000000 - enc_dec2) / dconv
;dec2 = enc_dec2 / dconv


dec1=dec1+the_offset
dec2=dec2+the_offset

print,'Star 1:'
print,'  star_ha1: ',star_ha1,' real_dec1: ',star_dec1
print,'  ha1: ',ha1,' dec1: ',dec1
print,'Star 2:'
print,'  star_ha2: ',star_ha2,' real_dec2: ',star_dec2
print,'  ha2: ',ha2,' dec2: ',dec2




real_r1 = [0.0,0.0,0.0]
real_r2 = [0.0,0.0,0.0]


real_r1[0] = cos(star_dec1/g) * cos(star_ha1/g)
real_r1[1] = cos(star_dec1/g) * sin(star_ha1/g)
real_r1[2] = sin(star_dec1/g)
real_r2[0] = cos(star_dec2/g) * cos(star_ha2/g)
real_r2[1] = cos(star_dec2/g) * sin(star_ha2/g)
real_r2[2] = sin(star_dec2/g)

; Our axes will be <r1 + r2>, r1 x r2

q = (real_r1 + real_r2)
q = q / sqrt(total(q*q))

r = crossp(real_r1, real_r2)
r = r / sqrt(total(r*r))

; Now, get matrix to rotate CCD into x',y' (q,r)

;tel_ra1 = ha1 + k * time1 * (0.25)    ;ha to ra
;tel_ra2 = ha2 + k * time2 * (0.25)    ;ha to ra

tel_r1=[0.0,0.0,0.0]
tel_r2=[0.0,0.0,0.0]
tel_r1[0]= cos(dec1 / g) * cos(ha1 / g)
tel_r1[1]= cos(dec1 / g) * sin(ha1 / g)
tel_r1[2]= sin(dec1 / g)
tel_r2[0]= cos(dec2 / g) * cos(ha2 / g)
tel_r2[1]= cos(dec2 / g) * sin(ha2 / g)
tel_r2[2] = sin(dec2 / g)

print,'tel_r1 = ',tel_r1
print,'tel_r2 = ',tel_r2

s = (tel_r1 + tel_r2)
s = s / sqrt(total(s*s))
t = crossp(tel_r1, tel_r2)
t = t / sqrt(total(t*t))

phi = atan(s[1],s[0])
S1 = replicate(0d,3,3)
S1(0,0) = cos(phi)
S1(0,1) = -sin(phi)
S1(1,0) = sin(phi)
S1(1,1) = cos(phi)
S1(2,2) = 1.0

spri = S1 ## s

theta = atan(spri[0],spri[2])
S2=replicate(0d,3,3)
S2(0,0)=-cos(theta)
S2(2,0)=sin(theta)
S2(1,1)=1.0
S2(0,2)=sin(theta)
S2(2,2)=cos(theta)

spripri = S2 ## spri
tpripri = S2 ## S1 ## t


phi = atan(tpripri[1],tpripri[0])
S3 = replicate(0d,3,3)
S3(0,0) = cos(phi)
S3(0,1) = -sin(phi)
S3(1,0) = sin(phi)
S3(1,1) = cos(phi)
S3(2,2) = 1.0

sfinal = S3 ## spripri   ; (1,0,0)
tfinal = S3 ## tpripri   ; (0,0,1)

Smat = S3 ## S2 ## S1

; And get matrix to rotate Real ra,dec into x',y'

phi = atan(q[1],q[0])
R1 = replicate(0d,3,3)
R1(0,0) = cos(phi)
R1(0,1) = -sin(phi)
R1(1,0) = sin(phi)
R1(1,1) = cos(phi)
R1(2,2) = 1.0

qpri = R1 ## q

theta = atan(qpri[0],qpri[2])
R2=replicate(0d,3,3)
R2(0,0)=-cos(theta)
R2(2,0)=sin(theta)
R2(1,1)=1.0
R2(0,2)=sin(theta)
R2(2,2)=cos(theta)

qpripri = R2 ## qpri
rpripri = R2 ## R1 ## r

phi = atan(rpripri[1],rpripri[0])
R3 = replicate(0d,3,3)
R3(0,0) = cos(phi)
R3(0,1) = -sin(phi)
R3(1,0) = sin(phi)
R3(1,1) = cos(phi)
R3(2,2) = 1.0

rfinal = R3 ## rpripri   ; (1,0,0)
qfinal = R3 ## qpripri   ; (0,0,1)

Rmat = R3 ## R2 ## R1


; Now, does this work? It should, damn it

tel_to_cel = invert(Rmat) ## Smat
cel_to_tel = invert(Smat) ## Rmat

print,'tel_to_cel:'
print,tel_to_cel
print,'cel_to_tel:'
print,cel_to_tel

; Now, do the conversion

in_loop = 1

while (in_loop eq 1) do begin
  print,'Options:'
  print,'   a.: Celestial to Telescope Coords'
  print,'   b.: Telescope to Celestial Coords'
  print,'   c.: Find the telescope pole'
  print,'   d.: Cel to Tel, norotate'
  print,'   e.: Plot path of a star'
  print,'   f.: Write out matrix file'
  print,'   g.: rate of ra/ha'
  print,'   q.: Quit'
  ans = ' '
  read, ans, $
     prompt = '         Enter Option: '

  if (ans eq 'a') then begin
     print,''
     print,'Convert Celestial to Telescope Coordinates:'
     read, ans, prompt='  Enter RA (deg): '
     the_ra = double(ans)
     read, ans, prompt='  Enter Dec (deg): '
     the_dec = double(ans)
     read, ans, prompt='  Enter mjd: '
     mjd = double(ans)

     ; Precess coords
     daycnv,mjd+2400000.5d,yr,mon,day,hr
     now = yr + mon/12.0 + day/365. + hr/(365.*24.)
     precess,the_ra,the_dec,2000.0,now
     print,'Precessed RA = ',the_ra,' dec = ',the_dec

     do_cel_to_tel,cel_to_tel,the_ra,the_dec,mjd,enc_ha,enc_dec,rconv=rconv,dconv=dconv,lon=lon
     
     ; Next, find the tracking speed
     mjd_plusmin = mjd + 1d/(60d*24d)
     print,'mjd+ = ',mjd_plusmin
     do_cel_to_tel,cel_to_tel,the_ra,the_dec,mjd_plusmin,future_ha,future_dec,rconv=rconv,dconv=dconv,lon=lon
     print,'future ha = ', future_ha, ' future dec = ', future_dec
     gcirc,0,(enc_ha / rconv) / g, (enc_dec / dconv) / g, (future_ha / rconv) / g, $
        (future_dec / dconv) / g, dis
     print,'dis (deg) = ',dis * g

  ;   track_ra = ((future_ha - enc_ha) / (dis * g * rconv)) * 60.
  ;   track_dec = ((future_dec - enc_dec) / (dis * g * dconv)) * 60.

     delta_t = 60.0
     track_ra = (((future_ha - enc_ha) / rconv) / delta_t) * rconv
     track_dec = (((future_dec - enc_dec) / dconv) / delta_t) * dconv

     ; alternately - I don't think this is right
     delta_t = dis * g / sidrate
     alt_tra =  (((future_ha - enc_ha) / rconv) / delta_t) * rconv
     alt_tdec =  (((future_dec - enc_dec) / dconv) / delta_t) * dconv

     print,''
     print,'The star is at encoder ra = ',enc_ha
     print,'               encoder dec = ',enc_dec - dconv*the_offset
     print,'               Track ra at = ',track_ra
     print,'               Track dec at = ',track_dec
   ;  print,' or track ra at = ',alt_tra
   ;  print,' or track dec at = ',alt_tdec

     daycnv,mjd+2400000.5d,yr,mon,day,hr
     ct2lst,lst,lon,fred,mjd+2400000.5d
     print,''
     print,'Year: ',yr,' Month: ',mon,' day: ',day
     the_hour = fix(hr) - 6   ; -6 for the time zone
     if (the_hour lt 0) then the_hour = 24 + the_hour
     print,'Hour: ',the_hour,' Min: ',(hr - fix(hr))*60.0
     the_ra_arr = sixty(the_ra/15.0)
     the_dec_arr = sixty(the_dec)
     star_ra_str=string(fix(the_ra_arr[0]),format='(i2)')+' '+string(fix(the_ra_arr[1]),format='(i2)')+' '+string(fix(the_ra_arr[2]),format='(f5.2)')
     star_dec_str=string(fix(the_dec_arr[0]),format='(i3)')+' '+string(fix(the_dec_arr[1]),format='(i2)')+' '+string(fix(the_dec_arr[2]),format='(f5.2)')

     print,'STAR: '
     print,' RA = ',star_ra_str
     print,' Dec = ',star_dec_str
     print,'TELESCOPE: '
     tel_ra = lst - (enc_ha / rconv) / 15.0
     if (tel_ra gt 24) then tel_ra = tel_ra - 24.0
     if (tel_ra lt 0) then tel_ra = 24.0 + tel_ra
     the_ra_arr = sixty(tel_ra)
     ;alt_dec = 180.0 - (enc_dec / dconv)
     ;alt_dec = enc_dec / dconv
     alt_dec = enc_dec / dconv - the_offset     ; BEST SO FAR  -- Raw as can be
     ;alt_dec = 180.0 - (enc_dec / dconv - the_offset)
     ; put in provisions if alt_dec > 90 to flip around ra ("pole flip")
     the_dec_arr = sixty(alt_dec)
     tel_ra_str=string(fix(the_ra_arr[0]),format='(i2)')+' '+string(fix(the_ra_arr[1]),format='(i2)')+' '+string(fix(the_ra_arr[2]),format='(f5.2)')
     tel_dec_str=string(fix(the_dec_arr[0]),format='(i3)')+' '+string(fix(the_dec_arr[1]),format='(i2)')+' '+string(fix(the_dec_arr[2]),format='(f6.2)')
     lst_arr = sixty(lst)
     lst_str=string(fix(lst_arr[0]),format='(i2)')+' '+string(ten(lst_arr[1],lst_arr[2]),'(f5.2)')

     print,' ha = ',(enc_ha / rconv)
     print,' RA = ',tel_ra_str
     print,' Dec = ',tel_dec_str
     print,' lmst = ',lst_str

     if keyword_set(append) then begin
         ;; now append to the file
         printf,datlun,star_ra_str+' '+star_dec_str+' '+tel_ra_str+' '+tel_dec_str+' '+lst_str
     endif

 endif else if (ans eq 'b') then begin
     print,''
     print,'Convert Telescope to Celestial Coordinates:'
     read, ans, prompt='  Enter Encoder RA: '
     enc_ha = double(ans)
     read, ans, prompt='  Enter Encoder Dec: '
     enc_dec = double(ans)
     read, ans, prompt='  Enter mjd: '
     mjd = double(ans)

     do_tel_to_cel,tel_to_cel,enc_ha,enc_dec,mjd,new_ra,new_dec,rconv=rconv,dconv=dconv,lon=lon
     

     print,''
     print,'The celestial position is ra = ',new_ra
     print,'                          dec= ',new_dec

  endif else if (ans eq 'c') then begin

      print,''
      print,'Find the poles'
    ;  read, ans, prompt = '  mjd: '
    ;  mjd = double(ans)
      mjd = 0

      tel_ha = 0
      tel_dec = 90. * dconv

      do_tel_to_cel, tel_to_cel, tel_ha, tel_dec, mjd, pol_ha, pol_dec, rconv=rconv,dconv=dconv,/norotate,lon=lon

    ;  print,'Uncorrected ha = ',pol_ha

    ;  pol_ha = pol_ha + lon

      print,''
      print,'The pole should be at sky ha = ',pol_ha, ' degrees'
      print,'                          dec = ',pol_dec, ' degrees'

      ; Next, we need the encoder position that corresponds with that
   ;   do_cel_to_tel, cel_to_tel, pol_ha, pol_dec, mjd, enc_ha, enc_dec,rconv=rconv,dconv=dconv,/norotate
   ;   print,''
   ;   print,'The pole is at telescope ha = ', tel_ha
   ;   print,'                         dec= ', tel_dec - the_offset*dconv

  endif else if (ans eq 'd') then begin
      print,''
      print,' From a specific ha/dec to encpos (norotate)'
      read,ans,prompt='   Enter HA: '
      the_ha=double(ans)
      read,ans,prompt='   Enter dec: '
      the_dec=double(ans)
     
      do_cel_to_tel,cel_to_tel,the_ha,the_dec,0.0,enc_ha,enc_dec,rconv=rconv,dconv=dconv,lon=lon,/norotate

      print,''
     print,'The star is at encoder ra = ',enc_ha
     print,'               encoder dec = ',enc_dec - dconv*the_offset


  endif else if (ans eq 'e') then begin
      print,''
      print,'Path of a star...'
      read,ans,prompt='   Enter RA: '
      the_ra=double(ans)
      read,ans,prompt='   Enter dec: '
      the_dec = double(ans)
      read,ans,prompt='   Enter start time: '
      mjd = double(ans)
      read,ans,prompt='   Enter step size (min): '
      stepsize = double(ans)
      read,ans,prompt='   Enter num steps: '
      numsteps = fix(ans)

      daycnv,mjd+2400000.5d,the_year,the_mon,the_day,the_hour
      ct2lst,gst0,0,0,0,the_day,the_mon,the_year

      ha_array = replicate(0d,numsteps)
      dec_array = replicate(0d, numsteps)

      for i=0l,numsteps - 1 do begin
          the_ha = k * (the_hour + i * stepsize / 60.0) + gst0 - the_ra / 15.0
          the_ha = (the_ha * 15.0) mod 360.
 
          cel_vec = [0d,0d,0d]
          cel_vec[0] = cos(the_dec / g) * cos(the_ha / g)
          cel_vec[1] = cos(the_dec / g ) * sin(the_ha/g)
          cel_vec[2] = sin(the_dec/g)     
  
          tel_vec = cel_to_tel ## cel_vec

          
          new_dec = asin(tel_vec[2]) * g
          print,'new_dec = ',new_dec 
          if (tel_vec[1] ge 0) then begin
              new_ha = acos(tel_vec[0]/sqrt(tel_vec[0]^2 + tel_vec[1]^2)) * g
          endif else begin
              new_ha = 360.0 - acos(tel_vec[0]/sqrt(tel_vec[0]^2 + tel_vec[1]^2)) *g
          endelse
          
          enc_ha = new_ha * rconv
          enc_dec = new_dec * dconv
          
          ha_max = 0
          ha_min = -170         ; what to do?
          
          
          if (new_ha gt ha_max) then begin
              print,'Need to rotate the solution'
              new_ha = new_ha - 180
              new_dec = 180 - new_dec

          endif
          enc_ha = new_ha * rconv
          enc_dec = new_dec * dconv

          ha_array[i] = enc_ha
          dec_array[i] = enc_dec

      endfor

      plot,ha_array,dec_array,psym=1,/ynozero

   ;   theline = linfit(ha_array, dec_array)
   ;   plots,ha_array[0],theline[1]*ha_array[0] + theline[0]
   ;   plots,ha_array[numsteps-1],theline[1]*ha_array[numsteps-1]+theline[0],/continue

  endif else if (ans eq 'f') then begin
      print,'Write out matrix file for daq system'
      print,''
      read,ans,prompt='  Filename: '
      fname = ans
      
      openw, lun, fname, /get_lun

      printf,lun,the_offset
      printf,lun,cel_to_tel

      close,lun
      
  endif else if (ans eq 'g') then begin
      print,'Rate of ra/ha'
      print,''
      read,ans,prompt = 'Star ra: '
      the_ra = double(ans)
      read,ans,prompt = 'Star dec: '
      the_dec = double(ans)
      read,ans,prompt = 'mjd to start: '
      mjd_start = double(ans)
      read,ans,prompt = 'stepsize (days): '
      stepsize = double(ans)
      read,ans,prompt = 'numsteps: '
      numsteps = fix(ans)

      ra_array = replicate(0d,numsteps)
      ha_array = replicate(0d,numsteps)
      mjd_array = replicate(0d,numsteps)
      
      for i=0l,numsteps-1 do begin
          mjd_array[i] = mjd_start + i*stepsize
          do_cel_to_tel,cel_to_tel,the_ra,the_dec,mjd_array[i],enc_ha,enc_dec,rconv=rconv,dconv=dconv,lon=lon
          ha_array[i] = (enc_ha / rconv) / 15.0
          ct2lst,lst,lon,fred,mjd_array[i]+2400000.5d
         ; ra_array[i] = lst - abs((enc_ha / rconv) / 15.0)
          ra_array[i] = lst - (enc_ha / rconv) / 15.0
      endfor
      killmehere

  endif else if (ans eq 'q') then begin
      if keyword_set(append) then begin
          free_lun,datlun
      endif
      in_loop = 0
  endif else begin
    print,'Invalid Option'
    print,''
  endelse

endwhile


return

end


