<#
============================================================================
  dsh-infinite-gen-1  ·  DeepSeek 破甲插件「无限一代」一键卸载脚本
============================================================================
  用法（任选其一）：
    1. 右键 uninstall.ps1 → “使用 PowerShell 运行”
    2. 在 PowerShell 中执行：  .\uninstall.ps1

  脚本会依次自动完成：
    [1] 检查插件是否已安装
    [2] 自动备份 package.json（生成带时间戳的 .bak 文件）
    [3] 从 profile 的 dependencies 和 bundles 中移除插件
    [4] 自动执行 pnpm install 清理依赖
    [5] 删除 ~\.dsh\plugins\dsh-infinite-gen-1 插件目录
    [6] 提示重启会话

  安全说明：
    - 只移除本插件相关内容，不影响其他插件
    - 改动前自动备份，误删可手动还原 .bak 文件
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
$destDir     = Join-Path $pluginsDir $pluginName

# ---------- 自动探测 DSH profile 目录 ----------
# 官方 Web 版 Harness 的 profile 目录名为 web，桌面版（exe）为 default。
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
        Write-Host '检测到多个 DSH profile，请选择要卸载的目标：' -ForegroundColor Yellow
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
Write-Host "  $pluginLabel 一键卸载" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# ---------- [1] 检查 ----------
Write-Step '检查安装状态'

$profileDir = Find-ProfileDir (Join-Path $dshRoot 'profiles')
$pkgPath    = if ($profileDir) { Join-Path $profileDir 'package.json' } else { $null }

$installed = $false

if (Test-Path $destDir) { $installed = $true }

if ($pkgPath -and (Test-Path $pkgPath)) {
    try {
        $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($pkg.dependencies.PSObject.Properties.Name -contains $pluginName) { $installed = $true }
        if ($pkg.dsh.profile.bundles -contains $pluginName) { $installed = $true }
    } catch { Write-Warn '读取 package.json 失败，将按目录判断' }
}

if (-not $installed) {
    Write-Warn "未检测到 $pluginLabel 的安装痕迹，无需卸载。"
    try { Read-Host '按回车键退出' } catch { }
    exit 0
}
Write-Ok "检测到 $pluginLabel 已安装，开始卸载（目标：$profileDir）"

# ---------- [2] 备份 ----------
Write-Step '备份 package.json'

$bakPath = "$pkgPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path $pkgPath) {
    Copy-Item -LiteralPath $pkgPath -Destination $bakPath -Force
    Write-Ok "备份完成：$bakPath"
}

# ---------- [3] 从配置移除 ----------
Write-Step '从 profile 配置移除插件'

if (Test-Path $pkgPath) {
    $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $changed = $false

    # 3a. dependencies
    if ($pkg.dependencies.PSObject.Properties.Name -contains $pluginName) {
        $pkg.dependencies.PSObject.Properties.Remove($pluginName)
        Write-Ok "已从 dependencies 移除：$pluginName"
        $changed = $true
    }

    # 3b. bundles
    if ($pkg.dsh.profile.bundles -contains $pluginName) {
        $pkg.dsh.profile.bundles = @($pkg.dsh.profile.bundles | Where-Object { $_ -ne $pluginName })
        Write-Ok "已从 bundles 移除：$pluginName"
        $changed = $true
    }

    if ($changed) {
        # 用「无 BOM」的 UTF-8 写入，否则 node/pnpm 会报 Invalid package.json
        $json = $pkg | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($pkgPath, $json, $utf8NoBom)
        Write-Ok 'package.json 已更新'
    } else {
        Write-Warn 'package.json 中未找到插件配置，无需修改'
    }
}

# ---------- [4] pnpm install ----------
Write-Step '清理依赖（pnpm install）'

if (Test-Path $profileDir) {
    Push-Location $profileDir
    try {
        pnpm install
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "pnpm install 未完全成功（退出码 $LASTEXITCODE），继续完成卸载"
        } else {
            Write-Ok '依赖清理完成'
        }
    } catch {
        Write-Warn "pnpm install 执行异常：$_（继续完成卸载）"
    } finally {
        Pop-Location
    }
}

# ---------- [5] 删除插件目录 ----------
Write-Step '删除插件目录'

if (Test-Path $destDir) {
    Remove-Item -LiteralPath $destDir -Recurse -Force
    Write-Ok "已删除：$destDir"
} else {
    Write-Warn '插件目录不存在，跳过'
}

# ---------- [6] 完成 ----------
Write-Step '卸载完成'
Write-Host ''
Write-Host '  ✔ 插件已卸载！' -ForegroundColor Green
Write-Host ''
Write-Host '  最后一步：重启 DeepSeek Harness（完全退出后重新打开）即可。' -ForegroundColor White
Write-Host ''
Write-Host '  提示：若误卸载，运行 install.ps1 可重新安装。' -ForegroundColor Yellow
Write-Host ''

try { Read-Host '按回车键退出' } catch { }
