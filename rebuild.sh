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
CONF_DIR=$CURRENT_DIR/config_bak/$INPUT

cd $CURRENT_DIR/$INPUT

if [ ! -d package ] || [ ! -d scripts ] || [ ! -d  tools ]; then
    echo "$INPUT not found openwrt! Please check it ..."
    exit 1;
fi

if [ -d .git ]; then
    echo 'Update Openwrt Source...'
    git pull
    if [ $? -ne 0 ]; then
        exit 1
    fi
    printf '\n'
fi

echo -e 'Update Feeds...'
if [ -d .git ]; then
    ./scripts/feeds update -a && ./scripts/feeds install -a
else 
    if [ -L feeds/passwall_luci ]; then
        ./scripts/feeds update passwall_luci
        ./scripts/feeds install -a -p passwall_luci
    fi

    if [ -L feeds/passwall_packages ]; then
        ./scripts/feeds update passwall_packages
        ./scripts/feeds install -a -p passwall_packages
    fi
fi
echo -e '***Done***\n'

# read -n 1 -s -p "Press any key to continue..."
if read -n 1 -t 10 -rp "Rebuild now? [Y/n] " input; then
    case $input in
        [yY][eE][sS]|[yY])
            echo -e '\nRebuilding Now, Please Wait...'
            make -j$(nproc) defconfig world
            if [ $? -ne 0 ];then
                echo " make  -- error"
                exit 1
            fi
        ;;
    esac
fi
printf '\n'

if read -n 1 -t 5 -rp "Backup config file now? [Y/n] " input; then
    case $input in
        [yY][eE][sS]|[yY])
            configfile=${INPUT}_defconf_$(date "+%Y-%m-%d_%H:%M")
            ./scripts/diffconfig.sh > /tmp/$configfile
            if [ $? -ne 0 ];then
                echo '\n./scripts/diffconfig.sh error, please check!'
                exit 1
            fi

            diff -uEZbBw $CONF_DIR/${INPUT}_defconfig /tmp/$configfile 2>/dev/null
            if [ $? -ne 0 ];then
                if [ ! -d $CONF_DIR ]; then
                    mkdir -p $CONF_DIR
                fi

                mv /tmp/$configfile $CONF_DIR/
                ln -snf $CONF_DIR/$configfile $CONF_DIR/${INPUT}_defconf
                echo -e '\n***Backup Done***'
            else
                rm /tmp/$configfile
                echo -e '\nThe same configuration file already exists'
            fi
        ;;
    esac
fi

printf '\n'
