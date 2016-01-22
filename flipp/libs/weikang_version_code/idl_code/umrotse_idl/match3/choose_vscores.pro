pro choose_vscores,vscores,variable,alpha=alpha,v_cut=v_cut

 if (n_params() lt 2) then begin
     print,'syntax- choose_vscores,vscores,variable,alpha=alpha,v_cut=v_cut'
     return
 endif

 if (n_elements(alpha) eq 0) then alpha = 0.01

 if (n_elements(vscores) ge 10) then begin
     scaled_vscores = (vscores - mean(vscores))/stddev(vscores)
     pvals = 1. - gaussint(scaled_vscores)
     sort_pv = pvals[sort(pvals)]
     j_alpha = alpha * (findgen(n_elements(sort_pv))+1)/n_elements(sort_pv)
     diff = sort_pv - j_alpha
     h=where(diff le 0.0,count)
     if (count eq 0) then p_cut = 0.0 else p_cut = sort_pv[max(h)]
     variable=where(pvals le p_cut,count)
 endif else begin
     ;; not enough to compare, so set to none
     count = 0l
     variable = -1l
 endelse


 if (count gt 0) then begin
     v_cut = min(vscores[variable])
 endif else begin
     v_cut = max(vscores) + 0.01
 endelse


 return
end
