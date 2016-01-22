#!/bin/sh
#b [startvalue endvalue]
#if [ $# -ne 1 -a $# -ne 5 ]
if [ $# -ne 1 ]
then
        echo "usage:command DataFileName"
        exit 0
fi
FileName=$1
awk 'BEGIN{print "#Tstart(s) Tstop(s)  Mag err M_lim"} {printf("%.1f  %.1f  %.2f  %.2f  %.2f\n",$1-$2,$1+$2,$3,($5-$4)/2.0,$6)}' $FileName  | column -t
