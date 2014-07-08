#!/usr/bin/env python3

# Dependency: python-lxml
# 
# Use '-h' for help
#

import sys
import os
import argparse

from urllib.request import urlopen 
from lxml.html import fromstring
from pickle import dump, load

# stable globals
encoding = 'utf-8'
xpath_rule = '//table//img/../@href'
save_path_base = os.path.join(os.environ['HOME'], 'Downloads')
cache_file = '.url_cache'
pack_size = 1024

def grb(thread, start, end):
  '''
  xpath grab to dictionary
  '''
  result = {}
  for pn in range(start, end+1):
    page = urlopen(thread + '?pn=' + str(pn))
    doc = fromstring(page.read().decode(encoding), base_url=thread)
    doc.make_links_absolute()
    result[pn] = doc.xpath(xpath_rule)
    page.close()
  return result

def dmp(urls, save_folder):
  '''
  iter dump wrapper with noooob cache control
  '''
  global cache_file

  parent_path = os.path.join(save_path_base, save_folder)
  if not os.path.exists(parent_path):
    os.makedirs(parent_path)

  cache_buf = {}
  cache_file = os.path.join(parent_path, cache_file)
  try:
    with open(cache_file, 'rb') as fh:
      cache_buf = load(fh)
  except IOError:
    print('No cache <{}> found.'.format(cache_file))
    pass

  cur, skip = 0, 0
  try:
    for(pn, lst) in urls.items():
      print('Page {0:0>4d}: '.format(pn))
      for i in lst:
        if pn in cache_buf and i in cache_buf[pn]:
          skip += 1
          continue
        elif pn not in cache_buf:
          cache_buf[pn] = []

        fname = os.path.join(parent_path, '{:04d}_{:04d}.{}'.format(pn, cur+skip, i.split('.')[-1]))
        dmp_aux(i, fname)
        cur += 1
        cache_buf[pn].append(i)
  except KeyboardInterrupt:
    sys.stderr.write('\nUser interrupted.\n')
    exit(1)
  finally:
    with open(cache_file, 'wb') as fh:
      dump(cache_buf, fh)

  print('{} pic(s) done, {} pic(s) skipped.'.format(cur, skip))


def dmp_aux(url, path):
  '''
  do dump with noooob progress bar monitored
  '''
  try:
    res = urlopen(url)
    size = int(res.headers.get('Content-Length'))
    with open(path, 'wb') as fh:
      curval = 0
      while True:
        chunk = res.read(pack_size)
        if not chunk:
          break
        fh.write(chunk)
        curval += len(chunk)
        perc = int(curval*1.0/size*100)
        info = ' Pic {}: '.format(path.split('/')[-1])
        width, fill = 40, int(perc/100*40)
        sys.stderr.write(info)
        sys.stderr.write('[{}{}] {:>3d}%\r'.format(fill*'#', (width - fill)*'-', perc))
        sys.stderr.flush()
      sys.stderr.write('\n')
    res.close()
  except Exception as err:
    print(err)
    return

def main():
  parser = argparse.ArgumentParser(description='Grab pics from <h.acfun.tv> threads')
  parser.add_argument('url', help='target thread url to grab pics', metavar='URL')
  parser.add_argument('-s', '--start', dest='start', type=int, default=1, help='start page number', metavar='START')
  parser.add_argument('-e', '--end', dest='end', type=int, default=-1, help='end page number', metavar='END')
  parser.add_argument('-f', '--folder', dest='save_folder', default='', help='save path(under $HOME/Downloads/)', metavar='FOLDER')

  args = parser.parse_args()
# required url
  if not args.url:
    parser.error('You must specify URL')
# normalize url
  if '?' in args.url:
    args.url = args.url.split('?')[-2]

# adjust (start, end)
  if args.end == -1:
    tp = urlopen(args.url)
    td = fromstring(tp.read().decode(encoding), args.url)
    args.end = int(td.xpath('//table[@border="1"]//td[last()]/a/@href')[0].split('=')[-1])
    tp.close()
  elif args.start > args.end:
    parser.error('You must make START <= END')

# info
  print('thread: {}    page:[{:0>3d} - {:0>3d}]'.format(args.url, args.start, args.end))
  print('saveto: {}'.format(os.path.join(save_path_base, args.save_folder)))

# iter dump
  result = grb(args.url, args.start, args.end)
  dmp(result, args.save_folder)

if __name__ == '__main__':
  main()

# vim: set ft=python:
