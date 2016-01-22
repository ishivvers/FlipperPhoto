function degminsec,deg

;  Created:  Bob Kehoe   UM   11-2-00

   hr=fix(deg)
   min=60.0*(deg-hr)
   sec=60.0*(min-fix(min))

   output = string(hr)+' '+string(fix(min))+' '+string(fix(sec))

   return,output
end
