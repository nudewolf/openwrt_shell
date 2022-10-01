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

echo 'Update Openwrt Source...'
git pull
echo -e '***Done***\n'

echo 'Update Feeds...'
./scripts/feeds update -a && ./scripts/feeds install -a
echo -e '***Done***\n'

echo 'Now Check config...'
make defconfig
if [ $? -ne 0 ];then
    echo " make  -- error"
    exit 1
fi

# read -n 1 -s -p "Press any key to continue..."
if read -t 3 -rp "Do you want Rebuild ? [Y/n] " input; then
    case $input in
        [yY][eE][sS]|[yY])
            echo 'Now Clean temp Dir'
            rm -rf tmp
            echo -e '***Done***\n'

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
else
    printf "\n"
    exit 0
fi

if read -t 3 -rp "The build succeeded, Do you want Backup config? [Y/n] " input; then
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
else
    printf "\n"
fi

