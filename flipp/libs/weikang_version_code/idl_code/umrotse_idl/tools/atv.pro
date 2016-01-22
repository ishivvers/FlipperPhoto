;+
; NAME:
;       ATV
; 
; PURPOSE: 
;       Interactive display of 2-D images.
;
; CATEGORY: 
;       Image display.
;
; CALLING SEQUENCE:
;       atv [,array_name OR fits_file] [,min = min_value] [,max=max_value] 
;           [,/autoscale] [,/linear] [,/log] [,/histeq] 
;
; REQUIRED INPUTS:
;       None.  If atv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to atv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D data array to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       autoscale:  set min and max to show a range of data values
;                      around the median value
;       linear:     use linear stretch
;       log:        use log stretch 
;       histeq:     use histogram equalization
;       
; OUTPUTS:
;       None.  
; 
; COMMON BLOCKS:
;       atv_state:  contains variables describing the display state
;       atv_images: contains the internal copies of the display image
;       atv_color:  contains colormap vectors
;       atv_pdata:  contains plot and text annotation information
;
; RESTRICTIONS:
;       Requires IDL version 5.1 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy library routines,
;         for fits input and world coordinate system information.
;       Some features may not work under all operating systems.
;       For a current list of atv's bugs and weirdnesses, go to
;              http://cfa-www.harvard.edu/~abarth/atv/atv.html
;
; SIDE EFFECTS:
;       Modifies the color table.
;
; EXAMPLE:
;       To start atv running, just enter the command 'atv' at the idl
;       prompt, either with or without an array name or fits file name 
;       as an input.  Only one atv window will be created at a time,
;       so if one already exists and another image is passed to atv
;       from the idl command line, the new image will be displayed in 
;       the pre-existing atv window.
;
; MODIFICATION HISTORY:
;       Written by Aaron J. Barth, first release 17 December 1998.
;
;       This version is 1.0b10, last modified 12 May 2000.
;       For the most current version, revision history, instructions,
;       and further information, go to:
;              http://cfa-www.harvard.edu/~abarth/atv/atv.html
;
;-
;----------------------------------------------------------------------
;        atv startup, initialization, and shutdown routines
;----------------------------------------------------------------------

pro atv_initcommon

; Routine to initialize the atv common blocks.  Use common blocks so
; that other IDL programs can access the atv internal data easily.

common atv_state, state
common atv_color, r_vector, g_vector, b_vector
common atv_pdata, nplot, maxplot, plot_ptr
common atv_images, $
  main_image, $
  display_image, $
  scaled_image, $
  blink_image1, $
  blink_image2, $
  blink_image3, $
  unblink_image, $  
  pan_image


state = {                   $
          version: '1.0b10', $            ; version # of this release
          head_ptr: ptr_new(), $         ; pointer to image header
          astr_ptr: ptr_new(), $         ; pointer to astrometry info structure
          equinox: 'J2000', $            ; equinox of coord system
          display_coord_sys: 'RA--', $   ; coord system displayed
          display_equinox: 'J2000', $    ; equinox of displayed coords
          imagename: '', $               ; image file name
          base_id: 0L, $                 ; id of top-level base
          base_min_size: [512L, 300L], $ ; min size for top-level base
          draw_base_id: 0L, $            ; id of base holding draw window
          draw_window_id: 0L, $          ; window id of draw window
          draw_widget_id: 0L, $          ; widget id of draw widget
          track_window_id: 0L, $         ; widget id of tracking window
          pan_widget_id: 0L, $           ; widget id of pan window
          pan_window_id: 0L, $           ; window id of pan window
          active_window_id: 0L, $        ; user's active window outside atv
          info_base_id: 0L, $            ; id of base holding info bars
          location_bar_id: 0L, $         ; id of (x,y,value) label
          wcs_bar_id: 0L, $              ; id of WCS label widget
          min_text_id: 0L,  $            ; id of min= widget
          max_text_id: 0L, $             ; id of max= widget
          menu_ids: lonarr(30), $        ; list of top menu items
          colorbar_base_id: 0L, $        ; id of colorbar base widget
          colorbar_widget_id: 0L, $      ; widget id of colorbar draw widget
          colorbar_window_id: 0L, $      ; window id of colorbar
          colorbar_height: 6L, $         ; height of colorbar in pixels
          ncolors: 0B, $                 ; image colors (!d.table_size - 8)
          brightness: 500L, $            ; initial brightness setting
          contrast: 500L, $              ; initial contrast setting
          maxbright: 1000L, $            ; max for bright and contrast (min=1)
          keyboard_text_id: 0L, $        ; id of keyboard input widget
          image_min: 0.0, $              ; min(main_image)
          image_max: 0.0, $              ; max(main_image)
          min_value: 0.0, $              ; min data value mapped to colors
          max_value: 0.0, $              ; max data value mapped to colors
          draw_window_size: [512L, 512L], $    ; size of main draw window
          track_window_size: 121L, $     ; size of tracking window
          pan_window_size: 121L, $       ; size of pan window
          pan_scale: 0.0, $              ; magnification of pan image
          image_size: [0L,0L], $         ; size of main_image
          invert_colormap: 0L, $         ; 0=normal, 1=inverted
          coord: [0L, 0L],  $            ; cursor position in image coords
          scaling: 0L, $                 ; 0=linear, 1=log, 2=histeq
          offset: [0L, 0L], $            ; offset to viewport coords
          base_pad: [0L, 0L], $          ; padding around draw base
          zoom_level: 0L, $              ; integer zoom level, 0=normal
          zoom_factor: 1.0, $            ; magnification factor = 2^zoom_level
          centerpix: [0L, 0L], $         ; pixel at center of viewport
          cstretch: 0B, $                ; flag = 1 while stretching colors
          pan_offset: [0L, 0L], $        ; image offset in pan window
          frame: 1L, $                   ; put frame around ps output?
          lineplot_widget_id: 0L, $      ; id of lineplot widget
          lineplot_window_id: 0L, $      ; id of lineplot window
          lineplot_base_id: 0L, $        ; id of lineplot top-level base
          lineplot_size: [600L, 450L], $ ; size of lineplot window
          lineplot_pad: [0L, 0L], $      ; padding around lineplot window
          cursorpos: lonarr(2), $        ; cursor x,y for photometry & stats
          centerpos: fltarr(2), $        ; centered x,y for photometry
          cursorpos_id: 0L, $            ; id of cursorpos widget
          centerpos_id: 0L, $            ; id of centerpos widget
          centerbox_id: 0L, $            ; id of centeringboxsize widget
          radius_id: 0L, $               ; id of radius widget
          innersky_id: 0L, $             ; id of inner sky widget
          outersky_id: 0L, $             ; id of outer sky widget
          skyresult_id: 0L, $            ; id of sky widget
          photresult_id: 0L, $           ; id of photometry result widget
          fwhm_id: 0L, $                 ; id of fwhm widget
          radplot_widget_id: 0L, $       ; id of radial profile widget
          radplot_window_id: 0L, $       ; id of radial profile window
          photzoom_window_id: 0L, $      ; id of photometry zoom window
          photzoom_size: 200L, $         ; size in pixels of photzoom window
          showradplot_id: 0L, $          ; id of button to show/hide radplot
          photwarning_id: 0L, $          ; id of photometry warning widget
          photwarning: ' ', $            ; photometry warning text
          centerboxsize: 7L, $           ; centering box size
          r: 5L, $                       ; aperture photometry radius
          innersky: 10L, $               ; inner sky radius
          outersky: 20L, $               ; outer sky radius
          headinfo_base_id: 0L, $        ; headinfo base widget id
          stats_base_id: 0L, $           ; base widget for image stats
          statboxsize: 11L, $            ; box size for computing statistics
          statbox_id: 0L, $              ; widget id for stat box size 
          stat_npix_id: 0L, $            ; widget id for # pixels in stats box
          statxcenter_id: 0L, $          ; widget id for stat box x center
          statycenter_id: 0L, $          ; widget id for stat box y center
          statbox_min_id: 0L, $          ; widget id for stat min box
          statbox_max_id: 0L, $          ; widget id for stat max box
          statbox_mean_id: 0L, $         ; widget id for stat mean box
          statbox_median_id: 0L, $       ; widget id for stat median box
          statbox_stdev_id: 0L, $        ; widget id for stat stdev box
          statzoom_size: 300, $          ; size of statzoom window
          statzoom_widget_id: 0L, $      ; widget id for stat zoom window
          statzoom_window_id: 0L, $      ; window id for stat zoom window
          showstatzoom_id: 0L, $         ; widget id for show/hide button
          pan_pixmap: 0L, $              ; window id of pan pixmap
          default_autoscale: 1, $        ; autoscale images by default?
          current_dir: '', $             ; current readfits directory
          blinks: 0B $                   ; remembers which images are blinked
        }

nplot = 0
maxplot = 5000
plot_ptr = ptrarr(maxplot+1)  ; The 0th element isn't used.

blink_image1 = 0
blink_image2 = 0
blink_image3 = 0

end

;---------------------------------------------------------------------

pro atv_startup

; This routine initializes the atv internal variables, and creates and
; realizes the window widgets.  It is only called by the atv main
; program level, when there is no previously existing atv window.

common atv_state
common atv_color

; Read in a color table to initialize !d.table_size
; As a bare minimum, we need the 8 basic colors used by ATV_ICOLOR(),
; plus 2 more for a color map.

loadct, 0, /silent
if (!d.table_size LT 10) then begin
    message, 'Too few colors available for color table'
    atv_shutdown
endif

; Initialize the common blocks
atv_initcommon

state.ncolors = !d.table_size - 8

; Get the current window id
atv_getwindow

; Define the widgets.  For the widgets that need to be modified later
; on, save their widget ids in state variables

base = widget_base(title = 'atv', $
                   /column, /base_align_right, $
                   app_mbar = top_menu, $
                   uvalue = 'atv_base', $
                   /tlb_size_events, /tracking_events)
state.base_id = base

tmp_struct = {cw_pdmenu_s, flags:0, name:''}

top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $         ; file menu
                  {cw_pdmenu_s, 0, 'ReadFits'}, $
                  {cw_pdmenu_s, 0, 'WritePS'},  $
                  {cw_pdmenu_s, 0, 'WriteTiff'}, $
                  {cw_pdmenu_s, 2, 'Quit'}, $
                  {cw_pdmenu_s, 1, 'ColorMap'}, $     ; color menu
                  {cw_pdmenu_s, 0, 'Grayscale'}, $
                  {cw_pdmenu_s, 0, 'Blue-White'}, $
                  {cw_pdmenu_s, 0, 'Red-Orange'}, $
                  {cw_pdmenu_s, 0, 'Rainbow'}, $
                  {cw_pdmenu_s, 0, 'BGRY'}, $
                  {cw_pdmenu_s, 0, 'Stern Special'}, $
;                  {cw_pdmenu_s, 0, 'STD Gamma-II'}, $
                  {cw_pdmenu_s, 2, 'ATV Special'}, $
                  {cw_pdmenu_s, 1, 'Scaling'}, $      ; scaling menu
                  {cw_pdmenu_s, 0, 'Linear'}, $
                  {cw_pdmenu_s, 0, 'Log'}, $
                  {cw_pdmenu_s, 2, 'HistEq'}, $
                  {cw_pdmenu_s, 1, 'Labels'}, $       ; labels menu
                  {cw_pdmenu_s, 0, 'TextLabel'}, $
                  {cw_pdmenu_s, 0, 'Contour'}, $
                  {cw_pdmenu_s, 0, 'Compass'}, $
                  {cw_pdmenu_s, 0, 'ScaleBar'}, $
                  {cw_pdmenu_s, 0, 'EraseLast'}, $
                  {cw_pdmenu_s, 2, 'EraseAll'}, $
                  {cw_pdmenu_s, 1, 'Blink'}, $
                  {cw_pdmenu_s, 0, 'SetBlink1'}, $
                  {cw_pdmenu_s, 0, 'SetBlink2'}, $
                  {cw_pdmenu_s, 2, 'SetBlink3'}, $
                  {cw_pdmenu_s, 1, 'ImageInfo'}, $    ;info menu
                  {cw_pdmenu_s, 0, 'Photometry'}, $
                  {cw_pdmenu_s, 0, 'Statistics'}, $
                  {cw_pdmenu_s, 0, 'ImageHeader'}, $
                  {cw_pdmenu_s, 0, '--------------'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (J2000)'}, $
                  {cw_pdmenu_s, 0, 'RA,dec (B1950)'}, $
                  {cw_pdmenu_s, 0, 'Galactic'}, $
                  {cw_pdmenu_s, 0, 'Ecliptic (J2000)'}, $
                  {cw_pdmenu_s, 2, 'Native'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 2, 'ATV Help'} $
                ]

top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_name, $
                     uvalue = 'top_menu')

track_base =    widget_base(base, /row)
state.info_base_id = widget_base(track_base, /column, /base_align_right)
buttonbar_base = widget_base(base, column=2, /base_align_center)

state.draw_base_id = $
  widget_base(base, $
              /column, /base_align_left, $
              /tracking_events, $
              uvalue = 'draw_base', $
              frame = 2)

state.colorbar_base_id = $
  widget_base(base, $
              uvalue = 'colorbar_base', $
              /column, /base_align_left, $
              frame = 2)

state.min_text_id = $
  cw_field(state.info_base_id, $
           uvalue = 'min_text', $
           /floating,  $
           title = 'Min=', $
           value = state.min_value,  $
           /return_events, $
           xsize = 12)

state.max_text_id = $
  cw_field(state.info_base_id, $
           uvalue = 'max_text', $
           /floating,  $
           title = 'Max=', $
           value = state.max_value, $
           /return_events, $
           xsize = 12)

tmp_string = string(1000, 1000, 1.0e-10, $
                    format = '("(",i4,",",i4,") ",g12.5)' )

state.location_bar_id = $
  widget_label (state.info_base_id, $
                value = tmp_string,  $
                uvalue = 'location_bar',  frame = 1)

tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $
        format = '(i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )
    
state.wcs_bar_id = $
  widget_label (state.info_base_id, $
                value = tmp_string,  $
                uvalue = 'wcs_bar',  frame = 1)

state.pan_widget_id = $
  widget_draw(track_base, $
              xsize = state.pan_window_size, $
              ysize = state.pan_window_size, $
              frame = 2, uvalue = 'pan_window', $
              /button_events, /motion_events)

track_window = $
  widget_draw(track_base, $
              xsize=state.track_window_size, $
              ysize=state.track_window_size, $
              frame=2, uvalue='track_window')

modebase = widget_base(buttonbar_base, /row, /base_align_center)
modelist = ['Color', 'Zoom', 'Blink', 'ImExam']
mode_droplist_id = widget_droplist(modebase, $
                                   frame = 1, $
                                   title = 'MouseMode:', $
                                   uvalue = 'mode', $
                                   value = modelist)

button_base = widget_base(buttonbar_base, row=2, /base_align_right)

invert_button = $
  widget_button(button_base, $
                value = 'Invert', $
                uvalue = 'invert')

reset_button = $
  widget_button(button_base, $
                value = 'ResetColor', $
                uvalue = 'reset_color')

autoscale_button = $
  widget_button(button_base, $
                uvalue = 'autoscale_button', $
                value = 'AutoScale')

fullrange_button = $
  widget_button(button_base, $
                uvalue = 'full_range', $
                value = 'FullRange')

state.keyboard_text_id = $
  widget_text(button_base, $
              /all_events, $
              scr_xsize = 1, $
              scr_ysize = 1, $
              units = 0, $
              uvalue = 'keyboard_text', $
              value = '')

zoomin_button = $
  widget_button(button_base, $
                value = 'ZoomIn', $
                uvalue = 'zoom_in')

zoomout_button = $ 
  widget_button(button_base, $
                value = 'ZoomOut', $
                uvalue = 'zoom_out')

zoomone_button = $
  widget_button(button_base, $
                value = 'Zoom1', $
                uvalue = 'zoom_one')

center_button = $
  widget_button(button_base, $
                value = 'Center', $
                uvalue = 'center')

done_button = $
  widget_button(button_base, $
                value = 'Done', $
                uvalue = 'done')

state.draw_widget_id = $
  widget_draw(state.draw_base_id, $
              uvalue = 'draw_window', $
              /motion_events,  /button_events, $
              scr_xsize = state.draw_window_size[0], $
              scr_ysize = state.draw_window_size[1]) 

state.colorbar_widget_id = $
  widget_draw(state.colorbar_base_id, $
              uvalue = 'colorbar', $
              scr_xsize = state.draw_window_size[0], $
              scr_ysize = state.colorbar_height)

; Create the widgets on screen

widget_control, base, /realize
widget_control, state.pan_widget_id, draw_motion_events = 0
xmanager, 'atv', state.base_id, /no_block, $
  cleanup = 'atv_shutdown'

; get the window ids for the draw widgets

widget_control, track_window, get_value = tmp_value
state.track_window_id = tmp_value
widget_control, state.draw_widget_id, get_value = tmp_value
state.draw_window_id = tmp_value
widget_control, state.pan_widget_id, get_value = tmp_value
state.pan_window_id = tmp_value
widget_control, state.colorbar_widget_id, get_value = tmp_value
state.colorbar_window_id = tmp_value


; set the event handlers

widget_control, top_menu, event_pro = 'atv_topmenu_event'
widget_control, state.draw_widget_id, event_pro = 'atv_draw_color_event'
widget_control, state.draw_base_id, event_pro = 'atv_draw_base_event'
widget_control, state.keyboard_text_id, event_pro = 'atv_keyboard_event'
widget_control, state.pan_widget_id, event_pro = 'atv_pan_event'

; Find window padding sizes needed for resizing routines.
; Add extra padding for menu bar, since this isn't included in 
; the geometry returned by widget_info.
; Also add extra padding for margin (frame) in draw base.

basegeom = widget_info(state.base_id, /geometry)
drawbasegeom = widget_info(state.draw_base_id, /geometry)

state.base_pad[0] = basegeom.xsize - drawbasegeom.xsize $
  + (2 * basegeom.margin)
state.base_pad[1] = basegeom.ysize - drawbasegeom.ysize + 30 $
  + (2 * basegeom.margin)

state.base_min_size = [state.base_pad[0] + state.base_min_size[0], $
                       state.base_pad[1] + 100]

; Initialize the vectors that hold the current color table.
; See the routine atv_stretchct to see why we do it this way.

r_vector = bytarr(state.ncolors)
g_vector = bytarr(state.ncolors)
b_vector = bytarr(state.ncolors)

atv_getct, 0
state.invert_colormap = 0

; Create a pixmap window to hold the pan image
window, /free, xsize=state.pan_window_size, ysize=state.pan_window_size, $
  /pixmap
state.pan_pixmap = !d.window
atv_resetwindow

atv_colorbar

end

;--------------------------------------------------------------------

pro atv_colorbar

; Routine to tv the colorbar at the bottom of the atv window

common atv_state

atv_setwindow, state.colorbar_window_id

xsize = (widget_info(state.colorbar_widget_id, /geometry)).xsize

b = congrid( findgen(state.ncolors), xsize) + 8
c = replicate(1, state.colorbar_height)
a = b # c

tv, a

atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_shutdown, windowid

; routine to kill the atv window(s) and clear variables to conserve
; memory when quitting atv.  Since we can't delvar the atv internal
; variables, just set them equal to zero so they don't take up a lot
; of space. The windowid parameter is used when atv_shutdown is called
; automatically by the xmanager.

common atv_images
common atv_state
common atv_color
common atv_pdata

; Kill top-level base if it still exists
if (xregistered ('atv')) then widget_control, state.base_id, /destroy

; Destroy all pointers to plots and their heap variables
if (nplot GT 0) then begin
    atverase, /norefresh
    plot_ptr = 0
endif

; Destroy state structure, images, and color vectors
if (size(state, /tname) EQ 'STRUCT') then begin
    if (size(state.head_ptr, /tname) EQ 'POINTER') then $
      ptr_free, state.head_ptr
    if (size(state.astr_ptr, /tname) EQ 'POINTER') then $   ;changed 4/16/2000
      ptr_free, state.astr_ptr
    wdelete, state.pan_pixmap
    main_image = 0
    display_image = 0
    scaled_image = 0
    blink_image1 = 0
    blink_image2 = 0
    blink_image3 = 0
    unblink_image = 0
    pan_image = 0
    r_vector = 0
    g_vector = 0
    b_vector = 0
    state = 0
endif

return    
end

;--------------------------------------------------------------------
;                  main atv event loops
;--------------------------------------------------------------------

pro atv_topmenu_event, event

; Event handler for top menu

common atv_state
common atv_images

widget_control, event.id, get_uvalue = event_name

; Need to get active window here in case mouse goes to menu from top
; of atv window without entering the main base
atv_getwindow

case event_name of
    
; File menu options:
    'ReadFits': begin
        atv_readfits, newimage=newimage
        if (newimage EQ 1) then begin
            atv_getstats
            atv_settitle
            state.zoom_level =  0
            state.zoom_factor = 1.0
            if (state.default_autoscale EQ 1) then atv_autoscale
            atv_set_minmax
            atv_displayall
            atv_cleartext
        endif
    end
    'WritePS' : atv_writeps
    'WriteTiff': atv_writetiff
    'Quit':     atv_shutdown
; ColorMap menu options:            
    'Grayscale': atv_getct, 0
    'Blue-White': atv_getct, 1
    'Red-Orange': atv_getct, 3
    'BGRY': atv_getct, 4
    'Rainbow': atv_getct, 13
    'Stern Special': atv_getct, 15
;    'STD Gamma-II': atv_getct, 5
    'ATV Special': atv_makect, event_name
; Scaling options:
    'Linear': begin
        state.scaling = 0
        atv_displayall
        atv_cleartext
    end
    'Log': begin
        state.scaling = 1
        atv_displayall
        atv_cleartext
    end
    'HistEq': begin
        state.scaling = 2
        atv_displayall
        atv_cleartext
    end
; Label options:
    'TextLabel': atv_textlabel
    'Contour': atv_oplotcontour
    'Compass': atv_setcompass
    'ScaleBar': atv_setscalebar
    'EraseLast': atverase, 1
    'EraseAll': atverase
; Blink options:
    'SetBlink1': begin   
        atv_setwindow, state.draw_window_id
        blink_image1 = tvrd()
    end
    'SetBlink2': begin   
        atv_setwindow, state.draw_window_id
        blink_image2 = tvrd()
    end
    'SetBlink3': begin   
        atv_setwindow, state.draw_window_id
        blink_image3 = tvrd()
    end

; Info options:
    'Photometry': atv_apphot
    'ImageHeader': atv_headinfo
    'Statistics': atv_showstats

; Coordinate system options:
    '--------------':
    'RA,dec (J2000)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       atv_gettrack             ; refresh coordinate window
    END 
    'RA,dec (B1950)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'B1950'
       atv_gettrack             ; refresh coordinate window
    END
    'Galactic': BEGIN 
       state.display_coord_sys = 'GLON'
       atv_gettrack             ; refresh coordinate window
    END 
    'Ecliptic (J2000)': BEGIN 
       state.display_coord_sys = 'ELON'
       state.display_equinox = 'J2000'
       atv_gettrack             ; refresh coordinate window
    END 
    'Native': BEGIN 
       IF ptr_valid(state.astr_ptr) THEN BEGIN 
          state.display_coord_sys = strmid((*state.astr_ptr).ctype[0], 0, 4)
          state.display_equinox = state.equinox
          atv_gettrack          ; refresh coordinate window
       ENDIF 
    END 

    
; Help options:            
    'ATV Help': atv_help
    
    else: print, 'Unknown event in file menu!'
endcase

; Need to test whether atv is still alive, since the quit option
; might have been selected.        
if (xregistered('atv', /noshow)) then atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_draw_color_event, event

; Event handler for color mode

common atv_state

case event.type of
    0: begin           ; button press
        if (event.press EQ 1) then begin
            state.cstretch = 1
            atv_stretchct, event.x, event.y, /getmouse
        endif else begin
            atv_zoom, 'none', /recenter
        endelse
    end
    1: begin
        state.cstretch = 0  ; button release
        atv_draw_motion_event, event
    end
    2: begin                ; motion event
        if (state.cstretch EQ 1) then $
          atv_stretchct, event.x, event.y, /getmouse $
        else atv_draw_motion_event, event
    end 
endcase

widget_control, state.keyboard_text_id, /input_focus

end

;--------------------------------------------------------------------

pro atv_draw_zoom_event, event

; Event handler for zoom mode

common atv_state

if (event.type EQ 0) then begin 
    case event.press of
        1: atv_zoom, 'in', /recenter
        2: atv_zoom, 'none', /recenter
        4: atv_zoom, 'out', /recenter
    endcase
    widget_control, state.keyboard_text_id, /input_focus
endif

if (event.type EQ 2) then atv_draw_motion_event, event

end

;---------------------------------------------------------------------

pro atv_draw_blink_event, event

; Event handler for blink mode

common atv_state
common atv_images

case event.type of
    0: begin                    ; button press
        atv_setwindow, state.draw_window_id
        case event.press of
            1: if n_elements(blink_image1) GT 1 then tv, blink_image1
            2: if n_elements(blink_image2) GT 1 then tv, blink_image2
            4: if n_elements(blink_image3) GT 1 then tv, blink_image3  
            else: event.press = 0   ; in case of errors
        endcase
        state.blinks = (state.blinks + event.press) < 7
    end
    
    1: begin                    ; button release
        atv_setwindow, state.draw_window_id
        state.blinks = (state.blinks - event.release) > 0
        case state.blinks of
            0: tv, unblink_image
            1: if n_elements(blink_image1) GT 1 then tv, blink_image1 $
            else tv, unblink_image
            2: if n_elements(blink_image2) GT 1 then tv, blink_image2 $
            else tv, unblink_image
            3: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1 
            endif else if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2
            endif else begin
                tv, unblink_image
            endelse
            4: if n_elements(blink_image3) GT 1 then tv, blink_image3 $
            else tv, unblink_image
            5: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1 
            endif else if n_elements(blink_image3) GT 1 then begin
                tv, blink_image3
            endif else begin
                tv, unblink_image
            endelse 
            6: if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2 
            endif else if n_elements(blink_image4) GT 1 then begin
                tv, blink_image4
            endif else begin
                tv, unblink_image
            endelse
            else: begin          ; check for errors
                state.blinks = 0
                tv, unblink_image
            end
        endcase
    end
    2: atv_draw_motion_event, event    ; motion event
endcase

widget_control, state.keyboard_text_id, /input_focus
atv_resetwindow

end

;-------------------------------------------------------------------

pro atv_draw_phot_event, event

; Event handler for ImExam mode

common atv_state
common atv_images

if (event.type EQ 0) then begin
    case event.press of
        1: atv_apphot
        2: atv_showstats
        4: atv_showstats
        else: 
    endcase
    widget_control, state.draw_widget_id, /clear_events
    widget_control, state.keyboard_text_id, /input_focus
endif

if (event.type EQ 2) then atv_draw_motion_event, event

end

;--------------------------------------------------------------------

pro atv_draw_motion_event, event

; Event handler for motion events in draw window

common atv_state

tmp_event = [event.x, event.y]            
state.coord = $
  round( (0.5 >  ((tmp_event / state.zoom_factor) + state.offset) $
          < (state.image_size - 0.5) ) - 0.5)
atv_gettrack

end

;--------------------------------------------------------------------

pro atv_draw_base_event, event

; If the mouse enters the main draw base, set the input focus to
; the invisible text widget, for keyboard input.
; When the mouse leaves the main draw base, de-allocate the input
; focus by setting the text widget value.

common atv_state

case event.enter of
    0: begin
        widget_control, state.draw_base_id, /clear_events
        atv_resetwindow
        widget_control, state.keyboard_text_id, set_value = ''
    end
    
    1: begin
        widget_control, state.keyboard_text_id, /input_focus
        atv_getwindow
    end
endcase      

atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_keyboard_event, event

; Event procedure for keyboard input when the cursor is in the 
; main draw window.

common atv_state

eventchar = string(event.ch)
case eventchar of
    '1': atv_move_cursor, eventchar
    '2': atv_move_cursor, eventchar
    '3': atv_move_cursor, eventchar
    '4': atv_move_cursor, eventchar
    '6': atv_move_cursor, eventchar
    '7': atv_move_cursor, eventchar
    '8': atv_move_cursor, eventchar
    '9': atv_move_cursor, eventchar
    'r': atv_rowplot
    'c': atv_colplot
    's': atv_surfplot
    't': atv_contourplot
    'p': atv_apphot
    'i': atv_showstats
    'q': atv_shutdown
    else:  ;any other key press does nothing
endcase

if (xregistered('atv', /noshow)) then $
  widget_control, state.keyboard_text_id, /clear_events

end

;--------------------------------------------------------------------

pro atv_pan_event, event

; event procedure for moving the box around in the pan window

common atv_state

case event.type of
    0: begin                     ; button press
        widget_control, state.pan_widget_id, draw_motion_events = 1
        atv_pantrack, event
    end
    1: begin                     ; button release
        widget_control, state.pan_widget_id, draw_motion_events = 0
        widget_control, state.pan_widget_id, /clear_events
        atv_pantrack, event
        atv_getdisplay
    end
    2: begin
        atv_pantrack, event     ; motion event
        widget_control, state.pan_widget_id, /clear_events
    end
    else:
endcase

end

;--------------------------------------------------------------------

pro atv_event, event

; Main event loop for atv top-level base, and for all the buttons.

common atv_state
common atv_images
common atv_color


widget_control, event.id, get_uvalue = uvalue

; Get currently active window
atv_getwindow

case uvalue of

    'atv_base': begin     
        c = where(tag_names(event) EQ 'ENTER', count)
        if (count EQ 0) then begin       ; resize event
            atv_resize
            atv_refresh
            atv_cleartext
        endif
    end

    'mode': case event.index of
        0: widget_control, state.draw_widget_id, $
          event_pro = 'atv_draw_color_event'
        1: widget_control, state.draw_widget_id, $
          event_pro = 'atv_draw_zoom_event'
        2: widget_control, state.draw_widget_id, $
          event_pro = 'atv_draw_blink_event'
        3: widget_control, state.draw_widget_id, $
          event_pro = 'atv_draw_phot_event'
        else: print, 'Unknown mouse mode!'
    endcase

    'invert': begin                  ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)

        r_vector = reverse(r_vector)
        g_vector = reverse(g_vector)
        b_vector = reverse(b_vector)

        atv_stretchct, state.brightness, state.contrast
       
        atv_cleartext
    end

    'reset_color': begin   ; set color sliders to default positions
        state.brightness = state.maxbright / 2
        state.contrast = state.maxbright / 2
        atv_stretchct, state.brightness, state.contrast
        atv_cleartext
    end


    'min_text': begin     ; text entry in 'min = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'max_text': begin     ; text entry in 'max = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'autoscale_button': begin   ; autoscale the image
        atv_autoscale
        atv_displayall
        atv_cleartext
    end

    'full_range': begin    ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
            state.min_value = state.max_value - 1
            state.max_value = state.max_value + 1
        endif
        atv_set_minmax
        atv_displayall
        atv_cleartext
    end
    
    'zoom_in':  atv_zoom, 'in'         ; zoom buttons
    'zoom_out': atv_zoom, 'out'
    'zoom_one': atv_zoom, 'one'

    'center': begin   ; center image and preserve current zoom level
        atv_drawbox
        state.centerpix = round(state.image_size / 2.)
        atv_getoffset
        atv_drawbox
        atv_getdisplay
    end

    'done':  atv_shutdown

    else:  print, 'No match for uvalue....'  ; bad news if this happens

endcase
end

;-----------------------------------------------------------------------
;      main atv routines for scaling, displaying, cursor tracking...
;-----------------------------------------------------------------------

pro atv_displayall

; Call the routines to scale the image, make the pan image, and
; re-display everything.  Use this if the scaling changes (log/
; linear/ histeq), or if min or max are changed, or if a new image is
; passed to atv.  If the display image has just been moved around or
; zoomed without a change in scaling, then just call atv_refresh
; rather than this routine.

atv_scaleimage
atv_makepan
atv_refresh

end

;---------------------------------------------------------------------


pro atv_refresh

; Make the display image from the scaled_image, and redisplay the pan
; image and tracking image. 

common atv_state
common atv_images

atv_getwindow
atv_getoffset
atv_getdisplay

; redisplay the pan image and plot the boundary box
atv_setwindow, state.pan_pixmap
erase
tv, pan_image, state.pan_offset[0], state.pan_offset[1]
atv_resetwindow

atv_setwindow, state.pan_window_id
tv, pan_image, state.pan_offset[0], state.pan_offset[1]
atv_resetwindow
atv_drawbox


; redisplay the tracking image
atv_gettrack

; Prevent rapid-fire mouse clicks
widget_control, state.draw_base_id, /clear_events   

atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_getdisplay

; make the display image from the scaled image by applying the zoom
; factor and matching to the size of the draw window, and display the
; image.

common atv_state
common atv_images

widget_control, /hourglass   

display_image = bytarr(state.draw_window_size[0], state.draw_window_size[1])

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

view_min = (0 > view_min < (state.image_size - 1)) 
view_max = (0 > view_max < (state.image_size - 1)) 

newsize = round( (view_max - view_min + 1) * state.zoom_factor) > 1
startpos = abs( round(state.offset * state.zoom_factor) < 0)

tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
                                 view_min[1]:view_max[1]], $
                    newsize[0], newsize[1])

xmax = newsize[0] < (state.draw_window_size[0] - startpos[0])
ymax = newsize[1] < (state.draw_window_size[1] - startpos[1])

display_image[startpos[0], startpos[1]] = $
  temporary(tmp_image[0:xmax-1, 0:ymax-1])

; Display the image
atv_setwindow, state.draw_window_id
erase
tv, display_image
atv_resetwindow

; Overplot x,y plots from atvplot
atv_plotall

atv_setwindow, state.draw_window_id
unblink_image = tvrd()  

atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_getoffset
common atv_state

; Routine to calculate the display offset for the current value of
; state.centerpix, which is the central pixel in the display window.

state.offset = $
  round( state.centerpix - $
         (0.5 * state.draw_window_size / state.zoom_factor) )

end

;----------------------------------------------------------------------


pro atv_makepan

; Make the 'pan' image that shows a miniature version of the full image.

common atv_state
common atv_images

sizeratio = state.image_size[1] / state.image_size[0]

if (sizeratio GE 1) then begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[1])
endif else begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[0])
endelse

tmp_image = $
  scaled_image[0:state.image_size[0]-1, 0:state.image_size[1]-1]

pan_image = $
  congrid(tmp_image, round(state.pan_scale * state.image_size[0])>1, $
          round(state.pan_scale * state.image_size[1])>1 )

state.pan_offset[0] = round((state.pan_window_size - (size(pan_image))[1]) / 2)
state.pan_offset[1] = round((state.pan_window_size - (size(pan_image))[2]) / 2)

end

;----------------------------------------------------------------------


pro atv_move_cursor, direction

; Use keypad arrow keys to step cursor one pixel at a time.
; Get the new track image, and update the cursor position.

common atv_state

i = 1L

case direction of
    '2': state.coord[1] = max([state.coord[1] - i, 0])
    '4': state.coord[0] = max([state.coord[0] - i, 0])
    '8': state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
    '6': state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    '7': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = max([state.coord[0] - i, 0])
    end
    '9': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '3': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '1': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = max([state.coord[0] - i, 0])
    end

endcase

newpos = (state.coord - state.offset + 0.5) * state.zoom_factor

atv_setwindow,  state.draw_window_id
tvcrs, newpos[0], newpos[1], /device
atv_resetwindow

atv_gettrack

; Prevent the cursor move from causing a mouse event in the draw window

widget_control, state.draw_widget_id, /clear_events

atv_resetwindow

end

;----------------------------------------------------------------------

pro atv_set_minmax

; Updates the min and max text boxes with new values.

common atv_state

widget_control, state.min_text_id, set_value = string(state.min_value)
widget_control, state.max_text_id, set_value = string(state.max_value)

end

;----------------------------------------------------------------------

pro atv_get_minmax, uvalue, newvalue

; Change the min and max state variables when user inputs new numbers
; in the text boxes. 

common atv_state

case uvalue of
    
    'min_text': begin
        if (newvalue LT state.max_value) then begin
            state.min_value = newvalue
        endif
    end

    'max_text': begin
        if (newvalue GT state.min_value) then begin
            state.max_value = newvalue
        endif
    end
        
endcase

atv_set_minmax

end

;--------------------------------------------------------------------

pro atv_cleartext

; Routine to clear the widget for keyboard input when the cursor is not
; in the main draw window.  This deallocates the input focus from the
; text input widget.

common atv_state

widget_control, state.draw_base_id, /clear_events
widget_control, state.keyboard_text_id, set_value = ''

end

;----------------------------------------------------------------------

pro atv_zoom, zchange, recenter = recenter
common atv_state

; Routine to do zoom in/out and recentering of image

case zchange of
    'in':    state.zoom_level = (state.zoom_level + 1) < 6
    'out':   state.zoom_level = (state.zoom_level - 1) > (-6) 
    'one':   state.zoom_level =  0
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  print,  'problem in atv_zoom!'
endcase

state.zoom_factor = 2.^state.zoom_level

if (n_elements(recenter) GT 0) then begin
    state.centerpix = state.coord
    atv_getoffset
endif

atv_refresh

if (n_elements(recenter) GT 0) then begin
    newpos = (state.coord - state.offset + 0.5) * state.zoom_factor
    atv_setwindow,  state.draw_window_id
    tvcrs, newpos[0], newpos[1], /device 
    atv_resetwindow
    atv_gettrack
endif

atv_resetwindow

end

;-----------------------------------------------------------------------

pro atv_autoscale

; Routine to auto-scale the image.

common atv_state 
common atv_images

widget_control, /hourglass

med = median(main_image)
sig = stddev(main_image)

state.max_value = (med + (10 * sig)) < max(main_image)

state.min_value = (med - (2 * sig))  > min(main_image)
if (state.min_value LT 0 AND med GT 0) then begin
  state.min_value = 0.0
endif

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

atv_set_minmax

end  

;--------------------------------------------------------------------

function atv_wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox

; Routine to return a string which displays cursor coordinates.
; Allows choice of various coordinate systems.
; Contributed by D. Finkbeiner, April 2000.

; ctype - coord system in header
; disp_type - type of coords to display

headtype = strmid(ctype[0], 0, 4)

; need numerical equinox values
IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
  IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
  num_equinox = float(equinox)

IF (disp_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
  IF (disp_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
  num_disp_equinox = float(equinox)

; first convert lon,lat to RA,dec (J2000)
CASE headtype OF 
    'GLON': euler, lon, lat, ra, dec, 2 ; J2000
    'ELON': BEGIN 
        euler, lon, lat, ra, dec, 4 ; J2000
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
    'RA--': BEGIN    
        ra = lon
        dec = lat
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
ENDCASE  

; Now convert RA,dec (J2000) to desired display coordinates:  

IF disp_type[0] EQ 'RA--' THEN BEGIN ; generate (RA,dec) string
    
    disp_ra  = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    
    neg_dec  = disp_dec LT 0

    radec, disp_ra, abs(disp_dec), ihr, imin, xsec, ideg, imn, xsc
    
    wcsstring = string(ihr, imin, xsec, ideg, imn, xsc, disp_equinox, $
                       format = '(i2.2,":",i2.2,":",f6.3,"   ",i2.2,":",i2.2,":",f5.2," ",a6)' )
    if (strmid(wcsstring, 6, 1) EQ ' ') then $
      strput, wcsstring, '0', 6
    if (strmid(wcsstring, 21, 1) EQ ' ') then $
      strput, wcsstring, '0', 21
    IF neg_dec THEN strput, wcsstring, '-', 14
ENDIF 

IF disp_type[0] EQ 'GLON' THEN BEGIN ; generate (l,b) string
    euler, ra, dec, l, b, 1
    
    wcsstring = string(l, b, format='("Galactic (",F9.5,",",F9.5,")")')
ENDIF 

IF disp_type[0] EQ 'ELON' THEN BEGIN ; generate (l,b) string
    
    disp_ra = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    euler, disp_ra, disp_dec, lam, bet, 3
    
    wcsstring = string(lam, bet, format='("Ecliptic (",F9.5,",",F9.5,")")')
ENDIF 

return, wcsstring
END

;--------------------------------------------------------------------


pro atv_gettrack

; Create the image to display in the track window that tracks
; cursor movements.  Also update the coordinate display and the
; (x,y) and pixel value.

common atv_state
common atv_images

; Get x and y for center of track window

zcenter = (0 > state.coord < state.image_size)

track = bytarr(11,11)
boxsize=5
xmin = 0 > (zcenter[0] - boxsize)
xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
ymin = 0 > (zcenter[1] - boxsize) 
ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

startx = abs( (zcenter[0] - boxsize) < 0 )
starty = abs( (zcenter[1] - boxsize) < 0 ) 

track[startx,starty] = scaled_image[xmin:xmax,ymin:ymax]
track_image = rebin(track, $
                    state.track_window_size, state.track_window_size, $
                    /sample)

atv_setwindow, state.track_window_id
tv, track_image

; Overplot an X on the central pixel in the track window, to show the
; current mouse position

; Changed central x to be green always
plots, [0.46, 0.54], [0.46, 0.54], /normal, color = 2, psym=0
plots, [0.46, 0.54], [0.54, 0.46], /normal, color = 2, psym=0

; update location bar with x, y, and pixel value

loc_string = $
  string(state.coord[0], $
         state.coord[1], $
         main_image[state.coord[0], $
                    state.coord[1]], $
         format = '("(",i4,",",i4,") ",g12.5)') 
widget_control, state.location_bar_id, set_value = loc_string

; Update coordinate display

if (ptr_valid(state.astr_ptr)) then begin
    xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat

    wcsstring = atv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
                 state.equinox, state.display_coord_sys, state.display_equinox)

    widget_control, state.wcs_bar_id, set_value = wcsstring

endif    

atv_resetwindow

end

;----------------------------------------------------------------------

pro atv_drawbox

; routine to draw the box on the pan window, given the current center
; of the display image.

common atv_state
common atv_images

atv_setwindow, state.pan_window_id

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

; Create the vectors which contain the box coordinates

box_x = float((([view_min[0], $
                 view_max[0], $
                 view_max[0], $
                 view_min[0], $
                 view_min[0]]) * state.pan_scale) + state.pan_offset[0]) 

box_y = float((([view_min[1], $
                 view_min[1], $
                 view_max[1], $
                 view_max[1], $
                 view_min[1]]) * state.pan_scale) + state.pan_offset[1]) 

; Redraw the pan image and overplot the box
device, copy=[0,0,state.pan_window_size, state.pan_window_size, 0, 0, $
              state.pan_pixmap]
;tv, pan_image, state.pan_offset[0], state.pan_offset[1]

plots, box_x, box_y, /device, color = 2, psym=0

atv_resetwindow

end

;----------------------------------------------------------------------

pro atv_pantrack, event

; routine to track the view box in the pan window during cursor motion

common atv_state

; erase the old box
atv_drawbox

; get the new box coords and draw the new box

tmp_event = [event.x, event.y] 

newpos = state.pan_offset > tmp_event < $
  (state.pan_offset + (state.image_size * state.pan_scale))

state.centerpix = round( (newpos - state.pan_offset ) / state.pan_scale)

atv_drawbox
atv_getoffset

end

;----------------------------------------------------------------------

pro atv_resize

; Routine to resize the draw window when a top-level resize event
; occurs.

; modified 8/29/99 so that the event structure is not passed to this
; routine as an argument.

common atv_state

widget_control, state.base_id, tlb_get_size=tmp_event

drawpad = (widget_info(state.draw_base_id,/geometry)).xsize - $
  state.draw_window_size[0]

window = (state.base_min_size > tmp_event)

newbase = window - state.base_pad

; Note: don't know why the (-4) is needed below, but it seems
; to work... without it the base becomes the wrong size when the
; colorbar draw widget is resized.

widget_control, state.colorbar_base_id, $
  xsize = newbase[0]-4, ysize = state.colorbar_height + 6

widget_control, state.draw_base_id, $
  xsize = newbase[0], ysize = newbase[1]

newxsize = (widget_info(state.draw_base_id,/geometry)).xsize - drawpad
newysize = (widget_info(state.draw_base_id,/geometry)).ysize - drawpad

widget_control, state.draw_widget_id, $
  xsize = newxsize, ysize = newysize
widget_control, state.colorbar_widget_id, $
  xsize = newxsize, ysize = state.colorbar_height

state.draw_window_size = [newxsize, newysize]

atv_colorbar

end

;----------------------------------------------------------------------

pro atv_scaleimage

; Create a byte-scaled copy of the image, scaled according to
; the state.scaling parameter.  Add a padding of 5 pixels around the
; image boundary, so that the tracking window can always remain
; centered on an image pixel even if that pixel is at the edge of the
; image.    

common atv_state
common atv_images

; Since this can take some time for a big image, set the cursor 
; to an hourglass until control returns to the event loop.

widget_control, /hourglass

case state.scaling of
    0: tmp_image = $                 ; linear stretch
      bytscl(main_image, $                           
             min=state.min_value, $
             max=state.max_value, $
             top = state.ncolors - 1) + 8
    
    1: tmp_image = $                 ; log stretch
      bytscl( alog10 (bytscl(main_image, $                       
                             min=state.min_value, $
                             max=state.max_value) + 1),  $
            top = state.ncolors - 1) + 8
    
    2: tmp_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = state.min_value, $    
                        maxv = state.max_value), $
             top = state.ncolors - 1) + 8
    
endcase

scaled_image = temporary(tmp_image)

end

;----------------------------------------------------------------------

pro atv_getstats

; Get basic image stats: min and max, and size.

common atv_state
common atv_images

; this routine operates on main_image, which is in the
; atv_images common block

widget_control, /hourglass

state.image_size = [ (size(main_image))[1], (size(main_image))[2] ]

state.image_min = min(main_image)
state.image_max = max(main_image)

state.min_value = state.image_min
state.max_value = state.image_max

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

; zero the current display position on the center of the image

state.coord = round(state.image_size / 2.)
state.centerpix = round(state.image_size / 2.)
atv_getoffset

; Clear all plot annotations
atverase, /norefresh  

end

;-------------------------------------------------------------------

pro atv_setwindow, windowid

; replacement for atv_setwindow.  Reads the current active window first.

common atv_state

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
    wset, windowid
endif

end

;---------------------------------------------------------------------

pro atv_resetwindow

; reset to current active window

common atv_state

; The empty command used below is put there to make sure that all
; graphics to the previous atv window actually get displayed to screen
; before we wset to a different window.  Without it, some line
; graphics would not actually appear on screen.

if (!d.name NE 'PS') then begin
    empty
    wset, state.active_window_id
endif

end

;------------------------------------------------------------------

pro atv_getwindow

; get currently active window id

common atv_state

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
endif
end

;--------------------------------------------------------------------
;     file I/O routines: readfits, postscript output, etc. 
;--------------------------------------------------------------------
pro atv_readfits, fitsfilename=fitsfilename, newimage=newimage

; Read in a new image when user goes to the File->ReadFits menu.

common atv_state
common atv_images

newimage = 0

if (n_elements(fitsfilename) EQ 0) then begin
    fitsfile = $
      dialog_pickfile(filter = '*.fits', $
                      group = state.base_id, $
                      /must_exist, $
                      /read, $
                      path = state.current_dir, $
                      get_path = tmp_dir, $
                      title = 'Select Fits Image')        
    if (tmp_dir NE '') then state.current_dir = tmp_dir
    if (fitsfile EQ '') then return ; 'cancel' button returns empty string
endif else begin
    fitsfile = fitsfilename
endelse

head = headfits(fitsfile)

; Check validity of fits file if necessary. 

if (n_elements(strcompress(head, /remove_all)) LT 2) then begin
    if (n_elements(fitsfilename) EQ 0) then begin
        mesg = 'File does not appear to be a valid fits image!'
        tmp_result = dialog_message(mesg, /error, $
                                    dialog_parent = state.base_id)
    endif else begin
        print, 'ERROR: File does not appear to be a valid fits image!'
    endelse
    return
endif
nax = sxpar(head, 'NAXIS')
if (!ERR EQ -1) then begin
    if (n_elements(fitsfilename) EQ 0) then begin
        mesg = 'Selected file does not appear to be a valid FITS image!'
        tmp_result = dialog_message(mesg, /error, $
                                    dialog_parent = state.base_id)
        endif else begin
            print, 'ERROR: File does not appear to be a valid fits image!'
        endelse
    return
endif

; Two system variable definitions are needed in order to run fits_info
defsysv,'!TEXTOUT',1
defsysv,'!TEXTUNIT',0

; Find out if this is a fits extension file, and how many extensions
fits_info, fitsfile, n_ext = numext, /silent
if numext EQ 0 then extension = 0
instrume = strcompress(string(sxpar(head, 'INSTRUME')), /remove_all)

if ((numext GT 0) AND (instrume NE 'WFPC2')) then begin
; If there are extensions, bring up a dialog box for the user to 
; select the extension to load.
    numlist = ''
    for i = 1, numext do begin
        numlist = strcompress(numlist + string(i) + '|', /remove_all)
    endfor

    numlist = strmid(numlist, 0, strlen(numlist)-1)
    
    droptext = strcompress('0, droplist, ' + numlist + $
                           ', label_left=Select Extension:, set_value=0')
    
    formdesc = ['0, button, Read Primary Image, quit', $
                '0, label, OR:', $
                droptext, $
                '0, button, Read Fits Extension, quit', $
                '0, button, Cancel, quit']
    
    textform = cw_form(formdesc, /column, $
                       title = 'Fits Extension Selector')
    if (textform.tag4 EQ 1) then return  ; cancelled    

    if (textform.tag3 EQ 1) then begin    ;extension selected
        extension = long(textform.tag2) + 1
    endif else begin
        extension = 0   ; primary image selected
    endelse

endif else begin
    extension = 0   ; plain fits file with no extensions, or wfpc2
endelse

tmp_image = mrdfits(fitsfile, extension, head, /silent, /fscale) 

; Check for wfpc2 4-panel image: if yes, read in new tmp_image
if ( instrume EQ 'WFPC2' AND $
     ((size(tmp_image))[0] EQ 3) AND $
     ((size(tmp_image))[1] EQ 800) AND  $
     ((size(tmp_image))[2] EQ 800) ) then begin
    
    droptext = strcompress('0, droplist, 1 | 2 | 3 | 4 | Mosaic,' + $
                           'label_left = Select WFPC2 CCD:, set_value=0')
    
    formdesc = [droptext, $
                '0, button, Read WFPC2 Image, quit', $
                '0, button, Cancel, quit']
    
    textform = cw_form(formdesc, /column, title = 'WFPC2 Chip Selector')
    
    if (textform.tag2 EQ 1) then return ; cancelled
    
    ccd = long(textform.tag0) + 1

    widget_control, /hourglass
    if (ccd LE 4) then begin
        wfpc2_read, fitsfile, tmp_image, head, num_chip = ccd
    endif
    
    if (ccd EQ 5) then begin
        wfpc2_read, fitsfile, tmp_image, head, /batwing
    endif
        
endif

if ( (size(tmp_image))[0] NE 2 ) then begin
    mesg = 'Selected file is not a 2-D fits image!'
    tmp_result = dialog_message(mesg, /error, $
                                dialog_parent = state.base_id)
    return
endif

; Check for NaNs
w = where(NOT float(finite(tmp_image)), count)
if (count GT 0) then begin
    tmp_image(w) = 0
    mesg = strcompress(string(count)+$
                       ' pixels with value NaN converted to zero.')
    tmp_result = dialog_message(mesg, dialog_parent = state.base_id)    
endif

; If the new image is valid, put it into main_image and display it
main_image = temporary(tmp_image)
state.imagename = fitsfile
atv_setheader, head
newimage = 1

end

;----------------------------------------------------------------------

pro atv_writetiff

; writes a tiff image of the current display

common atv_state
common atv_images

; Get filename to save image

filename = dialog_pickfile(filter = '*.tiff', $ 
                           file = 'atv.tiff', $
                           group =  state.base_id, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           /write)
if (tmp_dir NE '') then state.current_dir = tmp_dir
tmp_result = findfile(filename, count = nfiles)

result = ''

if (strcompress(filename, /remove_all) EQ '') then return   ; cancel

if (filename EQ state.current_dir) then begin
    mesg = 'Must indicate filename to save.'
    result = dialog_message(mesg, /error, dialog_parent = state.base_id)
    return
endif

if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(filename, rstrpos(filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif


if ((nfiles EQ 0 OR result EQ 'Yes') AND filename NE '') then begin
 
    atv_setwindow, state.draw_window_id

; In 8-bit mode, the screen color table will have fewer than 256
; colors.  Stretch out the existing color table to a full 256 colors
; when writing the tiff image.
 
    tvlct, rr, gg, bb, /get
 
    rn = congrid(rr[8:!d.table_size-1], 248)
    gn = congrid(gg[8:!d.table_size-1], 248)
    bn = congrid(bb[8:!d.table_size-1], 248)
 
    rvec = bytarr(256)
    gvec = bytarr(256)
    bvec = bytarr(256)
 
    rvec[0] = rr  ; load in the first 8 colors
    gvec[0] = gg
    bvec[0] = bb
 
    rvec[8] = temporary(rn)
    gvec[8] = temporary(gn)
    bvec[8] = temporary(bn)
 
    img = tvrd()
    w = where(img GT 7, count)

    if (count GT 0) then begin
        tmp_img = img[w]
        tmp_img = bytscl((img[w]), top = 247, min=8, max=(!d.n_colors-1)) + 8
        img[w] = tmp_img
    endif

    write_tiff, filename, img, $
      red = temporary(rvec), $
      green = temporary(gvec), $
      blue = temporary(bvec)

endif

atv_cleartext

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_writeps

; Writes an encapsulated postscript file of the current display.
; Calls cmps_form to get postscript file parameters.

common atv_state
common atv_images
common atv_color

widget_control, /hourglass

aspect = float(state.draw_window_size[1]) / state.draw_window_size[0]
fname = strcompress(state.current_dir + 'atv.ps', /remove_all)

tvlct, rr, gg, bb, 8, /get
forminfo = cmps_form(cancel = canceled, create = create, $
                     aspect = aspect, parent = state.base_id, $
                     /preserve_aspect, $
                     xsize = 6.0, ysize = 6.0 * aspect, $
                     /color, /encapsulated, $
                     /nocommon, papersize='Letter', $
                     bits_per_pixel=8, $
                     filename = fname, $
                     button_names = ['Create PS File'])

if (canceled) then return
if (forminfo.filename EQ '') then return
tvlct, rr, gg, bb, 8

tmp_result = findfile(forminfo.filename, count = nfiles)

result = ''
if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(forminfo.filename, rstrpos(forminfo.filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if (result EQ 'No') then return
    
widget_control, /hourglass

screen_device = !d.name

; In 8-bit mode, the screen color table will have fewer than 256
; colors.  Stretch out the existing color table to 256 colors for the
; postscript plot.

;tvlct, rr, gg, bb, 8, /get
set_plot, 'ps'
device, _extra = forminfo

tvlct, rr, gg, bb, 8, /get
rn = congrid(rr, 248)
gn = congrid(gg, 248)
bn = congrid(bb, 248)

tvlct, temporary(rn), temporary(gn), temporary(bn), 8
tv, bytscl(display_image, top = 247, min=8, max=(!d.n_colors-1)) + 8
atv_plotall

if (state.frame EQ 1) then begin
    plot, [0], [0], /nodata, /noerase, /normal, $
      xrange = [0,1], yrange = [0,1], position=[0,0,1,1], $
      xticks = 1, yticks = 1, ticklen=0, $
      xtickformat = 'atv_null_string', ytickformat = 'atv_null_string'
endif

tvlct, temporary(rr), temporary(gg), temporary(bb), 8

device, /close
set_plot, screen_device

atv_cleartext

end

function atv_null_string,a,b,c
return, ''
end

;----------------------------------------------------------------------
;       routines for defining the color maps
;----------------------------------------------------------------------

pro atv_stretchct, brightness, contrast,  getmouse = getmouse

; routine to change color stretch for given values of 
; brightness and contrast.
; Brightness and contrast range from 1 up to state.maxbright
; A rather brute-force algorithm, but it works well enough.

common atv_state
common atv_color

if (keyword_set(getmouse)) then begin
    contrast = 0 > (contrast / float(state.draw_window_size[1]) * $
                    state.maxbright) < (state.maxbright-1)
    contrast = long(abs(state.maxbright - contrast))

    brightness = 0 > $
      (brightness / float(state.draw_window_size[0]) * state.maxbright) < $
      (state.maxbright - 1)
    brightness = long(abs(brightness-state.maxbright))
endif

d = state.ncolors

maxdp = 600
mindp = 4

if (contrast LT (state.maxbright / 2)) then begin
    dp = ((d - maxdp) / float((state.maxbright / 2) - 1)) * contrast + $
      ((maxdp * state.maxbright / 2) - d) / float(state.maxbright / 2)
endif else begin
    dp = ((mindp - d) / float(state.maxbright / 2)) * contrast + $
      ((d * state.maxbright) - (mindp * state.maxbright / 2)) / $
      float(state.maxbright / 2)
endelse

dp =  fix(dp)

r = replicate(r_vector(d-1), 2*d + dp)
g = replicate(g_vector(d-1), 2*d + dp)
b = replicate(b_vector(d-1), 2*d + dp)

r[0:d-1] = r_vector(0)
g[0:d-1] = g_vector(0)
b[0:d-1] = b_vector(0)

a = findgen(d)

r[d] = congrid(r_vector, dp)
g[d] = congrid(g_vector, dp)
b[d] = congrid(b_vector, dp)

bshift = round(brightness * (d+dp) / float(state.maxbright))

rr = r[a + bshift] 
gg = g[a + bshift]
bb = b[a + bshift]

tvlct, rr, gg, bb, 8

state.brightness = brightness
state.contrast = contrast

end

;--------------------------------------------------------------------

pro atv_getct, tablenum

; Read in a pre-defined color table, and invert if necessary.

common atv_color
common atv_state

; Load a simple color table with the basic 8 colors in the lowest 8 entries
; of the color table
rtiny   = [0, 1, 0, 0, 0, 1, 1, 1]
gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
btiny  = [0, 0, 0, 1, 1, 1, 0, 1]
tvlct, 255*rtiny, 255*gtiny, 255*btiny

loadct, tablenum, /silent,  bottom=8
tvlct, r, g, b, 8, /get

if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = r
g_vector = g
b_vector = b

atv_stretchct, state.brightness, state.contrast

end

;--------------------------------------------------------------------


function atv_polycolor, p

; Routine to return an vector of length !d.table_size-8,
; defined by a 5th order polynomial.   Called by atv_makect
; to define new color tables in terms of polynomial coefficients.

common atv_state

x = findgen(256)

y = p[0] + x * p[1] + x^2 * p[2] + x^3 * p[3] + x^4 * p[4] + x^5 * p[5]

w = where(y GT 255, nw)
if (nw GT 0) then y(w) = 255

w =  where(y LT 0, nw)
if (nw GT 0) then y(w) = 0

z = congrid(y, state.ncolors)

return, z
end

;----------------------------------------------------------------------

pro atv_makect, tablename

; Define new color tables here, in terms of 5th order polynomials.
; To define a new color table, first set it up using xpalette,
; then load current color table into 3 256-element vectors, and
; do a 5th order poly_fit.  Store the coefficients and name
; the color table here.  Invert if necessary.

common atv_state
common atv_color

case tablename of
    'ATV Special': begin
 
        r = atv_polycolor([39.4609, $
                           -5.19434, $
                           0.128174, $
                           -0.000857115, $
                           2.23517e-06, $
                           -1.87902e-09])
        
        g = atv_polycolor([-15.3496, $
                           1.76843, $
                           -0.0418186, $
                           0.000308216, $
                           -6.07106e-07, $
                           0.0000])
        
        b = atv_polycolor([0.000, $ 
                           12.2449, $
                           -0.202679, $
                           0.00108027, $
                           -2.47709e-06, $
                           2.66846e-09])
   end

; add more color table definitions here as needed...
    else:

endcase


if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = temporary(r)
g_vector = temporary(g)
b_vector = temporary(b)

atv_stretchct, state.brightness, state.contrast

end

;----------------------------------------------------------------------

function atv_icolor, color

; Routine to reserve the bottom 8 colors of the color table
; for plot overlays and line plots.

   if (n_elements(color) EQ 0) then return, 1

   ncolor = N_elements(color)

   ; If COLOR is a string or array of strings, then convert color names
   ; to integer values
   if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string

      ; Detemine the default color for the current device
      if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
       else defcolor = 0 ; black otherwise

      icolor = 0 * (color EQ 'black') $
             + 1 * (color EQ 'red') $
             + 2 * (color EQ 'green') $
             + 3 * (color EQ 'blue') $
             + 4 * (color EQ 'cyan') $
             + 5 * (color EQ 'magenta') $
             + 6 * (color EQ 'yellow') $
             + 7 * (color EQ 'white') $
             + defcolor * (color EQ 'default')

   endif else begin
      icolor = long(color)
   endelse

   return, icolor
end 
 
;---------------------------------------------------------------------
;    routines dealing with image header, title,  and related info
;--------------------------------------------------------------------

pro atv_settitle

; Update title bar with the image file name

common atv_state

if (state.imagename EQ '') then begin
    widget_control, state.base_id, tlb_set_title = 'atv'
endif else begin
    slash = rstrpos(state.imagename, '/')
    ; inserted untested code for MacOS and Windows delimiters
    if (slash EQ -1) then slash = rstrpos(state.imagename, '\')
    if (slash EQ -1) then slash = rstrpos(state.imagename, ':')

    if (slash NE -1) then name = strmid(state.imagename, slash+1) $
      else name = state.imagename
    title = strcompress('atv:  '+name)
    widget_control, state.base_id, tlb_set_title = title
endelse

end

;----------------------------------------------------------------------

pro atv_setheader, head

; Routine to keep the image header using a pointer to a 
; heap variable.  If there is no header (i.e. if atv has just been
; passed a data array rather than a filename), then make the
; header pointer a null pointer.  Get astrometry info from the 
; header if available.  If there's no astrometry information, set 
; state.astr_ptr to be a null pointer.

common atv_state

; Kill the header info window when a new image is read in

if (xregistered('atv_headinfo')) then begin
    widget_control, state.headinfo_base_id, /destroy
endif

if (xregistered('atv_stats')) then begin
    widget_control, state.stats_base_id, /destroy
endif

if (n_elements(head) GT 1) then begin
   ptr_free, state.head_ptr
   state.head_ptr = ptr_new(head)
   
; Get astrometry information from header, if it exists
   ptr_free, state.astr_ptr     ; kill previous astrometry info
   state.astr_ptr = ptr_new()
   extast, head, astr, noparams
   
   IF (noparams EQ -1) THEN BEGIN 
      widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
   ENDIF ELSE BEGIN 
      widget_control, state.wcs_bar_id, set_value = '                 '
      
; Check for GSS type header  
      if strmid( astr.ctype[0], 5, 3) EQ 'GSS' then begin
         hdr1 = head
         gsss_STDAST, hdr1
         extast, hdr1, astr, noparams
      endif
      
; Create a pointer to the header info
      state.astr_ptr = ptr_new(astr)
      
; Get the equinox of the coordinate system
      equ = get_equinox(head, code)
      if (code NE -1) then begin
         if (equ EQ 2000.0) then state.equinox = 'J2000'
         if (equ EQ 1950.0) then state.equinox = 'B1950'
         if (equ NE 2000.0 and equ NE 1950.0) then $
           state.equinox = string(equ, format = '(f6.1)')
      endif else begin
         IF (strmid(astr.ctype[0], 0, 4) EQ 'GLON') THEN BEGIN 
            state.equinox = 'J2000' ; (just so it is set)
         ENDIF ELSE BEGIN 
                                ; clear pointer
            ptr_free, state.astr_ptr
            state.astr_ptr = ptr_new()
            state.equinox = 'J2000'
            widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
         ENDELSE 
      endelse
; Set default display to native system in header
      state.display_equinox = state.equinox
      state.display_coord_sys = strmid(astr.ctype[0], 0, 4)
   ENDELSE 
   
ENDIF else begin
; If there's no image header...
   ptr_free, state.head_ptr
   state.head_ptr = ptr_new()
   ptr_free, state.astr_ptr
   state.astr_ptr = ptr_new()
   
   widget_control, state.wcs_bar_id, set_value = $
     '---No WCS Info---'
endelse
 
end

;---------------------------------------------------------------------


pro atv_headinfo

common atv_state

; If there's no header, kill the headinfo window and exit this
; routine.
if (not(ptr_valid(state.head_ptr))) then begin
    if (xregistered('atv_headinfo')) then begin
        widget_control, state.headinfo_base_id, /destroy
    endif

    mesg = 'No header information available for this image!'
    junk = dialog_message(mesg, /error, $
                          dialog_parent = state.base_id)
    return
endif


; If there is header information but not headinfo window,
; create the headinfo window.
if (not(xregistered('atv_headinfo', /noshow))) then begin

    headinfo_base = $
      widget_base(/floating, $
                  /base_align_right, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv image header information', $
                  uvalue = 'headinfo_base')
    state.headinfo_base_id = headinfo_base

    h = *(state.head_ptr)

    headinfo_text = widget_text(headinfo_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    headinfo_done = widget_button(headinfo_base, $
                              value = 'Done', $
                              uvalue = 'headinfo_done')

    widget_control, headinfo_base, /realize
    xmanager, 'atv_headinfo', headinfo_base, /no_block

endif


end

;---------------------------------------------------------------------

pro atv_headinfo_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'headinfo_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;             routines to do plot overlays
;----------------------------------------------------------------------

pro atv_plot1plot, iplot
common atv_pdata
common atv_state

; Plot a point or line overplot on the image

atv_setwindow, state.draw_window_id

widget_control, /hourglass

oplot, [(*(plot_ptr[iplot])).x], [(*(plot_ptr[iplot])).y], $
  _extra = (*(plot_ptr[iplot])).options

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_plot1text, iplot
common atv_pdata
common atv_state

; Plot a text overlay on the image
atv_setwindow, state.draw_window_id

widget_control, /hourglass

xyouts, (*(plot_ptr[iplot])).x, (*(plot_ptr[iplot])).y, $
  (*(plot_ptr[iplot])).text, _extra = (*(plot_ptr[iplot])).options

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_plot1contour, iplot
common atv_pdata
common atv_state

; Overplot contours on the image

atv_setwindow, state.draw_window_id
widget_control, /hourglass

xrange = !x.crange
yrange = !y.crange

; The following allows for 2 conditions, depending upon whether X and Y
; are set

dims = size( (*(plot_ptr[iplot])).z,/dim )

if (size( (*(plot_ptr[iplot])).x,/N_elements ) EQ dims[0] $
    AND size( (*(plot_ptr[iplot])).y,/N_elements) EQ dims[1] ) then begin
    
    contour, (*(plot_ptr[iplot])).z, (*(plot_ptr[iplot])).x, $
      (*(plot_ptr[iplot])).y, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
    
endif else begin
    
    contour, (*(plot_ptr[iplot])).z, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(plot_ptr[iplot])).options
          
endelse
;tv_setsamewindow

atv_resetwindow
end

;---------------------------------------------------------------------

pro atv_plot1compass, iplot

; Uses idlastro routine arrows to plot compass arrows.

common atv_pdata
common atv_state

atv_setwindow, state.draw_window_id

widget_control, /hourglass

arrows, *(state.head_ptr), $
  (*(plot_ptr[iplot])).x, $
  (*(plot_ptr[iplot])).y, $
  thick = (*(plot_ptr[iplot])).thick, $
  charsize = (*(plot_ptr[iplot])).charsize, $
  arrowlen = (*(plot_ptr[iplot])).arrowlen, $
  color = (*(plot_ptr[iplot])).color, $
  notvertex = (*(plot_ptr[iplot])).notvertex, $
  /data

atv_resetwindow
end

;---------------------------------------------------------------------

pro atv_plot1scalebar, iplot

; uses modified version of idlastro routine arcbar to plot a scalebar

common atv_pdata
common atv_state

atv_setwindow, state.draw_window_id
widget_control, /hourglass

; routine arcbar doesn't recognize color=0, because it uses 
; keyword_set to check the color.  So we need to set !p.color = 0
; to get black if the user wants color=0

!p.color = 0

atv_arcbar, *(state.head_ptr), $
  (*(plot_ptr[iplot])).arclen, $
  position = (*(plot_ptr[iplot])).position, $
  thick = (*(plot_ptr[iplot])).thick, $
  size = (*(plot_ptr[iplot])).size, $
  color = (*(plot_ptr[iplot])).color, $
  seconds = (*(plot_ptr[iplot])).seconds, $
  /data

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
                DATA =data, COLOR = color, POSITION = position, $
                NORMAL = normal, SECONDS=SECONDS

common atv_state

; This is a copy of the GSFC arcbar routine, abbreviated for atv and 
; modified to work with zoomed images.
; REVISION HISTORY:
;       written by L. Taylor (STX) from ARCBOX (Boothman)
;       modified for Version 2 IDL,                     B. Pfarr, STX, 4/91
;       New ASTROMETRY structures               W.Landsman,  HSTX, Jan 94
;       Recognize a GSSS header                 W. Landsman June 94
;       Added /NORMAL keyword                   W. Landsman Feb. 96
;       Use NAXIS1 for postscript if data coords not set,  W. Landsman Aug 96
;       Fixed typo for postscript W. Landsman   Oct. 96
;       Account for zeropoint offset in postscript  W. Landsman   Apr 97
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Added /DATA, /SECONDS keywords   W. Landsman    July 1998
;       Modified to work with zoomed ATV images,           AJB  Jan. 2000
;       Moved text label upwards a bit for better results, AJB  Jan. 2000

On_error,2                      ;Return to caller
 
extast, hdr, bastr, noparams    ;extract astrom params in deg.
 
if N_params() LT 2 then arclen = 1 ;default size = 1 arcmin

if not keyword_set( SIZE ) then size = 1.0
if not keyword_set( THICK ) then thick = !P.THICK
if not keyword_set( COLOR ) then color = !P.COLOR

a = bastr.crval[0]
d = bastr.crval[1]
if keyword_set(seconds) then factor = 3600.0d else factor = 60.0
d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

proj = strmid(bastr.ctype[0],5,3)

case proj of 
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y 
endcase

dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

if (!D.FLAGS AND 1) EQ 1 then begin ;Device have scalable pixels?
    if !X.s[1] NE 0 then begin
        dmin = convert_coord( dmin, 0, /DATA, /TO_DEVICE) - $ 
          convert_coord(    0, 0, /DATA, /TO_DEVICE) ;Fixed Apr 97
        dmin = dmin[0]
    endif else dmin = dmin/sxpar(hdr, 'NAXIS1' ) ;Fixed Oct. 96
endif else  dmin = dmin * state.zoom_factor    ; added by AJB Jan. '00

dmini2 = round(dmin * arclen)

if keyword_set(NORMAL) then begin
    posn = convert_coord(position,/NORMAL, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else if keyword_set(DATA) then begin
    posn = convert_coord(position,/DATA, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else begin
    xi = position[0]   & yi = position[1]
endelse         


xf = xi + dmini2
dmini3 = dmini2/10       ;Height of vertical end bars = total length/10.

plots,[xi,xf],[yi,yi], COLOR=color, /DEV, THICK=thick
plots,[xf,xf],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
plots,[xi,xi],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick

if not keyword_set(Seconds) then begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym='!9'+string(162B)+'!X' else arcsym = "'" 
endif else begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym = '!9'+string(178B)+'!X' else arcsym = "''" 
endelse
if not keyword_set( LABEL) then begin
    if (arclen LT 1) then arcstr = string(arclen,format='(f4.2)') $
    else arcstr = string(arclen)
    label = strtrim(arcstr,2) + arcsym 
endif

; AJB modified this to move the numerical label upward a bit: 5/8/2000
xyouts,(xi+xf)/2, (yi+(dmini2/10)), label, SIZE = size,COLOR=color,$
  /DEV, alignment=.5, CHARTHICK=thick

return
end

;----------------------------------------------------------------------

pro atv_plotwindow
common atv_state

atv_setwindow, state.draw_window_id

; Set plot window
xrange=[state.offset[0], $
 state.offset[0] + state.draw_window_size[0] / state.zoom_factor] - 0.5
yrange=[state.offset[1], $
 state.offset[1] + state.draw_window_size[1] / state.zoom_factor] - 0.5

plot, [0], [0], /nodata, position=[0,0,1,1], $
 xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_plotall
common atv_state
common atv_pdata

; Routine to overplot all line, text, and contour plots

if (nplot EQ 0) then return

atv_plotwindow

for iplot = 1, nplot do begin
    case (*(plot_ptr[iplot])).type of
        'points'  : atv_plot1plot, iplot
        'text'    : atv_plot1text, iplot
        'contour' : atv_plot1contour, iplot
        'compass' : atv_plot1compass, iplot
        'scalebar': atv_plot1scalebar, iplot
        else      : print, 'Problem in atv_plotall!'   
    endcase
endfor

end

;----------------------------------------------------------------------

pro atvplot, x, y, _extra = options
common atv_pdata
common atv_state

; Routine to read in line plot data and options, store in a heap
; variable structure, and plot the line plot

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVPLOT.'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'color', 'red')
   options.color = atv_icolor(options.color)

   pstruct = {type: 'points',   $     ; points
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   atv_plotwindow
   atv_plot1plot, nplot

endif else begin
   print, 'Too many calls to ATVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro atvxyouts, x, y, text, _extra = options
common atv_pdata
common atv_state

; Routine to read in text overplot string and options, store in a heap
; variable structure, and overplot the text

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 3) then begin
   print, 'Too few parameters for ATVXYOUTS'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'color', 'red')
   options.color = atv_icolor(options.color)

;  set default font to 1
   c = where(tag_names(options) EQ 'FONT', count)
   if (count EQ 0) then options = create_struct(options, 'font', 1)

   pstruct = {type: 'text',   $       ; type of plot 
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              text: text,       $     ; text to plot
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   atv_plotwindow
   atv_plot1text, nplot

endif else begin
   print, 'Too many calls to ATVPLOT.'
endelse

end

;----------------------------------------------------------------------

pro atvcontour, z, x, y, _extra = options
common atv_pdata
common atv_state

; Routine to read in contour plot data and options, store in a heap
; variable structure, and overplot the contours.  Data to be contoured
; need not be the same dataset displayed in the atv window, but it
; should have the same x and y dimensions in order to align the
; overplot correctly.

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVCONTOUR.'
   return
endif

if (n_params() EQ 1 OR n_params() EQ 2) then begin
    x = 0
    y = 0
endif

if (n_elements(options) EQ 0) then options = {c_color: 'red'}

if (nplot LT maxplot) then begin
   nplot = nplot + 1

;  convert color names to index numbers, and set default=red
   c = where(tag_names(options) EQ 'C_COLOR', count)
   if (count EQ 0) then options = create_struct(options, 'c_color', 'red')
   options.c_color = atv_icolor(options.c_color)

   pstruct = {type: 'contour',  $     ; type of plot
              z: z,             $     ; z values
              x: x,             $     ; x coordinate
              y: y,             $     ; y coordinate
              options: options  $     ; plot keyword options
             }

   plot_ptr[nplot] = ptr_new(pstruct)

   atv_plotwindow
   atv_plot1contour, nplot

endif else begin
   print, 'Too many calls to ATVCONTOUR.'
endelse

end

;----------------------------------------------------------------------

pro atverase, nerase, norefresh = norefresh
common atv_pdata

; Routine to erase line plots from ATVPLOT, text from ATVXYOUTS, and
; contours from ATVCONTOUR.

if (n_params() LT 1) then begin
    nerase = nplot
endif else begin
    if (nerase GT nplot) then nerase = nplot
endelse

for iplot = nplot - nerase + 1, nplot do begin
    ptr_free, plot_ptr[iplot]
    plot_ptr[iplot] = ptr_new()
endfor

nplot = nplot - nerase

if (NOT keyword_set(norefresh) ) then atv_refresh

end

;----------------------------------------------------------------------

pro atv_textlabel

; widget front end for atvxyouts

formdesc = ['0, text, , label_left=Text: , width=15', $
            '0, integer, 0, label_left=x: ', $
            '0, integer, 0, label_left=y: ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 2.0, label_left=Charsize: ', $
            '0, integer, 1, label_left=Charthick: ', $
            '0, integer, 0, label_left=Orientation: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawText, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'atv text label')

if (textform.tag9 EQ 1) then begin
; switch red and black indices
    case textform.tag3 of
        0: labelcolor = 1
        1: labelcolor = 0
        else: labelcolor = textform.tag3
    endcase

    atvxyouts, textform.tag1, textform.tag2, textform.tag0, $
      color = labelcolor, charsize = textform.tag4, $
      charthick = textform.tag5, orientation = textform.tag6
endif

end

;---------------------------------------------------------------------

pro atv_oplotcontour

; widget front end for atvcontour

common atv_state
common atv_images

minvalstring = strcompress('0, float, ' + string(state.min_value) + $
                           ', label_left=MinValue: , width=15 ')
maxvalstring = strcompress('0, float, ' + string(state.max_value) + $
                           ', label_left=MaxValue: , width=15')

formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
;            '0, float, 1.0, label_left=Charsize: ', $
;            '0, integer, 1, label_left=Charthick: ', $
            '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
            '0, integer, 1, label_left=LineThickness: ', $
            minvalstring, $
            maxvalstring, $
            '0, integer, 6, label_left=NLevels: ', $
            '1, base, , row,', $
            '0, button, Cancel, quit', $
            '0, button, DrawContour, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv text label')


if (cform.tag8 EQ 1) then begin
; switch red and black indices
    case cform.tag0 of
        0: labelcolor = 1
        1: labelcolor = 0
        else: labelcolor = cform.tag0
    endcase

    atvcontour, main_image, c_color = labelcolor, $
;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
      c_linestyle = cform.tag1, $
      c_thick = cform.tag2, $
      min_value = cform.tag3, max_value = cform.tag4, $, 
      nlevels = cform.tag5
endif

end

;---------------------------------------------------------------------

pro atv_setcompass

; Routine to prompt user for compass parameters

common atv_state
common atv_images
common atv_pdata

if (nplot GE maxplot) then begin
    mesg = 'Total allowed number of overplots exceeded.'
    tmp_result = dialog_message(mesg, /error, $
                                dialog_parent = state.base_id)
    return
endif
    

if (not(ptr_valid(state.astr_ptr))) then begin 
    mesg = 'There is no WCS information for this image!'
    tmp_result = dialog_message(mesg, /error, $
                                dialog_parent = state.base_id)
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.15 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=XCenter: ')
yposstring = strcompress('0,integer,'+ypos+',label_left=YCenter: ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, droplist, Vertex of Compass|Center of Compass, label_left = Coordinates Specify:, set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '0, float, 3.5, label_left=ArrowLength: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawCompass, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv compass properties')

if (cform.tag8 EQ 1) then return

cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)

; switch red and black indices
case cform.tag3 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag3
endcase

pstruct = {type: 'compass',  $  ; type of plot
           x: cform.tag0,         $ 
           y: cform.tag1,         $
           notvertex: cform.tag2, $
           color: labelcolor, $
           thick: cform.tag4, $
           charsize: cform.tag5, $
           arrowlen: cform.tag6 $
          }

nplot = nplot + 1
plot_ptr[nplot] = ptr_new(pstruct)

atv_plotwindow
atv_plot1compass, nplot

end

;---------------------------------------------------------------------

pro atv_setscalebar

; Routine to prompt user for scalebar parameters

common atv_state
common atv_images
common atv_pdata

if (nplot GE maxplot) then begin
    mesg = 'Total allowed number of overplots exceeded.'
    tmp_result = dialog_message(mesg, /error, $
                                dialog_parent = state.base_id)
    return
endif
    

if (not(ptr_valid(state.astr_ptr))) then begin 
    mesg = 'There is no WCS information for this image!'
    tmp_result = dialog_message(mesg, /error, $
                                dialog_parent = state.base_id)
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.75 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=X (left end of bar): ')
yposstring = strcompress('0,integer,'+ypos+',label_left=Y (center of bar): ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, float, 5.0, label_left=BarLength: ', $
             '0, droplist, arcsec|arcmin, label_left=Units:,set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawScalebar, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv scalebar properties')

if (cform.tag8 EQ 1) then return

; switch red and black indices
case cform.tag4 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag4
endcase


cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)
cform.tag3 = abs(cform.tag3 - 1)  ; set default to be arcseconds

arclen = cform.tag2
if (float(round(arclen)) EQ arclen) then arclen = round(arclen)

pstruct = {type: 'scalebar',  $  ; type of plot
           arclen: arclen, $
           seconds: cform.tag3, $
           position: [cform.tag0,cform.tag1], $ 
           color: labelcolor, $
           thick: cform.tag5, $
           size: cform.tag6 $
          }

nplot = nplot + 1
plot_ptr[nplot] = ptr_new(pstruct)

atv_plotwindow
atv_plot1scalebar, nplot

end

;---------------------------------------------------------------------
;          routines for drawing in the lineplot window
;---------------------------------------------------------------------

pro atv_lineplot_init

; This routine creates the window for line plots

common atv_state

state.lineplot_base_id = $
  widget_base(/floating, $
              group_leader = state.base_id, $
              /column, $
              /base_align_right, $
              title = 'atv plot', $
              /tlb_size_events, $
              uvalue = 'lineplot_base')

state.lineplot_widget_id = $
  widget_draw(state.lineplot_base_id, $
              frame = 0, $
              scr_xsize = state.lineplot_size[0], $
              scr_ysize = state.lineplot_size[1], $
              uvalue = 'lineplot_window')

lbutton_base = $
  widget_base(state.lineplot_base_id, $
              /base_align_bottom, $
              /row)

lineplot_done = $
  widget_button(lbutton_base, $
                value = 'Done', $
                uvalue = 'lineplot_done')

widget_control, state.lineplot_base_id, /realize
widget_control, state.lineplot_widget_id, get_value = tmp_value
state.lineplot_window_id = tmp_value

basegeom = widget_info(state.lineplot_base_id, /geometry)
drawgeom = widget_info(state.lineplot_widget_id, /geometry)

state.lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
state.lineplot_pad[1] = basegeom.ysize - drawgeom.ysize
    
xmanager, 'atv_lineplot', state.lineplot_base_id, /no_block

atv_resetwindow
end

;--------------------------------------------------------------------

pro atv_rowplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot', /noshow))) then begin
    atv_lineplot_init
endif

atv_setwindow, state.lineplot_window_id
erase

plot, main_image[*, state.coord[1]], $
  xst = 3, yst = 3, psym = 10, $
  title = strcompress('Plot of row ' + $
                      string(state.coord[1])), $
  xtitle = 'Column', $
  ytitle = 'Pixel Value', $
  color = 7 

widget_control, state.lineplot_base_id, /clear_events

atv_resetwindow
end

;--------------------------------------------------------------------

pro atv_colplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot', /noshow))) then begin
    atv_lineplot_init
endif

atv_setwindow, state.lineplot_window_id
erase

plot, main_image[state.coord[0], *], $
  xst = 3, yst = 3, psym = 10, $
  title = strcompress('Plot of column ' + $
                      string(state.coord[0])), $
  xtitle = 'Row', $
  ytitle = 'Pixel Value', $
  color = 7
widget_control, state.lineplot_base_id, /clear_events
        
atv_resetwindow
end

;--------------------------------------------------------------------

pro atv_surfplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot', /noshow))) then begin
    atv_lineplot_init
endif

atv_setwindow, state.lineplot_window_id
erase

plotsize = $
  fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
center = plotsize > state.coord < (state.image_size - plotsize) 

tmp_string = $
  strcompress('Surface plot of ' + $
              strcompress('['+string(center[0]-plotsize)+ $
                          ':'+string(center[0]+plotsize-1)+ $
                          ','+string(center[1]-plotsize)+ $
                          ':'+string(center[1]+plotsize-1)+ $
                          ']', /remove_all))

surface, $
  main_image[center[0]-plotsize:center[0]+plotsize-1, $
             center[1]-plotsize:center[1]+plotsize-1], $
  title = temporary(tmp_string), $
  xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
  color = 7

widget_control, state.lineplot_base_id, /clear_events

atv_resetwindow
end

;--------------------------------------------------------------------

pro atv_contourplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot', /noshow))) then begin
    atv_lineplot_init
endif

atv_setwindow, state.lineplot_window_id
erase

plotsize = $
  fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
center = plotsize > state.coord < (state.image_size - plotsize) 

contour_image =  main_image[center[0]-plotsize:center[0]+plotsize-1, $
                            center[1]-plotsize:center[1]+plotsize-1]
if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
endif else begin
    logflag = ''
endelse

tmp_string =  $
  strcompress(logflag + $
              ' Contour plot of ' + $
              strcompress('['+string(round(center[0]-plotsize))+ $
                          ':'+string(round(center[0]+plotsize-1))+ $
                          ','+string(round(center[1]-plotsize))+ $
                          ':'+string(round(center[1]+plotsize-1))+ $
                          ']', /remove_all))

contour, temporary(contour_image), $
  nlevels = 10, $
  /follow, $
  title = temporary(tmp_string), $
  xtitle = 'X', ytitle = 'Y', color = 7

widget_control, state.lineplot_base_id, /clear_events
        
atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_lineplot_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue


case uvalue of
    'lineplot_done': widget_control, event.top, /destroy
    'lineplot_base': begin                       ; Resize event
        atv_setwindow, state.lineplot_window_id
        state.lineplot_size = [event.x, event.y]- state.lineplot_pad
        widget_control, state.lineplot_widget_id, $
          xsize = (state.lineplot_size[0] > 100), $
          ysize = (state.lineplot_size[1] > 100)
        atv_resetwindow
    end    
else:
endcase

end

;----------------------------------------------------------------------
;                         help window
;---------------------------------------------------------------------

pro atv_help
common atv_state

h = strarr(100)
i = 0
h[i] =  'ATV HELP'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'MENU BAR:'
i = i + 1
h[i] =  'File->ReadFits:         Read in a new fits image from disk'
i = i + 1
h[i] =  'File->WritePS:          Write a PostScript file of the current display'
i = i + 1
h[i] =  'File->WriteTiff:        Write a tiff image of the current display'
i = i + 1
h[i] =  'File->Quit:             Quits atv'
i = i + 1
h[i] =  'ColorMap Menu:          Selects color table'
i = i + 1
h[i] =  'Scaling Menu:           Selects linear, log, or histogram-equalized scaling'
i = i + 1
h[i] =  'Labels->TextLabel:      Brings up a dialog box for text input'
i = i + 1
h[i] =  'Labels->Contour:        Brings up a dialog box for overplotting contours'
i = i + 1
h[i] =  'Labels->Compass:        Draws a compass (requires WCS info in header)'
i = i + 1
h[i] =  'Labels->Scalebar:       Draws a scale bar (requires WCS info in header)'
i = i + 1
h[i] =  'Labels->EraseLast:      Erases the most recent plot label'
i = i + 1
h[i] =  'Labels->EraseAll:       Erases all plot labels'
i = i + 1
h[i] =  'Blink->SetBlink:        Sets the current display to be the blink image'
i = i + 1
h[i] =  '                             for mouse button 1, 2, or 3'
i = i + 1
h[i] =  'ImageInfo->Photometry:  Brings up photometry window'
i = i + 1
h[i] =  'ImageInfo->ImageHeader: Display the FITS header, if there is one.'
i = i + 1
h[i] =  'ImageInfo menu also gives a choice of coordinate systems, '
i = i + 1
h[i] =  '    or of native image coordinates (default), for images with a WCS.'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'CONTROL PANEL ITEMS:'
i = i + 1
h[i] = 'Min:             shows minimum data value displayed; enter new min value here'
i = i + 1
h[i] = 'Max:             shows maximum data value displayed; enter new max value here'
i = i + 1
h[i] = 'Pan Window:      use mouse to drag the image-view box around'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'MOUSE MODE SELECTOR:'
i = i + 1
h[i] =  'Color:          sets color-stretch mode:'
i = i + 1
h[i] = '                    With mouse button 1 down, drag mouse to change the color stretch.  '
i = i + 1
h[i] = '                    Move vertically to change contrast, and'
i = i + 1
h[i] = '                         horizontally to change brightness.'
i = i + 1 
h[i] = '                    button 2 or 3: center on current position'
i = i + 1
h[i] = 'Zoom:           sets zoom mode:' 
i = i + 1 
h[i] = '                    button1: zoom in & center on current position'
i = i + 1
h[i] = '                    button2: center on current position'
i = i + 1 
h[i] = '                    button3: zoom out & center on current position'
i = i + 1
h[i] = 'Blink:           sets blink mode:'
i = i + 1
h[i] = '                    press mouse button in main window to show blink image'
i = i + 1
h[i] = 'ImExam:          sets ImageExamine mode:'
i = i + 1
h[i] = '                    mouse button 1 for photometry, button 2 for statistics'
i = i + 2
h[i] = 'BUTTONS:'
i = i + 1
h[i] = 'Invert:          inverts the current color table'
i = i + 1
h[i] = 'ResetColor:      sets brightness and contrast back to default values'
i = i + 1
h[i] = 'AutoScale:       sets min and max to show data values around image median'
i = i + 1
h[i] = 'FullRange:       sets min and max to show the full data range of the image'
i = i + 1
h[i] = 'ZoomIn:          zooms in by x2'
i = i + 1
h[i] = 'ZoomOut:         zooms out by x2'
i = i + 1
h[i] = 'Zoom1:           sets zoom level to original scale'
i = i + 1
h[i] = 'Center:          centers image on display window'
i = i + 1
h[i] = 'Done:            quits atv'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'Keyboard commands in display window:'
i = i + 1
h[i] = '    Numeric keypad (with NUM LOCK on) moves cursor'
i = i + 1
h[i] = '    r: row plot'
i = i + 1
h[i] = '    c: column plot'
i = i + 1
h[i] = '    s: surface plot'
i = i + 1
h[i] = '    t: contour plot'
i = i + 1
h[i] = '    p: aperture photometry at current position'
i = i + 1
h[i] = '    i: image statistics at current position'
i = i + 1
h[i] = '    q: quits atv'
i = i + 2
h[i] = 'IDL COMMAND LINE HELP:'
i = i + 1
h[i] =  'To pass an array to atv:'
i = i + 1
h[i] =  '   atv, array_name [, options]'
i = i + 1
h[i] = 'To pass a fits filename to atv:'
i = i + 1
h[i] = '    atv, fitsfile_name [, options] (enclose filename in single quotes) '
i = i + 1
h[i] = 'To overplot a contour plot on the draw window:'
i = i + 1
h[i] = '    atvcontour, array_name [, options...]'
i = i + 1
h[i] = 'To overplot text on the draw window: '
i = i + 1
h[i] = '    atvxyouts, x, y, text_string [, options]  (enclose string in single quotes)'
i = i + 1
h[i] = 'To overplot points or lines on the current plot:'
i = i + 1
h[i] = '    atvplot, xvector, yvector [, options]'
i = i + 2
h[i] = 'The options for atvcontour, atvxyouts, and atvplot are essentially'
i = i + 1
h[i] =  'the same as those for the idl contour, xyouts, and plot commands,'
i = i + 1
h[i] = 'except that data coordinates are always used.' 
i = i + 1
h[i] = 'The default color for overplots is red.'
i = i + 2
h[i] = 'Other commands:'
i = i + 1
h[i] = 'atverase [, N]:       erases all (or last N) plots and text'
i = i + 1
h[i] = 'atv_shutdown:   quits atv'
i = i + 1
h[i] = 'NOTE: If atv should crash, type atv_shutdown at the idl prompt.'
i = i + 5
h[i] = strcompress('ATV.PRO version '+state.version+' by Aaron J. Barth')
i = i + 1
h[i] = 'For full instructions, or to download the most recent version, go to:'
i = i + 1
h[i] = 'http://cfa-www.harvard.edu/~abarth/atv/atv.html'


if (not (xregistered('atv_help', /noshow))) then begin

helptitle = strcompress('atv v' + state.version + ' help')

    help_base =  widget_base(/floating, $
                             group_leader = state.base_id, $
                             /column, $
                             /base_align_right, $
                             title = helptitle, $
                             uvalue = 'help_base')

    help_text = widget_text(help_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    help_done = widget_button(help_base, $
                              value = 'Done', $
                              uvalue = 'help_done')

    widget_control, help_base, /realize
    xmanager, 'atv_help', help_base, /no_block
    
endif

end

;----------------------------------------------------------------------

pro atv_help_event, event

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;      Routines for displaying image statistics
;----------------------------------------------------------------------

pro atv_stats_refresh

; Calculate box statistics and update the results

common atv_state
common atv_images

b = round((state.statboxsize - 1) / 2)

xmin = 0 > (state.cursorpos[0] - b) < (state.image_size[0] - 1)
xmax = 0 > (state.cursorpos[0] + b) < (state.image_size[0] - 1)
ymin = 0 > (state.cursorpos[1] - b) < (state.image_size[1] - 1)
ymax = 0 > (state.cursorpos[1] + b) < (state.image_size[1] - 1)

xmin = round(xmin)
xmax = round(xmax)
ymin = round(ymin)
ymax = round(ymax)

cut = float(main_image[xmin:xmax, ymin:ymax])
npix = (xmax - xmin + 1) * (ymax - ymin + 1)

cutmin = min(cut)
cutmax = max(cut)
cutmean = mean(cut)
cutmedian = median(cut)
cutstddev = stddev(cut)

widget_control, state.statbox_id, set_value=state.statboxsize
widget_control, state.statxcenter_id, set_value = state.cursorpos[0]
widget_control, state.statycenter_id, set_value = state.cursorpos[1]
tmp_string = strcompress('# Pixels in Box:  ' + string(npix))
widget_control, state.stat_npix_id, set_value = tmp_string
tmp_string = strcompress('Min:  ' + string(cutmin))
widget_control, state.statbox_min_id, set_value = tmp_string
tmp_string = strcompress('Max:  ' + string(cutmax))
widget_control, state.statbox_max_id, set_value = tmp_string
tmp_string = strcompress('Mean:  ' + string(cutmean))
widget_control, state.statbox_mean_id, set_value = tmp_string
tmp_string = strcompress('Median:  ' + string(cutmedian))
widget_control, state.statbox_median_id, set_value = tmp_string
tmp_string = strcompress('StdDev:  ' + string(cutstddev))
widget_control, state.statbox_stdev_id, set_value = tmp_string

atv_tvstats

end

;----------------------------------------------------------------------

pro atv_stats_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'statbox': begin
        state.statboxsize = long(event.value) > 3
        if ( (state.statboxsize / 2 ) EQ $
             round(state.statboxsize / 2.)) then $
          state.statboxsize = state.statboxsize + 1
        atv_stats_refresh
    end

    'statxcenter': begin
        state.cursorpos[0] = 0 > long(event.value) < (state.image_size[0] - 1)
        atv_stats_refresh
    end

    'statycenter': begin
        state.cursorpos[1] = 0 > long(event.value) < (state.image_size[1] - 1)
        atv_stats_refresh
    end

    'showstatzoom': begin
        widget_control, state.showstatzoom_id, get_value=val
        case val of
            'Show Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=state.statzoom_size, ysize=state.statzoom_size
                widget_control, state.showstatzoom_id, $
                  set_value='Hide Region'
            end
            'Hide Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showstatzoom_id, $
                  set_value='Show Region'
             end
         endcase
         atv_stats_refresh
    end

    'stats_done': widget_control, event.top, /destroy
    else:
endcase


end

;----------------------------------------------------------------------

pro atv_showstats

; Brings up a widget window for displaying image statistics

common atv_state
common atv_images

common atv_state

state.cursorpos = state.coord

if (not (xregistered('atv_stats', /noshow))) then begin

    stats_base = $
      widget_base(/floating, $
                  group_leader = state.base_id, $
                  /column, $
                  /base_align_center, $
                  title = 'atv image statistics', $
                  uvalue = 'stats_base')
    state.stats_base_id = stats_base
    
    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)

    tmp_string = strcompress('Image size:  ' + $
                             string(state.image_size[0]) + $
                             ' x ' + $
                             string(state.image_size[1]))

    size_label = widget_label(stats_base1, value = tmp_string)

    tmp_string = strcompress('Image Min:  ' + string(state.image_min))
    min_label= widget_label(stats_base1, value = tmp_string)
    tmp_string = strcompress('Image Max:  ' + string(state.image_max))
    max_label= widget_label(stats_base1, value = tmp_string)

    state.statbox_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Size for Stats:', $
               uvalue = 'statbox', $
               value = state.statboxsize, $
               xsize = 5)
    
    state.statxcenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box X Center:', $
               uvalue = 'statxcenter', $
               value = state.cursorpos[0], $ 
               xsize = 5)

    state.statycenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Y Center:', $
               uvalue = 'statycenter', $
               value = state.cursorpos[1], $ 
               xsize = 5)

    tmp_string = strcompress('# Pixels in Box:  ' + string(100000))
    state.stat_npix_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Min:  ' + '0.00000000')
    state.statbox_min_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Max:  ' + '0.00000000')
    state.statbox_max_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Mean:  ' + '0.00000000')
    state.statbox_mean_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Median:  ' + '0.00000000')
    state.statbox_median_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('StdDev:  ' + '0.00000000')
    state.statbox_stdev_id = widget_label(stats_base2a, value = tmp_string)
    
    state.showstatzoom_id = widget_button(stats_base2, $
          value = 'Show Region', uvalue = 'showstatzoom')

    stat_done = $
      widget_button(stats_base2, $
                    value = 'Done', $
                    uvalue = 'stats_done')
    
    state.statzoom_widget_id = widget_draw(stats_zoombase, $
       scr_xsize = 1, scr_ysize = 1)

    widget_control, stats_base, /realize
    
    xmanager, 'atv_stats', stats_base, /no_block
    
    widget_control, state.statzoom_widget_id, get_value = tmp_val
    state.statzoom_window_id = tmp_val

    atv_resetwindow

endif

atv_stats_refresh

end

;---------------------------------------------------------------------


pro atv_tvstats

; Routine to display the zoomed region around a stats point

common atv_state
common atv_images

atv_setwindow, state.statzoom_window_id
erase

x = round(state.cursorpos[0])
y = round(state.cursorpos[1])

boxsize = (state.statboxsize - 1) / 2
xsize = state.statboxsize
ysize = state.statboxsize
image = bytarr(xsize,ysize)

xmin = (0 > (x - boxsize))
xmax = ((x + boxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - boxsize) )
ymax = ((y + boxsize) < (state.image_size[1] - 1))

startx = abs( (x - boxsize) < 0 )
starty = abs( (y - boxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.statzoom_size
dev_pos = [0.15 * state.statzoom_size, $
           0.15 * state.statzoom_size, $
           0.95 * state.statzoom_size, $
           0.95 * state.statzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1

tv, image, /device, dev_pos[0], dev_pos[1], $
  xsize=dev_pos[2]-dev_pos[0], $
  ysize=dev_pos[3]-dev_pos[1]

plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
  /device, position = dev_pos, color=7, $
  xrange = x_ran, yrange = y_ran

atv_resetwindow
end

;----------------------------------------------------------------------
;        aperture photometry and radial profile routines
;---------------------------------------------------------------------

pro atv_imcenterf, xcen, ycen

; program to calculate the center of mass of an image around
; the point (x,y), return the answer in (xcen,ycen).
;
; by M. Liu, adapted for inclusion in ATV by AJB
;
; ALGORITHM:
;   1. first finds max pixel value in
;	   a 'bigbox' box around the cursor
;   2. then calculates centroid around the object 
;   3. iterates, recalculating the center of mass 
;      around centroid until the shifts become smaller 
;      than MINSHIFT (0.3 pixels) 

common atv_images
common atv_state

; iteration controls
MINSHIFT = 0.3

; max possible x or y direction shift
MAXSHIFT = 3

; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
bigbox=round(1.5*state.centerboxsize)

sz = size(main_image)

; box size must be odd
dc = (state.centerboxsize-1)/2
if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
db = (bigbox-1)/2

; need to start with integers
xx = state.cursorpos[0]
yy = state.cursorpos[1]

; first find max pixel in box around the cursor
;
x0 = (xx-db) > 0
x1 = (xx+db) < (sz(1)-1)
y0 = (yy-db) > 0
y1 = (yy+db) < (sz(2)-1)
cut = main_image[x0:x1,y0:y1]
cutmax = max(cut)
w=where(cut EQ cutmax)
cutsize = size(cut)
my = (floor(w/cutsize[1]))[0]
mx = (w - my*cutsize[1])[0]

xx = mx + x0
yy = my + y0 
xcen = xx
ycen = yy

;
; then find centroid 
;

if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen)) 
    yy = round(total(ycen)/n_elements(ycen)) 
endif

done = 0
niter = 1
    
;	cut out relevant portion
sz = size(main_image)
x0 = round((xx-dc) > 0)		; need the ()'s
x1 = round((xx+dc) < (sz[1]-1))
y0 = round((yy-dc) > 0)
y1 = round((yy+dc) < (sz[2]-1))
xs = x1 - x0 + 1
ys = y1 - y0 + 1
cut = float(main_image[x0:x1, y0:y1])

                                ; find x position of center of mass
cenxx = fltarr(xs, ys, /nozero)
for i = 0L, (xs-1) do $         ; column loop
  cenxx[i, *] = cut[i, *] * i
xcen = total(cenxx) / total(cut) + x0

                                ; find y position of center of mass
cenyy = fltarr(xs, ys, /nozero)
for i = 0L, (ys-1) do $         ; row loop
  cenyy[*, i] = cut[*, i] * i
ycen = total(cenyy) / total(cut) + y0

if (abs(xcen-state.cursorpos[0]) gt MAXSHIFT) or $
  (abs(ycen-state.cursorpos[1]) gt MAXSHIFT) then begin
    state.photwarning = 'Warning: Possible mis-centering?'
endif

end

;----------------------------------------------------------------------

function atv_splinefwhm, rad, prof, splrad, splprof

; given a radial profile (counts vs radius) will use
; a spline to extract the FWHM
;
; ALGORITHM
;   finds peak in radial profile, then marches along until finds
;   where radial profile has dropped to half of that,
;   assumes peak value of radial profile is at minimum radius
;
; original version by M. Liu, adapted for ATV by AJB

common atv_state

nrad = n_elements(rad)

; check the peak
w = where(prof eq max(prof))
if float(rad(w[0])) ne min(rad) then begin
state.photwarning = 'Warning: Profile peak is off-center!'
  return,-1
endif

; interpolate radial profile at 50 times as many points
splrad = min(rad) + findgen(nrad*50+1) * (max(rad)-min(rad)) / (nrad*50)
nspl = n_elements(splrad)

; spline the profile
splprof = spline(rad,prof,splrad)

; march along splined profile until cross 0.5*peak value
found = 0
i = 0
repeat begin
  if splprof(i) lt 0.5*max(splprof) then $
	found = 1 $
  else $
	i = i+1
endrep until ((found) or (i eq nspl))

if (i lt 2) or (i eq nspl) then begin
state.photwarning = 'Warning: Unable to measure FWHM!'
  return,-1
endif

; now interpolate across the 2 points straddling the 0.5*peak
fwhm = splrad(i)+splrad(i-1)

return,fwhm
end

;-----------------------------------------------------------------------

pro atv_radplotf, x, y, fwhm

; Program to calculate radial profile of an image
; given aperture location, range of sizes, and inner and 
; outer radius for sky subtraction annulus.  Calculates sky by
; median.
; 
; original version by M. Liu, adapted for inclusion in ATV by AJB


common atv_state
common atv_images

; set defaults
inrad = 0.5*sqrt(2)
outrad = round(state.outersky * 1.2)
drad=1.
insky = outrad+drad
outsky = insky+drad+20.

; initialize arrays
inrad = float(inrad)
outrad = float(outrad)
drad = float(drad)
nrad = ceil((outrad-inrad)/drad) + 1
out = fltarr(nrad,12)

; extract relevant image subset (may be rectangular), translate coord origin,
;   bounded by edges of image
;   (there must be a cute IDL way to do this neater)
sz = size(main_image)
x0 = floor(x-outsky) 
x1 = ceil(x+outsky)   ; one pixel too many?
y0 = floor(y-outsky) 
y1 = ceil(y+outsky)
x0 = x0 > 0.0
x1 = x1 < (sz[1]-1)
y0 = y0 > 0.0
y1 = y1 < (sz[2]-1)
nx = x1 - x0 + 1
ny = y1 - y0 + 1

; trim the image, translate coords
img = main_image[x0:x1,y0:y1]
xcen = x - x0
ycen = y - y0

; for debugging, can make some masks showing different regions
skyimg = fltarr(nx,ny)			; don't use /nozero!!
photimg = fltarr(nx,ny)			; don't use /nozero!!

; makes an array of (distance)^2 from center of aperture
;   where distance is the radial or the semi-major axis distance.
;   based on DIST_CIRCLE and DIST_ELLIPSE in Goddard IDL package,
;   but deals with rectangular image sections
distsq = fltarr(nx,ny,/nozero)

xx = findgen(nx)
yy = findgen(ny)
x2 = (xx - xcen)^(2.0)
y2 = (yy - ycen)^(2.0)
for i = 0L,(ny-1) do $          ; row loop
  distsq[*,i] = x2 + y2(i)

; get sky level by masking and then medianing remaining pixels
; note use of "gt" to avoid picking same pixels as flux aperture
;  (checked graphically and there is no overlap between the 2 regions)
;  can disable sky subtraction then by setting insky=outsky
ns = 0
msky = 0.0
errsky = 0.0

in2 = insky^(2.0)
out2 = outsky^(2.0)
w = where((distsq gt in2) and (distsq le out2),ns)

skyann = img[w]

msky = median(skyann)
errsky = stddev(skyann)
skyimg[w] = -5.0
photimg = skyimg

errsky2 = errsky * errsky

out[*,8] = msky
out[*,9] = ns
out[*,10]= errsky

; now loop through photometry radii, finding the total flux, differential
;	flux, and differential average pixel value along with 1 sigma scatter
; 	relies on the fact the output array is full of zeroes
for i = 0,nrad-1 do begin
    
    dr = drad
    if i eq 0 then begin
        rin =  0.0
        rout = inrad
        rin2 = -0.01
    endif else begin
        rin = inrad + drad *(i-1)	
        rout = (rin + drad) < outrad
        rin2 = rin*rin
    endelse
    rout2 = rout*rout
    
; 	get flux and pixel stats in annulus, wary of counting pixels twice
;	checking if necessary if there are pixels in the sector
    w = where(distsq gt rin2 and distsq le rout2,np)
    
    pfrac = 1.0                 ; fraction of pixels in each annulus used
    
    if np gt 0 then begin
        ann = img[w]
        dflux = total(ann) * 1./pfrac
        dnpix = np
        dnet = dflux - (dnpix * msky) * 1./pfrac
        davg = dnet / (dnpix * 1./pfrac)
        if np gt 1 then dsig = stddev(ann) else dsig = 0.00
        
;		std dev in each annulus including sky sub error
        derr = sqrt(dsig*dsig + errsky2)
        
        photimg[w] = rout2
        
        out[i,0] = (rout+rin)/2.0
        out[i,1] = out[i-1>0,1] + dflux
        out[i,2] = out[i-1>0,2] + dnet
        out[i,3] = out[i-1>0,3] + dnpix
        out[i,4] = dflux
        out[i,5] = dnpix
        out[i,6] = davg
        out[i,7] = dsig
        out[i,11] = derr
    endif else if (i ne 0) then begin
        out[i,0]= rout
        out[i,1:3] = out[i-1,1:3]
        out[i, 4:7] = 0.0
        out[i,11] = 0.0
    endif else begin
        out[i, 0] = rout
    endelse
    
endfor

; fill radpts array after done with differential photometry
w = where(distsq ge 0.0 and distsq le outrad*outrad)
radpts = dblarr(2,n_elements(w))
radpts[0,*] = sqrt(distsq[w])
radpts[1,*] = img[w]

; compute FWHM via spline interpolation of radial profile
fwhm = atv_splinefwhm(out[*,0],out[*,6])

; plot the results

if n_elements(radpts(1, *)) gt 100 then pp = 3 else pp = 1

plot, radpts(0, *), radpts(1, *), /nodata, xtitle = 'Radius (pixels)', $
  ytitle = 'Counts', color=7, charsize=1.2
oplot, radpts(0, *), radpts(1, *), psym = pp, color=6
oploterror, out(*, 0), out(*, 6)+out(*, 8), $
  out(*, 11)/sqrt(out(*, 5)), psym=-4, color=7, errcolor=7

end

;-----------------------------------------------------------------------

pro atv_apphot_refresh

; Do aperture photometry using idlastro daophot routines.

common atv_state
common atv_images

state.photwarning = 'Warnings: None.'

; Center on the object position nearest to the cursor
atv_imcenterf, x, y

; Make sure that object position is on the image
x = 0 > x < (state.image_size[0] - 1)
y = 0 > y < (state.image_size[1] - 1)

if ((x - state.outersky) LT 0) OR $
  ((x + state.outersky) GT (state.image_size[0] - 1)) OR $
  ((y - state.outersky) LT 0) OR $
  ((y + state.outersky) GT (state.image_size[1] - 1)) then $
  state.photwarning = 'Warning: Sky apertures fall outside image!'

; Condition to test whether phot aperture is off the image
if (x LT state.r) OR $
  ((state.image_size[0] - x) LT state.r) OR $
  (y LT state.r) OR $
  ((state.image_size[1] - y) LT state.r) then begin
    flux = -1.
    state.photwarning = 'Warning: Aperture Outside Image Border!'
endif
    
phpadu = 1.0                    ; don't convert counts to electrons
apr = [state.r]
skyrad = [state.innersky, state.outersky]
; Assume that all pixel values are good data
badpix = [state.image_min, state.image_max]  

aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
  skyrad, badpix, /flux, /silent

flux = flux[0]
sky = sky[0]

if (flux EQ 99.999) then begin
    state.photwarning = 'Warning: Error in computing flux!'
    flux = -1.0
endif

; Run atv_radplotf and plot the results

atv_setwindow, state.radplot_window_id
atv_radplotf, x, y, fwhm

; overplot the phot apertures on radial plot
plots, [state.r, state.r], !y.crange, line = 1, color=2, thick=2, psym=0
xyouts, /data, state.r, !y.crange(1)*0.92, ' aprad', $
  color=2, charsize=1.3
plots, [state.innersky,state.innersky], !y.crange, $
  line = 1, color=4, thick=2, psym=0
xyouts, /data, state.innersky, !y.crange(1)*0.85, ' insky', $
  color=4, charsize=1.3
plots, [state.outersky,state.outersky], !y.crange, $
  line = 1, color=5, thick=2, psym=0
xyouts, /data, state.outersky * 0.82, !y.crange(1)*0.75, ' outsky', $
  color=5, charsize=1.3

atv_resetwindow

; output the results
  
state.centerpos = [x, y]

tmp_string = string(state.cursorpos[0], state.cursorpos[1], $
                    format = '("Cursor position:  x=",i4,"  y=",i4)' )
tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
                    format = '("Object centroid:  x=",f6.1,"  y=",f6.1)' )
tmp_string2 = string(flux, format = '("Object counts: ",g12.6)' )
tmp_string3 = string(sky, format = '("Sky level: ",g12.6)' )
tmp_string4 = string(fwhm, format='("FWHM (pix): ",g7.3)' )

widget_control, state.centerbox_id, set_value = state.centerboxsize
widget_control, state.cursorpos_id, set_value = tmp_string
widget_control, state.centerpos_id, set_value = tmp_string1
widget_control, state.radius_id, set_value = state.r 
widget_control, state.outersky_id, set_value = state.outersky
widget_control, state.innersky_id, set_value = state.innersky
widget_control, state.skyresult_id, set_value = tmp_string3
widget_control, state.photresult_id, set_value = tmp_string2
widget_control, state.fwhm_id, set_value = tmp_string4
widget_control, state.photwarning_id, set_value=state.photwarning

if (ptr_valid(state.astr_ptr)) then begin

    xy2ad, state.centerpos[0], state.centerpos[1], *(state.astr_ptr), $
      clon, clat
    
    wcsstring = atv_wcsstring(clon, clat, (*state.astr_ptr).ctype,  $
                 state.equinox, state.display_coord_sys, state.display_equinox)

; Uncomment next line if you want atv to output the WCS coords of 
; the centroid for the photometry object
;    print, 'Centroid WCS coords: ', wcsstring

endif

atv_tvphot

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_tvphot

; Routine to display the zoomed region around a photometry point,
; with circles showing the photometric apterture and sky radii.

common atv_state
common atv_images

atv_setwindow, state.photzoom_window_id
erase

x = round(state.centerpos[0])
y = round(state.centerpos[1])

boxsize = round(state.outersky * 1.2)
xsize = (2 * boxsize) + 1
ysize = (2 * boxsize) + 1
image = bytarr(xsize,ysize)

xmin = (0 > (x - boxsize))
xmax = ((x + boxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - boxsize) )
ymax = ((y + boxsize) < (state.image_size[1] - 1))

startx = abs( (x - boxsize) < 0 )
starty = abs( (y - boxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.photzoom_size
dev_pos = [0.15 * state.photzoom_size, $
           0.15 * state.photzoom_size, $
           0.95 * state.photzoom_size, $
           0.95 * state.photzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1


tv, image, /device, dev_pos[0], dev_pos[1], $
  xsize=dev_pos[2]-dev_pos[0], $
  ysize=dev_pos[3]-dev_pos[1]

plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
  /device, position = dev_pos, color=7, $
  xrange = x_ran, yrange = y_ran

tvcircle, /data, state.r, state.centerpos[0], state.centerpos[1], $
  color=2, thick=2, psym=0
tvcircle, /data, state.innersky, state.centerpos[0], state.centerpos[1], $
  color=4, thick=2, psym=0
tvcircle, /data, state.outersky, state.centerpos[0], state.centerpos[1], $
  color=5, thick=2, psym=0

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_apphot_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'centerbox': begin
        state.centerboxsize = long(event.value) > 3
        if ( (state.centerboxsize / 2 ) EQ $
             round(state.centerboxsize / 2.)) then $
          state.centerboxsize = state.centerboxsize + 1
        atv_apphot_refresh
    end
        
    'radius': begin
        state.r = 1 > long(event.value) < state.innersky
        atv_apphot_refresh
    end

    'innersky': begin
        state.innersky = state.r > long(event.value) < (state.outersky - 1)
        state.innersky = 2 > state.innersky
        if (state.outersky EQ state.innersky + 1) then $
          state.outersky = state.outersky + 1
        atv_apphot_refresh
    end

    'outersky': begin
        state.outersky = long(event.value) > (state.innersky + 2)
        atv_apphot_refresh
    end

    'showradplot': begin
        widget_control, state.showradplot_id, get_value=val
        case val of
            'Show Radial Profile': begin
                widget_control, state.radplot_widget_id, $
                  xsize=500, ysize=350
                widget_control, state.showradplot_id, $
                  set_value='Hide Radial Profile'
            end
            'Hide Radial Profile': begin
                widget_control, state.radplot_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showradplot_id, $
                  set_value='Show Radial Profile'
             end
         endcase
         atv_apphot_refresh
    end

    'apphot_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------

pro atv_apphot

; aperture photometry front end

common atv_state

state.cursorpos = state.coord

if (not (xregistered('atv_apphot', /noshow))) then begin

    apphot_base = $
      widget_base(/floating, $
                  /base_align_center, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv aperture photometry', $
                  uvalue = 'apphot_base')
    
    apphot_top_base = widget_base(apphot_base, /row, /base_align_center)

    apphot_data_base1 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_data_base2 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_zoom_base = widget_base(apphot_data_base2, /row, $
                           frame=1, /base_align_center)
    apphot_draw_base = widget_base( $
            apphot_base, /row, /base_align_center, frame=0)

    apphot_data_base1a = widget_base(apphot_data_base1, /column, frame=1)
    tmp_string = $
      string(1000, 1000, $
             format = '("Cursor position:  x=",i4,"  y=",i4)' )

    state.cursorpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string, $
                   uvalue = 'cursorpos')

    state.centerbox_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Centering box size (pix):', $
               uvalue = 'centerbox', $
               value = state.centerboxsize, $
               xsize = 5)
    
    tmp_string1 = $
      string(99999.0, 99999.0, $
             format = '("Object centroid:  x=",f7.1,"  y=",f7.1)' )
    
    state.centerpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string1, $
                   uvalue = 'centerpos')

    state.radius_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Aperture radius:', $
               uvalue = 'radius', $
               value = state.r, $
               xsize = 5)
    
    state.innersky_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Inner sky radius:', $
               uvalue = 'innersky', $
               value = state.innersky, $
               xsize = 5)
    
    state.outersky_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Outer sky radius:', $
               uvalue = 'outersky', $
               value = state.outersky, $
               xsize = 5)
    
    tmp_string4 = string(0.0, format='("FWHM (pix): ",g7.3)' )
    state.fwhm_id = widget_label(apphot_data_base2, $
                                 value=tmp_string4, $
                                 uvalue='fwhm')

    tmp_string3 = string(10000000.00, $
                         format = '("Sky level: ",g12.6)' )
    
    state.skyresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string3, $
                   uvalue = 'skyresult')
    
    tmp_string2 = string(1000000000.00, $
                         format = '("Object counts: ",g12.6)' )
    
    state.photresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photresult', $
                   /frame)

    state.photwarning_id = $
      widget_label(apphot_data_base1, $
                   value='-------------------------', $
                   /dynamic_resize, frame=1)

    state.showradplot_id = $
      widget_button(apphot_data_base1, $
                    value = 'Show Radial Profile', $
                    uvalue = 'showradplot')

    apphot_done = $
      widget_button(apphot_data_base1, $
                    value = 'Done', $
                    uvalue = 'apphot_done')
    
    state.radplot_widget_id = widget_draw( $
         apphot_draw_base, scr_xsize=1, scr_ysize=1)

    photzoom_widget_id = widget_draw( $
         apphot_zoom_base, $
         scr_xsize=state.photzoom_size, scr_ysize=state.photzoom_size)

    widget_control, apphot_base, /realize

    widget_control, photzoom_widget_id, get_value=tmp_value
    state.photzoom_window_id = tmp_value
    widget_control, state.radplot_widget_id, get_value=tmp_value
    state.radplot_window_id = tmp_value

    xmanager, 'atv_apphot', apphot_base, /no_block
    
    atv_resetwindow
endif

atv_apphot_refresh

end

;--------------------------------------------------------------------
;    atv main program.  needs to be last in order to compile.
;---------------------------------------------------------------------

; Main program routine for ATV.  If there is no current ATV session,
; then run atv_startup to create the widgets.  If ATV already exists,
; then display the new image to the current ATV window.

pro atv, image, $
             min = minimum, $
             max = maximum, $
             autoscale = autoscale,  $
             linear = linear, $
             log = log, $
             histeq = histeq

common atv_state
common atv_images

newimage = 0

if ( (n_params() EQ 0) AND (xregistered('atv', /noshow))) then begin
    print, 'USAGE: atv, array_name OR fitsfile'
    print, '            [,min = min_value] [,max=max_value]'
    print, '            [,/autoscale] [,/linear] [,/log] [,/histeq]'
    return
endif

if (not (xregistered('atv', /noshow))) then atv_startup

; If image is a filename, read in the file
if ( (n_params() NE 0) AND (size(image, /tname) EQ 'STRING')) then begin
    ifexists = findfile(image, count=count)
    if (count EQ 0) then begin
        print, 'ERROR: File not found!'
    endif else begin
        atv_readfits, fitsfilename=image, newimage=newimage
    endelse
endif

; Check for existence of array
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) EQ 'UNDEFINED')) then begin
    print, 'ERROR: Data array does not exist!'
endif

; If user has passed atv a data array, read it into main_image.
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) NE 'UNDEFINED')) then begin
; Make sure it's a 2-d array
    if ( (size(image))[0] NE 2) then begin
        print, 'ERROR: Input data must be a 2-d array!'    
    endif else begin
        main_image = image
        newimage = 1
; test for NaNs
        w = where(NOT float(finite(main_image)), count)
        if (count NE 0) then begin
            main_image(w) = 0
            print, strcompress('Warning: '+ $
                               string(count) + $
                               ' pixels with value NaN converted to zero.')
        endif
        state.imagename = ''
        atv_setheader, ''
    endelse
endif

;   Define default startup image 
if (n_elements(main_image) LE 1) then begin
    main_image = byte(((findgen(500)-250)/10)^2 # ((findgen(500)-250)/10)^2)
;    main_image = byte(dist(500)*10000)
    imagename = ''
    newimage = 1
    atv_setheader, ''
endif


if (newimage EQ 1) then begin  
; skip this part if new image is invalid or if user selected 'cancel'
; in dialog box
    atv_settitle
    atv_getstats
    
    scaled_image = 0
    display_image = 0

    if n_elements(minimum) GT 0 then begin
        state.min_value = minimum
    endif
    
    if n_elements(maximum) GT 0 then begin 
        state.max_value = maximum
    endif
    
    if state.min_value GE state.max_value then begin
        state.min_value = state.max_value - 1.
    endif
    
    atv_set_minmax
    
    if (keyword_set(autoscale) OR $
        ((state.default_autoscale EQ 1) AND (n_elements(minimum) EQ 0) $
         AND (n_elements(maximum) EQ 0)) ) $
      then atv_autoscale
    
    if (keyword_set(linear)) then state.scaling = 0
    if (keyword_set(log))    then state.scaling = 1
    if (keyword_set(histeq)) then state.scaling = 2
    
    state.zoom_level = 0
    state.zoom_factor = 1.0
    
    atv_displayall
    
    atv_resetwindow
endif

end


