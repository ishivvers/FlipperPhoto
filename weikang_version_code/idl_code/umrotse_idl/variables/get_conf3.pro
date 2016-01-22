pro get_conf3,match,vari,good_arr,magbin,chg1,chg2,prime_struct,$
conf,magbin_cut=magbin_cut,in_cut=in_cut,conf1=conf1,skip_prime=skip_prime

s=systime(1)
all=where(vari.mean ne -1)
nobs=n_elements(match.m(*,0))
nobj=n_elements(match.m(0,*))
pair1=indgen(nobs)*2
pair2=pair1+1
nall=n_elements(all)
nvari=n_elements(vari.vari)
if not keyword_set(in_cut) then numkeep=nobs else numkeep=ceil(in_cut*nobs/100.0)
noerrmean=vari.mean

allp=all
;allp=all(magbin.(0))
;for i=1,26 do $
; if n_elements(magbin.(i)) gt 200 then allp=[allp,all(magbin.(i)(0:199))] else $
;   allp=[allp,all(magbin.(i))]  
nallp=n_elements(allp)

ra_ind=sort(match.ra(allp))
ra=match.ra(allp(ra_ind))
dec=match.dec(allp(ra_ind))

close=replicate(long(-1),nobj)
noerrmeanp=replicate(-1.0,nobj)
Iprime=replicate(-1.0,nobj)
dif_arr=replicate(-1.0,nobj)

if not keyword_set (skip_prime) then begin

print,nallp,' elements in loop'
for i=long(0),long(nallp)-1 do begin
print,i
 gd=where(good_arr(*,allp(ra_ind(i))) eq 1)
 
 if i lt nallp-(50) then $
   test_ind=ra_ind(indgen(100)+((i-(50)) > 0)) $
   else test_ind=ra_ind(indgen(100)+(nallp-(100)))
      
 remove,where(test_ind eq ra_ind(i)),test_ind

 dif=fltarr(n_elements(test_ind))
 if vari.mean(allp(ra_ind(i))) le 12.5 then lt_125=1 else lt_125=0

 for k=0,n_elements(test_ind)-1 do begin
   ngd=n_elements(where(good_arr(gd,allp(test_ind(k))) eq 1))
   nobs_dif=(-99)*((numkeep-ngd) < 0)+ $
     ((2.667/n_elements(gd))*(n_elements(gd)-ngd))
   dist_dif=(1/0.0778)*sqrt((match.ra(allp(test_ind(k)))- $
          match.ra(allp(ra_ind(i))))^2 $
          +(match.dec(allp(test_ind(k)))-match.dec(allp(ra_ind(i))))^2)
   mag_dif=lt_125*(-99)*((13.0-vari.mean(allp(test_ind(k)))) < 0) + $
         (vari.mean(allp(test_ind(k)))-vari.mean(allp(ra_ind(i))))   
   poss_test=where(vari.vari eq all(ra_ind(test_ind(k))))
   if poss_test(0) eq -1 then poss_vari=0 else poss_vari=1
   dif(k)=sqrt((mag_dif)^2+(nobs_dif)^2+(dist_dif)^2+(poss_vari)^2)
 endfor

 keep=where(dif eq min(dif))
 dif_arr(all(ra_ind(i)))=dif(keep)
 close(all(ra_ind(i)))=all(test_ind(keep(0)))
 
 both_gd=where(good_arr(gd,close(all(ra_ind(i)))) eq 1)
 one_search,gd(both_gd),pair2,bgin_pair,in_pair

 if in_pair(0) ne -1.0 then begin
      sub_pair1=indgen(n_elements(in_pair))*2
      sub_pair2=sub_pair1+1
      magp=fltarr(n_elements(in_pair)*2)
      magp(sub_pair1)=match.m(pair1(in_pair),allp(ra_ind(i)))
      magp(sub_pair2)=match.m(pair2(in_pair),close(all(ra_ind(i))))
      noerrmeanp(all(ra_ind(i)))=total(magp)/(n_elements(in_pair)*2)
      chgarrp=total(chg1(in_pair,ra_ind(i))*chg2(in_pair,test_ind(keep(0))))
      Iprime(all(ra_ind(i)))=(sqrt(1.0/(n_elements(in_pair)* $
            (n_elements(in_pair)-1.0))))*chgarrp
 endif
endfor

prime_struct=create_struct('ip',iprime,'close',close,'dif',dif_arr,$
'mean',noerrmeanp)
plot,prime_struct.ip(all),vari.mean(all),psym=3,yrange=[8,15]

ENDIF ELSE PRIME_STRUCT=SKIP_PRIME
;*** Get confidence
if keyword_set(conf1) then begin

conf=fltarr(nvari)
magbin_lg=create_struct('magbin9',where(prime_struct.mean lt 9.0),$
 'magbin9_10',where(prime_struct.mean ge 9.0 and prime_struct.mean lt 10.0),$
 'magbin10_11',where(prime_struct.mean ge 10.0 and prime_struct.mean lt 11.0),$
 'magbin11_12',where(prime_struct.mean ge 11.0 and prime_struct.mean lt 12.0),$
 'magbin12_13',where(prime_struct.mean ge 12.0 and prime_struct.mean lt 13.0),$
 'magbin13_14',where(prime_struct.mean ge 13.0 and prime_struct.mean lt 14.0),$
 'magbin14',where(prime_struct.mean ge 14.0))

for i=0,6 do begin
  bin=magbin_lg.(i)
  if bin(0) ne -1 then begin
     ra_ind2=sort(match.ra(all(bin)))
     one_search,all(bin(ra_ind2)),vari.vari,in_bin,in_vari
     if in_vari(0) ne -1.0 then begin
       nbin=n_elements(bin)
       ra2=match.ra(all(bin(ra_ind2)))
       dec2=match.dec(all(bin(ra_ind2)))

       for k=0,n_elements(in_vari)-1 do begin
          if in_bin(k) lt nbin-251 then $
           test_ind=indgen(nbin < 502) + ((in_bin(k)-251) > 0) $
           else test_ind=indgen(nbin < 502) + (nbin-(nbin < 502))
          remove,where(test_ind eq in_bin(k)),test_ind
          dif=fltarr((nbin-1) < 501)
          for j=0,(500 < (nbin-2)) do $
             dif(j)=sqrt((ra2(test_ind(j))-ra2(in_bin(k)))^2+ $
                (dec2(test_ind(j))-dec2(in_bin(k)))^2)
          num=1
          while n_elements(use) le (100 < nbin) do begin
	    use=where(dif lt 0.0778*num)    
            num=num+1
            if num ge 99 then begin
              print,'bummer, stuck in while loop'
              return
            endif
          endwhile

          below=where(prime_struct.ip(magbin_lg.(i)(ra_ind2(test_ind(use)))) $
            le vari.i(vari.vari(in_vari(k))))
          if below(0) ne -1 then conf(in_vari(k))=$
            float(n_elements(below))/float(n_elements(use)) $
            else conf(in_vari(k))=0.0
       endfor
     endif
  endif
endfor

endif 
print,systime(1)-s,' seconds'
return
end










