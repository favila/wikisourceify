import sys
import posixpath as path
import xml.etree.cElementTree as ET
import csv
import urlparse
import urllib


def canonicalize_wiki_url(url):
    parts = urlparse.urlparse(url)
    articlename = path.basename(parts.path).replace('_', ' ')
    articlename = urllib.unquote(articlename.encode('utf-8'))
    articlename = articlename.decode('utf-8')
    return articlename


def convertfile(infile, outfile):
    root = ET.Element('items')
    with open(infile, 'rU') as ifp:
        csvreader = csv.reader(ifp)
        csvreader.next()
        for row in csvreader:
            row = [i.decode('CP1252') for i in row]
            ET.SubElement(root, 'item', id=row[0],
                          name=row[1],
                          wikipedia=canonicalize_wiki_url(
                              row[2]))
    ET.ElementTree(root).write(outfile, 'utf-8')

if __name__ == '__main__':
    convertfile(*sys.argv[1:3])
