#!/bin/bash
# I used to have template ending with tmpl. It was a bad idea
# as tmpl is a filetype. I created this function to convert
# all template with the good .template extension
TEMPLATE=/home/ludo/source/mana/skel/template
for dir in ${TEMPLATE}/*;
do
	for fdir in $dir $dir/fr;
	do
		for file in ${fdir}/*.tmpl;
		do
			mv "$file" "${file%.tmpl}.template";
		done;
	done;
done
