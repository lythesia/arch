#!/usr/bin/env python2

import sys
import os
import argparse
import zipfile


def main():
  parser = argparse.ArgumentParser(description='Unzip files compressed under non-utf8 env')
  parser.add_argument('file', default=[], nargs='+', help='zip files')
  parser.add_argument('-d', '--decode', dest='decode', type=str, default='gbk', help='specify decode(default: gbk)')
  parser.add_argument('-p', '--passwd', dest='passwd', type=str, default=None, help='specify password')
  parser.add_argument('-l', '--list', help='only list files', action='store_true')

  args = parser.parse_args()
  if not args.file:
    parser.exit(message='No file(s) to process.')

  for fname in args.file:
    zfile = zipfile.ZipFile(fname, 'r')
    zfile.setpassword(args.passwd)
    for iname in zfile.namelist():
      utf8name = iname.decode(args.decode)
      if args.list:
        print '>> [%s]' % utf8name
      else:
        print 'Extracting %s ..' % utf8name
        pathname = os.path.dirname(utf8name)
        if not os.path.exists(pathname) and pathname != '':
          os.makedirs(pathname)
        #data = zfile.read(iname, pwd=args.passwd)
        data = zfile.read(iname)
        if not os.path.exists(utf8name):
          fo = open(utf8name, 'w')
          fo.write(data)
          fo.close()
    zfile.close()

if __name__ == '__main__':
  main()
