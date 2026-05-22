#!/bin/bash
set -e

echo "================================================="
echo " Redmi AC2100 Campus Build"
echo " DIY part1: add custom packages"
echo "================================================="


# =========================================================
# 0. 清理旧的错误结构
# =========================================================

echo "[0/4] Cleaning old broken custom package layouts..."

# 旧的错误 UA2F 拆分结构，必须清理
rm -rf package/custom/ua2f
rm -rf package/custom/ua2f-src
rm -rf custom-src/ua2f-src

# 旧的 custom 包结构，统一清理
rm -rf package/custom/luci-app-ua2f
rm -rf package/custom/mentohust
rm -rf package/custom/luci-app-mentohust

# 正确官方结构也先清理，避免重复 clone
rm -rf package/UA2F
rm -rf package/luci-app-ua2f
rm -rf package/mentohust
rm -rf package/luci-app-mentohust

# 临时目录
rm -rf /tmp/luci-app-ua2f
rm -rf /tmp/luci-app-mentohust


# =========================================================
# 1. UA2F 主程序：使用官方 OpenWrt 包结构
# =========================================================
# 正确结构：
# package/UA2F/
# ├── CMakeLists.txt
# ├── src/
# └── openwrt/
#     └── Makefile
#
# OpenWrt 会扫描 package/UA2F/openwrt/Makefile。
# UA2F 官方 Makefile 里 PKG_BUILD_DIR=$(CURDIR)/..，
# 所以它会自动回到 package/UA2F 找 CMakeLists.txt。
#
# 不要再拆成：
# package/custom/ua2f
# package/custom/ua2f-src
# custom-src/ua2f-src

echo "================================================="
echo "[1/4] Installing UA2F official package layout"
echo "================================================="

git clone --depth=1 --branch v4.10.2 https://github.com/Zxilly/UA2F.git package/UA2F

echo "[UA2F] Checking official layout..."

test -f package/UA2F/CMakeLists.txt || {
  echo "ERROR: package/UA2F/CMakeLists.txt not found."
  echo "ERROR: UA2F source is incomplete."
  exit 1
}

test -f package/UA2F/openwrt/Makefile || {
  echo "ERROR: package/UA2F/openwrt/Makefile not found."
  echo "ERROR: UA2F OpenWrt Makefile is missing."
  exit 1
}

echo "---- package/UA2F ----"
ls -la package/UA2F | head -50

echo "---- package/UA2F/openwrt ----"
ls -la package/UA2F/openwrt

echo "---- UA2F PKG_BUILD_DIR ----"
grep '^PKG_BUILD_DIR' package/UA2F/openwrt/Makefile || true

echo "[UA2F] OK."


# =========================================================
# 2. UA2F LuCI 配置界面
# =========================================================

echo "================================================="
echo "[2/4] Installing luci-app-ua2f"
echo "================================================="

git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git /tmp/luci-app-ua2f

test -d /tmp/luci-app-ua2f/luci-app-ua2f || {
  echo "ERROR: /tmp/luci-app-ua2f/luci-app-ua2f not found."
  echo "ERROR: luci-app-ua2f source layout changed or clone failed."
  exit 1
}

cp -a /tmp/luci-app-ua2f/luci-app-ua2f package/luci-app-ua2f

test -f package/luci-app-ua2f/Makefile || {
  echo "ERROR: package/luci-app-ua2f/Makefile not found."
  exit 1
}

echo "[luci-app-ua2f] OK."


# =========================================================
# 3. MentoHUST 主程序 + LuCI 界面
# =========================================================

echo "================================================="
echo "[3/4] Installing mentohust and luci-app-mentohust"
echo "================================================="

git clone --depth=1 https://github.com/sbwml/luci-app-mentohust.git /tmp/luci-app-mentohust

test -d /tmp/luci-app-mentohust/mentohust || {
  echo "ERROR: /tmp/luci-app-mentohust/mentohust not found."
  exit 1
}

test -d /tmp/luci-app-mentohust/luci-app-mentohust || {
  echo "ERROR: /tmp/luci-app-mentohust/luci-app-mentohust not found."
  exit 1
}

cp -a /tmp/luci-app-mentohust/mentohust package/mentohust
cp -a /tmp/luci-app-mentohust/luci-app-mentohust package/luci-app-mentohust

test -f package/mentohust/Makefile || {
  echo "ERROR: package/mentohust/Makefile not found."
  exit 1
}

test -f package/luci-app-mentohust/Makefile || {
  echo "ERROR: package/luci-app-mentohust/Makefile not found."
  exit 1
}

echo "[mentohust] OK."
echo "[luci-app-mentohust] OK."


# =========================================================
# 4. 最终检查
# =========================================================

echo "================================================="
echo "[4/4] Final package layout check"
echo "================================================="

echo "---- package root custom packages ----"
ls -la package | grep -E "UA2F|ua2f|mentohust" || true

echo "---- make sure old wrong UA2F layouts do not exist ----"

test ! -d package/custom/ua2f || {
  echo "ERROR: package/custom/ua2f still exists."
  echo "ERROR: old split UA2F layout must be removed."
  exit 1
}

test ! -d package/custom/ua2f-src || {
  echo "ERROR: package/custom/ua2f-src still exists."
  echo "ERROR: old split UA2F source layout must be removed."
  exit 1
}

test ! -d custom-src/ua2f-src || {
  echo "ERROR: custom-src/ua2f-src still exists."
  echo "ERROR: old workaround UA2F layout must be removed."
  exit 1
}

test -f package/UA2F/CMakeLists.txt || exit 1
test -f package/UA2F/openwrt/Makefile || exit 1
test -f package/luci-app-ua2f/Makefile || exit 1
test -f package/mentohust/Makefile || exit 1
test -f package/luci-app-mentohust/Makefile || exit 1

echo "================================================="
echo " DIY part1 done."
echo " Correct UA2F layout: package/UA2F/openwrt"
echo "================================================="
