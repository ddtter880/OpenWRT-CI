#!/bin/bash
# ============================================================================
# 私有扩展脚本 (PRIVATE.sh)
# 由 Scripts/Packages.sh 在末尾 source 调用，工作目录为 ./wrt/package/
# 用途：仅在用户 fork (ddtter880/OpenWRT-CI) 中加入额外软件包源码，
#       不改动上游 VIKINGYFY/OpenWRT-CI 的 Packages.sh / Config/*.txt。
# 配套配置文件：Config/PRIVATE.txt (追加到 .config 的 =y 选项)
# ============================================================================

# ---------------------------------------------------------------------------
# luci-app-dockerman (Docker 管理)
# 仓库为单体结构，包位于 applications/luci-app-dockerman，用 pkg 特例提取
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "dockerman" "lisaac/luci-app-dockerman" "master" "pkg"

# ---------------------------------------------------------------------------
# luci-app-adguardhome (广告过滤)
# 仓库根即为 luci-app 包，空特例直接克隆进 package/
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "adguardhome" "rufengsuixing/luci-app-adguardhome" "master" ""

# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# luci-app-tailscale-community (Tailscale 虚拟组网)
# 仓库根含 luci-app-tailscale-community 子目录，用 pkg 特例提取
# 依赖 +tailscale 进程包（标准 packages feed 提供）
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "tailscale-community" "Tokisaki-Galaxy/luci-app-tailscale-community" "master" "pkg"

# ---------------------------------------------------------------------------
# luci-app-lucky (多功能网络代理)
# 仓库根含 luci-app-lucky(luci 前端) 与 lucky(进程包) 两个子目录，
# pkg 特例匹配 *lucky* 会同时拷贝两者
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main" "pkg"

# ---------------------------------------------------------------------------
# luci-app-oaf (应用过滤，已启用并随系统启动)
# 仓库根含 luci-app-oaf(luci 前端) / oaf(kmod) / open-app-filter(后端)，
# pkg 特例匹配 *oaf* 会同时拷贝三者，保证依赖完整
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "oaf" "destan19/OpenAppFilter" "master" "pkg"

# 让 oaf 应用过滤后端(appfilter)在镜像首次启动时自动启用（uci-defaults 覆盖进固件）
mkdir -p ../files/etc/uci-defaults
cat > ../files/etc/uci-defaults/zz_oaf_enable <<'EOF'
/etc/init.d/appfilter enable 2>/dev/null
exit 0
EOF

# ---------------------------------------------------------------------------
# luci-app-pbr (策略路由)
# 仓库根为 luci-app-pbr 包；依赖 +pbr 进程包（标准 packages feed 提供）
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "pbr" "stangri/luci-app-pbr" "main" ""

# ---------------------------------------------------------------------------
# daed (eBPF 代理，需内核 BTF) —— 使用 immortalwrt 官方 feed 版本，不要克隆第三方前端
# ---------------------------------------------------------------------------
# 【重要·回归教训】曾用 UPDATE_PACKAGE 从 QiuSimons/luci-app-daed (kix) 克隆，它会先
# 删除官方 feed 的新架构包（feeds/luci/applications/luci-app-daed、feeds/packages/net/daed），
# 再放入「老式 Lua 界面（luasrc/）」。本固件是 modern LuCI（immortalwrt 23.05+ ucode 架构），
# 老 Lua 界面依赖 luci-compat 的 Lua 兼容桥（luci.sys / nixio 等不完整），controller 的
# index() 执行失败 -> entry(...) 菜单静默不注册 -> 用户在 LuCI 里「看不到 daed」。
# 官方 immortalwrt/luci 的 luci-app-daed 已是 htdocs/（JS + ucode 新架构）；
# 官方 immortalwrt/packages 的 daed 直接用 GitHub Release 预编译 web.zip（CI 无需跑 pnpm），
# 依赖 daed-geoip/daed-geosite（<- v2ray-geodata）均来自标准 feed，开箱即用。
# 因此此处不再克隆 daed 源码，直接用官方 feed。内核 BTF 见 Config/PRIVATE.txt。

# ---------------------------------------------------------------------------
# luci-app-istorex (iStore 应用商店) + iStore 依赖生态
# linkease/nas-packages-luci 为单体仓库，luci-app-istorex 的全部依赖
# (luci-lib-iform / luci-lib-linkeasefile / luci-lib-linkeaseauth /
#  luci-app-quickstart / luci-mod-istorenext / luci-nginxer /
#  luci-theme-istorenas 等) 均在同一仓库的 luci/ 目录下，
# 因此直接复制整个 luci/ 目录，确保依赖完整可编译。
# ---------------------------------------------------------------------------
if [ -d "./nas-packages-luci" ]; then
	rm -rf ./nas-packages-luci/
fi
git clone --depth=1 --single-branch --branch main "https://github.com/linkease/nas-packages-luci.git"
if [ -d "./nas-packages-luci/luci" ]; then
	cp -rf ./nas-packages-luci/luci/* ./ 2>/dev/null || true
fi
rm -rf ./nas-packages-luci/
