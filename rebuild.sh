#!/usr/bin/env bash
bak_config()
{
    newconfig=$CURRENT_DIR/$INPUT/bin/targets/x86/64/config.buildinfo

    INPUT=$(echo "${INPUT}" | sed 's/src\///')
    local SMALL_VER=echo "${INPUT:0-2}"
    if [ "${SMALL_VER}" -gt 0 ] 2>/dev/null ;then
        local CONF_FIX=${INPUT::-2}
    else
        local CONF_FIX=${INPUT}
    fi

    CONF_DIR=$CURRENT_DIR/config/${CONF_FIX}

    curconfig=${CONF_FIX}_defconf
    bakconfig=${curconfig}_$(date "+%Y-%m-%d_%H:%M")

    if ! diff -uEZbBw "$CONF_DIR"/"$curconfig" "$newconfig" 2>/dev/null ;then
        if read -n 1 -t 5 -rp "Config changed, Backup it now? [Y/n] " input; then
            case $input in
                [yY][eE][sS]|[yY])
                        if [ ! -d "$CONF_DIR" ]; then
                            mkdir -p "$CONF_DIR"
                        fi
                        cd "$CONF_DIR/" || exit
                        cp "$newconfig" "$bakconfig"
                        ln -snf "$bakconfig" "$curconfig"
                ;;
            esac
        fi
    fi
}

init()
{
    echo "No target found, Init one? 1)immortalwrt 2)lede 3)openwrt 4)quit"
    read -r n
    case $n in
        1)
            repo="https://github.com/immortalwrt/immortalwrt"
            dir="src/immortalwrt"
            config="https://downloads.immortalwrt.org/snapshots/targets/x86/64/config.buildinfo";;
        2)
            repo="https://github.com/coolsnowwolf/lede"
            dir="src/lede";;
        3)
            repo="https://git.openwrt.org/openwrt/openwrt.git"
            dir="src/openwrt"
            config="https://downloads.openwrt.org/snapshots/targets/x86/64/config.buildinfo" ;;
        4) exit 0 ;;
        *)
            echo "USAGE: $0 target"
            echo " e.g.: $0 lede"
            exit 1;
        ;;
    esac

    if [ ! -d src ]; then
        mkdir src
    fi

    if ! git clone -b master --single-branch $repo $dir; then
        exit 1
    fi

    cd "$dir" || exit

    if [ ! -d ../../dl ]; then
        mkdir -p ../../dl
    fi
    ln -snf ../../dl .

    ./scripts/feeds update -a && ./scripts/feeds install -a

    if [ -n "$config" ]; then
        wget https://downloads.immortalwrt.org/snapshots/targets/x86/64/config.buildinfo -O .config
    fi

    read -r -p "Add Passwall Feeds ? [Y/n] " input
    case $input in
        [yY][eE][sS]|[yY])
            echo 'Modify Default Feeds...'
            cp feeds.conf.default feeds.conf
            echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall.git;packages" >> "feeds.conf"
            echo "src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;luci" >> "feeds.conf"

            if [ ! -d ../../feeds/passwall_luci ] ; then
                mkdir -p ../../feeds/passwall_luci
            fi

            if [ ! -d ../../feeds/passwall_packages ] ; then
                mkdir -p ../../feeds/passwall_packages
            fi

            ln -snf ../../feeds/passwall_luci feeds/passwall_luci
            ln -snf ../../feeds/passwall_packages feeds/passwall_packages

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
    if read -n 1 -t 10 -rp "Build Image now? [Y/n] " input; then
        case $input in
            [yY][eE][sS]|[yY])
                echo -e '\nBuilding Image Now, Please Wait...'

                if ! make -j1 V=s defconfig download clean world ;then
                    exit 1
                fi
            ;;
        esac
    fi
}

if [ $# -ne 1 ] ; then
    init
    exit 0
fi

INPUT=$1
if [ "${INPUT: -1}" = "/" ]; then
    INPUT=${INPUT::-1}
fi

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

cd "$CURRENT_DIR/$INPUT" || exit

if [ ! -f ./scripts/feeds ];then
    echo " $INPUT is not openwrt"
    exit 1
fi

if [ -d .git ]; then
    echo 'Update Openwrt Source...'
    if ! git pull; then
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

            if ! make "-j$(nproc) defconfig world";then
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
            passwall=$(find package/feeds/ -name "luci-app-passwall")
            if [ -z "$passwall" ];then
                echo -e "Passwall not found\n"
                exit 1
            fi
            make "$passwall/{clean,compile}"
        ;;
    esac
fi
printf '\n'
