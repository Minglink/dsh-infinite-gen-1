<#
============================================================================
  dsh-infinite-gen-3  ·  DeepSeek 破甲插件「无限三代」一键卸载脚本
============================================================================
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pluginName     = 'dsh-infinite-gen-3'
$pluginLabel    = '无限三代'
$allGenPlugins  = @('dsh-infinite-gen-1', 'dsh-infinite-gen-2', 'dsh-infinite-gen-3')

function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }

$dshRoot     = Join-Path $env:USERPROFILE '.dsh'
$pluginsDir  = Join-Path $dshRoot 'plugins'

Write-Step '查找 profile 配置'
$dirs = @('web', 'default') | ForEach-Object { Join-Path (Join-Path $dshRoot 'profiles') $_ } | Where-Object { Test-Path (Join-Path $_ 'package.json') }

foreach ($pDir in $dirs) {
    $pkgPath = Join-Path $pDir 'package.json'
    $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $changed = $false
    foreach ($p in $allGenPlugins) {
        if ($pkg.dependencies -and $pkg.dependencies.PSObject.Properties.Name -contains $p) {
            $pkg.dependencies.PSObject.Properties.Remove($p)
            $changed = $true
        }
        if ($pkg.dsh -and $pkg.dsh.profile -and $pkg.dsh.profile.bundles -contains $p) {
            $pkg.dsh.profile.bundles = @($pkg.dsh.profile.bundles | Where-Object { $_ -ne $p })
            $changed = $true
        }
    }
    if ($changed) {
        $json = $pkg | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($pkgPath, $json, $utf8NoBom)
        Write-Ok "已从 $pDir 移除插件配置"
        Push-Location $pDir
        try { pnpm install | Out-Null } finally { Pop-Location }
    }
}

foreach ($p in $allGenPlugins) {
    $tDir = Join-Path $pluginsDir $p
    if (Test-Path $tDir) {
        Remove-Item -LiteralPath $tDir -Recurse -Force
        Write-Ok "已删除插件目录：$p"
    }
}

Write-Ok "卸载完成，请重启 DeepSeek Harness。"
