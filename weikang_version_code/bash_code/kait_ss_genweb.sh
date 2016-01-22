#!/bin/sh
#This is the kait pipeline sh version

cand_date_dir=/kait/ss_cand/
ss_web_dir=/kait/web/

cand_tar_bz2_file=${cand_date_dir}/can.tar.bz2
echo $cand_tar_bz2_file

if [ ! -e "$cand_tar_bz2_file" ] 
then  
  echo "No $cand_tar_bz2_file found, doing nothing"
  exit
fi

cd $cand_date_dir
cand_tar_file=${cand_date_dir}/can.tar
cand_file=${cand_date_dir}/can

bunzip2 $cand_tar_bz2_file
tar xvf $cand_tar_file
rm -f $cand_tar_file

newdate=`date +%y%m%d`
mv -f $cand_file ${cand_file}_$newdate

##if also can1, tar that as well
cand1_tar_bz2_file=${cand_date_dir}/can1.tar.bz2
if [ -e "$cand1_tar_bz2_file" ] 
then  
  cand1_tar_file=${cand_date_dir}/can1.tar
  cand1_file=${cand_date_dir}/can1
  
  #Changed to this on 150629 begin
  cp -f $cand1_tar_bz2_file /kait/web/ss_can1/can1_$newdate.tar.bz2
  #Changed to this on 150629 end
  bunzip2 $cand1_tar_bz2_file
  tar xvf $cand1_tar_file
  rm -f $cand1_tar_file
  
  mv -f $cand1_file ${cand_file}1_$newdate
fi
##end done can1

cd ${cand_file}_$newdate

echo kait_ss_generate_webs_directory | nice idl

cd ${ss_web_dir}/ss/
./make_kait_ss_html.pl
