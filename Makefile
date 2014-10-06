PROJECTNAME=harpers-outdoor-book-for-boys
DROPBOXDIR=/home/david/Dropbox
DROPBOXLINK=https://www.dropbox.com/sh/2or8zucpgjvixkf/AACqw_svhgpx5i2N2anJNcmra?dl=0
SRDIR=$(DROPBOXDIR)/Public/sr/$(PROJECTNAME)
PNG=$(wildcard originals/illustrations/*.png)
JPG=$(patsubst originals/illustrations/%.png,images/%.jpg,$(PNG))
TARGETWIDTH=$(shell ppimg --gettargetwidth=$@)


all: $(JPG) $(PROJECTNAME).html

images/%.jpg: originals/illustrations/%.png
#TODO what about originals/illustrations/%.png to originals/illustrations/%.png
ifneq ($(wildcard images.json),)
	convert -trim -fuzz 3% $< -resize $(TARGETWIDTH) $@
else
	convert -resize 40% -trim -fuzz 3% $< $@
endif

$(PROJECTNAME).html: $(PROJECTNAME)-src.txt
	ppgen -i $(PROJECTNAME)-src.txt

errorcheck check: all
	@rm -f errorcheck-results.txt
#	@echo "================================================================================" >> errorcheck-results.txt
#	@echo "--- gutcheck                                                                 ---" >> errorcheck-results.txt
#	@echo "================================================================================" >> errorcheck-results.txt
#	gutcheck $(PROJECTNAME)-lat1.txt >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	@echo "--- bookloupe                                                                ---" >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	bookloupe $(PROJECTNAME)-utf8.txt --typo >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	@echo "--- jeebies                                                                  ---" >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	jeebies $(PROJECTNAME)-lat1.txt >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	@echo "--- pptxt                                                                    ---" >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	pptxt -i $(PROJECTNAME)-utf8.txt -o pptxt-results.txt
	@cat pptxt-results.txt >> errorcheck-results.txt
	@rm pptxt-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	@echo "--- ppspell                                                                  ---" >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
#	ppspell -i $(PROJECTNAME)-utf8.txt -o ppspell-results.txt -l #levenshtein checks
ifneq ($(wildcard originals/good_words.txt),)
	ppspell -i $(PROJECTNAME)-utf8.txt -o ppspell-results.txt -g originals/good_words.txt
else
	ppspell -i $(PROJECTNAME)-utf8.txt -o ppspell-results.txt
endif
	@cat ppspell-results.txt >> errorcheck-results.txt
	@rm ppspell-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	@echo "--- pphtml                                                                   ---" >> errorcheck-results.txt
	@echo "================================================================================" >> errorcheck-results.txt
	pphtml -i $(PROJECTNAME).html -o pphtml-results.txt
	@cat pphtml-results.txt >> errorcheck-results.txt
	@rm pphtml-results.txt
	@geany -i errorcheck-results.txt &

ebook epub kindle mobi: 
	@echo "--- Generating eBook formats"
	epubmaker --make=epub --make=kindle --max-depth=3 --title=$(PROJECTNAME) --author="UNKNOWN" --input-encoding="UTF-8" $(PROJECTNAME).html
	mv $(PROJECTNAME)-epub.epub $(PROJECTNAME).epub
	mv $(PROJECTNAME)-images-epub.epub $(PROJECTNAME)-i.epub
	mv $(PROJECTNAME)-kindle.mobi $(PROJECTNAME).mobi
	mv $(PROJECTNAME)-images-kindle.mobi $(PROJECTNAME)-i.mobi

compressimages:
# TODO this should be done on a file by file basis after conversion of originals/illustrations/ to images/
	@echo "--- Compressing /images"
ifneq ($(wildcard images/*.jpg),)
	jpegoptim images/*.jpg 
endif
ifneq ($(wildcard images/*.png),)
	optipng images/*.png
#	pngquant ./images/*.png #lossy compression
endif

validate: all
	@tidy -f errs.txt -q $(PROJECTNAME).html 1> /dev/null
	@geany errs.txt &
	@firefox -new-window -b http://www.asylumcs.net/pplink.php $(PROJECTNAME).html http://validator.w3.org/ http://jigsaw.w3.org/css-validator/ http://validator.w3.org/checklink http://pptools-pptools.rhcloud.com/ 2> /dev/null & 
	@echo "--------------------------------------"
	@echo "  TODO"
	@echo "--------------------------------------"
	@echo "* Remove unused CSS"
	@echo "* Validate HTML, CSS, Links"
	@echo "* Check title 'The Project Gutenberg eBook of Name of Book, by Author'"
	@echo "* Do diffs"
	@echo "--------------------------------------"

sr: all compressimages ebook 
	@echo "--- Packaging project for smoothreading"
	cp $(PROJECTNAME)-lat1.txt $(PROJECTNAME).txt
	todos -e $(PROJECTNAME).txt $(PROJECTNAME)-utf8.txt $(PROJECTNAME).html 
	zip -9 $(PROJECTNAME)-txt.zip $(PROJECTNAME).txt $(PROJECTNAME)-utf8.txt
	zip -9 $(PROJECTNAME)-html.zip $(PROJECTNAME).html 
	zip -9 $(PROJECTNAME)-html.zip ./images/*.jpg ./images/*.jpeg ./images/*.png ./images/*.gif
# copy HTML, .epub, .mobi to dropbox
	@echo "--- Moving smoothreading materials to dropbox"
	mkdir -p $(SRDIR)
	cp $(PROJECTNAME)-txt.zip $(SRDIR)
	cp $(PROJECTNAME)-html.zip $(SRDIR)
ifneq ($(wildcard $(PROJECTNAME).epub),)
	cp $(PROJECTNAME).epub $(SRDIR)
	cp $(PROJECTNAME)-i.epub $(SRDIR)
endif
ifneq ($(wildcard $(PROJECTNAME).mobi),)
	cp $(PROJECTNAME).mobi $(SRDIR)
	cp $(PROJECTNAME)-i.mobi $(SRDIR)
endif
	@echo "--- Generating SR comment"
#TODO: use link to folder instead of individual links.. dropbox wont link subfolders so create symbolic link in base dropbox folder
	@rm -f sr-comment.txt
	@echo "<INSERT BOOK SUMMARY HERE>" >> sr-comment.txt
	@echo "" >> sr-comment.txt
	@echo "The zip file contains text versions in Latin-1 and UTF-8 encodings. Other formats including HTML, epub and mobi can be found at:" >> sr-comment.txt
	@echo "" >> sr-comment.txt
	@echo $(DROPBOXLINK) >> sr-comment.txt
	@echo "" >> sr-comment.txt
	@echo "Thanks for your help!" >> sr-comment.txt
	@echo "--- Copy sr-comment.txt as SR comment"
	@cat sr-comment.txt | clipit
#TODO: script web interface to automate SR posting?	

release: compressimages
	cp $(PROJECTNAME)-lat1.txt $(PROJECTNAME).txt
	todos -e $(PROJECTNAME).txt $(PROJECTNAME)-utf8.txt $(PROJECTNAME).html 
	zip -9 $(PROJECTNAME).zip $(PROJECTNAME).txt $(PROJECTNAME)-utf8.txt $(PROJECTNAME).html 
	zip -9 $(PROJECTNAME).zip ./images/*.jpg ./images/*.jpeg ./images/*.png ./images/*.gif
