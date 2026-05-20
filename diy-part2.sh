#!/bin/bash
set -e

echo "=============================="
echo " Redmi AC2100 campus build"
echo " DIY part2: system defaults"
echo "=============================="

# =========================================================
# 1. 删除 feeds 里可能重复的软件包
# =========================================================
# 避免 feeds 中存在同名包时优先级混乱。
for pkg in ua2f luci-app-ua2f mentohust luci-app-mentohust; do
  find package/feeds -maxdepth 4 -type d -name "$pkg" -exec rm -rf {} + 2>/dev/null || true
done

# =========================================================
# 2. 设置默认 LAN IP
# =========================================================
# 校园网/宿舍网常见上级网段可能是 192.168.1.x，
# 所以这里改成 192.168.10.1，减少冲突。
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# =========================================================
# 3. 首次启动默认配置
# =========================================================
mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-redmi-ac2100-campus <<'EOF'
#!/bin/sh

# =========================================================
# Redmi AC2100 campus defaults
# 首次启动自动执行一次
# =========================================================

# 主机名与时区
uci -q batch <<EOT
set system.@system[0].hostname='Redmi-AC2100'
set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
commit system
EOT

# LAN IP
uci -q batch <<EOT
set network.lan.ipaddr='192.168.10.1'
commit network
EOT

# UA2F 默认启用
# 说明：
# handle_fw=1：自动处理防火墙规则
# handle_tls=0：不处理 HTTPS，减少无意义开销
# handle_mmtls=0：不处理微信加密流量，减少干扰
# handle_intranet=0：默认不处理内网流量
# disable_connmark=0：不禁用 connmark，优先性能
if [ -x /etc/init.d/ua2f ]; then
  uci -q batch <<EOT
set ua2f.enabled.enabled='1'
set ua2f.firewall.handle_fw='1'
set ua2f.firewall.handle_tls='0'
set ua2f.firewall.handle_mmtls='0'
set ua2f.firewall.handle_intranet='0'
set ua2f.main.disable_connmark='0'
commit ua2f
EOT

  /etc/init.d/ua2f enable
fi

# MentoHUST 不默认启动。
# 原因：需要先在 LuCI 里填写账号、密码、网卡、认证参数。
# 配好以后再手动启用更稳。

exit 0
EOF

chmod +x files/etc/uci-defaults/99-redmi-ac2100-campus

# =========================================================
# 4. 清理默认广告/无用内容，可选
# =========================================================
rm -rf package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true

echo "DIY part2 done."
