#!/usr/bin/env bash
INPUT=$1

if [ ! -d src ]; then
        mkdir src
fi

wget -P src https://github.com/immortalwrt/immortalwrt/archive/refs/tags/${INPUT}

if [ $? -ne 0 ]; then
    exit 1
fi

cd src

tar -xvf ${INPUT} 

if [ $? -ne 0 ]; then
    exit 1
fi

rm ${INPUT}

