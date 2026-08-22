#!/usr/bin/env bash
# ============================================================================
#  dsh-infinite-gen-2  ·  DeepSeek 破甲插件「无限二代」一键卸载脚本
#  适用：Linux / macOS（Windows 用户请用 uninstall.ps1）
# ============================================================================
#  用法：chmod +x uninstall.sh && ./uninstall.sh
#  自动完成：
#    [1] 检查安装状态（含旧版 dsh-infinite-gen-1 残留）
#    [2] 自动备份 package.json（带时间戳 .bak）
#    [3] 从 dependencies 和 bundles 移除插件（新旧版本一并清理）
#    [4] 自动执行 pnpm install 清理依赖
#    [5] 删除插件目录（新旧版本一并清理）
#    [6] 提示重启
# ============================================================================
set -euo pipefail

PLUGIN_NAME="dsh-infinite-gen-2"
PLUGIN_LABEL="无限二代"
OLD_PLUGIN_NAME="dsh-infinite-gen-1"
ALL_NAMES=("$PLUGIN_NAME" "$OLD_PLUGIN_NAME")
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
PLUGINS_DIR="$DSH_ROOT/plugins"
DEST_DIR="$PLUGINS_DIR/$PLUGIN_NAME"
OLD_DEST_DIR="$PLUGINS_DIR/$OLD_PLUGIN_NAME"

step() { printf "\n==> %s\n" "$1"; }
ok()   { printf "    [OK] %s\n" "$1"; }
warn() { printf "    [!] %s\n" "$1"; }
err()  { printf "    [X] %s\n" "$1" >&2; }

# ---------- 探测 DSH profile 目录 ----------
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
    echo "检测到多个 DSH profile，请选择要卸载的目标：" >&2
    for i in "${!dirs[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${dirs[$i]}" >&2; done
    read -rp "请输入序号: " sel
    local idx=$((sel-1))
    if (( idx >= 0 && idx < ${#dirs[@]} )); then echo "${dirs[$idx]}"; return 0; fi
    err "选择无效，退出。"
    exit 1
  fi
  return 1
}

# ---------- [1] 检查 ----------
step "检查安装状态"

PROFILE_DIR="$(find_profile_dir "$DSH_ROOT/profiles" 2>/dev/null || true)"
PKG_PATH=""
if [[ -n "$PROFILE_DIR" ]]; then PKG_PATH="$PROFILE_DIR/package.json"; fi

INSTALLED=false
for dir in "$DEST_DIR" "$OLD_DEST_DIR"; do
  [[ -d "$dir" ]] && INSTALLED=true
done
if [[ -n "$PKG_PATH" && -f "$PKG_PATH" ]]; then
  if node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const names = process.argv.slice(2);
    const deps = pkg.dependencies || {};
    const bundles = (pkg.dsh && pkg.dsh.profile && pkg.dsh.profile.bundles) || [];
    process.exit(names.some((n) => deps[n] !== undefined || bundles.includes(n)) ? 0 : 1);
  ' "$PKG_PATH" "${ALL_NAMES[@]}"; then
    INSTALLED=true
  fi
fi

if [[ "$INSTALLED" != "true" ]]; then
  warn "未检测到 $PLUGIN_LABEL（或旧版）的安装痕迹，无需卸载。"
  exit 0
fi
ok "检测到 $PLUGIN_LABEL 已安装，开始卸载（目标：$PROFILE_DIR）"

# ---------- [2] 备份 ----------
step "备份 package.json"

BAK_PATH="$PKG_PATH.bak-$(date +%Y%m%d-%H%M%S)"
if [[ -f "$PKG_PATH" ]]; then
  cp "$PKG_PATH" "$BAK_PATH"
  ok "备份完成：$BAK_PATH"
fi

# ---------- [3] 从配置移除（新旧版本一并清理） ----------
step "从 profile 配置移除插件"

if [[ -f "$PKG_PATH" ]]; then
  CHANGED=$(node -e '
    const fs = require("fs");
    const pkgPath = process.argv[1];
    const names = process.argv.slice(2);
    const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
    let changed = false;
    if (pkg.dependencies) {
      for (const n of names) {
        if (pkg.dependencies[n] !== undefined) { delete pkg.dependencies[n]; changed = true; }
      }
    }
    if (pkg.dsh && pkg.dsh.profile && Array.isArray(pkg.dsh.profile.bundles)) {
      const before = pkg.dsh.profile.bundles.length;
      pkg.dsh.profile.bundles = pkg.dsh.profile.bundles.filter((b) => !names.includes(b));
      if (pkg.dsh.profile.bundles.length !== before) changed = true;
    }
    if (changed) fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
    process.stdout.write(changed ? "1" : "0");
  ' "$PKG_PATH" "${ALL_NAMES[@]}")
  if [[ "$CHANGED" == "1" ]]; then
    ok "package.json 已更新（已移除：${ALL_NAMES[*]}）"
  else
    warn "package.json 中未找到插件配置，无需修改"
  fi
fi

# ---------- [4] pnpm install ----------
step "清理依赖（pnpm install）"

if [[ -n "$PROFILE_DIR" && -d "$PROFILE_DIR" ]]; then
  (
    cd "$PROFILE_DIR"
    pnpm install >/dev/null 2>&1 || warn "pnpm install 未完全成功，可稍后手动执行：cd $PROFILE_DIR && pnpm install"
  )
  ok "依赖清理完成"
fi

# ---------- [5] 删除插件目录（新旧版本一并清理） ----------
step "删除插件目录"

for dir in "$DEST_DIR" "$OLD_DEST_DIR"; do
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    ok "已删除：$dir"
  else
    warn "插件目录不存在，跳过：$dir"
  fi
done

# ---------- [6] 完成 ----------
step "卸载完成"

cat <<EOF

  ✔ 插件已卸载！
  最后一步：重启 DeepSeek Harness（完全退出后重新打开）即可。
  提示：若误卸载，运行 ./install.sh 可重新安装。
EOF
