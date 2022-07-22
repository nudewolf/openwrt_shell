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

cd $CURRENT_DIR/$INPUT

echo 'Now Update Openwrt Source...'
git pull
echo -e '***Done***\n'

echo 'Now Update Feeds...'
./scripts/feeds update -a && ./scripts/feeds install -a
echo -e '***Done***\n'

echo 'Now Check config...'
if [ ! -f .config ]; then
    if [ -f $CONF_DIR/${INPUT}_defconfig ]; then
        echo '.config not found, restore last config'
        cp $CONF_DIR/${INPUT}_defconfig .config
    fi
fi

make defconfig
if [ $? -ne 0 ];then
    echo " make  -- Faile"
    exit 1
fi

configfile=${INPUT}_$(date "+%Y-%m-%d_%H:%M")
./scripts/diffconfig.sh > /tmp/$configfile
if [ $? -ne 0 ];then
    echo " $INPUT is not openwrt"
    exit 1
fi

diff -EZbBw /tmp/$configfile $CONF_DIR/${INPUT}_defconfig

if [ $? -ne 0 ];then
    echo '.config is change,Backup now...'
    mv /tmp/$configfile $CONF_DIR/
    ln -snf $CONF_DIR/$configfile $CONF_DIR/${INPUT}_defconfig
else
    rm /tmp/$configfile
fi

# read -n 1 -s -p "Press any key to continue..."
read -r -p "Do you want Rebuild ? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo 'Rebuilding Now, Please Wait...'
        make -j$(($(nproc) + 1)) V=s
        ;;

    [nN][oO]|[nN])
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac
