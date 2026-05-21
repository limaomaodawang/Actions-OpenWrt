#!/bin/bash
set -e

echo "================================================="
echo " Redmi AC2100 Campus Build"
echo " DIY part2: system defaults and cleanup"
echo "================================================="


# =========================================================
# 1. 删除 feeds 里可能重复的软件包
# =========================================================
# 原因：
# diy-part1.sh 已经把 ua2f / luci-app-ua2f /
# mentohust / luci-app-mentohust 放进 package/custom。
# 如果 feeds 里也存在同名包，可能造成重复包、优先级混乱或编译冲突。

echo "[1/6] Cleaning duplicate packages from package/feeds..."

if [ -d "package/feeds" ]; then
  for pkg in ua2f luci-app-ua2f mentohust luci-app-mentohust; do
    find package/feeds -maxdepth 5 -type d -name "$pkg" -exec rm -rf {} + 2>/dev/null || true
  done
fi


# =========================================================
# 2. 检查 UA2F 自定义包结构
# =========================================================
# 正确结构：
# custom-src/ua2f-src      只放 UA2F 源码，不在 package/ 下，避免被误识别为包
# package/custom/ua2f      唯一 OpenWrt 包入口
#
# 错误结构：
# package/custom/ua2f-src  不能存在；它会被 OpenWrt 扫描，导致重复构建

echo "[2/6] Checking custom UA2F package layout..."

test -f custom-src/ua2f-src/CMakeLists.txt || {
  echo "ERROR: custom-src/ua2f-src/CMakeLists.txt not found."
  echo "ERROR: UA2F source is incomplete. Please check diy-part1.sh."
  exit 1
}

test -f package/custom/ua2f/Makefile || {
  echo "ERROR: package/custom/ua2f/Makefile not found."
  echo "ERROR: UA2F OpenWrt package wrapper is missing. Please check diy-part1.sh."
  exit 1
}

test ! -d package/custom/ua2f-src || {
  echo "ERROR: package/custom/ua2f-src still exists."
  echo "ERROR: UA2F source must not be placed under package/."
  exit 1
}

grep '^PKG_BUILD_DIR:=$(TOPDIR)/custom-src/ua2f-src' package/custom/ua2f/Makefile || {
  echo "ERROR: package/custom/ua2f/Makefile does not point to custom-src/ua2f-src."
  echo "Current PKG_BUILD_DIR:"
  grep '^PKG_BUILD_DIR' package/custom/ua2f/Makefile || true
  exit 1
}

echo "[UA2F layout] OK."


# =========================================================
# 3. 设置默认 LAN IP
# =========================================================
# 校园网/宿舍网常见上级网关可能是 192.168.1.1。
# 所以这里把 OpenWrt 默认地址改成 192.168.10.1，减少冲突。

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
# enabled=1              默认启用 UA2F
# handle_fw=1            自动处理防火墙规则
# handle_tls=0           不处理 HTTPS，减少干扰
# handle_mmtls=0         不处理微信 mmtls，减少干扰
# handle_intranet=0      默认不处理内网流量，稳定优先
# disable_connmark=0     保留 connmark
# max_http_sessions=0    不限制 HTTP 会话数量
# session_ttl=300        默认会话 TTL

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
# luci-app-ua2f 使用 /etc/config/autoua2f。
# 如果这里只写 ua2f，不写 autoua2f，
# 可能出现 LuCI 页面显示状态和实际后台状态不一致的问题。

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
# MentoHUST 需要先在 LuCI 里填写账号、密码、网卡、认证参数。
# 没配置好就开机自启，反而容易启动失败或反复认证异常。

exit 0
EOF

chmod +x files/etc/uci-defaults/99-redmi-ac2100-campus


# =========================================================
# 5. 移除 Lean 默认设置脚本
# =========================================================
# 如果使用 Lean / lede 源码，默认设置脚本可能会覆盖主题、
# IP、主机名、软件源等内容。这里移除，避免和自己的配置打架。

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
