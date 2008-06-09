#!/bin/sh

if [ $# -ge 1 ]
then
	echo `mplayer -ao null -vo null -frames 1 -identify $1 2>/dev/null | grep "ID_LENGTH" | cut -f2 -d"="`
else
	echo "0"
fi
