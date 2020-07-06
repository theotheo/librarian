VPATH = ./0_renamed

1_pdf/%.pdf : %.pdf
	mkdir -p $(dir $@)
	cp $^ $@	

0_data/%.toc : %.djvu
	mkdir -p $(dir $@)
	djvused $^ -u -e print-outline > $@
	$(info Extract TOC from DJVU)

0_data/%.metadata : 1_data/%.toc 
	# @pdftk $^ dump_data_utf8 > $@
	if [ -s $< ]; then ./toc_convert.py $< > $@; else touch $@; fi 

1_extracted/%.pdf : %.djvu  
	mkdir -p $(dir $@)
	ddjvu -format=pdf -quality=150 -mode=black $<  $@
	# ddjvu -format=pdf -quality=150 -mode=black -page=1-10 $<  $@

	$(info Convert DJVU to PDF)
	
1_pdf/%.pdf : 1_data/%.metadata 1_extracted/%.pdf
	mkdir -p $(dir $@)
	pdftk $(word 2,$^) update_info_utf8 $< output $@
	$(info Insert TOC)

1_pdf/%.pdf : %.doc %.docx %.rtf %.pptx %.ppsx %.odp
	mkdir -p $(dir $@)
	soffice --invisible --norestore --convert-to pdf --print-to-file --printer-name "$@" --outdir "./$(dirname "$^")" "$^" 

# .SECONDEXPANSION:
# 1_pdf/%.pdf : $$(wildcard %.epub) $$(wildcard %.fb2)
# 	ebook-convert "$^" "$@"


1_pdf/%.pdf : %.epub
	ebook-convert "$^" "$@"

1_pdf/%.pdf : %.fb2
	ebook-convert "$^" "$@"

.ONESHELL:
3_ocr/%.pdf : 1_pdf/%.pdf
	mkdir -p $(dir $@)
	
	MYFONTS=`pdffonts $^ | tail -n +3 | cut -d' ' -f1 | sort | uniq)`
	if [ "$$MYFONTS" = '' ] || [ "$$MYFONTS" = '[none]' ]; then \
		echo "NOT OCR'ed"
		ocrmypdf -l rus "$^" "$@";
	else
		echo "OCR'ed.";
		cp "$^" "$@";
	fi

# -ocrmypdf -l rus --tesseract-timeout=0 "$^" "$@"
# ifeq ($$?,0)
# 	ocrmypdf -l rus "$^" "$@"
# else 
# 	cp "$^" "$@"
# endif

.PRECIOUS: 3_ocr/%.pdf
4_min/%.pdf : 3_ocr/%.pdf
	mkdir -p $(dir $@)
	ps2pdf -dPDFSETTINGS=/ebook "$^" "$@" 
	echo "Minimization..."

/tmp/%.pdf : 4_min/%.pdf
	mkdir -p $(dir $@)
	mv $^ $@
	echo "Move to done/"  