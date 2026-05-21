# =========================================================
# UA2F：源码 + OpenWrt 包文件
# =========================================================

echo "[UA2F] Cleaning old ua2f directories..."

rm -rf package/custom/ua2f
rm -rf package/custom/ua2f-src
rm -rf package/custom/luci-app-ua2f

# 防止 feeds 里同名包冲突
find package/feeds -maxdepth 5 -type d \( \
  -name "ua2f" -o \
  -name "luci-app-ua2f" \
\) -exec rm -rf {} + 2>/dev/null || true

mkdir -p package/custom

echo "[UA2F] Cloning UA2F source..."

git clone --depth=1 --branch v4.10.2 https://github.com/Zxilly/UA2F.git package/custom/ua2f-src

echo "[UA2F] Creating OpenWrt package wrapper..."

mkdir -p package/custom/ua2f

cp package/custom/ua2f-src/openwrt/Makefile package/custom/ua2f/Makefile
cp -r package/custom/ua2f-src/openwrt/files package/custom/ua2f/files

# 关键：因为我们把源码放在 ua2f-src，把 OpenWrt 包壳放在 ua2f，
# 所以必须让 Makefile 指向真正源码目录
sed -i 's#^PKG_BUILD_DIR:=.*#PKG_BUILD_DIR:=$(TOPDIR)/package/custom/ua2f-src#' package/custom/ua2f/Makefile

echo "[UA2F] Checking source files..."

ls -la package/custom/ua2f-src
ls -la package/custom/ua2f

test -f package/custom/ua2f-src/CMakeLists.txt || {
  echo "ERROR: package/custom/ua2f-src/CMakeLists.txt not found"
  exit 1
}

test -f package/custom/ua2f/Makefile || {
  echo "ERROR: package/custom/ua2f/Makefile not found"
  exit 1
}

echo "[UA2F] UA2F source and package wrapper are ready."
