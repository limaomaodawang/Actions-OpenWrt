#!/bin/bash
set -e

echo "================================================="
echo " Redmi AC2100 Campus Build"
echo " DIY part2: system defaults and cleanup"
echo "================================================="


# =========================================================
# 1. 清理 feeds 里可能重复的软件包
# =========================================================

echo "[1/6] Cleaning duplicate packages from package/feeds..."

if [ -d "package/feeds" ]; then
  for pkg in ua2f luci-app-ua2f mentohust luci-app-mentohust; do
    find package/feeds -maxdepth 5 -type d -name "$pkg" -exec rm -rf {} + 2>/dev/null || true
  done
fi


# =========================================================
# 2. 检查 UA2F 官方目录结构
# =========================================================
# 正确结构：
# package/UA2F/CMakeLists.txt
# package/UA2F/openwrt/Makefile
#
# 不要再用：
# package/custom/ua2f
# package/custom/ua2f-src
# custom-src/ua2f-src

echo "[2/6] Checking UA2F official package layout..."

test -f package/UA2F/CMakeLists.txt || {
  echo "ERROR: package/UA2F/CMakeLists.txt not found."
  echo "ERROR: UA2F source is incomplete. Please check diy-part1.sh."
  exit 1
}

test -f package/UA2F/openwrt/Makefile || {
  echo "ERROR: package/UA2F/openwrt/Makefile not found."
  echo "ERROR: UA2F OpenWrt Makefile is missing. Please check diy-part1.sh."
  exit 1
}

test ! -d package/custom/ua2f || {
  echo "ERROR: package/custom/ua2f still exists."
  echo "ERROR: remove old split UA2F layout."
  exit 1
}

test ! -d package/custom/ua2f-src || {
  echo "ERROR: package/custom/ua2f-src still exists."
  echo "ERROR: remove old split UA2F source layout."
  exit 1
}

test ! -d custom-src/ua2f-src || {
  echo "ERROR: custom-src/ua2f-src still exists."
  echo "ERROR: old workaround layout should not be used."
  exit 1
}

grep '^PKG_BUILD_DIR' package/UA2F/openwrt/Makefile || true

echo "[UA2F layout] OK."


# =========================================================
# 3. 设置默认 LAN IP
# =========================================================

echo "[3/6] Setting default LAN IP to 192.168.10.1..."

if [ -f "package/base-files/files/bin/config_generate" ]; then
  sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
fi


# =========================================================
# 4. 创建首次启动默认配置
# =========================================================

echo "[4/6] Creating first boot defaults..."

mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-redmi-ac2100-campus <<'EOF'
#!/bin/sh

# =========================================================
# Redmi AC2100 Campus Defaults
# 首次启动自动执行一次
# =========================================================


# =========================================================
# 1. 系统基础设置
# =========================================================

uci -q batch <<EOT
set system.@system[0].hostname='Redmi-AC2100'
set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
commit system
EOT


# =========================================================
# 2. LAN 地址
# =========================================================

uci -q batch <<EOT
set network.lan.ipaddr='192.168.10.1'
commit network
EOT


# =========================================================
# 3. UA2F 底层配置
# =========================================================

if [ -x /etc/init.d/ua2f ]; then
  uci -q batch <<EOT
set ua2f.enabled.enabled='1'
set ua2f.firewall.handle_fw='1'
set ua2f.firewall.handle_tls='0'
set ua2f.firewall.handle_mmtls='0'
set ua2f.firewall.handle_intranet='0'
set ua2f.main.custom_ua=''
set ua2f.main.disable_connmark='0'
set ua2f.main.max_http_sessions='0'
set ua2f.main.session_ttl='300'
commit ua2f
EOT

  /etc/init.d/ua2f enable
fi


# =========================================================
# 4. luci-app-ua2f 配置界面同步配置
# =========================================================

if [ -x /etc/init.d/autoua2f ]; then
  uci -q batch <<EOT
set autoua2f.config.enabled='1'
set autoua2f.config.handle_fw='1'
set autoua2f.config.handle_tls='0'
set autoua2f.config.handle_mmtls='0'
set autoua2f.config.handle_intranet='0'
set autoua2f.config.Custom_UA=''
commit autoua2f
EOT

  /etc/init.d/autoua2f enable
fi


# =========================================================
# 5. MentoHUST 不默认启动
# =========================================================

exit 0
EOF

chmod +x files/etc/uci-defaults/99-redmi-ac2100-campus


# =========================================================
# 5. 移除 Lean 默认设置脚本
# =========================================================

echo "[5/6] Removing Lean default settings if present..."

rm -rf package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true


# =========================================================
# 6. 输出完成信息
# =========================================================

echo "[6/6] DIY part2 done."
echo "================================================="
echo " Default LAN IP: 192.168.10.1"
echo " Hostname: Redmi-AC2100"
echo " UA2F: enabled by default"
echo " MentoHUST: installed but not enabled by default"
echo "================================================="
