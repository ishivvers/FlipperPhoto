#!/bin/sh
#This is the kait pipeline sh version

if [ $# -ne 1 ]
then
  echo 'kait_ss_genweb_onecand fieldname'
  exit 0
fi

field=$1
cand_realtime_dir=/kait/ss_cand/can_realtime/
ss_web_dir=/kait/web/

newfile=${cand_realtime_dir}/${field}_001.fit
echo $newfile

if [ ! -e "$newfile" ] 
then  
  echo "No $newfile found, doing nothing"
  exit
fi

reffile=${cand_realtime_dir}/${field}.fit
if [ ! -e "$reffile" ] 
then  
  #need to copy the reference image to here
  cp /kait/ref_cal/${field}.fit ${cand_realtime_dir}
fi
#and copy anyway
#cp /kait/ref_cal/${field}.fit ${cand_realtime_dir}

cd $cand_realtime_dir
echo "kait_ss_generate_webs,'$field'" | nice idl
cd ${ss_web_dir}/ss/
./make_kait_ss_html.pl

rm -f ${cand_realtime_dir}/${field}*
