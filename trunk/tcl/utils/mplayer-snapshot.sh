#!/bin/sh

## Make a snapshot of a video
## Syntax is "mplayer-snapshot.sh video.filename [snapshot.filename [position in seconds]]"

if [ $# -ge 1 ]
then
	COMMAND="mplayer"
	FILEFORMAT="-vo png -z 5"
	DELAY="-ss 2"
	SNAPSHOT="$1.png"

	# manage additionnal parameters
	if [ $# -ge 2 ]
	then
		SNAPSHOT=$2
		if [ $# -ge 3 ]
		then
			DELAY="-ss $3"
		fi
	fi

	# take a snapshot if there isn't any existing one
	if [ ! -e $SNAPSHOT ]
	then
		COMMAND="$COMMAND $DELAY $1 $FILEFORMAT -nosound -frames 2 1>/dev/null 2>/dev/null"

		#echo $COMMAND
		eval $COMMAND
		if [ -e 00000002.png ]
		then
				mv 00000002.png $SNAPSHOT
			rm 00000001.png -f
		fi
	fi
fi

# output the filename
if [ -e $SNAPSHOT ]
then
	echo $SNAPSHOT
fi
