#!/usr/bin/python2

import os
import sys
import zipfile
 
nam=sys.argv[1]
pwd=''
if len(sys.argv) > 2:
  pwd=sys.argv[2]

print "Processing File " + nam
 
file=zipfile.ZipFile(nam,"r");
for name in file.namelist():
    utf8name=name.decode('gbk')
    print "Extracting " + utf8name
    pathname = os.path.dirname(utf8name)
    if not os.path.exists(pathname) and pathname!= "":
        os.makedirs(pathname)
    data = file.read(name, pwd)
    if not os.path.exists(utf8name):
        fo = open(utf8name, "w")
        fo.write(data)
        fo.close()
file.close()
