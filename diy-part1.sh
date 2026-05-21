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

echo "[UA2F] Cloning UA2F source..."

git clone --depth=1 https://github.com/Zxilly/UA2F.git package/custom/ua2f-src

echo "[UA2F] Checking source tree..."

if [ ! -f "package/custom/ua2f-src/CMakeLists.txt" ]; then
  echo "ERROR: package/custom/ua2f-src/CMakeLists.txt not found"
  echo "UA2F source tree:"
  find package/custom/ua2f-src -maxdepth 3 -type f | sort | head -80
  exit 1
fi

echo "[UA2F] Installing OpenWrt package files..."

mkdir -p package/custom/ua2f
cp -a package/custom/ua2f-src/openwrt/. package/custom/ua2f/

if [ ! -f "package/custom/ua2f/Makefile" ]; then
  echo "ERROR: package/custom/ua2f/Makefile not found"
  find package/custom/ua2f -maxdepth 3 -type f | sort
  exit 1
fi

# 关键修正：
# 官方 openwrt/Makefile 默认 PKG_BUILD_DIR=$(CURDIR)/..
# 但我们现在把 OpenWrt 包目录和源码目录拆开了：
#   package/custom/ua2f      = OpenWrt 包目录
#   package/custom/ua2f-src  = UA2F 源码根目录
# 所以必须明确指向 ua2f-src。
sed -i 's#^PKG_BUILD_DIR:=.*#PKG_BUILD_DIR:=$(TOPDIR)/package/custom/ua2f-src#g' package/custom/ua2f/Makefile

# 可选：统一包名大小写
sed -i 's#^PKG_NAME:=UA2F#PKG_NAME:=ua2f#g' package/custom/ua2f/Makefile

echo "[UA2F] Check result:"
grep '^PKG_BUILD_DIR' package/custom/ua2f/Makefile
ls -la package/custom/ua2f-src/CMakeLists.txt


# =========================================================
# 2. UA2F LuCI 配置界面
# =========================================================

echo "[luci-app-ua2f] Cloning..."

git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git /tmp/luci-app-ua2f

if [ -d "/tmp/luci-app-ua2f/luci-app-ua2f" ]; then
  cp -a /tmp/luci-app-ua2f/luci-app-ua2f package/custom/luci-app-ua2f
else
  cp -a /tmp/luci-app-ua2f package/custom/luci-app-ua2f
fi


# =========================================================
# 3. MentoHUST 主程序 + LuCI 界面
# =========================================================

echo "[mentohust] Cloning..."

git clone --depth=1 https://github.com/sbwml/luci-app-mentohust.git /tmp/luci-app-mentohust

cp -a /tmp/luci-app-mentohust/mentohust package/custom/mentohust
cp -a /tmp/luci-app-mentohust/luci-app-mentohust package/custom/luci-app-mentohust


echo "DIY part1 done."
