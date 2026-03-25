# 🚀 LibWrt — 深度定制版 (基于 ImmortalWrt / IPQ60xx)

## ⚖️ 特别提示
- **免责声明**：本人不对使用本固件造成的任何硬件损坏或数据丢失负责。
- **合规使用**：本固件仅限技术交流，严禁用于商业用途。请自觉遵守国家相关法律规定。

## 🛠️ 对比上游源码的修改与优化

相比于原版 ImmortalWrt 源码，本项目进行了以下深度的定制与性能压榨：

### 1. 底层内核与驱动优化 (IPQ60xx 专项)
- **NSS 驱动内存重分配**：将 `q6_region` 内存预留从默认值优化至 **64MB**。在确保 WiFi 6 全速吞吐的同时，为系统腾出更多可用运行内存。
- **CPU 调度优化**：修改内核默认调频策略，强制锁定 `performance` (高性能) 模式，解决高带宽下载时的频率波动问题。
- **内存回收加速**：默认开启 `LRU_GEN` (多代最近最少使用) 算法，显著提升高负载下的系统流畅度并减少掉线风险。
- **闪存寿命保护**：通过 `remount,noatime` 挂载参数减少 eMMC 读写；将系统日志限制为 **64KB** 循环存储。

### 2. 软件与插件增减 (定制清单)
**新增插件/功能：**
- **HomeProxy**：集成最新版高效率代理工具，适配 **SagerNet 官方 Sing-box** 核心。
- **Argon Theme**：集成 jerrykuku 版经典主题及 `luci-app-argon-config` 配置插件。
- **雅典娜 LED 控制**：专项集成 `luci-app-athena-led`，支持京东云雅典娜等机型的 LED 灯光自定义控制。
- **高性能 Go 环境**：强制引入 `Golang 1.23+` 编译链，确保所有 Go 语言编写的包性能最优化。

**精简与移除：**
- **移除冗余组件**：剔除了上游自带的部分不常用 Luci 界面与过时的工具包。
- **清理冲突配置**：在编译脚本中强制清理了可能与新版插件产生冲突的旧版 feeds。

## 🔑 默认配置
| 项目 | 内容 |
| :--- | :--- |
| **管理地址** | `192.168.2.1` |
| **默认用户** | `root` |
| **默认密码** | `none` (无密码) |
| **主机名称** | `LibWrt` |

## 📦 固件定制指南
1. **Fork 本仓库**：修改 `configs/` 目录下的 `.config` 文件（`y` 为选定，`n` 为取消）。
2. **脚本干预**：在 `Roc-script.sh` 中修改默认 IP 或添加你自己的个性化指令。
3. **Actions 编译**：点击 `Actions` -> `Run workflow` 开始编译。
4. **固件下载**：请前往 [Releases](https://github.com/jeojeo1225/openwrt-ci-roc-6.x-jdc-ax1800-ipq60xx/releases) 获取。

## 🖇️ 鸣谢
- **上游源码**：[ImmortalWrt](https://github.com/immortalwrt/immortalwrt) | [SagerNet](https://github.com/SagerNet/sing-box)
- **核心组件**：[sbwml](https://github.com/sbwml) (Golang) | [jerrykuku](https://github.com/jerrykuku) (Argon)
