function dub_to_str,dubval

bits=sixty(dubval)
the_string=string(bits[0],format='(i4)')+' '+string(bits[1],format='(i2)')+ $
  ' '+string(bits[2],format='(f5.2)')

return,the_string
end



