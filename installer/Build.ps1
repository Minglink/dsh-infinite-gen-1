# ------------------------------------------------------------------
#  无限三代 (dsh-infinite-gen-3) 一键安装器 —— 构建脚本
#  产物:自包含 WinForms GUI EXE（.NET Framework 4.8，随系统自带，无需额外安装运行库）
#
#  用法:  pwsh -ExecutionPolicy Bypass -File installer\Build.ps1
# ------------------------------------------------------------------
$ErrorActionPreference = "Stop"

$Root     = Split-Path $PSScriptRoot -Parent
$BuildDir = Join-Path $Root "installer"

$Csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $Csc)) { $Csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" }
if (-not (Test-Path $Csc)) { throw "未找到 csc.exe（需 .NET Framework 4.x 编译环境）" }
$Fw = Split-Path $Csc -Parent

# ---------------- 1) 打包插件 payload（顶层统一 pluginroot/） ----------------
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$relEntries = @(
    "index.js","client.js","cordis.patch.yml","plugin.json","package.json",
    "HARNESS_PLUGIN.md","README.md","LICENSE",
    "prompts","tests","scripts"
)

$zipPath = Join-Path $BuildDir "pluginpayload.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$fs   = [System.IO.File]::Create($zipPath)
$arch = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($rel in $relEntries) {
        $abs = Join-Path $Root $rel
        if (-not (Test-Path $abs)) { Write-Host ("WARN 跳过缺失: " + $rel); continue }
        $fileList = New-Object System.Collections.Generic.List[string]
        if (Test-Path $abs -PathType Container) {
            Get-ChildItem $abs -Recurse -File -Force | ForEach-Object { $fileList.Add($_.FullName) }
        } else {
            $fileList.Add($abs)
        }
        foreach ($full in $fileList) {
            $relNoRoot = $full.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
            $entry = $arch.CreateEntry(("pluginroot/" + $relNoRoot), [System.IO.Compression.CompressionLevel]::Optimal)
            $es = $entry.Open()
            $bytes = [System.IO.File]::ReadAllBytes($full)
            $es.Write($bytes, 0, $bytes.Length)
            $es.Close()
            Write-Host ("  + " + $relNoRoot)
        }
    }
} finally {
    $arch.Dispose()
    $fs.Close()
}
$raw = [System.IO.File]::ReadAllBytes($zipPath)
$b64 = [Convert]::ToBase64String($raw)
Write-Host ("打包完成: {0} 字节 zip, base64 {1} 字" -f $raw.Length, $b64.Length)

# ---------------- 2) 生成嵌入 C# 源 ----------------
$genLines = New-Object System.Collections.Generic.List[string]
$genLines.Add("// 自动生成，勿手改 -- 由 installer\Build.ps1 生成")
$genLines.Add("using System;")
$genLines.Add("namespace DshInfinite")
$genLines.Add("{")
$genLines.Add("    internal static class BundleData")
$genLines.Add("    {")
$genLines.Add("        private static string B64 =")
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $b64.Length; $i += 110) {
    $len = [Math]::Min(110, $b64.Length - $i)
    $seg = $b64.Substring($i, $len)
    if ($i -eq 0) { $sb.Append('            "' + $seg + '"') | Out-Null }
    else          { $sb.Append("`r`n                + `"$seg`"") | Out-Null }
}
$genLines.Add($sb.ToString())
$genLines.Add("        ;")
$genLines.Add("        public static byte[] GetPayload()")
$genLines.Add("        {")
$genLines.Add("            try { return Convert.FromBase64String(B64); }")
$genLines.Add("            catch { return new byte[0]; }")
$genLines.Add("        }")
$genLines.Add("    }")
$genLines.Add("}")
$genCs = Join-Path $BuildDir "BundleData.g.cs"
$utf8  = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($genCs, $genLines, $utf8)
Write-Host ("已生成嵌入源: " + $genCs)

# ---------------- 3) 编译 ----------------
$refs = @(
    "System.dll","System.Core.dll","System.Drawing.dll","System.Windows.Forms.dll",
    "System.Web.Extensions.dll","System.IO.Compression.dll","System.IO.Compression.FileSystem.dll",
    "System.Xml.dll"
)
$refArgs = New-Object System.Collections.Generic.List[string]
foreach ($r in $refs) {
    $p = Join-Path $Fw $r
    if (Test-Path $p) { $refArgs.Add("/reference:" + $p) }
}
$outExe  = Join-Path $Root "无限三代-一键安装器.exe"
$csSources = @(
    (Join-Path $BuildDir "InstallerMain.cs"),
    (Join-Path $BuildDir "InstallerForm.cs"),
    $genCs
)
# 为含中文注释的源文件统一前置 UTF-8 BOM，避免 Csc 按系统 ANSI 解码出错
$bomUtf8 = [System.Text.Encoding]::UTF8.GetPreamble()
foreach ($csf in $csSources) {
    $bytes = [System.IO.File]::ReadAllBytes($csf)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if (-not $hasBom) {
        $all = New-Object byte[] ($bomUtf8.Length + $bytes.Length)
        [Array]::Copy($bomUtf8, 0, $all, 0, $bomUtf8.Length)
        [Array]::Copy($bytes, 0, $all, $bomUtf8.Length, $bytes.Length)
        [System.IO.File]::WriteAllBytes($csf, $all)
    }
}
$srcList = New-Object System.Collections.Generic.List[string]
foreach ($s in $csSources) { $srcList.Add($s) }

$argList = New-Object System.Collections.Generic.List[string]
$argList.Add("/nologo")
$argList.Add("/target:winexe")
$argList.Add("/platform:anycpu")
$argList.Add("/codepage:65001")
$argList.Add("/optimize")
$argList.Add("/nowarn:1591")
$argList.Add("/out:" + $outExe)
foreach ($a in $refArgs) { $argList.Add($a) }
foreach ($s in $srcList) { $argList.Add($s) }

Write-Host "编译中…"
& $Csc $argList
if ($LASTEXITCODE -ne 0) { throw ("编译失败，退出码 " + $LASTEXITCODE) }

Write-Host ""
Write-Host ("成功生成 EXE: " + $outExe)
Write-Host ("体积: " + (Get-Item $outExe).Length + " 字节")
Write-Host "该 EXE 自包含插件数据，可复制到任意位置直接双击运行（无需安装额外运行库）。"
