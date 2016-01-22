;+
;  NAME:
;    TMPFILE
;
;  CALLING SEQUENCE:
;	s = tmpfile(prefix=prefix, suffix=suffix)
;
;	Returns a unique filename for scratch use.
;	Ex:  myfile = tmpfile(prefix='/tmp/', suffix='.tmp')
;
;-

function tmpfile, prefix=prefix, suffix=suffix, help=help

if keyword_set(help) then begin
	doc_library, 'tmpfile'
	return, 0
endif

if not keyword_set(prefix) then prefix = ''
if not keyword_set(suffix) then suffix = ''

add = 0
repeat begin
	file = prefix + strtrim(string(long(systime(1))+add), 2) + suffix
	s = findfile(file, count=count)
	add = add + 1
endrep until count eq 0

return, file

end
