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
CONF_DIR=$CURRENT_DIR/config_bak/${INPUT}

if [ ! -d $CONF_DIR ]; then
    mkdir -p $CONF_DIR
fi

configfile=${INPUT}_config_$(date "+%Y-%m-%d_%H:%M")

diff -uEZbBw $CONF_DIR/${INPUT}_config $CURRENT_DIR/$INPUT/.config 2>/dev/null

if [ $? -ne 0 ];then
    cp $CURRENT_DIR/$INPUT/.config $CONF_DIR/$configfile >/dev/null 2>&1
    if [ $? -eq 0 ];then
        ln -snf $CONF_DIR/$configfile $CONF_DIR/${INPUT}_config
        echo "Backup full config success"
    else
        echo "Backup full config fail"
    fi
else
    echo "The same configuration file already exists"
fi
