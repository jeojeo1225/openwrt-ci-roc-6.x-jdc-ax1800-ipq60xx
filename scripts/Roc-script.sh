set -Eeuo pipefail
trap 'status=$?; printf "ERROR: command failed at line %s (exit %s): %s\n" "$LINENO" "$status" "$BASH_COMMAND" >&2; exit "$status"' ERR

fetch_source() {
    local url="$1"
    local destination="$2"
    local marker="$3"
    local ref="$4"
    local env_name="$5"
    local actual_commit

    if [[ ! "$env_name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        printf 'Invalid environment variable name for %s: %s\n' "$url" "$env_name" >&2
        return 1
    fi

    printf 'Fetching latest %s from %s into %s\n' "$ref" "$url" "$destination"
    rm -rf "$destination"
    git init --quiet "$destination"
    git -C "$destination" remote add origin "$url"
    if ! git -C "$destination" fetch --depth=1 origin "$ref"; then
        printf 'Failed to fetch %s from %s\n' "$ref" "$url" >&2
        return 1
    fi
    git -C "$destination" checkout --quiet --detach FETCH_HEAD

    actual_commit="$(git -C "$destination" rev-parse HEAD)"

    if [ ! -f "$destination/$marker" ]; then
        printf 'Source %s is missing expected file: %s\n' "$url" "$marker" >&2
        return 1
    fi

    printf 'Resolved %s to %s\n' "$url" "$actual_commit"
    printf '%s=%s\n' "$env_name" "$actual_commit" >> "$GITHUB_ENV"
}

replace_checked() {
    local file="$1"
    local before="$2"
    local after="$3"
    local expression="$4"

    if [ ! -f "$file" ]; then
        printf 'Required file not found: %s\n' "$file" >&2
        return 1
    fi

    if grep -Eq -- "$before" "$file"; then
        sed -i -E "$expression" "$file"
    elif ! grep -Eq -- "$after" "$file"; then
        printf 'Expected text not found in %s: %s\n' "$file" "$before" >&2
        return 1
    fi

    if ! grep -Eq -- "$after" "$file"; then
        printf 'Replacement did not take effect in %s: %s\n' "$file" "$after" >&2
        return 1
    fi
}

# 修改默认IP & 固件名称 & 编译署名和时间
replace_checked \
    package/base-files/files/bin/config_generate \
    '192\.168\.1\.1' '192\.168\.2\.1' \
    's/192\.168\.1\.1/192.168.2.1/g'
# --- 补上这一行，设定主机名为 LibWrt ---
replace_checked \
    package/base-files/files/bin/config_generate \
    "hostname='[^']*'" "hostname='LibWrt'" \
    "s/hostname='[^']*'/hostname='LibWrt'/g"
# --- 统一署名修改 (稳健且带链接) ---
JS_FILE="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
BUILD_DATE="$(date "+%Y-%m-%d")"
if [ -f "$JS_FILE" ] && grep -Eq 'Built by Roc [0-9]{4}-[0-9]{2}-[0-9]{2}' "$JS_FILE"; then
    replace_checked \
        "$JS_FILE" 'Built by Roc [0-9]{4}-[0-9]{2}-[0-9]{2}' "Built by Roc $BUILD_DATE" \
        "s#Built by Roc [0-9]{4}-[0-9]{2}-[0-9]{2}#Built by Roc $BUILD_DATE#"
else
    replace_checked \
        "$JS_FILE" "_\\('Firmware Version'\\)," "Built by Roc $BUILD_DATE" \
        "s#_[(]'Firmware Version'[)],.*luciversion.*[,]#_('Firmware Version'), (L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + (luciversion || '') + ' / ' + E('a', { href: 'https://github.com/jeojeo1225/openwrt-ci-roc-6.x-jdc-ax1800-ipq60xx/releases', target: '_blank', rel: 'noopener noreferrer' }, [ 'Built by Roc $BUILD_DATE' ]),#"
fi

# --- 闪存优化：增加文件存在性检查 ---
RC_LOCAL="package/base-files/files/etc/rc.local"
if [ ! -f "$RC_LOCAL" ]; then
    printf '#!/bin/sh\nexit 0\n' > "$RC_LOCAL"
    chmod +x "$RC_LOCAL"
fi

ensure_rc_command() {
    local command="$1"

    if ! grep -Fqx -- "$command" "$RC_LOCAL"; then
        if ! grep -Fqx 'exit 0' "$RC_LOCAL"; then
            printf 'Expected exit 0 in %s\n' "$RC_LOCAL" >&2
            return 1
        fi
        sed -i "/^exit 0$/i $command" "$RC_LOCAL"
    fi

    grep -Fqx -- "$command" "$RC_LOCAL"
}

ensure_rc_command 'echo 7 > /sys/kernel/mm/lru_gen/enabled'
ensure_rc_command 'mount -o remount,noatime,nodiratime /'

# 调整NSS驱动q6_region内存区域预留大小（ipq6018.dtsi默认预留85MB，ipq6018-512m.dtsi默认预留55MB，带WiFi必须至少预留54MB，以下分别是改成预留16MB、32MB、64MB和96MB）
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x01000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x02000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
replace_checked \
    target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi \
    'reg = <0x0 0x4ab00000 0x0 0x[0-9a-fA-F]+>' 'reg = <0x0 0x4ab00000 0x0 0x04000000>' \
    's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-fA-F]+>/reg = <0x0 0x4ab00000 0x0 0x04000000>/'
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x06000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# 调节IPQ60XX的1.5GHz频率电压(从0.9375V提高到0.95V，过低可能导致不稳定，过高可能增加功耗和发热，具体数值需要根据实际情况调整)
# sed -i 's/opp-microvolt = <937500>;/opp-microvolt = <950000>;/' target/linux/qualcommax/patches-6.12/0038-v6.16-arm64-dts-qcom-ipq6018-add-1.5GHz-CPU-Frequency.patch
# 1. 移除旧包（确保清理干净）
rm -rf feeds/luci/applications/luci-app-homeproxy

# 2. Track the latest upstream branches for Argon theme and configuration.
fetch_source https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon Makefile master ARGON_THEME_COMMIT
fetch_source https://github.com/jerrykuku/luci-app-argon-config feeds/luci/applications/luci-app-argon-config Makefile master ARGON_CONFIG_COMMIT

# 3. Track the latest package sources on their maintained upstream branches.
fetch_source https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang golang/Makefile 27.x GOLANG_COMMIT
fetch_source https://github.com/immortalwrt/homeproxy package/homeproxy Makefile master HOMEPROXY_COMMIT

# Athena LED LuCI app, tracked on main and installed only on RE-CS-02.
fetch_source https://github.com/NONGFAH/luci-app-athena-led package/luci-app-athena-led Makefile main ATHENA_LED_COMMIT
chmod +x package/luci-app-athena-led/root/etc/init.d/athena_led package/luci-app-athena-led/root/usr/sbin/athena-led

set_sysctl() {
    local key="$1"
    local value="$2"
    local file="package/base-files/files/etc/sysctl.conf"
    local temporary_file="${file}.tmp"

    if [ ! -f "$file" ]; then
        printf 'Required file not found: %s\n' "$file" >&2
        return 1
    fi

    awk -v key="$key" '{
        line = $0
        sub(/^[[:space:]]*/, "", line)
        split(line, parts, "=")
        name = parts[1]
        gsub(/[[:space:]]/, "", name)
        if (name != key) print
    }' "$file" > "$temporary_file"
    printf '%s=%s\n' "$key" "$value" >> "$temporary_file"
    mv "$temporary_file" "$file"
}

# 5. 系统内核调优 (sysctl.conf)
set_sysctl vm.min_free_kbytes 16384
set_sysctl vm.swappiness 10
set_sysctl net.core.netdev_max_backlog 10000
set_sysctl kernel.printk '0 0 0 0'

# 6. 日志精简 (防止 eMMC 损耗)
SYSTEM_CONFIG="package/base-files/files/etc/config/system"
if [ -f "$SYSTEM_CONFIG" ]; then
    replace_checked \
        "$SYSTEM_CONFIG" \
        'option log_type.*' 'option log_type "circular"' \
        's/option log_type.*/option log_type "circular"/'
    replace_checked \
        "$SYSTEM_CONFIG" \
        'option log_size.*' 'option log_size "64"' \
        's/option log_size.*/option log_size "64"/'
else
    printf 'Skipping optional log settings; source does not provide %s\n' "$SYSTEM_CONFIG" >&2
fi
# 7. 强制 CPU Performance 模式 (如果配置文件存在)
if [[ -f package/base-files/files/etc/config/cpufreq ]]; then
    replace_checked \
        package/base-files/files/etc/config/cpufreq \
        "option governor[[:space:]]+('[^']*'|\"[^\"]*\")" "option governor[[:space:]]+'performance'" \
        "s/(option governor[[:space:]]+)('[^']*'|\"[^\"]*\")/\\1'performance'/"
fi
