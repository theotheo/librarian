VPATH = /tmp/renamed

pdfs/%.pdf : %.pdf
	mkdir -p $(dir $@)
	cp $^ $@	

metadata/%.toc : %.djvu
	mkdir -p $(dir $@)
	djvused $^ -u -e print-outline > $@
	$(info Extract TOC from DJVU)

metadata/%.metadata : metadata/%.toc 
	# @pdftk $^ dump_data_utf8 > $@
	if [ -s $< ]; then ./toc_convert.py $< > $@; else touch $@; fi 

extracted/%.pdf : %.djvu  
	mkdir -p $(dir $@)
	ddjvu -format=pdf -quality=150 -mode=black $<  $@
	# ddjvu -format=pdf -quality=150 -mode=black -page=1-10 $<  $@
	$(info Convert DJVU to PDF)

pdfs/%.pdf : metadata/%.metadata extracted/%.pdf
	mkdir -p $(dir $@)
	pdftk $(word 2,$^) update_info_utf8 $< output $@
	$(info Insert TOC)

pdfs/%.pdf : %.doc %.docx %.rtf %.pptx %.ppsx %.odp
	mkdir -p $(dir $@)
	soffice --invisible --norestore --convert-to pdf --print-to-file --printer-name "$@" --outdir "./$(dirname "$^")" "$^" 

# .SECONDEXPANSION:
# 1_pdf/%.pdf : $$(wildcard %.epub) $$(wildcard %.fb2)
# 	ebook-convert "$^" "$@"


pdfs/%.pdf : %.epub
	ebook-convert "$^" "$@"

pdfs/%.pdf : %.fb2
	ebook-convert "$^" "$@"

.ONESHELL:
ocr/%.pdf : pdfs/%.pdf
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

.PRECIOUS: ocr/%.pdf
min/%.pdf : ocr/%.pdf
	mkdir -p $(dir $@)
	ps2pdf -dPDFSETTINGS=/ebook "$^" "$@" 
	$(info Minimization...)

/tmp/%.pdf : min/%.pdf
	mkdir -p $(dir $@)
	mv $^ $@
	$(info Move to done)  