# OpenWRT-CI（ddtter880 自用固件）

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 云编译框架的**个人定制版**，
源码来自 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt)（`main` 分支）。
本仓库在框架标准配置之外，通过 `Scripts/PRIVATE.sh` + `Config/PRIVATE.txt` 两个扩展文件
预置了 **21 个 luci-app 软件包**、**启用 Wi-Fi**、并为 **daed** 开启内核 BTF。

---

## 一、固件定位与设备支持

- 编译平台（矩阵）：IPQ60XX（含 WIFI-YES / WIFI-NO）、IPQ807X（WIFI-YES / WIFI-NO）。
- **主要目标设备：`link_nn6000-v2`（高通 qualcommax / ipq60xx）**，已包含在 `IPQ60XX-*` 设备列表中。
- 同平台其他已内置设备：anysafe_e1、cmiot_ax18、glinet_gl-ax1800/axt1800、jdcloud_re-cs-02/07/ss-01、
  link_nn6000-v1、linksys_mr7350/7500、philips_ly1800、qihoo_360v6、redmi_ax5(-jdcloud)、sy_y6010、xiaomi_ax1800、zn_m2 等。

> ⚠️ **刷机请选 `IPQ60XX-WIFI-YES` 产物**：该产物启用 ath11k 无线驱动，固件带 Wi-Fi。
> `IPQ60XX-WIFI-NO` 仅关闭 `.config` 中的 ath11k 并把设备树换成 nowifi，**无线不可用**，一般无需刷。

---

## 二、已集成软件包清单（21 个）

所有包均通过 `Config/PRIVATE.txt` 设为 `=y` 编译进固件；应用过滤(oaf)亦已启用，
并在镜像首次启动时自动开启后端服务。
框架已自带的部分（argon 主题、diskman、quickfile、easytier、passwall）仅在此补开，不重复注入源码。

### 主题与界面
| 软件包 | 说明 | 状态 |
| --- | --- | --- |
| `luci-theme-argon` | Argon 主题（含 `luci-app-argon-config`） | ✅ 已启用（默认主题仍为 aurora，可在 LuCI 切换） |

### 应用商店 / 存储管理
| 软件包 | 说明 | 状态 |
| --- | --- | --- |
| `luci-app-istorex` | iStore 应用商店 | ✅ 已启用 |
| `luci-app-dockerman` | Docker 容器管理 | ✅ 已启用 |
| `luci-app-diskman` | 磁盘管理 | ✅ 已启用 |
| `luci-app-quickfile` | 文件管理 | ✅ 已启用 |
| `luci-app-samba4` | SMB 文件共享 | ✅ 已启用 |
| `luci-app-hd-idle` | 硬盘休眠 | ✅ 已启用 |
| `luci-app-p910nd` | USB 打印机共享 | ✅ 已启用 |

### 网络 / 代理 / 加速
| 软件包 | 说明 | 状态 |
| --- | --- | --- |
| `luci-app-passwall` | Passwall 代理 | ✅ 已启用 |
| `luci-app-daed` | daed（eBPF 代理，**需内核 BTF**） | ✅ 已启用 |
| `luci-app-lucky` | 多功能网络代理 | ✅ 已启用 |
| `luci-app-smartdns` | SmartDNS（DNS 加速，含 `smartdns` 进程包） | ✅ 已启用 |
| `luci-app-pbr` | 策略路由（含 `pbr` 进程包） | ✅ 已启用 |
| `luci-app-easytier` | EasyTier 虚拟组网 | ✅ 已启用 |
| `luci-app-tailscale-community` | Tailscale 虚拟组网（含 `tailscale` 进程包） | ✅ 已启用 |
| `luci-app-adguardhome` | AdGuardHome 广告过滤 | ✅ 已启用 |

### 系统 / 工具
| 软件包 | 说明 | 状态 |
| --- | --- | --- |
| `luci-app-autoreboot` | 定时重启 | ✅ 已启用 |
| `luci-app-sqm` | QoS 智能队列 | ✅ 已启用 |
| `luci-app-upnp` | UPnP 端口映射 | ✅ 已启用 |
| `luci-app-ttyd` | 网页终端 | ✅ 已启用 |
| `luci-app-oaf` | 应用过滤（OpenAppFilter，含后端 appfilter 与 kmod-oaf） | ✅ 已启用（镜像首次启动自动开启服务） |

---

## 三、关键说明

### Wi-Fi
`Config/PRIVATE.txt` 显式开启 ath11k 驱动与固件（`kmod-ath11k`、`ath11k-firmware-ipq6018/qcn9074` 等）。
实际可刷的无线固件为 **`IPQ60XX-WIFI-YES`** 产物。

### daed 与内核 BTF
daed 基于 eBPF CO-RE，运行时需要内核 `/sys/kernel/btf/vmlinux`。
本仓库已开启 `CONFIG_KERNEL_DEBUG_INFO=y` 与 `CONFIG_KERNEL_DEBUG_INFO_BTF=y`，
否则 daed 即使装进固件也无法启动（这正是“opkg 安装后 daed 起不来”的根因）。
注意：开启 BTF 会使内核体积与编译时间明显增加。

### iStore（istorex）依赖
istorex 依赖 iStore 后端生态。`Config/PRIVATE.txt` 开启 `luci-app-istorex=y`，
源码通过复制 `linkease/nas-packages-luci` 整个 `luci/` 目录带入其全部前端依赖。
若 defconfig 判定后端不全，istorex 可能被静默取消选中（不影响整体编译）。

---

## 四、默认登录信息

| 项目 | 值 |
| --- | --- |
| 管理地址 | `192.168.10.1` |
| 主机名 | `OWRT` |
| Wi-Fi 名称 | `OWRT` |
| Wi-Fi 密码 | `12345678` |
| 默认主题 | `argon`（Argon 主题，已设为默认） |

---

## 五、如何自行增删软件包（扩展点）

本仓库刻意**不改动**上游 `Scripts/Packages.sh` 与 `Config/*.txt`，所有定制集中在两个扩展文件，
由框架在编译时自动调用：

- **`Scripts/PRIVATE.sh`**：在 `Packages.sh` 末尾被 `source` 调用，用于克隆额外的软件包源码
  （使用框架提供的 `UPDATE_PACKAGE` 函数）。新增源码型包时在此追加一行即可。
- **`Config/PRIVATE.txt`**：在 `Settings.sh` 中于 `cat Config/*.txt >> .config` 之后被追加到 `.config`，
  用于把包设为 `=y` / `=n`。新增配置项（开启/禁用某个包、内核选项）写在这里。

> 这两个文件在 `Config/*.txt` 之后追加，相同配置符号以 `PRIVATE.txt` 为准（后写覆盖）。

---

## 六、本地编译 / 自动编译

- 自动编译：GitHub Actions 的 `QCA-ALL.yml` 工作流（手动 `workflow_dispatch` 触发，或 `Auto-Clean` 完成后自动触发）。
- 手动验证配置：可用 `WRT-TEST.yml`（仅生成 `.config`，不编译固件）先核对配置。
- 本地编译工具链参考上游：[VIKINGYFY/OWRT-Tools](https://github.com/VIKINGYFY/OWRT-Tools.git)

---

## 七、参考资源（上游）

- 高质量交流群（IPQ）：https://qm.qq.com/q/v7nMhzB4oU
- 付费中转站 LiBwrt-Ai：https://api.zipimg.cn/register?aff=LR7FSZ2ZZ4D3
- 上游框架：https://github.com/VIKINGYFY/OpenWRT-CI
- 上游源码：https://github.com/VIKINGYFY/immortalwrt （官方：https://github.com/immortalwrt/immortalwrt）
- 自用修改版插件：https://github.com/VIKINGYFY/packages
- U-BOOT：
  - 高通版-沉心：https://github.com/chenxin527/uboot-qsdk12.5-build.git
  - 高通版-小猪：https://github.com/1980490718/u-boot-2016.git
  - 联发科-全新版：https://github.com/VIKINGYFY/UBOOT-CI/releases
  - 联发科-官方版：https://drive.wrt.moe/uboot/mediatek

## 八、目录说明

- `workflows/` —— 自定义 CI 配置（编译流程）
- `Scripts/` —— 自定义脚本（`Packages.sh` 注入包、`Settings.sh` 改配置、`PRIVATE.sh` 为私有扩展）
- `Config/` —— 自定义配置（`GENERAL.txt` 通用项、`IPQ60XX-*` 平台项、`PRIVATE.txt` 为私有扩展）
