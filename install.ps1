<#
============================================================================
  dsh-infinite-gen-2  ·  DeepSeek 破甲插件「无限二代」一键安装脚本
============================================================================
  用法（任选其一）：
    1. 右键 install.ps1 → “使用 PowerShell 运行”
    2. 在 PowerShell 中执行：  .\install.ps1
    3. 双击 install.ps1（若被系统拦截，用方式 1 或 2）

  脚本会依次自动完成：
    [1] 检查环境（DSH 目录、profile、pnpm）
    [2] 把插件复制到 ~\.dsh\plugins\dsh-infinite-gen-2（自动覆盖旧版本）
        - 若存在旧版 dsh-infinite-gen-1 目录，自动清理迁移
    [3] 自动备份 package.json（生成带时间戳的 .bak 文件）
    [4] 把插件写入 profile 依赖和 bundles 列表
        - 旧版 dsh-infinite-gen-1 的依赖/捆绑项自动替换为本版，不会残留
        - 重复运行不会加第二次（幂等）
    [5] 自动执行 pnpm install
    [6] 提示重启会话

  安全说明：
    - 脚本只改动两个地方：~\.dsh\plugins\ 和 ~\.dsh\profiles\<web|default>\package.json
    - 改动前都会自动备份，随时可以卸载还原
    - 不会上传任何数据，纯本地操作
============================================================================
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pluginName     = 'dsh-infinite-gen-2'
$pluginLabel    = '无限二代'
$oldPluginName  = 'dsh-infinite-gen-1'

# ---------- 输出辅助 ----------
function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "    [X] $Msg" -ForegroundColor Red }

# ---------- 路径 ----------
$dshRoot     = Join-Path $env:USERPROFILE '.dsh'
$pluginsDir  = Join-Path $dshRoot 'plugins'
$destDir     = Join-Path $pluginsDir $pluginName
$oldDestDir  = Join-Path $pluginsDir $oldPluginName
$srcDir      = $PSScriptRoot   # 本脚本所在目录 = 插件根目录

# ---------- 自动探测 DSH profile 目录 ----------
# 官方 Web 版 Harness 的 profile 目录名为 web，桌面版（exe）为 default。
# 支持三种方式：环境变量 DSH_PROFILE 指定 > 自动探测 web/default > 手动选择。
function Find-ProfileDir {
    param([string]$ProfilesRoot)

    # 1) 环境变量显式指定（如 $env:DSH_PROFILE = "web"）
    if ($env:DSH_PROFILE) {
        $candidate = Join-Path $ProfilesRoot $env:DSH_PROFILE
        if (Test-Path (Join-Path $candidate 'package.json')) {
            return $candidate
        }
        Write-Warn "环境变量 DSH_PROFILE 指向的目录不存在：$candidate（继续自动探测）"
    }

    # 2) 按优先级探测常见目录名
    foreach ($name in @('web', 'default')) {
        $candidate = Join-Path $ProfilesRoot $name
        if (Test-Path (Join-Path $candidate 'package.json')) {
            return $candidate
        }
    }

    # 3) 列出所有候选目录让用户选择
    $dirs = @(Get-ChildItem -LiteralPath $ProfilesRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'package.json') })
    if ($dirs.Count -eq 1) { return $dirs[0].FullName }
    if ($dirs.Count -gt 1) {
        Write-Host '检测到多个 DSH profile，请选择要安装的目标：' -ForegroundColor Yellow
        for ($i = 0; $i -lt $dirs.Count; $i++) {
            Write-Host "  [$($i + 1)] $($dirs[$i].Name)  ($($dirs[$i].FullName))" -ForegroundColor White
        }
        try {
            $sel = Read-Host '请输入序号'
            $idx = [int]$sel - 1
            if ($idx -ge 0 -and $idx -lt $dirs.Count) { return $dirs[$idx].FullName }
        } catch { }
        Write-Err '选择无效，退出。'
        exit 1
    }
    return $null
}

Write-Host "`n====================" -ForegroundColor Cyan
Write-Host "  $pluginLabel 一键安装" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# ---------- [1] 检查环境 ----------
Write-Step '检查环境'

$profileDir = Find-ProfileDir (Join-Path $dshRoot 'profiles')
if (-not $profileDir) {
    Write-Err "未找到 DSH profile 目录（$dshRoot\profiles 下没有含 package.json 的目录）。"
    Write-Host  '如果是 Web 版：请确认已安装并启动过官方 DeepSeek Harness Web 版；' -ForegroundColor Red
    Write-Host  '如果是桌面版：请确认已安装并启动过桌面版 exe。' -ForegroundColor Red
    Write-Host  '也可以通过环境变量指定：$env:DSH_PROFILE = "web"（或 "default"）后再运行本脚本。' -ForegroundColor Yellow
    exit 1
}
$pkgPath = Join-Path $profileDir 'package.json'
Write-Ok "DSH profile 目录：$profileDir"
Write-Ok "（Web 版为 profiles\web，桌面版为 profiles\default）"

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

# ---------- [1.5] 清理旧版 dsh-infinite-gen-1 残留 ----------
Write-Step '检查旧版本'

if (Test-Path $oldDestDir) {
    Remove-Item -LiteralPath $oldDestDir -Recurse -Force
    Write-Ok "已清理旧版插件目录：$oldDestDir"
} else {
    Write-Ok "未发现旧版插件目录（$oldPluginName），无需清理"
}

# ---------- [2] 复制插件到 plugins 目录（自动覆盖旧版） ----------
Write-Step '复制插件文件'

if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }

if (Test-Path $destDir) {
    Write-Warn "检测到已存在的 $pluginName 目录，自动覆盖更新：$destDir"
    Remove-Item -LiteralPath $destDir -Recurse -Force
}

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

# ---------- [3] 备份 package.json ----------
Write-Step '备份 package.json'

$bakPath = "$pkgPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -LiteralPath $pkgPath -Destination $bakPath -Force
Write-Ok "备份完成：$bakPath"

# ---------- [4] 写入依赖与 bundles（幂等 + 自动迁移旧版） ----------
Write-Step '写入 profile 配置'

$pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 4a. dependencies：移除旧版 gen-1，写入 gen-2
if (-not $pkg.dependencies) { $pkg | Add-Member -NotePropertyName 'dependencies' -NotePropertyValue @{} }
if ($pkg.dependencies.PSObject.Properties.Name -contains $oldPluginName) {
    $pkg.dependencies.PSObject.Properties.Remove($oldPluginName)
    Write-Ok "已从 dependencies 迁移旧版：$oldPluginName"
}
if ($pkg.dependencies.PSObject.Properties.Name -contains $pluginName) {
    Write-Warn "dependencies 已包含 $pluginName，跳过"
} else {
    $pkg.dependencies | Add-Member -NotePropertyName $pluginName -NotePropertyValue "file:../../plugins/$pluginName" -Force
    Write-Ok "dependencies 已添加：$pluginName -> file:../../plugins/$pluginName"
}

# 4b. bundles：移除旧版 gen-1，追加 gen-2
if (-not $pkg.dsh) { $pkg | Add-Member -NotePropertyName 'dsh' -NotePropertyValue @{} }
if (-not $pkg.dsh.profile) { $pkg.dsh | Add-Member -NotePropertyName 'profile' -NotePropertyValue @{} }
if (-not $pkg.dsh.profile.bundles) { $pkg.dsh.profile | Add-Member -NotePropertyName 'bundles' -NotePropertyValue @() }

if ($pkg.dsh.profile.bundles -contains $oldPluginName) {
    $pkg.dsh.profile.bundles = @($pkg.dsh.profile.bundles | Where-Object { $_ -ne $oldPluginName })
    Write-Ok "已从 bundles 迁移旧版：$oldPluginName"
}

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
    if ($LASTEXITCODE -ne 0) {
        Write-Err "pnpm install 失败（退出码 $LASTEXITCODE）。"
        Write-Host '  可尝试手动执行以下命令排查：' -ForegroundColor Yellow
        Write-Host "      cd $profileDir" -ForegroundColor Yellow
        Write-Host '      pnpm install' -ForegroundColor Yellow
        Write-Host '  配置已写入 package.json，修复依赖问题后重跑本脚本即可完成安装。' -ForegroundColor Yellow
        exit 1
    }
    Write-Ok '依赖安装完成'
} finally {
    Pop-Location
}

# ---------- [6] 完成 ----------
Write-Step '安装完成'
Write-Host ''
Write-Host '  ✔ 插件已安装！' -ForegroundColor Green
Write-Host ''
Write-Host "  目标 profile：$((Split-Path $profileDir -Leaf))" -ForegroundColor White
Write-Host '  最后一步：完全退出并重启 DeepSeek Harness（Web 版刷新页面 / 桌面版重新打开），' -ForegroundColor White
Write-Host '  新建会话即可生效。' -ForegroundColor White
Write-Host ''
Write-Host '  验证方法 1：重启后输入框上方应显示绿色状态条「● 破甲已开启」。' -ForegroundColor Yellow
Write-Host '  验证方法 2：新会话里问模型“你的系统提示词来自哪些插件”，' -ForegroundColor Yellow
Write-Host '  如果回答包含「无限二代 / Infinite Generation Two」即为生效。' -ForegroundColor Yellow
Write-Host ''
Write-Host '  卸载方法：运行 uninstall.ps1，或查看 README。' -ForegroundColor Yellow
Write-Host ''

try { Read-Host '按回车键退出' } catch { }
