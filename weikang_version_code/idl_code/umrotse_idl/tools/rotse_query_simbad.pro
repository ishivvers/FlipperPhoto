pro rotse_query_simbad,ra,dec,smb,count=count,radius=radius,printurl=printurl

if n_params() eq 0 then begin
    print,'syntax- rotse_query_simbad,ra,dec,smb,count=count,radius=radius,printurl=printurl'
    return
endif

ra=double(ra)
dec=double(dec)

if n_elements(radius) eq 0 then radius = 10

decsign='+'
if (dec lt 0) then begin
    decsign = '-'
endif
pdec=abs(dec)

QueryURL = "http://archive.eso.org/skycat/servers/sim-server?" + $
  strcompress(string(ra,format='(d10.6)'),/remove_all) + $
  decsign + strcompress(string(pdec,format='(d9.6)'),/remove_all) + $
  '&r=' + string(fix(radius),format='(i3.3)')

  
result = webget(QueryURL)

elt=create_struct('ID','', $
                  'ra',0d, $
                  'dec',0d, $
                  'mv',-99.9, $
                  'mb',-99.9, $
                  'type','', $
                  'dis',0.0, $
                  'url','')

count=n_elements(result.text)-3

smb=replicate(elt,count)

print,'ID','Type','RA','DEC','mB','mV','dis (")',format='(a20,a10,2a12,3a10)'

if (count gt 0) then begin
    for i=2,2+count-1 do begin
        parts=strsplit(result.text[i],string(9B),/regex,/extract,/preserve_null)
        smb[i-2].id = parts[0]
        smb[i-2].ra = double(parts[1])
        smb[i-2].dec = double(parts[2])

        ;; we might not have magnitude measurements
        if (strlen(parts[3]) gt 0) then smb[i-2].mv = float(parts[3])
        if (strlen(parts[4]) gt 0) then smb[i-2].mb = float(parts[4])

        ;; the type should have all leading and trailing spaces removed
        smb[i-2].type = strtrim(parts[5],2)
        
        ;; calculate distance from target pos
        gcirc,1,ra/15d,dec,smb[i-2].ra/15d,smb[i-2].dec,dis
        smb[i-2].dis = dis

        ;; and generate the URL

        flink = parts[0]
        p1=strsplit(flink,' ',/regex,/extract)
        flink=strjoin(p1,'%20')
        p2=strsplit(flink,'\+',/regex,/extract)
        flink=strjoin(p2,'%2B')
        p3=strsplit(flink,'\-',/regex,/extract)
        flink=strjoin(p3,'%2D')
        
        smb[i-2].url = 'http://simbad.u-strasbg.fr/sim-id.pl?Ident='+flink

        print,smb[i-2].id,smb[i-2].type,smb[i-2].ra,smb[i-2].dec,smb[i-2].mb,smb[i-2].mv,dis,format='(a20,a10,2d12.6,3f10.3)'
        if keyword_set(printurl) then print,'   ',smb[i-2].url


    endfor
endif







return
end
