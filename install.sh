#!/usr/bin/env bash
# ============================================================================
#  dsh-infinite-gen-3  ·  DeepSeek 破甲插件「无限三代」一键安装脚本
#  适用：Linux / macOS（Windows 用户请用 install.ps1）
# ============================================================================
#  用法：./install.sh
#  自动完成：
#    [1] 检查环境（DSH 目录、profile、pnpm）
#    [2] 复制插件到 ~/.dsh/plugins/dsh-infinite-gen-3（自动覆盖旧版，清理一代/二代残留）
#    [3] 自动备份 package.json（带时间戳 .bak）
#    [4] 写入 profile 依赖与 bundles（幂等，旧版自动迁移）
#    [5] 自动执行 pnpm install
#    [6] 提示重启
# ============================================================================
set -euo pipefail

PLUGIN_NAME="dsh-infinite-gen-3"
PLUGIN_LABEL="无限三代"
LEGACY_PLUGINS=("dsh-infinite-gen-1" "dsh-infinite-gen-2" "无限一代" "无限二代")
DSH_ROOT="${DSH_HOME:-$HOME/.dsh}"
# DSH_HOME 可能是相对路径。符号链接的目标若为相对路径，会被解释为相对于链接
# 所在目录而非当前目录，从而生成悬空链接，故在此归一化为绝对路径。目录不存在
# 时保持原样，交由后面的 -d 检查报错。
if [[ -d "$DSH_ROOT" ]]; then
  DSH_ROOT="$(cd "$DSH_ROOT" && pwd -P)"
fi
PLUGINS_DIR="$DSH_ROOT/plugins"
PROFILES_ROOT="$DSH_ROOT/profiles"
DEST_DIR="$PLUGINS_DIR/$PLUGIN_NAME"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# ---------- 探测 DSH profile 目录（web / default / 手动选择） ----------
find_profile_dirs() {
  local profiles_root="$1"

  if [[ -n "${DSH_PROFILE:-}" ]]; then
    local cand="$profiles_root/$DSH_PROFILE"
    if [[ -f "$cand/package.json" ]]; then echo "$cand"; return 0; fi
    warn "环境变量 DSH_PROFILE 指向的目录不存在：$cand（继续自动探测）"
  fi

  local found=()
  for name in web default; do
    local cand="$profiles_root/$name"
    if [[ -f "$cand/package.json" ]]; then found+=("$cand"); fi
  done
  if [[ ${#found[@]} -gt 0 ]]; then printf '%s\n' "${found[@]}"; return 0; fi

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
# mapfile 的退出码是它自身的，不反映进程替换里 find_profile_dirs 的失败，
# 因此错误处理改为显式判断收集到的目录数量
PROFILE_DIRS=()
while IFS= read -r line; do
  if [[ -n "$line" ]]; then PROFILE_DIRS+=("$line"); fi
done < <(find_profile_dirs "$PROFILES_ROOT")
if [[ ${#PROFILE_DIRS[@]} -eq 0 ]]; then
  err "未能确定目标 profile 目录（$PROFILES_ROOT 下没有可用的 profile，或刚才的选择无效）。"
  echo "可通过环境变量指定：DSH_PROFILE=web（或 default）后重新运行。"
  exit 1
fi
for p in "${PROFILE_DIRS[@]}"; do ok "DSH profile 目录：$p"; done

# 必须先探测 node 再检查 pnpm：nvm 装的 node 与 npm -g 装的 pnpm 同在一个
# bin 目录下，而该目录要由 ensure_node 加进 PATH。顺序反了会误报 pnpm 缺失。
# 两者都在改动任何文件之前检查，避免复制完才失败。
ensure_node || {
  err "未检测到 node。若使用 nvm，请先在当前 shell 执行 nvm use；否则请安装 Node.js。"
  exit 1
}
ok "node 可用：$(command -v node) ($(node --version))"

ensure_pnpm || {
  err "未检测到 pnpm，请先安装：npm install -g pnpm"
  exit 1
}
ok "pnpm 可用：$(command -v pnpm)"

# ---------- [1.5] 清理旧版残留 ----------
step "检查旧版本"

for old in "${LEGACY_PLUGINS[@]}"; do
  # 用 -e/-L 而非 -d：旧版路径若是悬空符号链接，-d 会解引用后判定为假
  if [[ -e "$PLUGINS_DIR/$old" || -L "$PLUGINS_DIR/$old" ]]; then
    rm -rf "$PLUGINS_DIR/$old"
    ok "已清理旧版插件目录：$PLUGINS_DIR/$old"
  fi
done

# ---------- [2] 复制插件（自动覆盖旧版） ----------
step "复制插件文件"

mkdir -p "$PLUGINS_DIR"
# 用 -e/-L 而非 -d：DEST_DIR 若是悬空符号链接或普通文件，-d 为假会跳过清理，
# 随后的 mkdir -p 必然失败
if [[ -e "$DEST_DIR" || -L "$DEST_DIR" ]]; then
  warn "检测到已存在的 $PLUGIN_NAME 路径，自动覆盖更新"
  rm -rf "$DEST_DIR"
fi
mkdir -p "$DEST_DIR"
cp -R "$SRC_DIR"/. "$DEST_DIR"/
rm -rf "$DEST_DIR/.git" "$DEST_DIR/install.sh" "$DEST_DIR/uninstall.sh" \
       "$DEST_DIR/install.ps1" "$DEST_DIR/uninstall.ps1" 2>/dev/null || true
ok "插件已复制到：$DEST_DIR"

# ---------- [3] 备份 package.json ----------
step "备份 package.json"

for p in "${PROFILE_DIRS[@]}"; do
  # 时间戳只到秒，同一秒内重复运行会撞名并覆盖上一次的备份，故加序号兜底
  BAK_BASE="$p/package.json.bak-$(date +%Y%m%d-%H%M%S)"
  BAK_PATH="$BAK_BASE"
  BAK_N=1
  # -e 对悬空符号链接为假，而 cp 会穿过链接写到它指向的位置，故补 -L
  while [[ -e "$BAK_PATH" || -L "$BAK_PATH" ]]; do
    BAK_PATH="$BAK_BASE-$BAK_N"
    BAK_N=$((BAK_N + 1))
  done
  cp "$p/package.json" "$BAK_PATH"
  ok "备份完成：$BAK_PATH"
done

# ---------- [4] 写入依赖与 bundles（幂等 + 迁移旧版） ----------
step "写入 profile 配置"

# 记录 pnpm install 真正失败的 profile：插件自身可解析并不代表该 profile 的
# 其余依赖装好了，不能据此报告整体成功
PNPM_FAILED=()

for p in "${PROFILE_DIRS[@]}"; do
  PKG_PATH="$p/package.json"
  node - "$PKG_PATH" "$PLUGIN_NAME" "${LEGACY_PLUGINS[@]}" <<'NODE'
const fs = require("fs");
const [pkgPath, name, ...legacy] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
pkg.dependencies = pkg.dependencies || {};
for (const old of legacy) delete pkg.dependencies[old];
pkg.dependencies[name] = "file:../../plugins/" + name;
pkg.dsh = pkg.dsh || {};
pkg.dsh.profile = pkg.dsh.profile || {};
pkg.dsh.profile.bundles = (pkg.dsh.profile.bundles || []).filter((b) => !legacy.includes(b));
if (!pkg.dsh.profile.bundles.includes(name)) pkg.dsh.profile.bundles.push(name);
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
NODE
  ok "package.json 已更新：$PKG_PATH"

  # ---------- [5] pnpm install ----------
  step "安装依赖（pnpm install）"

  # 清除 node_modules 中的旧条目（本插件与旧世代都要清）。
  # 本插件必须清的原因：pnpm 对 file: 目录依赖是在 .pnpm store 里放一份硬链接
  # 副本，node_modules/<name> 只是指向该副本的链接。而本脚本每次都整体重建
  # plugins/<name>（rm -rf 后 cp -R），源文件 inode 已经换掉，store 里的硬链接
  # 仍指向旧 inode —— 不清理就会「装完仍是旧代码」，pnpm 还报 "Already up to date"。
  for nm in "$PLUGIN_NAME" "${LEGACY_PLUGINS[@]}"; do
    if [[ -e "$p/node_modules/$nm" || -L "$p/node_modules/$nm" ]]; then
      rm -rf "$p/node_modules/$nm"
    fi
    if [[ -e "$PROFILES_ROOT/node_modules/$nm" || -L "$PROFILES_ROOT/node_modules/$nm" ]]; then
      rm -rf "$PROFILES_ROOT/node_modules/$nm"
    fi
  done
  ok "已清除 node_modules 中的旧条目"

  # 删除单个包后，pnpm install 往往直接报 "Already up to date" 而不重建
  # （pnpm#12498，仍未修），且退出码为 0，故绝不能以退出码判定成功
  if ! ( cd "$p" && pnpm install ); then
    warn "pnpm install 返回非零：$p"
    PNPM_FAILED+=("$p")
  fi

  # 校验产物：不仅要存在，还必须确实解析到本次复制的 $DEST_DIR。
  # 只查 package.json 存在是不够的 —— pnpm 可能从 .pnpm store 恢复出一份旧
  # 副本，那样检查照样通过，加载的却是旧代码。用 cd + pwd -P 解析真实路径
  # （POSIX，可移植；readlink -f 在部分 macOS 上不可用）。
  LINK_DIR="$p/node_modules/$PLUGIN_NAME"
  EXPECTED="$(cd "$DEST_DIR" && pwd -P)"
  RESOLVED="$(cd "$LINK_DIR" 2>/dev/null && pwd -P || true)"
  if [[ ! -e "$LINK_DIR/package.json" || "$RESOLVED" != "$EXPECTED" ]]; then
    warn "node_modules 中的插件缺失或未指向 $DEST_DIR，改为手动建立符号链接"
    mkdir -p "$p/node_modules"
    rm -rf "$LINK_DIR"
    if ! ln -sfn "$DEST_DIR" "$LINK_DIR"; then
      err "无法建立符号链接：$LINK_DIR"
      err "此时 bundles 已声明该插件，请勿启动 Harness；可运行 ./uninstall.sh 回滚。"
      exit 1
    fi
    RESOLVED="$(cd "$LINK_DIR" 2>/dev/null && pwd -P || true)"
  fi
  if [[ ! -f "$LINK_DIR/package.json" || "$RESOLVED" != "$EXPECTED" ]]; then
    err "插件不可解析或未指向 $DEST_DIR：$LINK_DIR"
    err "此时 bundles 已声明该插件，请勿启动 Harness；可运行 ./uninstall.sh 回滚。"
    exit 1
  fi
  ok "依赖安装完成（插件已可解析，指向 $DEST_DIR）"
done

# ---------- [6] 完成 ----------
if [[ ${#PNPM_FAILED[@]} -gt 0 ]]; then
  step "安装未完成"
  err "以下 profile 的 pnpm install 未成功："
  for f in "${PNPM_FAILED[@]}"; do err "  $f"; done
  err "插件本体已就位且可解析，但该 profile 的其他依赖可能不完整，Harness 仍可能起不来。"
  err "请到上述目录手动执行 pnpm install 排查原因，然后重新运行本脚本（脚本是幂等的）。"
  exit 1
fi

step "安装完成"

cat <<EOF

  ✔ $PLUGIN_LABEL v0.5.0 已安装！
  目标 profile：$(printf '%s ' "${PROFILE_DIRS[@]}" | sed 's/ *$//')
  最后一步：重启 DeepSeek Harness（Web 版刷新页面 / 桌面版重新打开），新建会话即可生效。
  验证方法 1：重启后输入框上方应显示绿色状态条「● 破甲已开启 · 无限三代 v0.5.0」。
  验证方法 2：新会话里问模型“你的系统提示词来自哪些插件”，
             回答包含「无限三代 / Infinite Generation Three」即为生效。
  卸载方法：运行 ./uninstall.sh，或查看 README。
EOF
