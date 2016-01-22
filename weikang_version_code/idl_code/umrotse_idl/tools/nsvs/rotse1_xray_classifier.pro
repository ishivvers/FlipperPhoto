pro rotse1_xray_print_info,rselt,flagonly=flagonly

if not keyword_set(flagonly) then begin
    print,'RA = '+string(rselt.ra_twomass,format='(f9.5)')+'  Dec = '+string(rselt.dec_twomass,format='(f9.5)')
endif
print,' Flags Set:'
if (rselt.typeflag eq 0) then print,'  No flags set.'
if ((rselt.typeflag and ishft(1l,0)) gt 0) then print,'  Simbad Match: '+rselt.simbad_name
if ((rselt.typeflag and ishft(1l,1)) gt 0) then print,'  Simbad Classification'
if ((rselt.typeflag and ishft(1l,2)) gt 0) then print,'  ROTSE Classification'
if ((rselt.typeflag and ishft(1l,3)) gt 0) then print,'  Algol Eclipse (steep)'
if ((rselt.typeflag and ishft(1l,4)) gt 0) then print,'  Beta-Lyrae Eclipse (ellipsoidal)'
if ((rselt.typeflag and ishft(1l,5)) gt 0) then print,'  Contact Binary'
if ((rselt.typeflag and ishft(1l,6)) gt 0) then print,'  T-Tauri/Herbig (Young Stellar Object)'
if ((rselt.typeflag and ishft(1l,7)) gt 0) then print,'  Cataclysmic Variable/Dwarf Nova'
if ((rselt.typeflag and ishft(1l,8)) gt 0) then print,'  Long Period Variable'
if ((rselt.typeflag and ishft(1l,9)) gt 0) then print,'  White Dwarf System'
if ((rselt.typeflag and ishft(1l,10)) gt 0) then print,'  Pre-Contact Binary'
if ((rselt.typeflag and ishft(1l,11)) gt 0) then print,'  Quasar'
if ((rselt.typeflag and ishft(1l,12)) gt 0) then print,'  X-Ray Binary'
if ((rselt.typeflag and ishft(1l,13)) gt 0) then print,'  RS Can Ven/BY Draconis'
if ((rselt.typeflag and ishft(1l,14)) gt 0) then print,'  IRAS Source'
if ((rselt.typeflag and ishft(1l,15)) gt 0) then print,'  Rapid Irregular'
if ((rselt.typeflag and ishft(1l,16)) gt 0) then print,'  Eclipsing (unknown)'
if ((rselt.typeflag and ishft(1l,17)) gt 0) then print,'  Cepheid'
if ((rselt.typeflag and ishft(1l,18)) gt 0) then print,'  Delta Scuti'
if ((rselt.typeflag and ishft(1l,19)) gt 0) then print,'  RR Lyrae'

if ((rselt.typeflag and ishft(1l,30)) gt 0) then print,'  Unknown'


return
end

pro rotse1_xray_change_flag,rs,ind,option

flag=strcompress(option,/remove_all)

unset=0
if (strmid(flag,0,1) eq '-') then begin
    unset=1
    flag=strmid(flag,1,strlen(flag)-1)  ;; lop off the -ve
endif

flagval=fix(flag)
if ((flagval eq 0) and (flag ne '0')) then begin
    print,'Illegal Option.'
endif else begin
    ;; set or unset
    if (unset) then begin
        ;; unset it
        rs[ind].typeflag = (rs[ind].typeflag and (not ishft(1l,flagval)))
    endif else begin
        ;; set it
        rs[ind].typeflag = (rs[ind].typeflag or ishft(1l,flagval))
    endelse
endelse

rotse1_xray_print_info,rs[ind],/flagonly
rotse1_xray_get_option,option,/print,/flagonly

return
end



pro rotse1_xray_get_option,option,print=print,flagonly=flagonly

option=''
if keyword_set(print) then begin
    print,''
;;    print,' [s]set flags  [u]unset flags'
    if not keyword_set(flagonly) then begin
        print,' [S]query simbad [N]Enter Simbad Name'
        print,' [p]previous var [n]next var (or enter)'
        print,' [i]print information [r]replot'
        print,' [q]quit (and save) [s]save [?]this help'
        print,' [d]double freq [h]half freq'
    endif
    print,' Flag Options: (to unset, precede number with a negative, eg -5)'
    print,'  [0] Simbad Match         [1] Simbad Classification [2] ROTSE Classification'
    print,'  [3] Algol Eclipse        [4] Beta-Lyrae Eclipse    [5] Contact Binary'
    print,'  [6] Young Stellar Object [7] CV/Dwarf Nova         [8] Long Period Variable'
    print,'  [9] White Dwarf System   [10] Pre-Contact Binary   [11] Quasar'
    print,'  [12] X-Ray Binary        [13] RS Can Ven/BY Dra    [14] IRAS Source'
    print,'  [15] Rapid Irregular     [16] Eclipsing (unknown)  [17] Cepheid'
    print,'  [18] Delta-Scuti         [19] RR Lyrae             [30] Unknown'

endif
if not keyword_set(flagonly) then begin
    read,option,prompt='Enter Option: '
endif

return
end

;;pro rotse1_xray_rephase,rs,ind

pro rotse1_xray_change_freq,rs,frames,ind,factor

;; change period and frequency
rs[ind].freq=rs[ind].freq*factor
rs[ind].period=rs[ind].period/factor

;; and plot it

rotse1_xray_plot_lcs,rs,frames,ind


return
end

pro rotse1_xray_plot_lcs,rs,frames,ind

read_skydot_sql_new,rs,ind,obs
obs.mjd=frames[obs.frame_id-1].mjd
find_good_pairs,obs,good,npairs

mjd=helio_jd(frames[obs[good].frame_id-1].mjd,rs[ind].ra,rs[ind].dec)
obs[good].mjd=mjd
minjd=min(mjd)
phases=(mjd-minjd)/rs[ind].period
phases=phases-fix(phases)
mag=obs[good].mag
err=obs[good].err
meanerr=mean(err)

mmin=min(obs[good].mag-meanerr)
mmax=max(obs[good].mag+meanerr)
yrange=[mmax,mmin]

!p.multi=[0,1,3]

;; plot the unphased lightcurve

ploterror,obs[good].mjd-minjd,mag,err,psym=1,yrange=yrange,/ystyle,xtitle='Days',ytitle='Mag',charsize=3

;; and the phased lightcurve

phases=[phases,phases+1.0]
mag=[mag,mag]
err=[err,err]

ploterror,phases,mag,err,yrange=yrange,psym=1,/ystyle,xtitle='Phase',ytitle='Mag',charsize=3

;; and prepare the color-color plots
!p.multi=[2,2,3]

;; the hmk vs jmh plot
plot,rs.jmh,rs.hmk,xrange=[-0.1,1.8],/xstyle,yrange=[-0.5,1.5],/ystyle,psym=3,xtitle='J - H',ytitle='H-K',charsize=3
;; and the crosshairs
plots,[rs[ind].jmh,rs[ind].jmh],[-0.5,1.5]
plots,[-0.1,1.8],[rs[ind].hmk,rs[ind].hmk]

;; the J vs jmh plot
plot,rs.jmh,rs.j_m,xrange=[-0.1,1.8],/xstyle,yrange=[17,3],/ystyle,psym=3,xtitle='J - H',ytitle='J',charsize=3
;; and the crosshairs
plots,[rs[ind].jmh,rs[ind].jmh],[17,3]
plots,[-0.1,1.8],[rs[ind].j_m,rs[ind].j_m]



return
end




pro rotse1_xray_classifier,rsfile,simbadfile=simbadfile,startind=startind,simbadonly=simbadonly

if n_params() eq 0 then begin
    print,'syntax- rotse1_xray_classifier,rsfile,startind=startind,simbadonly=simbadonly,simbadfile=simbadfile'
    return
endif

if n_elements(startind) eq 0 then startind=0l
if n_elements(simbadfile) eq 1 then smbstr=mrdfits(simbadfile,1)

rs=mrdfits(rsfile,1)
frames=mrdfits('/rotse3/data0/rotse1/nsvs/frames.fit',1)


window,xsize=800,ysize=800
setupplot
device,set_font='Helvetica',/tt_font

if keyword_set(simbadonly) then begin
    use=where((iv.typeflag and ishft(1,0)) gt 0,nuse)
    if (nuse eq 0) then begin
        print,'No Simbad matches (yet)'
        return
    endif
endif else begin
    use=lindgen(n_elements(rs))
    nuse=n_elements(rs)
endelse

i=long(startind)

while (i lt nuse) do begin
    ind=use[i]
    
    rotse1_xray_plot_lcs,rs,frames,ind

    print,'Object '+string(use[i],format='(i5)')+' of '+string(n_elements(rs),format='(i5)')
    rotse1_xray_print_info,rs[ind]

    cont=0
    first=1
    while (not cont) do begin
        if (first eq 1) then begin
            rotse1_xray_get_option,option,/print
            first = 0
        endif else rotse1_xray_get_option,option
        case option of
            'n': begin
                i=i+1
                cont=1
            end
            '': begin
                i=i+1
                cont=1
            end
            'p': begin
                if (i gt 0) then begin
                    i=i-1
                    cont=1
                endif else begin
                    print,'Already at first variable!'
                endelse
            end
            'q': begin
                cont=1
                i=n_elements(rs)+1
            end
            's': begin
                print,'Saving to ',rsfile
                mwrfits,rs,rsfile,/create
            end
            'i': rotse1_xray_print_info,rs[ind]
            '?': first=1
            'r': rotse1_xray_plot_lcs,rs,frames,ind
            'd': rotse1_xray_change_freq,rs,frames,ind,2.0
            'h': rotse1_xray_change_freq,rs,frames,ind,0.5
            'S': begin
                if n_elements(simbadfile) eq 0 then begin
                    rotse_query_simbad,rs[ind].ra_twomass,rs[ind].dec_twomass,smb,radius=5
                endif else begin
                    ;; we have the simbad file
                    sst=ind*10
                    print,' # ','ID','Type','RA','DEC','mB','mV','dis (")',format='(a3,a20,a10,2a12,3a10)'
                    for sctr=sst,sst+9 do begin
                        if (smbstr[sctr].ra ge 0) then begin
                            print,string(sctr-sst,format='(i2)')+' ',strtrim(smbstr[sctr].id,2),strtrim(smbstr[sctr].type,2),smbstr[sctr].ra,smbstr[sctr].dec,smbstr[sctr].mb,smbstr[sctr].mv,smbstr[sctr].dis,format='(a3,a20,a10,2d12.6,3f10.3)'
                        endif else sctr=sst+10
                    endfor
                endelse
            end
            'N': begin
                ;; simbad name
                name=''
                read,name,prompt='Enter Simbad Name: '
                rs[ind].simbad_name=name
            end
            else: begin
                ;; special name setting (if we have the smbstr)
                if (option eq '0') and n_elements(smbstr) gt 0 then begin
                    ans=''
                    read,ans,prompt='Enter Simbad Number: '
                    num=fix(ans)
                    if (num eq 0 and ans ne '0') then begin
                        print,'Illegal Entry.'
                    endif else begin
                        rs[ind].simbad_name=smbstr[ind*10+num].id
                    endelse
                endif
                ;; this is the set/unset part
                rotse1_xray_change_flag,rs,ind,option
            end
        endcase
    endwhile

endwhile

print,'Saving ',rsfile
mwrfits,rs,rsfile,/create

!p.multi=0

return
end
