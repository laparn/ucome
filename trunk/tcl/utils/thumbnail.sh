#!/bin/sh
## syntax : thumbnail.sh picture.filename thumbnail.filename [resolution]

if [ $# -ge 2 ]
then
	FILENAME=$1
	MINIATURE=$2
	RESOLUTION="80x80"
    
        if [ $# -ge 3 ]
	then
	    RESOLUTION=$3
        fi
	
	if [ ! -e $MINIATURE ]
	then
	    convert $FILENAME -colors 256 -resize $RESOLUTION $MINIATURE
	fi
fi
