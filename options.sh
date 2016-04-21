#!/bin/bash

usage()
{
cat << EOF
usage:

This script used for test

OPTIONS:
-h	Show this message
-d	Backup database file
-f	Backup regular file
EOF

}

#pasrse
while getopts "df" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
		;;
		d)
			timestamp=$ date "+%Y-%m-%d_%H:%M:%S:%N"
			#echo "$timestamp"
			exit 1
		;;
		f)
			echo "choose f"
			exit 1
		;;
		?)
			usage
			exit 1

	esac
done


