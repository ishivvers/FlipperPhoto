pro ival_aggregate_print_info,ivelt

print,'RA = '+string(ivelt.ra,format='(f9.5)')+'  Dec = '+string(ivelt.dec,format='(f9.5)')
print,' '+ivelt.matchname+' Index: '+string(ivelt.index,format='(i5)')
print,' Flags:'
if ((ivelt.vflag and ishft(1,0)) gt 0) then print,'  Good Variable.'
if ((ivelt.vflag and ishft(1,1)) gt 0) then print,'  Bad Variable.'
if ((ivelt.vflag and ishft(1,2)) gt 0) then print,'  Good Phase.'
if ((ivelt.vflag and ishft(1,3)) gt 0) then print,'  ROSAT match.'
if ((ivelt.vflag and ishft(1,4)) gt 0) then print,'  2MASS match.'
if ((ivelt.vflag and ishft(1,5)) gt 0) then print,'  SDSS match.'
if ((ivelt.vflag and ishft(1,6)) gt 0) then print,'  ROTSE-I match.'
if ((ivelt.vflag and ishft(1,7)) gt 0) then print,'  Not sure.'


return
end

pro ival_aggregate_get_option,option,print=print

option=''
if keyword_set(print) then begin
    print,''
    print,' [g]good variable  [v]good variable & phase [u]unsure'
    print,' [b]bad variable   [i]print information  [R]replot'
    print,' [p]previous var   [n]next var (or enter)'
    print,' [s]save structure [q]quit (and save) [?]this help'
    print,' [r]rephase        [d]double freq [h]half freq [S]query Simbad'
endif
read,option,prompt='Enter option: '


return
end

pro ival_aggregate_rephase,iv,ind

ans=''
read,ans,prompt='Enter max freq. [10]: '
if (ans eq '') then maxfreq=10 else maxfreq=float(ans)
;;mjd_all=iv[ind].tzero+(double(iv[ind].n)+double(iv[ind].phase))/double(iv[ind].freq)
date_all=(double(iv[ind].n)+double(iv[ind].phase))/double(iv[ind].freq)
gd=where(iv[ind].good eq 1,ngd)
if (ngd gt 2) then begin
    npairs=ngd/2
    pairind0=lindgen(npairs)*2
    pairind1=pairind0+1
    meanmags=0.5*(iv[ind].m[pairind0]+iv[ind].m[pairind1])
    meandate=0.5d*(date_all[pairind0]+date_all[pairind1])
    meanerr=sqrt(iv[ind].merr[pairind0]^2.+ iv[ind].merr[pairind1]^2.+0.02^2.)
    print,'rephasing...'
    find_this_phase,meandate,meanmags,meanerr,f,c,fname='rephase', $
      maxfreq=maxfreq,/nomean,freq_arr=freq_arr,chisq_arr=chisq_arr

    ofreq=iv[ind].freq
    ochisq=iv[ind].chisq

    print,'Frequency    Chisq'
    for i=0l,n_elements(freq_arr)-1 do begin
        line=string(freq_arr[i],format='(f10.4)') + string(chisq_arr[i],format='(f10.3)')
        if (freq_arr[i] eq ofreq) then line = line + ' *'
        print,line
    endfor

    ok = 0
    i=0
    reset = 0
    while (not ok) do begin
        if freq_arr[i] eq 0.0 then begin
            print,'resetting bad frequency to 1.0'
            freq_arr[i] = 1.0
            chisq_arr[i] = 0.0
        endif
        iv[ind].freq = freq_arr[i]
        iv[ind].chisq = chisq_arr[i]
        iv[ind].n = floor(date_all*iv[ind].freq)
        iv[ind].phase = date_all*iv[ind].freq - iv[ind].n
        !p.multi=[3,1,3]
        ival_aggregate_plot_lcs,iv[ind]
        ans=''
        print,'Frequency = '+string(iv[ind].freq,format='(f7.3)') + '  Chisq = '+string(iv[ind].chisq,format='(f7.3)')
        read,ans,prompt='[n]ext (or enter), [p]revious, [o]k, [c]ancel:'
        case ans of 
            'n': if (i lt (n_elements(freq_arr)-1)) then i=i+1
            '': if (i lt (n_elements(freq_arr)-1)) then i=i+1
            'p': if (i gt 0) then i=i-1
            'o': ok = 1
            'c': begin
                ok = 1
                reset = 1
            end
            else: print,'Illegal option.'
        endcase        
    endwhile

    if (reset eq 1) then begin
        iv[ind].freq = ofreq
        iv[ind].chisq = ochisq
        iv[ind].n = floor(date_all*iv[ind].freq)
        iv[ind].phase = date_all*iv[ind].freq - iv[ind].n
    endif

endif
return
end

pro ival_aggregate_change_freq,iv,ind,factor

date_all=(double(iv[ind].n)+double(iv[ind].phase))/double(iv[ind].freq)
iv[ind].freq = iv[ind].freq*factor
iv[ind].n = floor(date_all*iv[ind].freq)
iv[ind].phase = date_all*iv[ind].freq - iv[ind].n

ival_aggregate_plot_lcs,iv[ind]


return
end


pro ival_aggregate_plot_lcs,ivelt

gd=where(ivelt.good eq 1,ngd)

!p.multi=[0,1,3]

;; plot the unphased lightcurve
time=(double(ivelt.n[gd]) + ivelt.phase[gd])/ivelt.freq
m=ivelt.m[gd]
merr=ivelt.merr[gd]
yrange=[max(m+merr)+0.1,min(m-merr)-0.1]


ploterror,time,m,merr,psym=1,charsize=3, $
  yrange=yrange,xtitle='Days',ytitle='Mag',/ystyle
        
phase=ivelt.phase[gd]
        
ploterror,[phase,1+phase],[m,m],[merr,merr],psym=1,charsize=3,$
  yrange=yrange,xtitle='Phase',ytitle='Mag',/ystyle, $
  xrange=[-0.1,2.1],/xstyle, $
  title='Period = '+string(1./ivelt.freq,format='(f10.3)')+'   chisq = '+string(ivelt.chisq,format='(f10.2)')+'   Sig = '+string(ivelt.ival_sig,format='(f6.2)')
      
 
!p.multi=[2,2,3]
        
tvim2,ivelt.dim,title='Dimmest Detection',charsize=3
tvim2,ivelt.bright,title='Brightest Detection',charsize=3
      

return
end



pro ival_aggregate_viewer,ivfile,startind=startind,showall=showall,unflagged=unflagged,rosat=rosat

if n_params() eq 0 then begin
    print,'syntax- ival_aggregate_viewer,ivfile,startind=startind,showall=showall,unflagged=unflagged,rosat=rosat'
    return
endif

;;flag definitions
;; 0 : good variable
;; 1 : bad variable
;; 2 : good phase
;; 3 : ROSAT match
;; 4 : 2mass match
;; 5 : SDSS match
;; 6 : ROTSE-I variable match
;; 7 : unsure
;; and then variable classes (not yet implemented)
;; 8 : RR lyrae...

if n_elements(startind) eq 0 then startind = 0l

iv=mrdfits(ivfile,1)

window,xsize=800,ysize=800

setupplot
device,set_font='Helvetica',/tt_font

if keyword_set(showall) then begin
    use=lindgen(n_elements(iv))
    nuse=n_elements(iv)
endif else if keyword_set(unflagged) then begin
    use=where(iv.vflag eq 0,nuse)
    if (nuse eq 0) then begin
        print,'all variables have been flagged.'
        return
    endif 
endif else if (keyword_set(rosat)) then begin
    use=where((iv.vflag and ishft(1,3)) gt 0,nuse)
    if (nuse eq 0) then begin
        print,'no rosat matches'
        return
    endif
endif else begin
    use=where((iv.vflag and ishft(1,1)) eq 0,nuse)
    if (nuse eq 0) then begin
        print,'No good variables???'
        return
    endif
endelse

i=long(startind)  ;; tough...

while (i lt nuse) do begin
    
    ind=use[i]
    gd=where(iv[ind].good eq 1,ngd)
    if (ngd gt 1) then begin

        ival_aggregate_plot_lcs,iv[ind]

        
        print,'Object '+string(use[i],format='(i5)')+' of '+string(n_elements(iv),format='(i5)')
        ival_aggregate_print_info,iv[ind]

        cont=0
        first = 1
        while (not cont) do begin
            if (first eq 1) then begin
                ival_aggregate_get_option,option,/print
                first = 0
            endif else ival_aggregate_get_option,option
            case option of
                'g': begin
                    iv[ind].vflag = (iv[ind].vflag or ishft(1,0))  ;;good var
                    cont = 1
                    i=i+1
                end
                'v': begin
                    iv[ind].vflag = (iv[ind].vflag or ishft(1,0) or ishft(1,2)) ; good var & good phase
                    cont = 1
                    i=i+1
                end
                'b': begin
                    iv[ind].vflag = (iv[ind].vflag or ishft(1,1)) ;; bad var
                    cont = 1
                    i=i+1
                end
                'u': begin
                    iv[ind].vflag = (iv[ind].vflag or ishft(1,7)) ;; unsure
                    cont = 1
                    i=i+1
                end
                's': begin
                    print,'Saving to ',ivfile
                    mwrfits,iv,ivfile,/create
                end
                'i': ival_aggregate_print_info,iv[ind]
                'p': begin
                    if (i gt 0) then begin
                        i=i-1
                        cont = 1
                    endif else begin
                        print,'Already at first variable!'
                    endelse
                end
                'n': begin
                    i=i+1
                    cont = 1
                end
                '': begin
                    i=i+1
                    cont = 1
                end
                'q': begin
                    cont = 1
                    i = n_elements(iv)+1
                end
                'r': begin
;;                    print,'rephase not supported yet'
                    ival_aggregate_rephase,iv,ind
                    ival_aggregate_plot_lcs,iv[ind]
                end
                'S': rotse_query_simbad,iv[ind].ra,iv[ind].dec,smb
                'R': ival_aggregate_plot_lcs,iv[ind]
                '?': first=1
                'd': ival_aggregate_change_freq,iv,ind,2.0
                'h': ival_aggregate_change_freq,iv,ind,0.5
                else: print,'Illegal option'
            endcase
        endwhile

    endif

endwhile

print,'Saving ',ivfile
mwrfits,iv,ivfile,/create

!p.multi=0

return
end
