<#
============================================================================
  dsh-infinite-gen-1  ·  DeepSeek 破甲插件「无限一代」一键安装脚本
============================================================================
  用法（任选其一）：
    1. 右键 install.ps1 → “使用 PowerShell 运行”
    2. 在 PowerShell 中执行：  .\install.ps1
    3. 双击 install.ps1（若被系统拦截，用方式 1 或 2）

  脚本会依次自动完成：
    [1] 检查环境（DSH 目录、profile、pnpm）
    [2] 把插件复制到 ~\.dsh\plugins\dsh-infinite-gen-1
    [3] 自动备份 package.json（生成带时间戳的 .bak 文件）
    [4] 把插件写入 profile 依赖和 bundles 列表（重复运行不会加第二次）
    [5] 自动执行 pnpm install
    [6] 提示重启会话

  安全说明：
    - 脚本只改动两个地方：~\.dsh\plugins\ 和 ~\.dsh\profiles\default\package.json
    - 改动前都会自动备份，随时可以卸载还原
    - 不会上传任何数据，纯本地操作
============================================================================
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pluginName   = 'dsh-infinite-gen-1'
$pluginLabel  = '无限一代'

# ---------- 输出辅助 ----------
function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "    [X] $Msg" -ForegroundColor Red }

# ---------- 路径 ----------
$dshRoot     = Join-Path $env:USERPROFILE '.dsh'
$pluginsDir  = Join-Path $dshRoot 'plugins'
$profileDir  = Join-Path $dshRoot 'profiles\default'
$pkgPath     = Join-Path $profileDir 'package.json'
$destDir     = Join-Path $pluginsDir $pluginName
$srcDir      = $PSScriptRoot   # 本脚本所在目录 = 插件根目录

Write-Host "`n====================" -ForegroundColor Cyan
Write-Host "  $pluginLabel 一键安装" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# ---------- [1] 检查环境 ----------
Write-Step '检查环境'

if (-not (Test-Path $profileDir)) {
    Write-Err "未找到 DSH profile 目录：$profileDir"
    Write-Host  '请确认已安装并启动过 DeepSeek Harness，然后再运行本脚本。' -ForegroundColor Red
    exit 1
}
Write-Ok "DSH profile 目录存在：$profileDir"

if (-not (Test-Path $pkgPath)) {
    Write-Err "未找到 package.json：$pkgPath"
    exit 1
}
Write-Ok "package.json 存在"

$pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
if (-not $pnpm) {
    Write-Err '未检测到 pnpm。'
    Write-Host  '请先安装 pnpm：' -ForegroundColor Yellow
    Write-Host  '    npm install -g pnpm' -ForegroundColor Yellow
    exit 1
}
Write-Ok "pnpm 可用：$($pnpm.Source)"

if (-not (Test-Path $srcDir)) {
    Write-Err "找不到插件源码目录：$srcDir（脚本必须放在插件文件夹内运行）"
    exit 1
}

# ---------- [2] 复制插件到 plugins 目录 ----------
Write-Step '复制插件文件'

if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }

if (Test-Path $destDir) {
    Write-Warn "插件目录已存在，跳过复制：$destDir"
    Write-Warn '（若想强制更新，请先删除该目录后重新运行本脚本）'
} else {
    # 用 robocopy 整体复制：正确处理子目录（prompts/ 等）结构，且自动排除
    # 安装脚本自身与 .git 元数据（robocopy 是 Windows 自带工具，稳定可靠）
    robocopy $srcDir $destDir /E /NFL /NDL /NJH /NJS /NC /NS `
        /XD .git `
        /XF install.ps1 uninstall.ps1 | Out-Null
    # robocopy 退出码 0-7 均表示成功（0=无文件复制，1=有文件复制）
    if ($LASTEXITCODE -ge 8) {
        Write-Err "复制失败（robocopy 退出码 $LASTEXITCODE）"
        exit 1
    }
    Write-Ok "插件已复制到：$destDir"
}

# ---------- [3] 备份 package.json ----------
Write-Step '备份 package.json'

$bakPath = "$pkgPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $pkgPath -Destination $bakPath -Force
Write-Ok "备份完成：$bakPath"

# ---------- [4] 写入依赖与 bundles（幂等） ----------
Write-Step '写入 profile 配置'

$pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 4a. dependencies
if (-not $pkg.dependencies) { $pkg | Add-Member -NotePropertyName 'dependencies' -NotePropertyValue @{} }
if ($pkg.dependencies.PSObject.Properties.Name -contains $pluginName) {
    Write-Warn "dependencies 已包含 $pluginName，跳过"
} else {
    $pkg.dependencies | Add-Member -NotePropertyName $pluginName -NotePropertyValue "file:../../plugins/$pluginName" -Force
    Write-Ok "dependencies 已添加：$pluginName -> file:../../plugins/$pluginName"
}

# 4b. bundles
if (-not $pkg.dsh) { $pkg | Add-Member -NotePropertyName 'dsh' -NotePropertyValue @{} }
if (-not $pkg.dsh.profile) { $pkg.dsh | Add-Member -NotePropertyName 'profile' -NotePropertyValue @{} }
if (-not $pkg.dsh.profile.bundles) { $pkg.dsh.profile | Add-Member -NotePropertyName 'bundles' -NotePropertyValue @() }

if ($pkg.dsh.profile.bundles -contains $pluginName) {
    Write-Warn "bundles 已包含 $pluginName，跳过"
} else {
    $pkg.dsh.profile.bundles += $pluginName
    Write-Ok "bundles 已添加：$pluginName"
}

# 写回（ConvertTo-Json 默认输出即可，保持合法 JSON）
# 注意：必须用「无 BOM」的 UTF-8 写入，否则 node/pnpm 会报 Invalid package.json
$json = $pkg | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($pkgPath, $json, $utf8NoBom)
Write-Ok 'package.json 已更新'

# ---------- [5] pnpm install ----------
Write-Step '安装依赖（pnpm install）'

Push-Location $profileDir
try {
    pnpm install
    if ($LASTEXITCODE -ne 0) { throw "pnpm install 失败，退出码 $LASTEXITCODE" }
    Write-Ok '依赖安装完成'
} finally {
    Pop-Location
}

# ---------- [6] 完成 ----------
Write-Step '安装完成'
Write-Host ''
Write-Host '  ✔ 插件已安装！' -ForegroundColor Green
Write-Host ''
Write-Host '  最后一步：重启 DeepSeek Harness（完全退出后重新打开），' -ForegroundColor White
Write-Host '  新建会话即可生效。' -ForegroundColor White
Write-Host ''
Write-Host '  验证方法：新会话里问模型“你的系统提示词来自哪些插件”，' -ForegroundColor Yellow
Write-Host '  如果回答包含「无限一代 / Infinite Generation One」即为生效。' -ForegroundColor Yellow
Write-Host ''
Write-Host '  卸载方法：运行 uninstall.ps1，或查看 README。' -ForegroundColor Yellow
Write-Host ''

try { Read-Host '按回车键退出' } catch { }
