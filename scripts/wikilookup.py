"""wikilookup.py

Produce an xml lookup file file from a csv.

Can be run from the command line like:

    python wikilookup.py infile.csv outfile.xml

See documentation on convertfile() for input/output details.
"""

import sys
import posixpath as path
import xml.etree.cElementTree as ET
import csv
import urlparse
import urllib


def canonicalize_wiki_url(url):
    """Returns a wikipedia article name given a wikipedia url

    The return value is suitable for use in Wikitext links, e.g.
    [[Article Name]]
    """
    parts = urlparse.urlparse(url)
    articlename = path.basename(parts.path).replace('_', ' ')
    articlename = urllib.unquote(articlename.encode('utf-8'))
    articlename = articlename.decode('utf-8')
    return articlename


def convertfile(infile, outfile):
    """Write an XML lookup table given a csv file of ids and wikipedia urls

    infile is the input filename.
    outfile is the output filename.

    CSVs must satisfy the following format:

    1. File is windows-1252 encoded (default from Excel's "save as csv").
    2. First row is a header (discarded).
    3. First column is an identifier.
    4. Second column is a human-readable name.
    5. Third column is a full wikipedia url.
    6. Additional columns are ignored.

    Produces a utf-8-encoded XML file like this:

        <root>
          <item id="[column 1]" name="[column 2]"
                wikipedia="[wikipedia article name from column 3]"/>
          <item .../>
          ...
        </root>
    """
    root = ET.Element('items')
    with open(infile, 'rU') as ifp:
        csvreader = csv.reader(ifp)
        csvreader.next()
        for row in csvreader:
            row = [i.decode('CP1252').strip() for i in row]
            if all(row[:3]):
                id, name = row[:2]
                wikipedia = canonicalize_wiki_url(row[2])
                ET.SubElement(root, 'item', id=id, name=name, wikipedia=wikipedia)
    ET.ElementTree(root).write(outfile, 'utf-8')

if __name__ == '__main__':
    convertfile(*sys.argv[1:3])
