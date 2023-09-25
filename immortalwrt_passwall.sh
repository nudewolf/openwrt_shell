#!/usr/bin/env bash

INPUT=$1
if [ "${INPUT: -1}" = "/" ]; then
    INPUT=${INPUT%?}
fi

CURRENT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

cd "$CURRENT_DIR/$INPUT" || exit

if [ ! -f ./scripts/feeds ]; then
    echo " $INPUT is not openwrt"
    exit 1
fi

#VERSION=$(echo "${INPUT}" | sed 's/immortalwrt-//')
VERSION=${INPUT//immortalwrt-/}

#VERSION=$(echo "${VERSION}" | sed 's/src\///')
VERSION=${VERSION//src\//}

ln -snf ~/openwrt/dl .
ln -snf ~/openwrt/build_dir .
ln -snf ~/openwrt/staging_dir .

read -r -p "Replace PassWall ? [Y/n] " input
case $input in
[yY][eE][sS] | [yY])
    if [ ! -d feeds ]; then
        mkdir feeds
    fi
    ln -snf ~/openwrt/feeds/passwall feeds/passwall
    ln -snf ~/openwrt/feeds/passwall_packages feeds/passwall_packages

    cp feeds.conf.default feeds.conf

    # 将 immortalwrt 内置 passwall 替换成最新版本
    echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >>"feeds.conf"
    echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >>"feeds.conf"

    ./scripts/feeds update -a

    # 删除 feeds/packages 目录下与 passwall 重复组件
    cd feeds/passwall_packages || exit

    find "$CURRENT_DIR"/"$INPUT"/feeds/packages/net -maxdepth 1 -type d | awk -v FS='/' '{print $NF}' | xargs rm -rf

    rm -rf ../../luci/applications/luci-app-passwall

    cd "$CURRENT_DIR"/"$INPUT" || exit

    # 删除 无效软链接
    find . -xtype l -exec rm {} \; 2>/dev/null

    wget https://downloads.immortalwrt.org/releases/"${VERSION}"/targets/x86/64/config.buildinfo -O .config
    ;;
esac
