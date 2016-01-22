pro zphot_invert_natural_stand_objonly,natural_data_file,system

if n_params() ne 2 then begin
  print,'syntax- zphot_invert_natural_stand_objonly,natural_data_file,system'
  print,'system options: kait1, kait2, kait3, kait4, nickel'
  return
endif

;;see Mo's paper Table 4, observed color terms
case system of
  'kait1' : begin
      color_term={C_B:-0.095, C_V:0.027, C_R:-0.181, C_I:-0.071}
  end
  'kait2' : begin
      color_term={C_B:-0.085, C_V:0.032, C_R:0.062, C_I:-0.007}
  end
  'kait3' : begin
      color_term={C_B:-0.057, C_V:0.032, C_R:0.064, C_I:-0.001}
  end
  'kait4' : begin
      color_term={C_B:-0.134, C_V:0.051, C_R:0.107, C_I:0.014}
  end
  'nickel' : begin
      color_term={C_B:-0.092, C_V:0.053, C_R:0.089, C_I:-0.044}
  end
  else     : begin
      print,'Could not recognize the system, please check!'
      return
  end
endcase

;;readin natural mag file
;;examples
;; GROUP      MJD  STAR     B   EB     V   EV     R   ER     I   EI
;;    1 55798.1728    0 15.18 0.02 14.75 0.02 14.65 0.02 14.76 0.03
;;    2 55798.1740    0 15.20 0.02 14.76 0.02 14.65 0.02 14.77 0.03
readcolst,natural_data_file,natural_st

;;dealing with different groups
stand_st=natural_st
b_v=(natural_st.B-natural_st.V)/(1.0+color_term.C_B-color_term.C_V)
stand_st.B=natural_st.B-color_term.C_B*b_v
stand_st.V=natural_st.V-color_term.C_V*b_v
stand_st.R=(natural_st.R-color_term.C_R*stand_st.V)/(1.0-color_term.C_R)
stand_st.I=(natural_st.I-color_term.C_I*stand_st.R)/(1.0-color_term.C_I)

tagnames=strtrim(tag_names(stand_st),2)
;;print out tags, this need update, casue different filter numbers have diffferent number of tag names
;;this is for 4 filters
print,tagnames[0],tagnames[1],tagnames[2],tagnames[3],tagnames[4],tagnames[5],tagnames[6],tagnames[7],tagnames[8],tagnames[9],tagnames[10],format='(a6,a9,a6,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5)'
;;this is for 5 filters
;print,tagnames[0],tagnames[1],tagnames[2],tagnames[3],tagnames[4],tagnames[5],tagnames[6],tagnames[7],tagnames[8],tagnames[9],tagnames[10],tagnames[11],tagnames[12],format='(a6,a9,a6,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5,a6,a5)'
for i=0,n_elements(stand_st)-1 do begin
;;this is for 4 filters
  print,stand_st[i].(0),stand_st[i].(1),stand_st[i].(2),stand_st[i].(3),stand_st[i].(4),stand_st[i].(5),stand_st[i].(6),stand_st[i].(7),stand_st[i].(8),stand_st[i].(9),stand_st[i].(10),format='(i5,f11.4,i5,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2)'
;;this is for 5 filters
; print,stand_st[i].(0),stand_st[i].(1),stand_st[i].(2),stand_st[i].(3),stand_st[i].(4),stand_st[i].(5),stand_st[i].(6),stand_st[i].(7),stand_st[i].(8),stand_st[i].(9),stand_st[i].(10),stand_st[i].(11),stand_st[i].(12),format='(i5,f11.4,i5,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2,f6.2,f5.2)'
endfor

end
