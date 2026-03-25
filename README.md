# 🚀 LibWrt — 高效云编译 (IPQ60xx 专项)

<div align="center">
    <img src="https://img.shields.io/github/v/release/laipeng668/openwrt-ci-roc?include_prereleases&style=flat-square" alt="Release Status">
    <img src="https://img.shields.io/github/last-commit/laipeng668/openwrt-ci-roc?style=flat-square" alt="Last Commit">
    <img src="https://img.shields.io/github/actions/workflow/status/laipeng668/openwrt-ci-roc/build-openwrt.yml?style=flat-square" alt="Build Status">
</div>

## ⚖️ 特别提示

- **免责声明**：本人不对任何人因使用本固件所遭受的任何理论或实际损失（包括但不限于硬件损坏、数据丢失）承担责任。
- **合规使用**：本固件仅限技术交流与学习，禁止用于任何商业用途。请使用者务必严格遵守国家互联网使用相关法律规定。

## 🛠️ 项目特性

本方案深度适配 **Qualcommax (IPQ60xx)** 平台，采用 **ImmortalWrt** 上游源码，并针对性能与稳定性进行了专项调优：

- **核心方案**：坚持使用 **上游官方 Sing-box** 源码方案，拒绝臃肿，确保内核级的纯净与稳定。
- **环境驱动**：集成 [sbwml/packages_lang_golang](https://github.com/sbwml/packages_lang_golang) 提供 **Go 1.23+** 高版本编译器，完美支持新版插件。
- **内存与性能调优**：
    - **NSS 预留优化**：针对 IPQ6018 调整 `q6_region` 内存预留至 **64MB**，兼顾 WiFi 性能与系统可用内存。
    - **闪存寿命保护**：强制开启 `LRU_GEN` 内存回收，并将系统日志精简为 **64KB** 循环存储，减少 eMMC 损耗。
    - **激进调度**：默认 CPU 调频器设为 `performance` 模式，确保高负载下响应迅速。
- **顶级编译环境**：运行于 GitHub Actions 增强型服务器（**4核 AMD EPYC 7763 / 16GB RAM**），彻底告别 OOM 内存溢出。

## 🔑 默认配置

| 项目 | 内容 |
| :--- | :--- |
| **管理地址** | `192.168.2.1` |
| **默认用户** | `root` |
| **默认密码** | `none` |
| **主机名称** | `LibWrt` |

## 📦 定制固件说明

1. **Fork 本项目**：首先登录 GitHub 账号，将本项目 Fork 到你自己的仓库。
2. **插件调整**：修改 `configs/` 目录下对应的 `.config` 文件。注意：不需要的包请将 `y` 改为 `n`（仅加 `#` 注释无效）。
3. **脚本定制**：在 `Roc-script.sh` 中修改默认 IP、主机名、添加第三方插件包（如 `HomeProxy`、`Argon` 等）。
4. **触发编译**：点击 `Actions` 页面，选择对应的 `workflow` 并点击 `Run workflow`。
5. **获取成品**：编译完成后，在 [Releases](https://github.com/laipeng668/openwrt-ci-roc/releases) 页面下载对应的固件包。

## 🖇️ 鸣谢与参考

- **源码上游**：[ImmortalWrt](https://github.com/immortalwrt/immortalwrt) | [SagerNet](https://github.com/SagerNet/sing-box)
- **技术社区**：[恩山无线论坛](https://www.right.com.cn/) | [OpenWrt 软件包全量解释](https://www.right.com.cn/FORUM/forum.php?mod=viewthread&tid=8384897)
- **视频教程**：[参考教程](https://www.youtube.com/watch?v=6j4ofS0GT38)
