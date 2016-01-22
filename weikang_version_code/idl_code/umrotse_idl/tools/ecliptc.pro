pro ecliptc,ra,dec,el,eb,j,jd=jd,degree=degree

 if n_params() eq 0 then begin
     print,'syntax- ecliptc,ra,dec,el,eb,j,jd=jd,degree=degree'
     print,'j = 1: ra,dec --> el,eb    j = 2: el,eb --> ra,dec'
     return
 endif

 radeg = 180.0d/!dpi

 if (n_elements(jd) eq 0) then jdcnv,2000,1,1,12,jd

 ;; calculate epsilon
 ;;   t is the number of Julian centuries since epoch 2000 January 1.5

 jdcnv,2000,1,1,12,jd0
 t = (jd - jd0) / 36525d

 delta_eps = -1d * (46.815d * t + 0.0006d * t^2 - 0.00181 * t^3)/3600d
 eps = 23.43929167d + delta_eps

 case j of
     1: begin
         if not keyword_set(degree) then ras = ra*15.0d else ras = ra
         decs = dec

         sc = sin(ras / radeg) * cos(eps / radeg)
         ts = tan(decs / radeg) * sin(eps / radeg)
         y = sc + ts
         x = cos(ras / radeg)
         el = atan(y , x) * radeg

         sc = sin(decs / radeg) * cos(eps / radeg)
         css = cos(decs / radeg) * sin(eps / radeg) * sin(ras / radeg)
         eb = asin(sc - css) * radeg

         return
     end
     2: begin
         sc = sin(el / radeg) * cos(eps / radeg)
         ts = tan(eb / radeg) * sin(eps / radeg)
         y = sc - ts
         x = cos(el / radeg)
         ra = atan(y, x) * radeg

         sc = sin(eb / radeg) * cos(eps / radeg)
         css = cos(eb / radeg) * sin(eps / radeg) * sin(el / radeg)
         dec = asin(sc + css) * radeg

         if (not keyword_set(degree)) then ra = ra / 15.0d
         return
     end
 endcase




 return
end
