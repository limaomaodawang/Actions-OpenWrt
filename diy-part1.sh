#!/bin/bash
set -e

echo "================================================="
echo " Redmi AC2100 campus build"
echo " DIY part1: add custom packages"
echo "================================================="

# =========================================================
# 0. 基础目录
# =========================================================

mkdir -p package/custom

echo "[0/5] Cleaning old custom package directories..."

rm -rf package/custom/ua2f
rm -rf package/custom/ua2f-src
rm -rf package/custom/luci-app-ua2f
rm -rf package/custom/mentohust
rm -rf package/custom/luci-app-mentohust

rm -rf /tmp/UA2F
rm -rf /tmp/luci-app-ua2f
rm -rf /tmp/luci-app-mentohust

# 如果 package/feeds 已经存在，就顺手清理同名包，避免冲突。
# 在当前 workflow 里 diy-part1.sh 执行时通常还没 install feeds，
# 所以这里必须允许 package/feeds 不存在。
if [ -d "package/feeds" ]; then
  echo "[0/5] Cleaning duplicate packages from package/feeds..."
  find package/feeds -maxdepth 5 -type d -name "ua2f" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "luci-app-ua2f" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "mentohust" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "luci-app-mentohust" -exec rm -rf {} + 2>/dev/null || true
fi

# =========================================================
# 1. UA2F 主程序
# =========================================================

echo "================================================="
echo "[1/5] Installing UA2F"
echo "================================================="

echo "[UA2F] Clone official UA2F source..."
git clone --depth=1 --branch v4.10.2 https://github.com/Zxilly/UA2F.git /tmp/UA2F

echo "[UA2F] Check cloned source..."
ls -la /tmp/UA2F

if [ ! -f /tmp/UA2F/CMakeLists.txt ]; then
  echo "ERROR: /tmp/UA2F/CMakeLists.txt not found."
  echo "ERROR: UA2F source is incomplete."
  exit 1
fi

if [ ! -f /tmp/UA2F/openwrt/Makefile ]; then
  echo "ERROR: /tmp/UA2F/openwrt/Makefile not found."
  echo "ERROR: UA2F OpenWrt package Makefile is missing."
  exit 1
fi

echo "[UA2F] Copy full source to package/custom/ua2f-src..."
mkdir -p package/custom/ua2f-src
cp -a /tmp/UA2F/. package/custom/ua2f-src/

echo "[UA2F] Copy OpenWrt package wrapper to package/custom/ua2f..."
mkdir -p package/custom/ua2f
cp -a /tmp/UA2F/openwrt/. package/custom/ua2f/

echo "[UA2F] Patch PKG_BUILD_DIR..."
sed -i 's#^PKG_BUILD_DIR:=.*#PKG_BUILD_DIR:=$(TOPDIR)/package/custom/ua2f-src#' package/custom/ua2f/Makefile

echo "[UA2F] Final check..."
echo "---- package/custom/ua2f-src ----"
ls -la package/custom/ua2f-src

echo "---- package/custom/ua2f ----"
ls -la package/custom/ua2f

test -f package/custom/ua2f-src/CMakeLists.txt || {
  echo "ERROR: package/custom/ua2f-src/CMakeLists.txt not found."
  exit 1
}

test -f package/custom/ua2f/Makefile || {
  echo "ERROR: package/custom/ua2f/Makefile not found."
  exit 1
}

grep '^PKG_BUILD_DIR' package/custom/ua2f/Makefile

echo "[UA2F] OK."

# =========================================================
# 2. UA2F LuCI 配置界面
# =========================================================

echo "================================================="
echo "[2/5] Installing luci-app-ua2f"
echo "================================================="

git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git /tmp/luci-app-ua2f

if [ ! -d /tmp/luci-app-ua2f/luci-app-ua2f ]; then
  echo "ERROR: /tmp/luci-app-ua2f/luci-app-ua2f not found."
  echo "ERROR: luci-app-ua2f source layout changed or clone failed."
  exit 1
fi

cp -a /tmp/luci-app-ua2f/luci-app-ua2f package/custom/luci-app-ua2f

test -f package/custom/luci-app-ua2f/Makefile || {
  echo "ERROR: package/custom/luci-app-ua2f/Makefile not found."
  exit 1
}

echo "[luci-app-ua2f] OK."

# =========================================================
# 3. MentoHUST 主程序 + LuCI 界面
# =========================================================

echo "================================================="
echo "[3/5] Installing mentohust and luci-app-mentohust"
echo "================================================="

git clone --depth=1 https://github.com/sbwml/luci-app-mentohust.git /tmp/luci-app-mentohust

if [ ! -d /tmp/luci-app-mentohust/mentohust ]; then
  echo "ERROR: /tmp/luci-app-mentohust/mentohust not found."
  exit 1
fi

if [ ! -d /tmp/luci-app-mentohust/luci-app-mentohust ]; then
  echo "ERROR: /tmp/luci-app-mentohust/luci-app-mentohust not found."
  exit 1
fi

cp -a /tmp/luci-app-mentohust/mentohust package/custom/mentohust
cp -a /tmp/luci-app-mentohust/luci-app-mentohust package/custom/luci-app-mentohust

test -f package/custom/mentohust/Makefile || {
  echo "ERROR: package/custom/mentohust/Makefile not found."
  exit 1
}

test -f package/custom/luci-app-mentohust/Makefile || {
  echo "ERROR: package/custom/luci-app-mentohust/Makefile not found."
  exit 1
}

echo "[mentohust] OK."
echo "[luci-app-mentohust] OK."

# =========================================================
# 4. 最终检查
# =========================================================

echo "================================================="
echo "[4/5] Final custom package list"
echo "================================================="

echo "---- package/custom ----"
ls -la package/custom

echo "---- UA2F source check ----"
ls -la package/custom/ua2f-src | head -50

echo "---- UA2F package Makefile check ----"
grep '^PKG_NAME' package/custom/ua2f/Makefile || true
grep '^PKG_VERSION' package/custom/ua2f/Makefile || true
grep '^PKG_BUILD_DIR' package/custom/ua2f/Makefile || true

# =========================================================
# 5. 完成
# =========================================================

echo "================================================="
echo "[5/5] DIY part1 done."
echo "================================================="
