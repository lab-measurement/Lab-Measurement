all: poster.pdf

%.pdf : %.tex *.pl
	pdflatex $<

clean:
	rm -f poster.pdf poster.aux poster.log

.PHONY: clean
