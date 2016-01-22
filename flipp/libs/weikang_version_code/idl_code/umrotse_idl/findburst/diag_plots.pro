pro diag_plots,stat,fileonly=fileonly

; Created:	9-1-00  Bob Kehoe

if not keyword_set(fileonly) then begin
   !P.MULTI=[0,2,2]
   plot, stat.nframe, stat.pos_sigma, psym=3
   plot, stat.nframe, stat.zp_sigma, psym=3
   plot, stat.nframe, stat.m_lim, psym=3
   plot, stat.pos_sigma, stat.m_lim, psym=3
endif
!P.MULTI=[0,2,2]
set_plot, 'ps'
device,file='diag_plots.ps'
plot, stat.nframe, stat.pos_sigma, psym=3
plot, stat.nframe, stat.zp_sigma, psym=3
plot, stat.nframe, stat.m_lim, psym=3
plot, stat.pos_sigma, stat.m_lim, psym=3
device, /close
set_plot, 'X'

end
