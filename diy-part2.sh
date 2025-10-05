#!/bin/bash
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# 0) 定位 OpenWrt 源码根目录（优先 ./openwrt；否则取当前目录）
# ─────────────────────────────────────────────────────────────
OWRT="${PWD}/openwrt"
[ -d "$OWRT" ] || OWRT="${PWD}"
echo "→ Using OpenWrt source dir: $OWRT"

# ─────────────────────────────────────────────────────────────
# 1) 修改默认 IP（幂等，不会多次替换）
# ─────────────────────────────────────────────────────────────
CFG_GEN="${OWRT}/package/base-files/files/bin/config_generate"
if [ -f "$CFG_GEN" ]; then
  echo "→ Patching default LAN IP in: $CFG_GEN"
  # 仅当目标字符串存在时才替换
  if grep -q '192\.168\.1\.1' "$CFG_GEN"; then
    sed -i 's/192\.168\.1\.1/192\.168\.2\.1/g' "$CFG_GEN"
  else
    echo "  (i) default 192.168.1.1 not found, skip replace."
  fi
else
  echo "⚠️  $CFG_GEN not found, skip IP patch."
fi

# ─────────────────────────────────────────────────────────────
# 2) 修改默认主题 / 主机名（按需解注释）
# ─────────────────────────────────────────────────────────────
# LUCI_META="${OWRT}/feeds/luci/collections/luci/Makefile"
# if [ -f "$LUCI_META" ]; then
#   echo "→ Switching default theme to argon in: $LUCI_META"
#   sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$LUCI_META"
# fi
#
# echo "→ Patching hostname in: $CFG_GEN"
# sed -i 's/\(hostname='\''\)OpenWrt/\1P3TERX-Router/' "$CFG_GEN"

# ─────────────────────────────────────────────────────────────
# 3) 启用 360P2（HC5861B）USB：把 dts 中 usbphy/ehci/ohci 设为 "okay"
#    若节点不存在则追加；若为 disabled 则改为 okay（幂等）
# ─────────────────────────────────────────────────────────────
DTS_DIR="${OWRT}/target/linux/ramips/dts"
if [ -d "$DTS_DIR" ]; then
  DTS="$(grep -Rl 'hiwifi' "$DTS_DIR" | grep -E 'hc5861|hc5861b' | head -n1 || true)"
  if [ -n "${DTS:-}" ] && [ -f "$DTS" ]; then
    echo "→ Editing DTS: $DTS"

    # 已存在节点：把 disabled 改为 okay
    sed -i 's/\(&usbphy[^{]*{[^}]*\)status *= *"disabled";/\1status = "okay";/g' "$DTS" || true
    sed -i 's/\(&ehci[^{]*{[^}]*\)status *= *"disabled";/\1status = "okay";/g' "$DTS" || true
    sed -i 's/\(&ohci[^{]*{[^}]*\)status *= *"disabled";/\1status = "okay";/g' "$DTS" || true

    # 不存在节点：在文件末尾追加（先检测，防止重复追加）
    grep -q '&usbphy' "$DTS" || echo -e '\n&usbphy { status = "okay"; };' >> "$DTS"
    grep -q '&ehci'   "$DTS" || echo -e '\n&ehci   { status = "okay"; };' >> "$DTS"
    grep -q '&ohci'   "$DTS" || echo -e '\n&ohci   { status = "okay"; };' >> "$DTS"

    echo "✅ USB nodes ensured to be \"okay\"."
  else
    echo "⚠️  Could not locate HC5861/HC5861B DTS under $DTS_DIR"
  fi
else
  echo "⚠️  DTS directory not found: $DTS_DIR"
fi

# ─────────────────────────────────────────────────────────────
# 4) 结束
# ─────────────────────────────────────────────────────────────
echo "✔ diy-part2.sh finished."
