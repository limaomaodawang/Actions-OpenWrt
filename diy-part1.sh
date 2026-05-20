#!/bin/bash
set -e

echo "=============================="
echo " Redmi AC2100 campus build"
echo " DIY part1: add custom packages"
echo "=============================="

mkdir -p package/custom

# 清理旧目录，避免重复包导致编译冲突
rm -rf package/custom/ua2f
rm -rf package/custom/ua2f-src
rm -rf package/custom/luci-app-ua2f
rm -rf package/custom/mentohust
rm -rf package/custom/luci-app-mentohust

rm -rf /tmp/UA2F
rm -rf /tmp/luci-app-ua2f
rm -rf /tmp/luci-app-mentohust

# =========================================================
# 1. UA2F 主程序
# =========================================================
# Zxilly/UA2F 的 OpenWrt 包在仓库 openwrt/ 子目录里，
# 这里复制成标准 package/custom/ua2f 结构，便于 OpenWrt 识别。
git clone --depth=1 https://github.com/Zxilly/UA2F.git /tmp/UA2F

mkdir -p package/custom/ua2f
mkdir -p package/custom/ua2f-src

cp -r /tmp/UA2F/openwrt/* package/custom/ua2f/
cp -r /tmp/UA2F/. package/custom/ua2f-src/

# 修正 UA2F Makefile 的源码目录指向
sed -i 's#PKG_BUILD_DIR:=$(CURDIR)/..#PKG_BUILD_DIR:=$(CURDIR)/../ua2f-src#g' package/custom/ua2f/Makefile

# =========================================================
# 2. UA2F LuCI 配置界面
# =========================================================
git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git /tmp/luci-app-ua2f
cp -r /tmp/luci-app-ua2f/luci-app-ua2f package/custom/luci-app-ua2f

# =========================================================
# 3. MentoHUST 主程序 + LuCI 界面
# =========================================================
git clone --depth=1 https://github.com/sbwml/luci-app-mentohust.git /tmp/luci-app-mentohust

cp -r /tmp/luci-app-mentohust/mentohust package/custom/mentohust
cp -r /tmp/luci-app-mentohust/luci-app-mentohust package/custom/luci-app-mentohust

echo "DIY part1 done."
