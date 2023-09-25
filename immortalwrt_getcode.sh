#!/usr/bin/env bash
INPUT=$1

if [ ! -d src ]; then
    mkdir src
fi

if ! wget -P src https://github.com/immortalwrt/immortalwrt/archive/refs/tags/"${INPUT}"; then
    exit 1
fi

cd src || exit

if ! tar -xvf "${INPUT}"; then
    exit 1
fi

rm "${INPUT}"
