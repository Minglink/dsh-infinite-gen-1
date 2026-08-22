#!/usr/bin/env bash
# ============================================================================
#  dsh-infinite-gen-2  ·  DeepSeek 破甲插件「无限二代」一键安装脚本
#  适用：Linux / macOS（Windows 用户请用 install.ps1）
# ============================================================================
#  用法：chmod +x install.sh && ./install.sh
#  自动完成：
#    [1] 检查环境（DSH 目录、profile、pnpm）
#    [2] 复制插件到 ~/.dsh/plugins/dsh-infinite-gen-2（自动覆盖旧版，清理一代残留）
#    [3] 自动备份 package.json（带时间戳 .bak）
#    [4] 写入 profile 依赖与 bundles（幂等，旧版 dsh-infinite-gen-1 自动迁移）
#    [5] 自动执行 pnpm install
#    [6] 提示重启
# ============================================================================
set -euo pipefail

PLUGIN_NAME="dsh-infinite-gen-2"
PLUGIN_LABEL="无限二代"
OLD_PLUGIN_NAME="dsh-infinite-gen-1"
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
PLUGINS_DIR="$DSH_ROOT/plugins"
DEST_DIR="$PLUGINS_DIR/$PLUGIN_NAME"
OLD_DEST_DIR="$PLUGINS_DIR/$OLD_PLUGIN_NAME"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf "\n==> %s\n" "$1"; }
ok()   { printf "    [OK] %s\n" "$1"; }
warn() { printf "    [!] %s\n" "$1"; }
err()  { printf "    [X] %s\n" "$1" >&2; }

# ---------- 探测 DSH profile 目录（web / default / 手动选择） ----------
find_profile_dir() {
  local profiles_root="$1"

  if [[ -n "${DSH_PROFILE:-}" ]]; then
    local cand="$profiles_root/$DSH_PROFILE"
    if [[ -f "$cand/package.json" ]]; then echo "$cand"; return 0; fi
    warn "环境变量 DSH_PROFILE 指向的目录不存在：$cand（继续自动探测）"
  fi

  for name in web default; do
    local cand="$profiles_root/$name"
    if [[ -f "$cand/package.json" ]]; then echo "$cand"; return 0; fi
  done

  local dirs=()
  for d in "$profiles_root"/*/; do
    [[ -d "$d" && -f "$d/package.json" ]] && dirs+=("$d")
  done
  if [[ ${#dirs[@]} -eq 1 ]]; then echo "${dirs[0]}"; return 0; fi
  if [[ ${#dirs[@]} -gt 1 ]]; then
    echo "检测到多个 DSH profile，请选择要安装的目标：" >&2
    for i in "${!dirs[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${dirs[$i]}" >&2; done
    read -rp "请输入序号: " sel
    local idx=$((sel-1))
    if (( idx >= 0 && idx < ${#dirs[@]} )); then echo "${dirs[$idx]}"; return 0; fi
    err "选择无效，退出。"
    exit 1
  fi
  return 1
}

# ---------- [1] 检查环境 ----------
step "检查环境"

[[ -d "$DSH_ROOT" ]] || { err "未找到 DSH 目录：$DSH_ROOT"; exit 1; }
PROFILE_DIR="$(find_profile_dir "$DSH_ROOT/profiles")" || {
  err "未找到 DSH profile 目录（$DSH_ROOT/profiles 下没有含 package.json 的目录）。"
  echo "可通过环境变量指定：DSH_PROFILE=web（或 default）后重新运行。"
  exit 1
}
PKG_PATH="$PROFILE_DIR/package.json"
[[ -f "$PKG_PATH" ]] || { err "未找到 package.json：$PKG_PATH"; exit 1; }
ok "DSH profile 目录：$PROFILE_DIR"

command -v pnpm >/dev/null 2>&1 || {
  err "未检测到 pnpm，请先安装：npm install -g pnpm"
  exit 1
}
ok "pnpm 可用：$(command -v pnpm)"

# ---------- [1.5] 清理旧版 gen-1 残留 ----------
step "检查旧版本"

if [[ -d "$OLD_DEST_DIR" ]]; then
  rm -rf "$OLD_DEST_DIR"
  ok "已清理旧版插件目录：$OLD_DEST_DIR"
else
  ok "未发现旧版插件目录（$OLD_PLUGIN_NAME），无需清理"
fi

# ---------- [2] 复制插件（自动覆盖旧版） ----------
step "复制插件文件"

mkdir -p "$PLUGINS_DIR"
if [[ -d "$DEST_DIR" ]]; then
  warn "检测到已存在的 $PLUGIN_NAME 目录，自动覆盖更新"
  rm -rf "$DEST_DIR"
fi
mkdir -p "$DEST_DIR"
cp -R "$SRC_DIR"/. "$DEST_DIR"/
rm -rf "$DEST_DIR/.git" "$DEST_DIR/install.sh" "$DEST_DIR/uninstall.sh" \
       "$DEST_DIR/install.ps1" "$DEST_DIR/uninstall.ps1" 2>/dev/null || true
ok "插件已复制到：$DEST_DIR"

# ---------- [3] 备份 package.json ----------
step "备份 package.json"

BAK_PATH="$PKG_PATH.bak-$(date +%Y%m%d-%H%M%S)"
cp "$PKG_PATH" "$BAK_PATH"
ok "备份完成：$BAK_PATH"

# ---------- [4] 写入依赖与 bundles（幂等 + 迁移旧版） ----------
step "写入 profile 配置"

node - "$PKG_PATH" "$PLUGIN_NAME" "$OLD_PLUGIN_NAME" <<'NODE'
const fs = require("fs");
const [pkgPath, name, oldName] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
pkg.dependencies = pkg.dependencies || {};
delete pkg.dependencies[oldName];
pkg.dependencies[name] = "file:../../plugins/" + name;
pkg.dsh = pkg.dsh || {};
pkg.dsh.profile = pkg.dsh.profile || {};
pkg.dsh.profile.bundles = (pkg.dsh.profile.bundles || []).filter((b) => b !== oldName);
if (!pkg.dsh.profile.bundles.includes(name)) pkg.dsh.profile.bundles.push(name);
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
NODE
ok "package.json 已更新（dependencies/bundles：$PLUGIN_NAME，旧版 $OLD_PLUGIN_NAME 已迁移）"

# ---------- [5] pnpm install ----------
step "安装依赖（pnpm install）"

(
  cd "$PROFILE_DIR"
  if ! pnpm install; then
    err "pnpm install 失败，请手动执行：cd $PROFILE_DIR && pnpm install"
    exit 1
  fi
)
ok "依赖安装完成"

# ---------- [6] 完成 ----------
step "安装完成"

cat <<EOF

  ✔ 插件已安装！
  目标 profile：$(basename "$PROFILE_DIR")
  最后一步：重启 DeepSeek Harness（Web 版刷新页面 / 桌面版重新打开），新建会话即可生效。
  验证方法 1：重启后输入框上方应显示绿色状态条「● 破甲已开启」。
  验证方法 2：新会话里问模型“你的系统提示词来自哪些插件”，
             回答包含「无限二代 / Infinite Generation Two」即为生效。
  卸载方法：运行 ./uninstall.sh，或查看 README。
EOF
