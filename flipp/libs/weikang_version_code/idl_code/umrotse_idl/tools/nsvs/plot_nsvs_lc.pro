pro plot_nsvs_lc,ct,frames,obj,obs=obs,nocut=nocut

   if (n_params(0) eq 0) then begin
       print,'Syntax: plot_nsvs_lc,ct,frames,obj,obs=obs,nocut=nocut
       return
   end

   read_skydot_sql_new,ct,obj,obs

   obs.mjd=frames(obs.frame_id-1).mjd

   good=where((obs.flags and 31229L) eq 0)
   if keyword_set(nocut) then good=lindgen(ct(obj).n_points)
   
   if (good(0) ne -1 and n_elements(good) gt 2) then begin
       
       jd=obs(good).mjd
       minjd=min(obs(good).mjd)
       mag=obs(good).mag
       err=obs(good).err

       mmin=min(mag)
       mmax=max(mag)

       ploterror,jd-minjd,mag,err,yrange=[mmax,mmin],psym=1

       find_good_pairs,obs,pind,npairs,pind2=pind2,npairs2=npairs2
       calculate_both_ivals_nsvs,obs,pind,npairs,ival,pind2,npairs2,ival2
       legend,['I!Dval!N = '+ntostr(ival,6),$
              'I!Dvaltol!N = '+ntostr(ival2,6)],/right

   endif else begin
       print,'No good observations!'
   endelse

   return
   end
