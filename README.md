# LibWrt

**基于 ImmortalWrt 的 IPQ60xx 定制固件**

[![Platform](https://img.shields.io/badge/Platform-IPQ60xx-00796B?style=flat-square)](configs/JDCloud.config)
[![Source](https://img.shields.io/badge/Source-LibWrt-2A9D8F?style=flat-square)](https://github.com/LiBwrt/LibWrt/tree/96a0ec8a427909c4d9ef112641b36bcc0728fa43)
[![Kernel](https://img.shields.io/badge/Kernel-6.12-D97706?style=flat-square)](https://github.com/LiBwrt/LibWrt/blob/96a0ec8a427909c4d9ef112641b36bcc0728fa43/target/linux/generic/kernel-6.12)

## 1. 使用说明
- **免责声明**：本人不对使用本固件造成的任何硬件损坏或数据丢失负责。
- **合规使用**：本固件仅限技术交流，严禁用于商业用途。请自觉遵守国家相关法律规定。

## 2. 定制内容

相比于上游 ImmortalWrt 源码，本项目包含以下定制：

### 2.1 内核与驱动
- **NSS 驱动内存预留**：将 `q6_region` 设为 **64MB**（512MB 内存配置的源码默认值约为 55MB）。增加的预留会减少系统可用内存，实际吞吐表现需在设备上测试。
- **CPU 调频设置**：若上游源码存在 `cpufreq` 配置文件，编译脚本会尝试将 governor 设为 `performance`；若文件不存在则跳过，运行时状态需在设备上确认。
- **内存回收加速**：系统启动时尝试启用 `LRU_GEN` (多代最近最少使用)；实际是否生效取决于内核支持情况。
- **闪存与日志设置**：启动时尝试以 `noatime` 重新挂载根分区；若源码提供 `etc/config/system`，脚本会将日志设为 **64KB** 循环模式，否则会提示跳过该可选设置。

### 2.2 定制插件与编译组件
- **HomeProxy**：集成 [HomeProxy](https://github.com/immortalwrt/homeproxy/tree/fadaa676104f59ff6ace480a780a258d846d0aec) 代理管理插件，使用 [SagerNet sing-box](https://github.com/SagerNet/sing-box) 核心。
- **Argon Theme**：集成 [jerrykuku Argon 主题](https://github.com/jerrykuku/luci-theme-argon/tree/517971b773991541ecb5e118b0c5d0b609a79e06) 及 [配置插件](https://github.com/jerrykuku/luci-app-argon-config/tree/9f096c916c16be8075610dd137d3b18982f81f1e) `luci-app-argon-config`。
- **Go 编译环境**：使用 [`Golang 1.23+`](https://github.com/sbwml/packages_lang_golang/tree/cd8953c31e0f64ea2853f87bb0f32256646a160d) 编译链，为固件中的 Go 语言包提供构建环境。

### 2.3 已选择的 LuCI 插件
以下插件在 [`configs/JDCloud.config`](configs/JDCloud.config) 中启用；最终是否进入固件还取决于对应源码/feed 中包是否可用，以及构建是否成功。

- **主题与系统管理**：Argon 主题、Argon 配置、CPU 调频、TTYD 终端、uHTTPd 管理、UPnP。
- **网络与访问控制**：HomeProxy（含简体中文翻译）、ARP 绑定。
- **存储与外设**：DiskMan 磁盘管理、USB 打印。

对应的 LuCI 包为：`luci-theme-argon`、`luci-app-argon-config`、`luci-app-cpufreq`、`luci-app-ttyd`、`luci-app-upnp`、`luci-app-uhttpd`、`luci-app-diskman`、`luci-app-arpbind`、`luci-app-usb-printer`、`luci-app-homeproxy` 和 `luci-i18n-homeproxy-zh-cn`。

### 2.4 其他已选软件包与功能
- **代理核心与网络依赖**：`sing-box`（启用 QUIC、ECH、TUIC、gRPC、TProxy 功能）、TUN、nftables TProxy/socket、`ip-full`、`dnsmasq-full`、CA 证书和 `libcap-bin`。
- **网络与硬件加速**：TCP BBR、`irqbalance`、QCA NSS 驱动与 ECM，以及 ath11k 无线驱动相关模块。
- **内存与编译优化**：启用 ZRAM swap（默认压缩算法为 LZ4）、LTO 和针对 Cortex-A53 的编译优化选项。
- **系统与维护工具**：`dmesg`、`htop`、`fdisk`、`cfdisk`、`sgdisk`、`tune2fs`、`fstrim`、`nano-full`、`hdparm`、`smartmontools-drivedb`、`coremark`、`openssh-sftp-server`、亚洲时区数据及 `autocore`。
- **默认设置组件**：`default-settings` 和 `default-settings-chn`。

### 2.5 精简与移除
- **移除冗余组件**：剔除了上游自带的部分不常用 Luci 界面与过时的工具包。
- **清理冲突配置**：在编译脚本中强制清理了可能与新版插件产生冲突的旧版 feeds。

## 3. 默认配置
| 项目 | 内容 |
| :--- | :--- |
| **管理地址** | `192.168.2.1` |
| **默认用户** | `root` |
| **默认密码** | `none` (无密码) |
| **主机名称** | `LibWrt` |

## 4. 固件定制指南
1. **Fork 本仓库**：修改 [`configs/JDCloud.config`](configs/JDCloud.config) 中的编译选项（`y` 为选定，`n` 为取消）。
2. **调整脚本**：在 [`scripts/Roc-script.sh`](scripts/Roc-script.sh) 中修改默认 IP 或添加定制指令。
3. **启动编译**：在 GitHub 仓库中选择 `Actions` → `Run workflow`。
4. **下载固件**：前往 [Releases](https://github.com/jeojeo1225/openwrt-ci-roc-6.x-jdc-ax1800-ipq60xx/releases) 获取。

## 5. 鸣谢
- **上游源码**：[ImmortalWrt](https://github.com/immortalwrt/immortalwrt)、[LiBwrt](https://github.com/LiBwrt/LibWrt/tree/96a0ec8a427909c4d9ef112641b36bcc0728fa43)。
- **核心组件**：[SagerNet](https://github.com/SagerNet/sing-box)、[sbwml](https://github.com/sbwml/packages_lang_golang/tree/cd8953c31e0f64ea2853f87bb0f32256646a160d)（Go）、[jerrykuku](https://github.com/jerrykuku)（Argon）。
