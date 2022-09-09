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
echo 'Reset Openwrt Source...'

./scripts/feeds clean
if [ $? -ne 0 ];then
    echo " $INPUT is not openwrt"
    exit 1
fi

git fetch --all && git reset --hard origin/HEAD && git pull

echo -e '***Done***\n'

read -r -p "Modify Default Feeds ? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
		echo 'Modify Default Feeds...'
		sed -i "/helloworld/d" "feeds.conf.default"
		echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"
		sed -i "/openclash/d" "feeds.conf.default"
		echo "src-git openclash https://github.com/vernesong/OpenClash.git" >> "feeds.conf.default"
		#sed -i "/passwall/d" "feeds.conf.default"
		#echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git" >> "feeds.conf.default"
		#sed -i "/passwall2/d" "feeds.conf.default"
		#echo "src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git" >> "feeds.conf.default"
		echo -e '***Done***\n'
		;;

	[nN][oO]|[nN])
		exit 0
		;;

	*)
		echo "Invalid input..."
		exit 1
		;;
esac

read -r -p "Modify Default IP ? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
		echo 'Modify Default IP...'
		sed -i "s/192.168.1.1/10.0.0.2/;s/192.168/10.0/" package/base-files/files/bin/config_generate

		echo -e '***Done***\n'
		;;

	[nN][oO]|[nN])
		exit 0
		;;
	
	*)
		echo "Invalid input..."
		exit 1
		;;
esac
