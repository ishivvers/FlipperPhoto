pro usno_missing,ra,dec,ucat,missing,miss_dist,alpha=alpha,sigma=sigma,m1=m1,m2=m2,d_cut=d_cut

 if n_params() lt 5 then begin
     print,'syntax- usno_missing,ra,dec,ucat,missing,miss_dist,alpha=alpha,sigma=sigma,m1=m1,m2=m2,d_cut=d_cut'
     return
 endif

 if n_elements(alpha) eq 0 then alpha = 0.02
 
 close_match_radec,ra,dec,ucat.ra,ucat.dec,m1,m2,0.0009d*50d,1

 if (m1[0] eq -1) then begin
     print,'serious problem.'
     missing = -1
     miss_dist = -1
     d_cut = 3.24
     return
 endif

 gcirc,1,ra[m1]/15.,dec[m1],ucat[m2].ra/15.,ucat[m2].dec,mdist
 

 if n_elements(sigma) eq 0 then begin
     ;; here we estimate sigma from what we've got
     binsize=0.3
     d2=mdist^2.
     hist=histogram(d2,bin=binsize,max=3.2)
     bins=findgen(n_elements(hist))*binsize+min(d2)
     fit=linfit(bins,alog(hist))
     sigma=sqrt(-1./(2.*fit[1]))
 endif

 pvals = exp(-(mdist^2.)/(2.*sigma^2.))
 sort_pv = pvals[sort(pvals)]
 j_alpha = alpha * (findgen(n_elements(sort_pv))+1)/n_elements(sort_pv)
 diff = sort_pv - j_alpha
 h=where(diff le 0.0,count)
 if (count eq 0) then p_cut = 0.0 else p_cut = sort_pv[max(h)]
 missing = where(pvals le p_cut, count)
 print,string(count) + ' missing from USNO'
 if (count eq 0) then begin 
     miss_dist = -1
     d_cut = max(mdist) + 0.01
 endif else begin 
     miss_dist = mdist[missing]
     d_cut = min(mdist[missing])
 endelse

 return
end
