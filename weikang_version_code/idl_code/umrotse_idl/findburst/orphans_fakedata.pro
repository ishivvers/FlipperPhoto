function orphans_fakedata,file,seed

; Created:   12-11-00	Bob Kehoe

  restore, file
  nobs = 100
  i = where(sum.tdwell, count)
  nobj = long(20000.0*sum.tdwell[i])
  ntot = total(nobj)
  mc = create_struct('peak',fltarr(ntot),'index',fltarr(ntot),'pass',bytarr(ntot))

  for k = 0,count-1 do begin
     match = fakevar(nobj[k],nobs,seed,'BURST',sum.mlim[i[k]],ntiles=sum.type[i[k]]) 
     nsofar = 0
     if (k gt 0) then nsofar = total(nobj[0:k-1])
     nfin = nsofar + nobj[k] - 1
     mc.peak[nsofar:nfin] = match.pars.peak
     mc.index[nsofar:nfin] = match.pars.index
     var = find_burst(match,0.5,5.0,minchisq=3.0)
     passed = var.ptr + nsofar
     mc.pass[passed] = 1
  endfor

  return, mc
end
