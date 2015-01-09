#!/bin/bash

while getopts "t:" arg; do
    case $arg in
        t)
            minutes=$OPTARG
            ;;
        ?)
            echo 'Usage: ttail -t $minutes $filename' >&2
            exit 3
            ;;
    esac
done

if [[ ( $# == 3 ) && ( $1 == '-t' ) ]];then
    :
else
    echo 'Usage: ttail -t $minutes $filename' >&2
    exit 3
fi


if [ "$minutes" -eq "$minutes" 2>/dev/null ];then
    :
else
    echo "$minutes is not a number." >&2
    echo 'Usage: ttail -t $minutes $filename' >&2
    exit 3
fi

filename=`python -c "import os,sys; print os.path.abspath(sys.argv[1])" ${!#}`
#echo $filename

if [ -f $filename ];then
    :
else
    echo "$filename: No such file" >&2
    exit 3
fi

if [ -f /var/run/follow.pid ]; then
    :
else
    echo "Follow is not running." >&2
    exit 3
fi

follow_conf='/etc/follow.conf'

points_dirname=`sed -n '/point/p' $follow_conf | sed "s/.*= '\(.*\)'.*/\1/g"`
pointname=$points_dirname/${filename//\//__}.point
#echo $pointname

if [ ! -f $pointname ]; then
    echo "$filename is not being followed." >&2
    exit 3
fi

points_count=$(( $minutes * 60 / 10 ))
#echo `tail -n $points_count $pointname`
lines_count=`tail -n $points_count $pointname | awk 'BEGIN{sum=0}{sum+=$1}END{print sum}'`
#echo $points_count, $lines_count

lines=`tail -n $lines_count $filename`
tail_exit_code=$?
if [ $tail_exit_code != 0 ]; then
    exit 2
else

    if [ `echo "$lines" | wc -l` -lt $lines_count ]; then
        echo "$filename: file truncated." >&2
        exit 1
    else
        if [ -n "$lines" ]; then
            echo "$lines"
        fi
    fi
fi
