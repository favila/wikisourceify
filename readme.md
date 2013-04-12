Wikisourceify
=============

*(Francis Avila, April 2013)*

Wikisourceify takes CatoXML-enhanced XML (US Congressional bill XML with
semantic tagging extensions) from the Deepbills Cato project and produces
hyperlinked Wikitext intended for publication on [Wikisource][wikisource].

Also contains crosswalks between government entity ID systems and Wikipedia
pages.

The XML source and final built TXT files are also included in the repository.

[wikisource]: http://wikisource.org

Repo Contents
-------------
* `Makefile` builds everything. (It requires `xsltproc` and
  `Python` to build anything.) 
* `lookups` contains lookup tables (produced by Cato interns) which map from 
  common unique identifiers to corresponding Wikipedia pages. The source 
  version is an excel spreadsheet, which is exported to a csv, which is 
  processed by a Python script into an XML file. Includes crosswalks for:
  * Federal Bodies (e.g., agencies and bureaus) using NIST SP800-87 codes
  * Congressional committees
  * Federal Elective Officials (congressmen) using Bioguide IDs
  * `xml` contains the source CatoXML-enhanced XML (see the 
    [CatoXML namespace documentation][catoxml]).
  * `wiki` contains the target wikitext
  * `scripts` contains scripts
  * `dumpxml.xq` gets source XML from the deepbills BaseX database using XQuery
  * `wikilookup.py` is a Python script to produce the XML lookup tables
  * `xml2wiki.xsl` is an XSLT 1.0 script to produce the wikitext from the
    source XML. (It uses exslt's `strings:tokenize` extension, but
    otherwise is vanilla XSLT 1.0.)

[catoxml]: http://namespaces.cato.org/catoxml/

How to Build
------------

1. First ensure you have source XML; bills the Cato interns have completed are
   included already. If you want the latest data run `make xmlsource` (requires
   you have a deepbills BaseX server running). 
2. `make` will build the lookup XML and the `wiki/*.txt` files. (This is easy
   and safe to parallelize with `make -j 100`.)
3. `make clean` will remove `wiki/*`
