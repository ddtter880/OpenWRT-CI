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
# daed (eBPF 代理，需内核 BTF)
# 仓库根含 daed(进程包) 与 luci-app-daed(luci 前端)，pkg 特例匹配 *daed* 同拷
# 内核 BTF 选项见 Config/PRIVATE.txt
# ---------------------------------------------------------------------------
UPDATE_PACKAGE "daed" "QiuSimons/luci-app-daed" "kix" "pkg"
# ---------------------------------------------------------------------------
# daed web UI 构建修复（eBPF 代理需要浏览器前端，Go 端 //go:embed "web" 嵌入）
# 根因：daed 源码仓库的 pnpm-lock.yaml 已过期（@graphql-codegen/cli 版本错位），
#       而 CI 环境 pnpm 默认 frozen-lockfile，导致 `pnpm install` 直接失败 ->
#       node_modules 缺失 -> `turbo run build` 报 turbo: not found ->
#       apps/web/dist 不生成 -> webrender.go 的 //go:embed "web" 失败：
#       "cannot embed directory web: contains no embeddable files" -> daed 编译失败。
# 修复：克隆后把 `pnpm install` 改为 `pnpm install --no-frozen-lockfile`，
#       让 pnpm 按 package.json 重建 lockfile 并继续安装（网络在 CI 中可用）。
# ---------------------------------------------------------------------------
if [ -f "./daed/Makefile" ]; then
	# 根治 frozen-lockfile：CI 默认 frozen-lockfile=true 且 dae-wing lockfile 过期，
	# 导致 pnpm install 失败 -> turbo 缺失 -> apps/web/dist 不生成 -> go embed 失败。
	# 广谱替换所有 pnpm install 为 CI=false pnpm install --no-frozen-lockfile。
	grep -q -- '--no-frozen-lockfile' "./daed/Makefile" || \
		sed -i 's#pnpm install#CI=false pnpm install --no-frozen-lockfile#g' "./daed/Makefile"
fi

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
