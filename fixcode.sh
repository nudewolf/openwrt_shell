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

cd $CURRENT_DIR/$INPUT

if [ ! -f ./scripts/feeds ];then
    echo " $INPUT is not openwrt"
    exit 1
fi

if [ -d .git ]; then
    echo 'Reset Openwrt Source...'
    git fetch --all && git clean -df && git reset --hard

    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo -e '***Done***\n'

    read -r -p "Modify Default IP ? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo 'Modify Default IP...'
            sed -i "s/192.168.1.1/10.0.0.2/;s/192.168/10.0/" package/base-files/files/bin/config_generate

            echo -e '***Done***\n'
        ;;
    esac

    if [ ! -L files ] && [ -d $CONF_DIR/files ]; then
        read -r -p "Found custom config files, use it? [Y/n]" input
        case $input in
            [yY][eE][sS]|[yY])
                echo 'Add custom config files...'
                ln -sf $CONF_DIR/files

                echo -e '***Done***\n'
            ;;
        esac
    fi
fi
