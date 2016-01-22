pro calculate_both_ivals_nsvs,obs,pind,npairs,ival,pind2,npairs2,ival2

     if (n_params(0) eq 0) then begin
         print,'Syntax: calculate_both_ivals_nsvs,obs,pind,npairs,ival,pind2,npairs2,ival2'
         return
     endif

     nepochs=npairs

     ival=0.
     if (nepochs ge 5) then begin

       meanmag=total(obs(pind).mag*obs(pind).err) / total(obs(pind).err)

       jsum=0
       for i=0,nepochs-1 do begin
         delta1=(obs(pind(i*2)).mag-meanmag)/$
           sqrt(obs(pind(i*2)).err^2 + 0.04^2)
         delta2=(obs(pind(i*2+1)).mag-meanmag)/$
           sqrt(obs(pind(i*2+1)).err^2 + 0.04^2)
         pval=delta1*delta2
         jsum=jsum+(pval / (abs(pval) > 1e-37))*sqrt(abs(pval))
       endfor
       jtot=jsum/sqrt(nepochs*(nepochs-1.))

       nobs=n_elements(pind)
       ksumnum=0.
       ksumdenom=0.
       for i=0,nobs-1 do begin
	 delta=obs(pind(i)).mag-meanmag
	 ksumnum=ksumnum+abs(delta)
	 ksumdenom=ksumdenom+delta^2.
       endfor
       ktot=(ksumnum / float(nobs)) / sqrt((ksumdenom) / float(nobs))

       ival=jtot*ktot / 0.798
  
     endif

     nepochs2=npairs2

     ival2=0.
     if (nepochs2 ge 5) then begin

       meanmag2=total(obs(pind2).mag*obs(pind2).err) / total(obs(pind2).err)

       jsum=0
       for i=0,nepochs2-1 do begin
         delta1=(obs(pind2(i*2)).mag-meanmag2)/$
           sqrt(obs(pind2(i*2)).err^2 + 0.04^2)
         delta2=(obs(pind2(i*2+1)).mag-meanmag2)/$
           sqrt(obs(pind2(i*2+1)).err^2 + 0.04^2)
         pval=delta1*delta2
         jsum=jsum+(pval/(abs(pval) > 1e-37))*sqrt(abs(pval))
       endfor
       jtot2=jsum/sqrt(nepochs2*(nepochs2-1.))

       nobs2=n_elements(pind2)
       ksumnum2=0.
       ksumdenom2=0.
       for i=0,nobs2-1 do begin
	 delta=obs(pind2(i)).mag-meanmag2   
	 ksumnum2=ksumnum2+abs(delta)
	 ksumdenom2=ksumdenom2+delta^2.
       endfor
       ktot2=(ksumnum2 / float(nobs2)) / sqrt((ksumdenom2) / float(nobs2))

       ival2=jtot2*ktot2 / 0.798

     endif

     return
     end

