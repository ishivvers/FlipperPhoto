#!/bin/bash

if [ !  -z  ${1}  ] & [ ! -z ${2} ] & [ ! -z ${3} ]; then
  echo "Telescope: ${1}"
  echo "Input folder: ${2}";
  echo "Output folder: ${3}";
  
  for file in `find ${2} -regextype findutils-default -regex ".*\.fi?ts?\(\.Z\)?"`
  do
    echo $file
    flipprun -t ${1} -o ${3} $file
  done
else
  echo "Usage: ${0} [telescope] [path/to/input/folder] [path/to/output/folder]"
fi

