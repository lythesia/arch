#!/usr/bin/env python3

import re
import sys
import optparse
import os
from urllib.request import urlopen
from bs4 import BeautifulSoup as bs 
from progressbar import Bar, ETA, FileTransferSpeed, Percentage, ProgressBar, Timer

# stable globals
url_base = 'http://h.acfun.tv'
rule = r'/Images/Upload/[^ ]+\.(jpg|png|gif)'
encoding = 'utf-8'
save_base_path = os.path.join(os.environ['HOME'], 'Downloads')
count = 0
pack_size = 1024 # in bytes

def grab(url, rule):
  page = bs(urlopen(url).read())
  result = page.find_all('a', href=re.compile(rule))
  return result

def dump(items, save_folder, show):
  global count
  parent_path = os.path.join(save_base_path, save_folder)
  if not os.path.exists(parent_path):
    os.makedirs(parent_path)
  for i in items:
    try:
      res = urlopen(url_base + i['href'])
      filename = os.path.join(parent_path, i['href'].split('/')[-1])
      if show:
        size = int(res.headers.get('Content-Length'))
        widgets = [' Item-{0:0>4d}: '.format(count), Percentage(), ' ', 
            Bar(marker='#', left='[', right=']'), ' ', ETA(), ' ', FileTransferSpeed()]
        with open(filename, 'wb') as fh:
          pbar = ProgressBar(widgets=widgets, maxval=size)
          pbar.start()
          currval = 0
          while True:
            chunk = res.read(pack_size)
            if not chunk:
              break
            fh.write(chunk)
            currval += len(chunk)
            pbar.update(currval)
          pbar.finish()
        res.close()
      else:
        with open(filename, 'wb') as fh:
          while True:
            chunk = res.read(pack_size)
            if not chunk:
              break
            fh.write(chunk)
        res.close()
        print('Item-{0:0>4d} Down.'.format(count))
      count += 1
    except Exception as err:
      print(err)
      return

def main():
  usage = "usage: %prog -t URL [-s START] [-e END] -f folder [-p]"
  parser = optparse.OptionParser(usage)
  parser.add_option("-t", "--target", dest="post_url", type="string", help="target post to download pics", metavar="POST")
  parser.add_option("-s", "--start", dest="start", type="int", default=1, help="start page number", metavar="START")
  parser.add_option("-e", "--end", dest="end", type="int", default=-1, help="end page number", metavar="END")
  parser.add_option("-f", "--folder", dest="save_folder", type="string", help="save path(under $HOME/Downloads/)", metavar="PATH")
  parser.add_option("-p", "--progress", action="store_true", dest="show_pbar", default=False, help="if show download progress")

  (options, args) = parser.parse_args()
# handle excepts
  if not (options.post_url or options.save_folder):
    parser.error("You must specify URL and SAVE-PATH")

# normalize post_url
  options.post_url = options.post_url.split('?')[-2]

# adjust (start, end)
  if options.end == -1:
    res = urlopen(options.post_url)
    temp = bs(res.read())
    options.end = int(temp.find('a', text='最后页')['href'].split('=')[-1])
    res.close()
  elif options.start > options.end:
    parse.error("You must make START <= END")

# display info
  print('POST: ', options.post_url, ' [{0:0>4d} - {0:0>4d}]'.format(options.start, options.end))
  print('SAVETO: ', '$HOME/Downloads/' + options.save_folder)

# iter dump
  for pn in range(options.start, options.end+1):
    dump(grab(options.post_url + '?pn=' + str(pn), rule), options.save_folder, options.show_pbar)
  print('Complete.')

if __name__ == '__main__':
  main()
