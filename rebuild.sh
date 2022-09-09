e!/usr/bin/env bash
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

echo 'Now Clean temp Dir'
rm -rf tmp
echo -e '***Done***\n'

echo 'Update Openwrt Source...'
git pull
echo -e '***Done***\n'

echo 'Update Feeds...'
./scripts/feeds update -a && ./scripts/feeds install -a
echo -e '***Done***\n'

echo 'Now Check config...'
if [ ! -f .config ]; then
    if [ -L $CONF_DIR/${INPUT}_defconfig ]; then
        echo '.config not found, restore last config'
        cp $CONF_DIR/${INPUT}_defconfig .config
    else
        echo ".config not found, restore default config"
    fi
fi

make defconfig
if [ $? -ne 0 ];then
    echo " make  -- error"
    exit 1
fi

# read -n 1 -s -p "Press any key to continue..."
read -r -p "Do you want Rebuild ? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo 'Rebuilding Now, Please Wait...'
        make -j$(($(nproc) + 1)) V=s
        if [ $? -ne 0 ];then
            echo " make  -- error"
            exit 1
        fi
        ;;

    [nN][oO]|[nN])
        exit 0
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

read -r -p "The build succeeded, Do you want Backup config? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        configfile=${INPUT}_defconf_$(date "+%Y-%m-%d_%H:%M")
        ./scripts/diffconfig.sh > /tmp/$configfile
        if [ $? -ne 0 ];then
            echo "./scripts/diffconfig.sh error, please check!"
            exit 1
        fi

        diff -uEZbBw $CONF_DIR/${INPUT}_defconfig /tmp/$configfile 2>/dev/null

        if [ $? -ne 0 ];then
            echo '.config is change,Backup...'
            mv /tmp/$configfile $CONF_DIR/
            ln -snf $CONF_DIR/$configfile $CONF_DIR/${INPUT}_defconfig
        else
            echo "The same configuration file already exists"
            rm /tmp/$configfile
        fi
        ;;

    [nN][oO]|[nN])
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac
