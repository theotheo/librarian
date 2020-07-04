#!/bin/bash
function convert () {
    input=$1
    basename="${input%.*}"
    ext=${input##*.}
    lang=${lang:-rus}
    local output="proc_${basename}.pdf"

    echo
    echo $1
    echo $2
    echo $op, $lang, "$input", $basename

    if [ -z $op ] && ! [[ "$ext" =~ ^(epub|fb2|doc|docx|rtf|pptx|odp|djvu|chm)$ ]]; then
        return 0
    fi

    if [[ -f $output ]]; then
        echo "$output" is exist
        return 0
    fi

    op=${op:-$ext}
    echo "$(dirname "$input")/$output"


    case $op in
        epub | fb2)
            ebook-convert "$input" "$output"
            ;;
        djvu)
            ddjvu -format=pdf -quality=150 "$input" "$output"
            ;;
        doc | docx | rtf | pptx | ppsx | odp)
            soffice --invisible --norestore --convert-to pdf --print-to-file --printer-name "$output" --outdir "./$(dirname "$input")" "$input" 
            ;;
        chm)
            chm2pdf --webpage "$input" "$output"
            ;;
        toc)
            /home/i/Downloads/book-tools/k2pdfopt -ui- -mode copy -n -toclist "${basename}_toc.txt" "$input" -o "$output"
            ;;
        ocr)
            ocrmypdf -l $lang "$input" "ocr_${basename}.pdf"
            ;;
        min)
            ps2pdf -dPDFSETTINGS=/ebook "$input" "min_${basename}.pdf" 
            ;;
        *)
            echo "Undefined command"
            ;;
    esac
}

while getopts ":o:l:" opt; do
  case $opt in
    o) op="$OPTARG"
    ;;
    l) lang="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

input=${@:$OPTIND:1}

if [[ -d "$input" ]]; then
    echo "$input" is a directory
    for filename in "$input"/*; do
	name=$(basename "$filename")
        convert "$name" $op
    done
elif [[ -f $input ]]; then
    echo "$input" is a file
    convert "$input" $op
else
    echo "$input" is not valid
    exit 1
fi
