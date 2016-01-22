pro find_good_pairs,obs,pind,npairs,pind2=pind2,npairs2=npairs2

    if (n_params(0) eq 0) then begin
        print,'Syntax: find_good_pairs,obs,pind,npairs,pind2=pind2,npairs2=npairs2'
        return
    endif

    nobs=n_elements(where(obs.mjd) ne 0.)
    
    pind=[-1]
    npairs=0
    npairs2=0
    for i=0,nobs-2 do begin
        ;First see if both are good
        if ((obs(i).flags and 32765L) eq 0 $
		 and (obs(i+1).flags and 32765L) eq 0) then begin
           if (abs(obs(i+1).mjd-obs(i).mjd) lt 0.007) then begin
               if npairs eq 0 then begin
                   pind=[i,i+1]
                   npairs=1
               endif else begin
                   pind=[pind,i,i+1]
                   npairs=npairs+1
               endelse
           endif
        endif
        ;Do it again with looser criteria
        if ((obs(i).flags and 31229L) eq 0 $
		 and (obs(i+1).flags and 31229L) eq 0) then begin
           if (abs(obs(i+1).mjd-obs(i).mjd) lt 0.007) then begin
               if npairs2 eq 0 then begin
                   pind2=[i,i+1]
                   npairs2=1
               endif else begin
                   pind2=[pind2,i,i+1]
                   npairs2=npairs2+1
               endelse
           endif
        endif
   endfor

   return
   end
