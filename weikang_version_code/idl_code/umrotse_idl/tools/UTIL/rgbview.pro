PRO rgbview, red, grn, blue, r, g, b, color_im, contrast=contrast, $
             xrange=xrange, yrange=yrange, noprompt=noprompt, $
             title=title, xtitle=xtitle, ytitle=ytitle, subtitle=subtitle, $
             noframe=noframe, nolabels=nolabels,$
             _extra=extra_key


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
;
; NAME:
;    RGBVIEW
;       
; PURPOSE:
;    Create and display a RGB image from red, green, and blue input images.
;    Contrast (number of sigma above mean) can be changed at the prompt.
;    WARNING:  There should be no zero elements in images.  For best effect, 
;              give images a large offset from zero.  E.g 1000
;    SDSS should use red=i, grn=r, blue=g although this will have false
;    color.  The result is similar to Steve Kent's images.
;    If the device is postscript, then a color postscript is made.
;    NOTE: The color map is NOT inverted so there is often large amounts
;          of black space.
;
;    This program requires 256 colors to work properly.  To insure the
;    you get all the colors, you can request a private color map.  This
;    is done when the first window is opened.  You must use this command:
;         IDL> window, colors=256
;
;    It won't work except on the first window so you might consider putting
;    it in your .idl.startup file.  Note that using a private color map
;    may cause "flashing" when you point in the window.
;
; CALLING SEQUENCE:
;    rgbview, red, grn, blue [, r, g, b, contrast=contrast, 
;            xrange=xrange, yrange=yrange, noprompt=noprompt, 
;            title=title, xtitle=xtitle, ytitle=ytitle, subtitle=subtitle, 
;            noframe=noframe, nolabels=nolabels,
;            _extra=extra_key]
;
; INPUTS: 
;    red, grn, blue: The red, green and blue images.  Images must be same size.
;
; KEYWORD PARAMETERS:
;    contrast:  The number of sigma above the mean to use in images.
;            The default is 10 but good results depend on the image.
;            Larger images often require larger contrast because of their
;            smaller variance.
;    noprompt: if set then don't ask for a change of contrast.
;    xrange, yrange, noframe, nolabels: see tvim2
;    title,xtitle,ytitle,subtitle: Plot labels.
;    _extra=extra_key:  Other plotting keywords.
;
;       
; OPTIONAL OUTPUTS: 
;    r,g,b: color map vectors.  These are the vectors used to display 
;           this image.  They can be sent to 
;
;                IDL> WRITE_GIF, filename, TVRD(), r, g, b
;           
;           The color map can be reset to BW linear with loadct,0
; 
;    color_im: The color image.  It will only look right if the color
;              map r,g,b is used.
;  
; CALLED ROUTINES:
;    DCENTER
;    SIGMA_CLIP
;    COLOR_QUAN
; 
; PROCEDURE: 
;    
;
; REVISION HISTORY:
;    Author: Erin Scott Sheldon  UofMich  11/28/99
;       
;                                      
;-                                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  IF n_params() EQ 0 THEN BEGIN
      print,'-Syntax: rgbview, red, grn, blue, r, g, b, contrast=contrast, '
      print,'       xrange=xrange, yrange=yrange, noprompt=noprompt, '
      print,'       title=title, xtitle=xtitle, ytitle=ytitle, subtitle=subtitle, '
      print,'       noframe=noframe, nolabels=nolabels,'
      print,'       _extra=extra_key'
      print
      print,' -For sloan, use red=i, grn=r, blue=g'
      print,' -contrast=nsigma above mean'
      print,'  Small images, contrast~5-10, Medium ~20 Large ~30   default=10'
      print,'  It really depends on the image'
      print,' -r,g,b are color map vectors.  WRITE_GIF,fname,TVRD(),r,g,b'
      return
  ENDIF 

  max_color=!d.n_colors-1
  IF n_elements(title) EQ 0 THEN title = ''
  IF n_elements(xtitle) EQ 0 THEN xtitle=''
  IF n_elements(ytitle) EQ 0 THEN ytitle=''
  IF n_elements(subtitle) EQ 0 THEN subtitle=''
  IF NOT keyword_set(noprompt) THEN noprompt = 0

  szr = size(red)
  szg = size(grn)
  szb = size(blue)

  IF (szr[4] NE szg[4]) OR (szr[4] NE szb[4]) THEN BEGIN
      print,'Arrays must be of same size'
      return
  ENDIF 


  IF n_elements(contrast) EQ 0 THEN contrast = 10.
  contrast = float(contrast)

  print,'Using ',ntostr(max_color+1),' colors'
  IF max_color LT 255 THEN BEGIN
      print,'WARNING: Not using all the colors.  See the online help'
  ENDIF 
  print,'Beginning with contrast = ',ntostr(contrast)
  low_cut = 1.
  niter = 3
  nsig = 3.5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set up plot
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  nx = szr[1]
  ny = szr[2]
  aspect = float(nx)/ny

  plot, [0,1],[0,1],/nodata,xstyle=4,ystyle=4
  px=!x.window*!d.x_vsize
  py=!y.window*!d.y_vsize
  xsize=px[1]-px[0]
  ysize=py[1]-py[0]
  
  IF xsize GT ysize*aspect THEN xsize=ysize*aspect ELSE ysize=xsize/aspect 
  px[1]=px[0]+xsize
  py[1]=py[0]+ysize

  nxm=nx-1
  nym=ny-1

  IF n_elements(xrange) EQ 0 THEN BEGIN
      xrng=[ -0.5, nxm+0.5]
  ENDIF ELSE BEGIN
      xrng=[xrange(0), xrange(n_elements(xrange)-1)]
  ENDELSE 

  IF n_elements(yrange) EQ 0 THEN BEGIN
      yrng = [-0.5,nym+0.5]
  ENDIF ELSE BEGIN
      yrng = [yrange(0), yrange(n_elements(yrange)-1)]
  ENDELSE 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; center up the display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  dcenter, xsize, ysize, px, py, /silent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get relative scaling 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  print,'Sigma Clipping'
  sigma_clip, red, meani, sigmai, niter=niter, nsig=nsig, /silent
  sigma_clip, grn, meanr, sigmar, niter=niter, nsig=nsig, /silent
  sigma_clip, blue, meang, sigmag, niter=niter, nsig=nsig, /silent

  ms = [meani, meanr, meang]
  maxx = max(ms)
  wmax = where(ms EQ maxx, nwmax)
  IF (nwmax GT 1) OR (nwmax EQ 0) THEN BEGIN
      print,'Dohh!'
      return
  ENDIF 

  print,'Finding Relative Scaling'
  CASE wmax[0] OF 
      0: BEGIN
          fc = 1./float(red)
          ifac = 1
          rfac = grn*fc < 1.
          gfac = blue*fc < 1.
      END 
      1: BEGIN
          fc = 1./float(grn)
          ifac = red*fc < 1.
          rfac = 1
          gfac = blue*fc < 1.
      END 
      2: BEGIN
          fc = 1./float(blue)
          ifac = red*fc < 1.
          rfac = grn*fc < 1.
          gfac = 1
      END 
  ENDCASE 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; byte scale each of the images
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  continue = 1
  WHILE continue DO BEGIN 
      continue = 0
      high = meani + contrast*sigmai
      low  = meani -  low_cut*sigmai
      ai = bytscl(red, min=low, max=high, top=max_color)
      w=where(ai*ifac LE 255)


      high = meanr + contrast*sigmar
      low  = meanr -  low_cut*sigmar
      ar = bytscl(grn, min=low, max=high, top=max_color)
      ar[*] = ar[*]*rfac

      high = meang + contrast*sigmag
      low  = meang -  low_cut*sigmag
      ag = bytscl(blue, min=low, max=high, top=max_color)
      ag[*] = ag[*]*gfac

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create pseudo color image
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      color_im = color_quan(ai, ar, ag, r, g, b)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Output to proper device
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      IF (!d.flags AND 1) EQ 0 THEN BEGIN ;X window
          tv, congrid(color_im, xsize, ysize), px[0],py[0]
          tvlct, r, g, b
          pos = [px[0], py[0], px[1], py[1]]
      ENDIF ELSE BEGIN          ;Postscript
          device,/color
          tvlct, r, g, b
          pos = [px[0], py[0], px[1], py[1]]
          tv, color_im, px[0], py[0], xsize=xsize, ysize=ysize, /device
      ENDELSE 
  
      max_color = max(ai)
      IF keyword_set(noframe) OR keyword_set(nolabels) THEN BEGIN 
          plot, [0,0], [0,0], xstyle=5, ystyle=5, $
            title=title,xtitle=xtitle,ytitle=ytitle, subtitle=subtitle, $
            xrange=xrng, yrange=yrng, position=pos, color=max_color, $
            /noerase, /device, /nodata
      ENDIF ELSE BEGIN 
          plot, [0,0], [0,0], xstyle=1, ystyle=1, $
            title=title, xtitle=xtitle, ytitle=ytitle, subtitle=subtitle, $
            xrange=xrng, yrange=yrng, position=pos, color=max_color,$
            /noerase, /device, /nodata
      ENDELSE 
      
      IF (NOT keyword_set(noframe)) AND keyword_set(nolabels) THEN BEGIN 
          axis,xaxis=1,xtickname=strarr(10)+" ",color=max_color
          axis,xaxis=0,xtickname=strarr(10)+" ",color=max_color
          axis,yaxis=1,ytickname=strarr(10)+" ",color=max_color
          axis,yaxis=0,ytickname=strarr(10)+" ",color=max_color
      ENDIF 

      IF NOT noprompt THEN BEGIN 
          print,format='($, "Change Contrast? (y/n)")'
          ans = get_kbrd(1)
          CASE ans OF
              'Y': continue = 1
              'y': continue = 1
              ELSE:
          ENDCASE
          IF continue EQ 1 THEN BEGIN
              print,format='($, " New contrast")'
              read, contrast
              contrast=float(contrast)
          ENDIF 
      ENDIF 

  ENDWHILE 
  print
return
END 
