#!/bin/bash
set -e

echo "================================================="
echo " Redmi AC2100 campus build"
echo " DIY part1: add custom packages"
echo "================================================="

# =========================================================
# 0. 基础目录清理
# =========================================================
mkdir -p package/custom

echo "[0/4] Cleaning old custom package directories..."
rm -rf package/custom/ua2f
rm -rf package/custom/luci-app-ua2f
rm -rf package/custom/mentohust
rm -rf package/custom/luci-app-mentohust
# 清理之前残留的魔改目录
rm -rf custom-src

# 如果 package/feeds 已经存在，就顺手清理同名包，避免冲突。
if [ -d "package/feeds" ]; then
  echo "[0/4] Cleaning duplicate packages from package/feeds..."
  find package/feeds -maxdepth 5 -type d -name "ua2f" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "luci-app-ua2f" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "mentohust" -exec rm -rf {} + 2>/dev/null || true
  find package/feeds -maxdepth 5 -type d -name "luci-app-mentohust" -exec rm -rf {} + 2>/dev/null || true
fi

# =========================================================
# 1. UA2F 主程序 (回归原生拉取方式)
# =========================================================
echo "================================================="
echo "[1/4] Installing UA2F"
echo "================================================="

# 直接拉取整个仓库到 package/custom/ua2f，保持官方目录结构完整
git clone --depth=1 --branch v4.10.2 https://github.com/Zxilly/UA2F.git package/custom/ua2f

echo "[UA2F] OK."

# =========================================================
# 2. UA2F LuCI 配置界面
# =========================================================
echo "================================================="
echo "[2/4] Installing luci-app-ua2f"
echo "================================================="

rm -rf /tmp/luci-app-ua2f
git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git /tmp/luci-app-ua2f
cp -a /tmp/luci-app-ua2f/luci-app-ua2f package/custom/luci-app-ua2f

echo "[luci-app-ua2f] OK."

# =========================================================
# 3. MentoHUST 主程序 + LuCI 界面
# =========================================================
echo "================================================="
echo "[3/4] Installing mentohust and luci-app-mentohust"
echo "================================================="

rm -rf /tmp/luci-app-mentohust
git clone --depth=1 https://github.com/sbwml/luci-app-mentohust.git /tmp/luci-app-mentohust
cp -a /tmp/luci-app-mentohust/mentohust package/custom/mentohust
cp -a /tmp/luci-app-mentohust/luci-app-mentohust package/custom/luci-app-mentohust

echo "[mentohust] OK."
echo "[luci-app-mentohust] OK."

# =========================================================
# 4. 最终检查
# =========================================================
echo "================================================="
echo "[4/4] Final custom package list"
echo "================================================="

ls -la package/custom

echo "================================================="
echo "[4/4] DIY part1 done."
echo "================================================="
