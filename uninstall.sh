#!/usr/bin/env bash
# ============================================================================
#  dsh-infinite-gen-3  ·  DeepSeek 破甲插件「无限三代」一键卸载脚本
#  适用：Linux / macOS（Windows 用户请用 uninstall.ps1）
# ============================================================================
#  用法：./uninstall.sh
#  自动完成（与 uninstall.ps1 保持一致）：
#    [1] 检查环境（DSH 目录、node）
#    [2] 从各 profile 的 package.json 移除一代/二代/三代的依赖与 bundles（先备份）
#    [3] 对改动过的 profile 执行 pnpm install 同步 lockfile
#    [4] 删除一代/二代/三代插件目录及 node_modules 残留
# ============================================================================
set -euo pipefail
# install.sh 支持用 DSH_PROFILE 指定 .custom 这类隐藏 profile，而 * 默认不匹配
# 点开头的名字。开启 dotglob 让下面的清理循环覆盖安装可能触及的全部 profile
#（bash 即使在 dotglob 下也不会让 * 匹配 . 和 ..）。
shopt -s dotglob

PLUGIN_LABEL="无限三代"
# 覆盖范围需与 install.sh 的 LEGACY_PLUGINS 一致，早期版本用的是中文目录名
ALL_GEN_PLUGINS=("dsh-infinite-gen-1" "dsh-infinite-gen-2" "dsh-infinite-gen-3" "无限一代" "无限二代")
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
# DSH_HOME 可能是相对路径。符号链接的目标若为相对路径，会被解释为相对于链接
# 所在目录而非当前目录，从而生成悬空链接，故在此归一化为绝对路径。目录不存在
# 时保持原样，交由后面的 -d 检查报错。
if [[ -d "$DSH_ROOT" ]]; then
  DSH_ROOT="$(cd "$DSH_ROOT" && pwd -P)"
fi
PLUGINS_DIR="$DSH_ROOT/plugins"
PROFILES_ROOT="$DSH_ROOT/profiles"

step() { printf "\n==> %s\n" "$1"; }
ok()   { printf "    [OK] %s\n" "$1"; }
warn() { printf "    [!] %s\n" "$1" >&2; }
err()  { printf "    [X] %s\n" "$1" >&2; }

# ---------- nvm / node / pnpm 探测（nvm 装的工具只在交互式 shell 里加载） ----------
# 把 nvm 的 bin 目录并入 PATH。nvm.sh 不兼容 set -eu，故把整个加载过程关进子
# shell，只取回它给出的 PATH；不可改为在当前 shell 里 set +eu 再用 $(set +o)
# 恢复 —— 命令替换本身是子 shell，其中采样到的 errexit 未必是父 shell 的真实
# 状态，会把 set -e 永久关掉。
load_nvm_path() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  if [[ ! -s "$nvm_dir/nvm.sh" ]]; then return 1; fi
  local new_path
  new_path="$(
    set +eu
    # shellcheck disable=SC1090
    . "$nvm_dir/nvm.sh" >/dev/null 2>&1 || exit 0
    if ! command -v node >/dev/null 2>&1; then
      nvm use --silent default >/dev/null 2>&1 || nvm use --silent node >/dev/null 2>&1 || true
    fi
    printf '%s' "$PATH"
  )"
  if [[ -z "$new_path" ]]; then return 1; fi
  PATH="$new_path"
  export PATH
  return 0
}

# node 与 pnpm 可能都只存在于 nvm 的 bin 目录，故各自在找不到时再加载一次；
# 只在 node 缺失时加载是不够的（系统自带 node + nvm 装的 pnpm 就会漏掉）
ensure_node() {
  if command -v node >/dev/null 2>&1; then return 0; fi
  load_nvm_path || return 1
  command -v node >/dev/null 2>&1
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then return 0; fi
  load_nvm_path || return 1
  command -v pnpm >/dev/null 2>&1
}

# ---------- [1] 检查环境 ----------
step "检查环境"

[[ -d "$DSH_ROOT" ]] || { err "未找到 DSH 目录：$DSH_ROOT"; exit 1; }
ok "DSH 目录：$DSH_ROOT"

# node 用于改写 package.json；提前检查，避免删掉插件目录后才失败
ensure_node || {
  err "未检测到 node。若使用 nvm，请先在当前 shell 执行 nvm use；否则请安装 Node.js。"
  exit 1
}
ok "node 可用：$(command -v node) ($(node --version))"

# ---------- [2] 清理 profile 配置 ----------
step "清理 profile 配置"

CHANGED_PROFILES=()
for pkg in "$PROFILES_ROOT"/*/package.json; do
  [[ -f "$pkg" ]] || continue
  # 时间戳只到秒，同一秒内重复运行会撞名并覆盖上一次的备份，故加序号兜底
  BAK_BASE="$pkg.bak-$(date +%Y%m%d-%H%M%S)"
  BAK_PATH="$BAK_BASE"
  BAK_N=1
  # -e 对悬空符号链接为假，而 cp 会穿过链接写到它指向的位置，故补 -L
  while [[ -e "$BAK_PATH" || -L "$BAK_PATH" ]]; do
    BAK_PATH="$BAK_BASE-$BAK_N"
    BAK_N=$((BAK_N + 1))
  done
  cp "$pkg" "$BAK_PATH"
  node - "$pkg" "${ALL_GEN_PLUGINS[@]}" <<'NODE'
const fs = require("fs");
const [pkgPath, ...names] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
let changed = false;
for (const name of names) {
  if (pkg.dependencies && name in pkg.dependencies) {
    delete pkg.dependencies[name];
    changed = true;
  }
  const bundles = pkg.dsh && pkg.dsh.profile && pkg.dsh.profile.bundles;
  if (Array.isArray(bundles) && bundles.includes(name)) {
    pkg.dsh.profile.bundles = bundles.filter((b) => b !== name);
    changed = true;
  }
}
// 仅在确有改动时写回，未引用本插件的 profile 不做任何改动
if (changed) fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
NODE
  if cmp -s "$pkg" "$BAK_PATH"; then
    rm -f "$BAK_PATH"
  else
    ok "已移除插件配置：$pkg"
    ok "原文件已备份：$BAK_PATH"
    CHANGED_PROFILES+=("$(dirname "$pkg")")
  fi
done

if [[ ${#CHANGED_PROFILES[@]} -eq 0 ]]; then
  ok "没有 profile 引用这些插件，跳过"
fi

# ---------- [3] 同步依赖 ----------
step "同步依赖（pnpm install）"

if [[ ${#CHANGED_PROFILES[@]} -eq 0 ]]; then
  ok "无需同步"
elif ! ensure_pnpm; then
  warn "未检测到 pnpm，跳过同步；请稍后在各 profile 目录手动执行 pnpm install"
else
  for p in "${CHANGED_PROFILES[@]}"; do
    if ( cd "$p" && pnpm install >/dev/null 2>&1 ); then
      ok "已同步：$p"
    else
      warn "pnpm install 未成功：$p（可稍后手动重试）"
    fi
  done
fi

# ---------- [4] 删除插件目录 ----------
step "删除插件目录"

REMOVED=0

# 必须先清 node_modules、后删插件目录：反过来的话，node_modules 里指向插件目录
# 的符号链接会先变成悬空链接，而 [[ -d ]] 会解引用、对悬空链接判定为假，于是
# 永远清不掉，留下坏链接让后续 pnpm install 报错。判断也用 -e 或 -L 兜住链接。
for name in "${ALL_GEN_PLUGINS[@]}"; do
  for nm in "$PROFILES_ROOT/node_modules/$name" "$PROFILES_ROOT"/*/node_modules/"$name"; do
    if [[ -e "$nm" || -L "$nm" ]]; then
      rm -rf "$nm"
      ok "已删除 node_modules 残留：$nm"
    fi
  done
done

for name in "${ALL_GEN_PLUGINS[@]}"; do
  # 与上面的 node_modules 清理一致，用 -e/-L 兜住悬空符号链接
  if [[ -e "$PLUGINS_DIR/$name" || -L "$PLUGINS_DIR/$name" ]]; then
    rm -rf "$PLUGINS_DIR/$name"
    ok "已删除插件目录：$PLUGINS_DIR/$name"
    REMOVED=$((REMOVED + 1))
  fi
done

if [[ $REMOVED -eq 0 ]]; then
  ok "插件目录不存在，跳过"
fi

# ---------- 完成 ----------
step "卸载完成"

cat <<EOF

  ✔ $PLUGIN_LABEL 已卸载。
  最后一步：重启 DeepSeek Harness（Web 版刷新页面 / 桌面版重新打开）。
  如需回滚，各 profile 目录下保留了 package.json.bak-* 备份。
EOF
