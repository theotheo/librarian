#!/bin/bash
mkdir -p processed
mkdir -p 0_renamed

size () { echo `stat --printf="%s" "$1" | numfmt --to=iec-i --suffix=B --format="%.2f"`; }
usage() { echo "Usage: $0 [-m] [-p DIRNAME] [-v] FILENAME" 1>&2; exit 1; }

while getopts 'ivp' flag; do
  case "${flag}" in
    # a) a_flag='true' ;;
    i) idempotent='true' ;;
    # f) files="${OPTARG}" ;;
    p) processed_dir=$OPTARG ;;
    v) verbose='true' ;;
    *) print_usage
       exit 1 ;;
  esac
  shift
done

if [[ ! -f "$1" ]]; then
    echo ERROR: "$1" doesn\'t exist 1>&2; 
    exit 1;
fi 

fn=$(basename "$1")
name=${fn%.*}
ext=${fn##*.}
new_name=$(slugify "$name")
processed_dir=${processed_dir:-done}

echo Original file size: `size "$1"`

cp "$1" 0_renamed/"$new_name.$ext"

if [ "$verbose" == 'true' ]; then
    make /tmp/${new_name}.pdf
else
    make -s /tmp/${new_name}.pdf
fi

mv /tmp/${new_name}.pdf "${processed_dir}/${name}.pdf"
echo Result file size: `size "${processed_dir}/${name}.pdf"`

if [ -z "$idempotent" ]; then
    mv -v books/"$fn" processed/"$fn" 
fi

rm 0_renamed/"$new_name.$ext"
