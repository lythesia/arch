#!/usr/bin/env python3

import re
import sys
import optparse
import os
from urllib.request import urlopen
from progressbar import Bar, ETA, FileTransferSpeed, Percentage, ProgressBar, Timer

# stable globals
encoding = 'utf-8'
save_base_path = os.path.join(os.environ['HOME'], 'Downloads')
pack_size = 1024 # in bytes

def grab(url, enc, begin_mark, end_mark, rule):
	'''
	grab image's url according to specified rule
	'''
	page = urlopen(url)
	result = []
	in_pos = False
	pattern = re.compile(rule)

	for line in page:
		line = line.decode(enc)
		# enter main_area
		if begin_mark in line:
			in_pos = True
		# processing grab
		if in_pos:
			match = pattern.search(line)
			if match:
				obj = match.group('obj')
				# image found
				if obj:
					result.append(obj)
		# leave main_area
		if end_mark in line:
			in_pos = False
			break
	page.close()
	return result


def dump(items, save_folder):
	'''
	dump image to disk from url-list
	'''
	parent_path = os.path.join(save_base_path, save_folder)
	if(not os.path.exists(parent_path)):
		os.makedirs(parent_path)
	count = 0
	for item in items:
		try:
			res = urlopen(item)
			size = int(res.headers.get('Content-Length'))
			widgets = [' Item-{0:0>2d}: '.format(count), Percentage(), ' ', Bar(marker='#',left='[',right=']'), ' ', ETA(), ' ', FileTransferSpeed()]
			filename = os.path.join(parent_path, item.split('/')[-1])
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
			count += 1
		except Exception as err:
			print(err)
			return


def main():
	'''
	main enter to grab Acfun images
	'''
	usage = "usage: %prog -t acfun-site -f folder"
	parser = optparse.OptionParser(usage)
	parser.add_option("-t", "--target", dest="url", type="string", help="target site to download pics")
	parser.add_option("-f", "--folder", dest="save_folder", type="string", help="save path(under ~/Downloads/) of pics")

	(options, args) = parser.parse_args()

	if len(sys.argv) != 5:
		parser.error("Incorrect number of arguments!")

	print("Target Site: " + options.url)
	print("Save Folder: " + options.save_folder)

	# locals
	begin = '<div id="area-player">'
	end = '<div id="area-tag">'
	rule = r'<img\s+alt=""\s+src="(?P<obj>http://[^ ]+[.](?:jpg|png|gif))".+/>'

	# processing
	items = grab(options.url, encoding, begin, end, rule)
	dump(items, options.save_folder)
	print("Complete.")


if __name__ == '__main__':
	main()
