pro zphot_invert_instru_stand,instru_data_file,cal_data_file

if n_params() eq 0 then begin
  print,'syntax- zphot_invert_instru_stand,instru_data_file,cal_data_file'
  return
endif

;;for kait4, see Mo's paper Table 4, observed color terms
color_term={C_U:0.00, C_B:-0.134, C_V:0.051, C_R:0.107, C_I:0.014}

;;readin instrument mag file
readcolst,instru_data_file,instru_st
;;readin calibration file
extend=strmid(cal_data_file,strlen(cal_data_file)-4,4)
;print,extend
if extend eq '.fit' or extend eq 'fits' then begin
  calstarst=mrdfits(cal_data_file,1)
endif else begin
  readcolst,cal_data_file,calstarst
endelse

;;dealing with different groups
totalgroup=max(instru_st.GROUP)
targetres=[]
for i=0,totalgroup-1 do begin
  print,'group: ',i+1
  indg=where(instru_st.GROUP eq i+1)
  ;;find the target
  indt=where(instru_st[indg].STAR eq 0)
  target=instru_st[indg[indt[0]]]
  ;help,target
  ;;find reference stars
  indr=where(instru_st[indg].STAR ne 0)
  refstars=instru_st[indg[indr]]
  ;help,refstars
  ;;locate the reference stars;; allowing 3" matching
  close_match_radec,refstars.RA,refstars.DEC,calstarst.RA,calstarst.DEC,wref,wcal,3.0/3600.0,1.0,missed
  usedrefstars=n_elements(wref)
  ;;for each matched reference star, calculate the constant
  ave_constant_u=[]
  ave_constant_b=[]
  ave_constant_v=[]
  ave_constant_r=[]
  ave_constant_i=[]
  constant_u=0.0
  constant_b=0.0
  constant_v=0.0
  constant_r=0.0
  constant_i=0.0
  for j=0,usedrefstars-1 do begin
    if refstars[wref[j]].U gt 0 and refstars[wref[j]].V gt 0 then constant_u=refstars[wref[j]].U-calstarst[wcal[j]].U-color_term.C_U*(calstarst[wcal[j]].U-calstarst[wcal[j]].V)
    if refstars[wref[j]].B gt 0 and refstars[wref[j]].V gt 0 then constant_b=refstars[wref[j]].B-calstarst[wcal[j]].B-color_term.C_B*(calstarst[wcal[j]].B-calstarst[wcal[j]].V)
    if refstars[wref[j]].V gt 0 and refstars[wref[j]].V gt 0 then constant_v=refstars[wref[j]].V-calstarst[wcal[j]].V-color_term.C_V*(calstarst[wcal[j]].B-calstarst[wcal[j]].V)
    if refstars[wref[j]].R gt 0 and refstars[wref[j]].R gt 0 then constant_r=refstars[wref[j]].R-calstarst[wcal[j]].R-color_term.C_R*(calstarst[wcal[j]].V-calstarst[wcal[j]].R)
    if refstars[wref[j]].I gt 0 and refstars[wref[j]].I gt 0 then constant_i=refstars[wref[j]].I-calstarst[wcal[j]].I-color_term.C_I*(calstarst[wcal[j]].V-calstarst[wcal[j]].I)
    print,constant_u,constant_b,constant_v,constant_r,constant_i
    if constant_u gt 0.0 or constant_u lt 0.0 then ave_constant_u=[ave_constant_u,constant_u]
    if constant_b gt 0.0 or constant_b lt 0.0 then ave_constant_b=[ave_constant_b,constant_b]
    if constant_v gt 0.0 or constant_v lt 0.0 then ave_constant_v=[ave_constant_v,constant_v]
    if constant_r gt 0.0 or constant_r lt 0.0 then ave_constant_r=[ave_constant_r,constant_r]
    if constant_i gt 0.0 or constant_i lt 0.0 then ave_constant_i=[ave_constant_i,constant_i]
  endfor
  if n_elements(ave_constant_u) gt 0 then ave_constant_u=median(ave_constant_u) else ave_constant_u=!values.d_nan
  if n_elements(ave_constant_b) gt 0 then ave_constant_b=median(ave_constant_b) else ave_constant_b=!values.d_nan
  if n_elements(ave_constant_v) gt 0 then ave_constant_v=median(ave_constant_v) else ave_constant_v=!values.d_nan
  if n_elements(ave_constant_r) gt 0 then ave_constant_r=median(ave_constant_r) else ave_constant_r=!values.d_nan
  if n_elements(ave_constant_i) gt 0 then ave_constant_i=median(ave_constant_i) else ave_constant_i=!values.d_nan
  print,ave_constant_u,ave_constant_b,ave_constant_v,ave_constant_r,ave_constant_i

  ;;now that we have the constant, we can transform target instrument mag to standard mag.
  ;;first need to calculate B-V
  sbv=( (target.B-target.V)-(ave_constant_b-ave_constant_v) )/(1.0+color_term.C_B-color_term.C_V)
  sb=target.B-color_term.C_B*sbv-ave_constant_b
  sv=target.V-color_term.C_V*sbv-ave_constant_v
  sr=(target.R-color_term.C_R*sv-ave_constant_r)/(1.0-color_term.C_R)
  si=(target.I-color_term.C_I*sv-ave_constant_i)/(1.0-color_term.C_I)
  su=(target.V+color_term.C_V*sv-ave_constant_u)/(1.0+color_term.C_U)
  target.U=su
  target.B=sb
  target.V=sv
  target.R=sr
  target.I=si
  targetres=[targetres,target]
endfor
ind=sort(targetres.mjd)
targetres=targetres[ind]
tagnames=strtrim(tag_names(targetres),2)
print,tagnames[0],tagnames[1],tagnames[2],tagnames[3],tagnames[4],tagnames[5],tagnames[6],tagnames[7],tagnames[8],tagnames[9],tagnames[10],tagnames[11],tagnames[12],tagnames[13],tagnames[14],format='(a6,a9,a6,a8,a10,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5)'
for i=0,n_elements(targetres)-1 do begin
  print,targetres[i].(0),targetres[i].(1),targetres[i].(2),targetres[i].(3),targetres[i].(4),targetres[i].(5),targetres[i].(6),targetres[i].(7),targetres[i].(8),targetres[i].(9),targetres[i].(10),targetres[i].(11),targetres[i].(12),targetres[i].(13),targetres[i].(14),format='(i5,f11.3,i4,f10.4,f10.4,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2)'
endfor

end
