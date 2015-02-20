#!/bin/sh
wget http://www.crosswire.org/svn/sword-tools/trunk/modules/python/usfm2osis.py
wget http://www.crosswire.org/svn/sword-tools/trunk/modules/crossreferences/xreffix.pl
wget http://www.crosswire.org/svn/sword-tools/trunk/modules/conf/confmaker.pl

chmod +x usfm2osis.py xreffix.pl confmaker.pl
git add usfm2osis.py xreffix.pl confmaker.pl
git commit -m "Scripts fetched" usfm2osis.py xreffix.pl confmaker.pl
