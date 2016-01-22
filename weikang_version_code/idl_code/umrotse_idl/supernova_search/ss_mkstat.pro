PRO ss_mkstat

w = '/rotse/data/sspipeline/'
nlines=200
lines=strarr(nlines)
oneline = 'err'
file = w+'newskys.txt'
openr,unit,file,/get_lun
i=0

while not eof(unit) do begin
   readf,unit,oneline
   lines[i]=oneline
   i=i+1
endwhile
close,unit
free_lun,unit
lines=lines[0:i-1]
sortindex = bsort(lines,lines)
n = n_elements(lines)

text = strarr(12,n+1)
datime = strarr(3,n+1)
datime[0,0] = 'date'
datime[1,0] = 'file'
text[*,*] = '0'
text[0,0] = 'indx'
text[1,0] = 'filename'
text[2,0] = 'images'
text[3,0] = 'coadds'
text[4,0] = 'files_coadd0'
text[5,0] = 'files_coadd1'
text[6,0] = 'files_coadd2'
text[7,0] = 'lim_coadd0'
text[8,0] = 'lim_coadd1'
text[9,0] = 'lim_coadd2'
text[10,0] = 'subtraction'
text[11,0] = 'candidates'

a = '000-00?_cobj.fit'
e = '111-00?_sobj.fit'

p = '_cand.fit'
prod = 'prod/'
old = 'oldcand/'


for i = 0, n-1 do begin

    text[0,i+1] = string(i,format='(i3)')
    text[1:2,i+1] = strsplit(lines[i],',',/extract)
    datime[0:2,i+1] = strsplit(text[1,i+1],'_',/extract)
    j = text[1,i+1]
    c = w+prod+j+a
    sult1 = findfile(c,count=ct)

    text[3,i+1]=string(ct,format='(i2)')
    if ct gt 0 then begin
        sult1=sult1[sort(sult1)]
        for ict=0,ct-1 do begin
            st1=mrdfits(sult1[ict],2,/silent)
            text[4+ict,i+1]=string(st1.ncoadd,format='(i2)')
            text[7+ict,i+1]=string(st1.m_lim,format='(f5.2)')
        endfor
        
        g = w+prod+j+e
        sult2=findfile(g,count=subct)
        text[10,i+1]=string(subct,format='(i2)')
        
        q = w+old+datime[0,i+1]+'_ss_'+datime[1,i+1]+'_'+datime[2,i+1]+p
        sult3=findfile(q,count=candct)

        if candct eq 1 then begin
            st2=mrdfits(sult3[0],1,/silent)
            n_can=n_elements(st2)
            text[11,i+1]=string(n_can,format='(i3)')
        endif        

    endif

endfor

name = w+'ss_stats/'+datime[0,1]+'_ss_3b_stats.txt'
newfile = '/rotse/data/pipeline/response/'+datime[0,1]+'_ss_3b_stats.txt'
openw, ounit,name, /get_lun
for i = 0,n  do printf,ounit,text[*,i],format = '(a8,a25,10(a14))'

free_lun,ounit

spawn, ' cp '+ name +'  ' +  newfile

spawn,'touch /rotse/data/pipeline/thumbcopy'

spawn, 'rm -f /rotse/data/sspipeline/newskys.txt'

end
