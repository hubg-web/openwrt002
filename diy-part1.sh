#!/bin/bash
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)

set -euo pipefail

# 1) 自动定位 feeds.conf.default
FEEDS_FILE="feeds.conf.default"
if [ ! -f "$FEEDS_FILE" ] && [ -f "openwrt/feeds.conf.default" ]; then
  FEEDS_FILE="openwrt/feeds.conf.default"
fi

echo "[diy-part1] using: $FEEDS_FILE"

# 2) 先删除可能已存在的同名源（保证幂等）
sed -i '/^[[:space:]]*src-git[[:space:]]\+helloworld[[:space:]]/d' "$FEEDS_FILE"
sed -i '/^[[:space:]]*#\?[[:space:]]*src-git[[:space:]]\+helloworld[[:space:]]/d' "$FEEDS_FILE"
# 如果以后要加 passwall，也先删掉旧行（现在先不加）
sed -i '/^[[:space:]]*src-git[[:space:]]\+passwall[[:space:]]/d' "$FEEDS_FILE"
sed -i '/^[[:space:]]*#\?[[:space:]]*src-git[[:space:]]\+passwall[[:space:]]/d' "$FEEDS_FILE"

# 3) 只追加一次你需要的源
echo "src-git helloworld https://github.com/fw876/helloworld" >> "$FEEDS_FILE"
# 如需 passwall，取消下一行注释
# echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall" >> "$FEEDS_FILE"

# 4) 打印确认
echo "----- final $FEEDS_FILE -----"
tail -n +1 "$FEEDS_FILE"
