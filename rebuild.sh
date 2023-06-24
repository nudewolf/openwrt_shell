#!/usr/bin/env bash
bak_config()
{
    if read -n 1 -t 5 -rp "Backup config file now? [Y/n] " input; then
        case $input in
            [yY][eE][sS]|[yY])
                CONF_DIR=~/openwrt/common/config/${INPUT}
                newconfig=./bin/targets/x86/64/config.buildinfo
                bakconfig=${INPUT}_defconf_$(date "+%Y-%m-%d_%H:%M")

                diff -uEZbBw $CONF_DIR/${INPUT}_defconf $newconfig 2>/dev/null
                if [ $? -ne 0 ];then
                    if [ ! -d $CONF_DIR ]; then
                        mkdir -p $CONF_DIR
                    fi

                    cp $newconfig $CONF_DIR/$bakconfig
                    ln -snf $CONF_DIR/$bakconfig $CONF_DIR/${INPUT}_defconf
                    echo -e '\n***Backup Done***'
                else
                    echo -e '\nThe same configuration file already exists'
                fi
            ;;
        esac
    fi
}

init()
{
    echo "No target found, Init one? 1)immortalwrt 2)lede 3)openwrt 4)quit"
    read n
    case $n in
        1)
            repo="https://github.com/immortalwrt/immortalwrt"
            dir="immortalwrt"
            config="https://downloads.immortalwrt.org/snapshots/targets/x86/64/config.buildinfo";;
        2)
            repo="https://github.com/coolsnowwolf/lede"
            dir="lede";;
        3)
            repo="https://git.openwrt.org/openwrt/openwrt.git"
            dir="openwrt"
            config="https://downloads.openwrt.org/snapshots/targets/x86/64/config.buildinfo" ;;
        4) exit 0 ;;
        *)
            echo "USAGE: $0 target"
            echo " e.g.: $0 lede"
            exit 1;
        ;;
    esac

    git clone -b master --single-branch $repo $dir
    if [ $? -ne 0 ]; then
        exit 1
    fi

    cd $dir

    if [ ! -d ~/openwrt/common/dl ]; then
        mkdir -p ~/openwrt/common/dl
    fi
    ln -snf ~/openwrt/common/dl

    ./scripts/feeds update -a && ./scripts/feeds install -a

    if [ -n $config ]; then
        wget https://downloads.immortalwrt.org/snapshots/targets/x86/64/config.buildinfo -O .config
    fi

    read -r -p "Add Passwall Feeds ? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo 'Modify Default Feeds...'
            cp feeds.conf.default feeds.conf
            echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall.git;packages" >> "feeds.conf"
            echo "src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;luci" >> "feeds.conf"

            if [ ! -d ~/openwrt/common/fees/passwall_luci ] ; then
                mkdir -p ~/openwrt/common/fees/passwall_luci
            fi

            if [ ! -d ~/openwrt/common/fees/passwall_packages ] ; then
                mkdir -p ~/openwrt/common/fees/passwall_packages
            fi

            ln -snf ~/openwrt/common/feeds/passwall_luci feeds/passwall_luci
            ln -snf ~/openwrt/common/feeds/passwall_packages feeds/passwall_packages

            ./scripts/feeds update passwall_luci
            ./scripts/feeds update passwall_packages
            ./scripts/feeds install -a -p passwall_packages
            ./scripts/feeds install -a -p passwall_luci
            echo -e '***Done***\n'
        ;;
    esac

    read -r -p "Modify Default IP ? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo 'Modify Default IP...'
            sed -i "s/192.168.1.1/10.0.0.2/;s/192.168/10.0/" package/base-files/files/bin/config_generate

            echo -e '***Done***\n'
        ;;
    esac

    make menuconfig
    make -j1 V=s defconfig download clean world
}

if [ $# -ne 1 ] ; then
    init
    exit 0
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
    echo 'Update Openwrt Source...'
    git pull
    if [ $? -ne 0 ]; then
        exit 1
    fi
    printf '\n'
fi

echo 'Update Feeds...'
./scripts/feeds update -a && ./scripts/feeds install -a
echo -e '***Done***\n'

# read -n 1 -s -p "Press any key to continue..."
if read -n 1 -t 10 -rp "Rebuild Image now? [Y/n] " input; then
    case $input in
        [yY][eE][sS]|[yY])
            echo -e '\nRebuilding Image Now, Please Wait...'
            make -j$(nproc) defconfig world
            if [ $? -ne 0 ];then
                exit 1
            fi

            bak_config
            printf '\n'
            exit 0
        ;;
    esac
fi
printf '\n'

if read -n 1 -t 10 -rp "Rebuild F**GFW now? [Y/n] " input; then
    case $input in
        [yY][eE][sS]|[yY])
            echo -e '\nRebuilding F**GFW Now, Please Wait...'
            passwall=`find package/feeds/ -name "luci-app-passwall"`
            if [ -z $passwall ];then
                echo -e "Passwall not found\n"
                exit 1
            fi
            make $passwall/{clean,compile}
        ;;
    esac
fi
printf '\n'
