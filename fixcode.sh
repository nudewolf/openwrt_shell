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

if [ ! -f ./scripts/feeds ];then
    echo " $INPUT is not openwrt"
    exit 1
fi

echo 'Reset Openwrt Source...'

git fetch --all && git reset --hard HEAD

echo -e '***Done***\n'

read -r -p "Modify Default Feeds ? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo 'Modify Default Feeds...'
        echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"
#       echo "src-git openclash https://github.com/vernesong/OpenClash.git" >> "feeds.conf.default"
        echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall.git;packages" >> "feeds.conf.default"
        echo "src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;luci" >> "feeds.conf.default"
        echo -e '***Done***\n'
        ;;

    [nN][oO]|[nN])
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

# read -r -p "Modify Default IP ? [Y/n] " input

# case $input in
#    [yY][eE][sS]|[yY])
#        echo 'Modify Default IP...'
#	    sed -i "s/192.168.1.1/10.0.0.2/;s/192.168/10.0/" package/base-files/files/bin/config_generate

#        echo -e '***Done***\n'
#	    ;;

#    [nN][oO]|[nN])
#        ;;
	
#    *)
#        echo "Invalid input..."
#        exit 1
#        ;;
# esac

read -r -p "Reset feeds? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo 'Reset feeds'
        ./scripts/feeds clean
        ./scripts/feeds update -a && ./scripts/feeds install -a
        echo -e '***Done***\n'

        if [ -L $CONF_DIR/${INPUT}_defconfig ]; then
            echo 'restore last config'
            cp $CONF_DIR/${INPUT}_defconfig .config
        else
            echo "restore default config"
        fi
        ;;

    [nN][oO]|[nN])
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac
