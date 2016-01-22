pro fill_in_window, ifo, psout=psout
  ivalplot2, ifo.ival, idx=[ifo.iix], name=ifo.name
  IF NOT keyword_set(psout) THEN BEGIN 
      key = 'Source '+string(ifo.iix+1,format="(i3.3)")+$
        ' of '+string(ifo.ntp,format="(i3.3)")
      xyouts, 0.98, 0.52, key, /norm, alignment=1.0
      key = 'File '+string(ifo.fix+1,format="(i3.3)")+$
        ' of '+string(n_elements(ifo.list),format="(i3.3)")
      xyouts, 0.1, 0.52, key, /norm, alignment=0.0
  ENDIF 
end

FUNCTION cut_maxdev, iarr, cv
  mflg = bytarr(n_elements(iarr))
  FOR i=0l,long(n_elements(iarr))-1l DO BEGIN 
      g = where(iarr[i].good EQ 1, ng)
      IF ng GT 0 THEN BEGIN 
          mags = iarr[i].m[g] - iarr[i].mavg
          msq = sqrt(mags*mags)
          IF max(msq) GE cv THEN mflg[i] = 1
      ENDIF 
  ENDFOR 
  return, mflg
END 

PRO xivalplots_resize, event
  widget_control, event.top, get_uvalue=info, /no_copy
  widget_control, info.drawid, draw_xsize=event.x, draw_ysize=event.y
  wset, info.wid
  fill_in_window, info
  widget_control, event.top, set_uvalue=info, /no_copy
END   

PRO xivalplots_quit, event
  widget_control, event.top, /destroy
END

PRO xivalplots_oldfile, event
  widget_control, event.top, get_uvalue=info, /no_copy
  increment_list, info, -1
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_newfile, event
  widget_control, event.top, get_uvalue=info, /no_copy
  increment_list, info, 1
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_redraw, event
  widget_control, event.top, get_uvalue=info, /no_copy
  fill_in_window, info
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO increment_list, ifo, mov
  help, ifo.clist
  nix = ifo.fix + mov
  nmax = n_elements(ifo.list)
  IF nix LT nmax AND nix GE 0 THEN BEGIN
      nlist = ifo.list
      ncut = ifo.cut
      nname = nlist[nix]
      print, 'Reading ',nname
      niv = mrdfits(nname,1)
      root = strsplit(nname, '_', /extract)
      matname = root[0]+'_'+root[1]+'_relmat.fit'
      print, 'Reading ', matname
      nmat = mrdfits(matname,1)
      print, 'Files read.'

      IF (size(ifo.clist))[0] GT 0 THEN BEGIN 
          close_match_radec, ifo.clist[0,*], ifo.clist[1,*], niv.ra, niv.dec, a1, a2, 0.002, 1
          IF a2[0] GE 0 THEN niv = niv[a2]
      ENDIF 
      max = cut_maxdev(niv, ncut) 
      top = where(niv.tophase GT 1 AND max EQ 1, newtp)
      IF newtp GT 0 THEN niv = niv[top] ELSE niv = niv[0]
      sti = reverse(sort(niv.ival))
      niv = niv[sti]
      
      nwid = ifo.wid
      ndrawid = ifo.drawid
      nifo = {wid:nwid, drawid:ndrawid, name:nname, ival:niv, iix:0, $
              ntp:newtp, list:nlist, fix:nix, cut:ncut, clist:ifo.clist, mat:nmat}
      ifo = 0
      ifo = nifo
      fill_in_window, ifo
  ENDIF ELSE xyouts, 0.5, 0.75, 'No more files.', /norm, size=4.0, alignment=0.5, charthick=3
END

PRO xivalplots_postage, event
  widget_control, event.top, get_uvalue=info, /no_copy
  IF info.ival[info.iix].matname EQ 'noname' THEN $
    xyouts, 0.5, 0.78, 'No match structure name.  Cannot perform.', $
          /norm, alignment=0.5, size=4, thick=3 $
  ELSE BEGIN 
      widget_control, /hourglass
      fname = object_to_postage2(mtch,info.ival[info.iix].index,matname=info.ival[info.iix].matname)
      IF fname NE ' ' THEN $
        spawn, 'pdis '+fname+' &' $
        ELSE print, 'No image files found.'
  ENDELSE 
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_next, event
  widget_control, event.top, get_uvalue=info, /no_copy
  move_to_next, info
  widget_control, event.top, set_uvalue=info, /no_copy
END

pro rephase_close, event
  widget_control,event.top,/destroy
end


PRO rephase_from_list, event
  widget_control,event.top, get_uvalue=info,/no_copy
  
  ;; first get the new frequency selected
  index = event.index
  iv = info.ival[info.iix]

  iv.freq = info.freq_arr[index]
  iv.chi = info.chisq_arr[index]
  h=where(iv.good eq 1)
  
  calc_phases, iv, 0, h[0], info.jds

  info.ival[info.iix] = iv

  fill_in_window,info

  (*info.ptr).iv = iv

  widget_control, event.top, set_uvalue=info,/no_copy
END

PRO xivalplots_rephase, event
  widget_control, event.top, get_uvalue=info, /no_copy

  freq_str = generic_dialog(parent=event.top, default='10', text='Max. Frequency')
  if (freq_str eq '') then maxfreq = 0.0 else maxfreq = double(freq_str)


  IF (maxfreq GT 0.0) THEN BEGIN
      fname = 'rephase'
      thisival = info.ival[info.iix]
      h=where(thisival.good EQ 1)
      mjd_all=thisival.tzero+ (double(thisival.n) + double(thisival.phase)) $
        / double(thisival.freq)
      ts = mjd_all[h]
      ms=thisival.m[h] - thisival.mavg
      merrs=thisival.mwholerr[h]
 
      widget_control, /hourglass
      find_this_phase,ts,ms,merrs,f,c,fname=fname,maxfreq=maxfreq,/nomean, $
                      freq_arr=freq_arr,chisq_arr=chisq_arr

      ;; determine which frequency is currently set
      findex = (where(info.ival[info.iix].freq eq freq_arr, count))[0]
      if (count eq 0) then begin 
          findex = 0
          print,'not found?'
      endif

      freq_strs=strarr(n_elements(freq_arr))
      FOR i=0,n_elements(freq_arr)-1 DO $ 
          freq_strs[i]='Freq: '+string(freq_arr[i],format='(f6.3)')+' Chisq: '+ $
            string(chisq_arr[i],format='(f5.2)')

      ;; Now, what do we do?  Need a list widget.
      newbase = widget_base(title='Frequency Options', column=1, tlb_size_events=0, $
                            /modal, group_leader=event.top)
      listid = widget_list(newbase,event_pro='rephase_from_list', $
                           value=freq_strs,ysize=n_elements(freq_arr))
      closeit = widget_button(newbase, value='Close', event_pro='rephase_close')
      
      widget_control,newbase,/realize
      widget_control,listid,set_list_select=findex

      tempiv = info.ival[info.iix]
      ptr = ptr_new({iv:tempiv})

      newinfo = {freq_arr:freq_arr, chisq_arr:chisq_arr, ival:info.ival, $
                 iix:info.iix, jds:mjd_all, $
                 name:info.name, ntp:info.ntp, fix:info.fix, list:info.list, ptr:ptr}
            
      widget_control,newbase,set_uvalue=newinfo,/no_copy
      fill_in_window,info
      xmanager,'Frequency Options', newbase
      info.ival[info.iix] = (*ptr).iv
      ptr_free,ptr
      

  ENDIF

  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_save, event
  widget_control, event.top, get_uvalue=info, /no_copy
  fulli = mrdfits(info.list[info.fix],1)
 
  match,fulli.index,info.ival.index,fsub,isub,count=count
  if count gt 0 then begin
      for i=0l,count-1 do begin
          temp=fulli[fsub[i]]
          struct_assign,/verbose,info.ival[isub[i]],temp
          fulli[fsub[i]]=temp
      endfor
  endif

  mwrfits, fulli, info.list[info.fix], /create
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_back, event
  widget_control, event.top, get_uvalue=info, /no_copy
  move_to_prev, info
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO move_to_prev, ifo
  nst = ifo.iix - 1
  IF nst GE 0 THEN BEGIN 
      erase
      ifo.iix = nst
      fill_in_window, ifo
  ENDIF ELSE xyouts, 0.5, 0.5, 'No more sources to examine.', /norm, size=4.0, alignment=0.5, charthick=3
END

PRO move_to_specific, event
  widget_control, event.top, get_uvalue=info, /no_copy
  tag = generic_dialog(parent=event.top, default=range, text='Enter object number or coordinates')
  iix = info.iix

  if (tag ne '') then BEGIN
      vals = strsplit(tag, ' ', /extract)
      IF ((size(vals))[1] GT 1) THEN BEGIN 
          good = 0
          IF ((size(vals))[1] EQ 6) THEN BEGIN 
              ra = vals[0] + (vals[1] + vals[2]/60.)/60.
              sum = 1.
              IF (vals[3] LT 0) THEN sum = -1.
              dec = vals[3] + sum*(vals[1] + vals[2]/60.)/60.
              good = 1
          ENDIF 
          IF ((size(vals))[1] EQ 2) THEN BEGIN 
              ra = vals[0]
              dec = vals[1]
              good = 1
          ENDIF 
          IF good EQ 1 THEN BEGIN 
              gcirc, 1, ra, dec, info.ival[info.iix].ra/15., info.ival[info.iix].dec, dsep
              qs = sort(dsep)
              iix = qs[0]
          ENDIF 
      ENDIF ELSE BEGIN
          xxx = where(info.ival.index EQ tag, nx)
          IF (nx EQ 0) THEN xyouts, 0.1, 0.5, 'That source is not in my list.', /norm, size=3 $
            ELSE iix = xxx[0]
      ENDELSE 
      info.iix = iix
  ENDIF
  fill_in_window, info
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO move_to_next, ifo
  nst = ifo.iix + 1
  IF nst LT ifo.ntp THEN BEGIN 
      erase
      ifo.iix = nst
      fill_in_window, ifo
  ENDIF ELSE xyouts, 0.5, 0.5, 'No more sources to examine.', /norm, size=4.0, alignment=0.5, charthick=3
END

PRO xivalplots_tzdate, event
  widget_control, event.top, get_uvalue=info, /no_copy

  xjd = info.ival[info.iix].tzero + 2400000.5D
  daycnv, xjd, yr, mn, day, hr
  today = string(yr,format="(i4.4)")
  today = today + '/' + string(mn,format="(i2.2)")
  today = today + '/' + string(day,format="(i2.2)")
  today = today + ' : ' + string(hr,format="(f6.3)") + ' hr'

  tzbase = widget_base(title='Date Conversion', column=1, tlb_size_events=0, $
                            /modal, group_leader=event.top)
  saydate = widget_text(tzbase, value=today)
  dateclo = widget_button(tzbase, value='Close', event_pro='xivalplots_quit')

  widget_control,tzbase,/realize
  xmanager, 'Date Conversion', tzbase

  widget_control, event.top, set_uvalue=info, /no_copy
END 

PRO xivalplots_stab, event
  widget_control, event.top, get_uvalue=info, /no_copy
  omul = !p.multi
  ochsz = !P.charsize
  ochth = !P.charthick
  !p.charsize=2.0
  thisiv = info.ival[info.iix]
  
  allra = info.mat.ra 
  alldec = info.mat.dec
  myra = thisiv.ra
  mydec = thisiv.dec
  mmag = thisiv.mavg
  period = 1.0/thisiv.freq
  t = (double(thisiv.n) + thisiv.phase) * period
  og = where(thisiv.good EQ 1, nog)
  xt = t[og]
  omags = thisiv.m[og]
  omerr = thisiv.mwholerr[og]
  omin = min(omags-omerr)
  omax = max(omags+omerr)
  tmax = max(xt)
  tmin = min(xt)
  tspan = tmax - tmin
  trange = [tmin-tspan*0.1,tmax+tspan*0.1]
      
  nbso = 0
  br = 0.1
  WHILE nbso LT 4 DO BEGIN 
      gcirc, 1, allra/15., alldec, myra/15., mydec, dsep
      bso = where(info.mat.mavg LT mmag+br AND info.mat.mavg GT mmag-br $
                  AND info.mat.ngood GT nog/2 AND dsep LT 600., nbso)
      br = br + 0.1
  ENDWHILE 
  IF (nbso GT 0) THEN BEGIN 
      gcirc, 1, allra[bso]/15., alldec[bso], myra/15., mydec, dsep
      qs = sort(dsep)
      ixs = bso[qs[1:3]]
      !p.multi = [0,1,3]
      FOR j=0,2 DO BEGIN 
          ii = ixs[j]
          idlabel = 'Object number '+string(ii, format="(i5.5)")          
          g = where(info.mat.m[*,ii] GT 10. AND info.mat.m[*,ii] LT 25., ng)
          IF ng EQ 0 THEN xyouts, 0.1, (5.-j)/6., idlabel+' No good observations.', /norm ELSE BEGIN 
              mags = info.mat.m[g,ii]
              merr = info.mat.merr[g,ii]
              mmin = min(mags-merr)
              IF omin LT mmin THEN mmin = omin
              mmax = max(mags+merr)
              IF omax GT mmax THEN mmax = omax
              mspan = mmax - mmin
              mrange = [mmax+0.1*mspan, mmin-0.1*mspan]
              t = info.mat.jd - thisiv.tzero
              
              IF j EQ 2 THEN $
                plot, xt, omags, psym=4, ytitle='Mag', $
                xtitle='Time from '+string(thisiv.tzero,format="(f12.6)")+' (Days)', $
                xrange=trange, xstyle=1, yrange=mrange, ystyle=1, title=idlabel $
                ELSE $
                plot, xt, omags, psym=4, ytitle='Mag', $
                xrange=trange, xstyle=1, yrange=mrange, ystyle=1, title=idlabel 

              errplot, xt, omags+omerr, omags-omerr
              whco = !p.color
              !p.color = 255
              oplot, t[g], mags, psym=5
              errplot, t[g], mags+merr, mags-merr
              blu = 0L
              red = 0L
              gre = 150L
              !p.color = red + 256L*gre + 256L*256L*blu
              !p.charthick = 2
              xyouts, 0.1, (5.-2.*j)/6.-0.07, string(dsep[qs[j+1]]/60.,format="(f6.2)"), /norm, size=2.
              !p.charthick = ochth
              !p.color = whco
          ENDELSE 
      ENDFOR 
  ENDIF ELSE xyouts, 0.1, 0.5, 'No sources found.', /norm, size=2.
  

  !p.multi = omul
  !P.charsize = ochsz
  !P.charthick = ochth
  widget_control, event.top, set_uvalue=info, /no_copy
END 

PRO xivalplots_coords, event
  widget_control, event.top, get_uvalue=info, /no_copy

  ra = info.ival[info.iix].ra
  dec = info.ival[info.iix].dec
  rah = ra/15.
  sign = 1.0
  IF (dec LT 0.) THEN sign = -1.0
  dech = dec * sign

  rh = string(rah,format="(i2.2)")
  rm = string((rah-rh)*60.,format="(i2.2)")
  rs = string(((rah-rh)*60.-rm)*60.,format="(f5.2)")
  IF dec GE 0.0 THEN dd = '' ELSE dd = '-'
  dd = dd + string(dech,format="(i2.2)")
  dm = string((dech-dd)*60.,format="(i2.2)")
  ds = string(((dech-dd)*60.-dm)*60.,format="(f5.2)")

  ras = string(ra,format="(f10.6)")
  decs = string(dec,format="(f10.6)")
  pos = 'RA '+ras+' ('+rh+'h '+rm+'m '+rs+'s), Dec '+decs+' ('+dd+'d '+dm+'m '+ds+'s)'

  cobase = widget_base(title='Source Coordinates', column=1, tlb_size_events=0, $
                            /modal, group_leader=event.top)
  saycoor = widget_text(cobase, value=pos)
  coclose = widget_button(cobase, value='Close', event_pro='xivalplots_quit')

  widget_control,cobase,/realize
  xmanager, 'Source Coordinates', cobase

  widget_control, event.top, set_uvalue=info, /no_copy
END 

PRO xivalplots_saveps, event
  widget_control, event.top, get_uvalue=info, /no_copy
  files = str_sep(info.name, '/')
  parts = str_sep(files[n_elements(files)-1],'_')
  psfile = parts[0]+'_'+strmid(parts[1],0,2)+'_ival_'+string(info.ival[info.iix].index,format="(i5.5)")+'.ps'
  thisdevice = !d.name
  set_plot,  'ps' 
  DEVICE, ENCAPSUL=0, /LANDSCAPE, filename=psfile
  !p.thick = 2
  !p.charthick = 2
  fill_in_window, info, /psout
  device, /close
  set_plot, thisdevice
  !p.thick = 1
  !p.charthick = 1
  xyouts, 0.5, 0.5, 'Hardcopy printed to '+psfile, /norm, size=3.0, alignment=0.5, charthick=3, orientation=45
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_log, event
  widget_control, event.top, get_uvalue=info, /no_copy
  openw, ul, 'logfile', /append, /get_lun
  printf, ul, 'Look at '+info.name+', source '+$
        string(info.ival[info.iix].index, format="(i4.4)")
  close, ul
  free_lun, ul
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots_lognote, event
  widget_control, event.top, get_uvalue=info, /no_copy
  tag = generic_dialog(parent=event.top, default='No Comment', text='Comment')
  if (tag ne '') then begin
      openw, ul, 'logfile', /append, /get_lun
      logstring = 'Note about '+info.name+', source '+$
        string(info.ival[info.iix].index, format="(i4.4)")+' '+tag
      printf, ul, logstring
      close, ul
      free_lun, ul
  endif
  widget_control, event.top, set_uvalue=info, /no_copy
END

PRO xivalplots, inlist, file=file, usef=usef, cut=cut, res=res, clist=clist
  IF n_params() EQ 0 THEN print,'syntax- xivalplots, inlist, file=file, usef=usef, cut=cut, res=res, clist=clist' $
  ELSE BEGIN 
      IF keyword_set(file) THEN readcol,file,inlist,format='a100'
      IF keyword_set(usef) THEN list = inlist[usef] ELSE list = inlist
      IF NOT keyword_set(cut) THEN cut = 0.05
      IF NOT keyword_set(res) THEN res = [600,600]
      IF NOT keyword_set(clist) THEN clist=-1

      ferr = 0
      i = 0
      WHILE i LT n_elements(list) AND ferr EQ 0 DO BEGIN 
          openr, mlun, list[i], /get_lun, error=ferr
          IF ferr EQ 0 THEN BEGIN 
              close, mlun
              free_lun, mlun
              root = strsplit(list[i], '_', /extract)
              matname = root[0]+'_'+root[1]+'_relmat.fit'
              openr, mlun, list[i], /get_lun, error=ferr
              IF ferr EQ 0 THEN BEGIN 
                  close, mlun
                  free_lun, mlun
              ENDIF 
          ENDIF 
          i = i + 1
      ENDWHILE 

      IF ferr EQ 0 THEN BEGIN 
          tlb = widget_base(title='Evaluate Ivalue Plots', column=1, tlb_size_events=1, mbar=menubaseid)
          fileid = widget_button(menubaseid, value='File', menu=1)
          backid = widget_button(fileid, value='Back', event_PRO='xivalplots_back') 
          nextid = widget_button(fileid, value='Next', event_PRO='xivalplots_next') 
          saveid = widget_button(fileid, value='Save', event_PRO='xivalplots_save') 
          quitid = widget_button(fileid, value='Quit', event_PRO='xivalplots_quit') 
          statid = widget_button(menubaseid, value='Status', menu=1)
          acceid = widget_button(statid, value='Log Numbers', event_PRO='xivalplots_log') 
          rejeid = widget_button(statid, value='Log with Note', event_PRO='xivalplots_lognote') 
          stamid = widget_button(statid, value='Make Mosaic', event_PRO='xivalplots_postage')
          redocf = widget_button(statid, value='Redraw', event_PRO='xivalplots_redraw')
          tzdate = widget_button(statid, value='Convert Date', event_PRO='xivalplots_tzdate')
          socoor = widget_button(statid, value='Display Coords', event_PRO='xivalplots_coords')
          
          subbase = widget_base(tlb, column=1, frame=1)
          
          drawid = widget_draw(subbase, xsize=res[0], ysize=res[1])
          butbase = widget_base(tlb, row=1)
          backif = widget_button(butbase, value='Back File', event_PRO='xivalplots_oldfile') 
          backdf = widget_button(butbase, value='Back', event_PRO='xivalplots_back') 
          nextdf = widget_button(butbase, value='Next', event_PRO='xivalplots_next') 
          nextif = widget_button(butbase, value='Next File', event_PRO='xivalplots_newfile')
          space1 = widget_label(butbase, value='     ')
          spcobj = widget_button(butbase, value='Pick Source', event_PRO='move_to_specific')
          space2 = widget_label(butbase, value='     ')
          rephzx = widget_button(butbase, value='Rephase', event_PRO='xivalplots_rephase')
          stabso = widget_button(butbase, value='Compare Neighbors', event_PRO='xivalplots_stab')
          
          widget_control,tlb,/realize
          widget_control, drawid, get_value=wid
          wset, wid
          
          fix = 0
          name = list[fix]
          print, 'Reading ',name
          inv = mrdfits(name,1)
          root = strsplit(name, '_', /extract)
          matname = root[0]+'_'+root[1]+'_relmat.fit'
          print, 'Reading ', matname
          mat = mrdfits(matname,1)
          print, 'Files read in.'
          
          IF (size(clist))[0] GT 0 THEN BEGIN 
              close_match_radec, clist[0,*], clist[1,*], inv.ra, inv.dec, a1, a2, 0.002, 1
              IF a2[0] GE 0 THEN inv = inv[a2]
          ENDIF 
          
          max = cut_maxdev(inv, cut) 
          top = where(inv.tophase GT 1 AND max EQ 1, ntp)
          IF ntp GT 0 THEN ival = inv[top] ELSE ival = inv[0]
          ;;print, ival.mavg
          sti = reverse(sort(ival.ival))
          ival = ival[sti]
          iix = 0
          
          freq_arr = fltarr(15)
          
          info = {wid:wid, drawid:drawid, name:name, ival:ival, iix:iix, $
                  ntp:ntp, list:list, fix:fix, cut:cut, clist:clist, mat:mat}
          
          fill_in_window, info
          widget_control, tlb, set_uvalue=info, /no_copy
          xmanager, 'Evaluate Ivalue Plots', tlb, /no_block, $
            event_handler='xivalplots_resize'
      ENDIF ELSE print, 'Errors found; exiting program.' 
  ENDELSE 
END 
  
