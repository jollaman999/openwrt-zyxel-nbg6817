#!/bin/sh

help()
{
	echo "Usage imgAlignment <file> <size> [align|pad]"
}

if [ $# -lt 2 ]; then
	help
	exit -1
fi

if [ ! -e $1 ]; then
	echo "\"$1\" not found!\n"
	exit -2
fi

AlignImage=y
if [ ! -z $3 ] && [ $3 != align ] ; then
	AlignImage=n
fi


OrigFileSize=`stat -c %s $1`
if [ $AlignImage = y ]; then
	# align image
	if [ $(($OrigFileSize & ($2 - 1))) == 0 ]; then
		ExpectSize=$OrigFileSize
	else
		ExpectSize=$((($OrigFileSize | ($2 - 1)) + 1))
	fi
else
	# pad image
	if [ $2 -gt $OrigFileSize ]; then
		ExpectSize=$2
	else
		ExpectSize=$OrigFileSize
	fi
fi
PaddingSize=$(($ExpectSize - $OrigFileSize))

echo "OrigFileSize=$OrigFileSize ExpectSize=$ExpectSize PadSize=$PaddingSize"

if [ $PaddingSize -gt 0 ]; then
	dd if=/dev/zero bs=$PaddingSize count=1 | tr '\000' '\377' >>$1
fi
