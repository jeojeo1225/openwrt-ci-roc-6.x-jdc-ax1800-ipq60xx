# 修改默认IP & 固件名称 & 编译署名和时间
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# --- 统一署名修改 (稳健且带链接) ---
JS_FILE="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
if [ -f "$JS_FILE" ]; then
    # 这里的正则匹配更精准，且使用了单行替换防止 Actions 报错
    sed -i "s#_('Firmware Version'), (L\.isObject(boardinfo\.release) ? boardinfo\.release\.description + ' / ' : '') + (luciversion || ''),#_('Firmware Version'), (L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + (luciversion || '') + ' / ' + E('a', { href: 'https://github.com/laipeng668/openwrt-ci-roc/releases', target: '_blank', rel: 'noopener noreferrer' }, [ 'Built by Roc $(date "+%Y-%m-%d")' ]),#" "$JS_FILE"
fi
# --- 闪存优化：增加文件存在性检查 ---
RC_LOCAL="package/base-files/files/etc/rc.local"
if [ -f "$RC_LOCAL" ]; then
    sed -i '/exit 0/i echo y > /sys/kernel/mm/lru_gen/enabled' "$RC_LOCAL"
    sed -i '/exit 0/i mount -o remount,noatime,nodiratime /' "$RC_LOCAL"
else
    # 如果文件不存在，直接创建并写入
    echo -e "#!/bin/sh\necho y > /sys/kernel/mm/lru_gen/enabled\nmount -o remount,noatime,nodiratime /\nexit 0" > "$RC_LOCAL"
    chmod +x "$RC_LOCAL"
fi

# 调整NSS驱动q6_region内存区域预留大小（ipq6018.dtsi默认预留85MB，ipq6018-512m.dtsi默认预留55MB，带WiFi必须至少预留54MB，以下分别是改成预留16MB、32MB、64MB和96MB）
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x01000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x02000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x04000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x06000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi

# 调节IPQ60XX的1.5GHz频率电压(从0.9375V提高到0.95V，过低可能导致不稳定，过高可能增加功耗和发热，具体数值需要根据实际情况调整)
# sed -i 's/opp-microvolt = <937500>;/opp-microvolt = <950000>;/' target/linux/qualcommax/patches-6.12/0038-v6.16-arm64-dts-qcom-ipq6018-add-1.5GHz-CPU-Frequency.patch

# 1. 移除旧包（确保清理干净）
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-homeproxy
rm -rf feeds/packages/net/sing-box
rm -rf feeds/packages/lang/golang

# 2. 克隆 Argon 主题与配置 (必须加回这两行)
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config feeds/luci/applications/luci-app-argon-config

# 3. 克隆 HomeProxy 源码
git clone --depth=1 https://github.com/immortalwrt/homeproxy package/homeproxy

# 4. 雅典娜LED控制
git clone --depth=1 https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led
# 5. 系统内核调优 (sysctl.conf)
echo "vm.min_free_kbytes=16384" >> package/base-files/files/etc/sysctl.conf
echo "vm.swappiness=10" >> package/base-files/files/etc/sysctl.conf
echo "net.core.netdev_max_backlog=10000" >> package/base-files/files/etc/sysctl.conf
echo "kernel.printk = 0 0 0 0" >> package/base-files/files/etc/sysctl.conf

# 6. 日志精简 (防止 eMMC 损耗)
sed -i 's/option log_type.*/option log_type "circular"/' package/base-files/files/etc/config/system
sed -i 's/option log_size.*/option log_size "64"/' package/base-files/files/etc/config/system
# 7. 强制 CPU Performance 模式 (如果配置文件存在)
if [ -f "package/base-files/files/etc/config/cpufreq" ]; then
    sed -i 's/governor=".*"/governor="performance"/g' package/base-files/files/etc/config/cpufreq
fi
