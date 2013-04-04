dumpxml    := scripts/dumpxml.xq
xml2wiki   := scripts/xml2wiki.xsl
csv2lookup := scripts/wikilookup.py
csvs       := $(wildcard lookups/*.csv)
lookups    := $(csvs:lookups/%.csv=lookups/%.xml)
xmlsource  := $(wildcard xml/*.xml)
wikitext   := $(xmlsource:xml/%.xml=wiki/%.txt)


.PHONY: all xmlsource xmllookups clean

all: $(wikitext)

xmlsource:
	basexclient -Uadmin -Padmin -bcwd="$$PWD/xml/" $(dumpxml)

xmllookups: $(lookups)

clean:
	rm wiki/*

# This is so make complains loudly if csvs are out of date
# CSVs must be manually exported from the XLS in word
lookups/%.csv: lookups/%.xls
	echo "$@ are out of date!" && exit 1

lookups/%.xml: lookups/%.csv $(csv2lookup)
	python $(csv2lookup) $< $@

wiki/%.txt: xml/%.xml $(xml2wiki) $(lookups)
	xsltproc --output $@ $(xml2wiki) $<
