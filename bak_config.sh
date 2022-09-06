#!/usr/bin/env bash
if [ $# != 1 ] ; then
    echo "USAGE: $0 target"
    echo " e.g.: $0 lede"
    exit 1;
fi

if [ ! -d $1 ]; then
    echo "$1 not found! Please check it..."
    exit 1;
fi

INPUT=$1
if [ `echo ${INPUT: -1}` = "/" ]; then
    INPUT=`echo ${INPUT%?}`
fi

CURRENT_DIR=$(cd $(dirname $0); pwd)
CONF_DIR=$CURRENT_DIR/config_bak

if [ ! -d $CONF_DIR ]; then
    mkdir $CONF_DIR
fi

configfile=${INPUT}_config_$(date "+%Y-%m-%d_%H:%M")
cp $CURRENT_DIR/$INPUT/.config $CONF_DIR/$configfile
