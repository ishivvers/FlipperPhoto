PRO make_full_jpeg, m, sts, f, alpha, delta, err, r1, d1, r2, d2, name, fast=fast,n=n

  iob=-1
  if (n_elements(n) eq 1) then begin
      if (m.nobs gt n) then begin
          use=lindgen(n)-n+m.nobs
          d=sort(m.m_lim[use])
          iob=use[d[n_elements(d)-1]]
      endif
  endif

  if (iob eq -1) then begin
      d = sort(m.m_lim)
      iob = d[n_elements(d)-1]
  endif

  bsz = f*err * 2.0
  pixr = err / 0.0009d
  IF bsz EQ 0.0 THEN bsz=1.
  IF bsz GT 1.85 THEN bsz = 1.85
  
  if (keyword_set(fast)) then begin 
      ;; make it smaller, lower quality, jpeg...and see!
      dim=[768,768]
      quality = 30
  endif

  radec_circle_new,m,alpha,delta,sts=sts,obs=iob,box=bsz,radius=10,/finding, $
    jpegname=name, rarr1=r1, darr1=d1, rarr2=r2, darr2=d2, errad=pixr, dim=dim, $
    quality = quality
END 
