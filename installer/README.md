# 无限三代 (dsh-infinite-gen-3) —— 一键安装器

本目录生成一个**自包含图形界面（WinForms）安装器**，用于把「无限三代」破甲提示词插件
装进本机已安装的 **DeepSeek Harness（DSH）** 运行时。

产物：`../无限三代-一键安装器.exe`（位于仓库根目录）

## 特性

- **图形界面（中文）**：下拉选择要安装的 DSH 实例，按钮式操作，实时日志。
- **自动检测实例**：同时探测「桌面客户端」（`%APPDATA%\@deepseek-ai\dsh-desktop\dsh-home`）
  与「CLI / Web 版」（`%USERPROFILE%\.dsh`），并优先列出**当前正在运行**的实例。
- **一键安装 / 修复**：把插件写入该实例的 `profiles\node_modules\dsh-infinite-gen-3`，
  并自动在 `profiles\web\package.json` 的 `dsh.profile.bundles` 数组完成登记。
- **卸载**：删除插件目录并从 bundles 移除登记。
- **安全**：每个被改文件（package.json）写前自动 `备份为 .bak`；插件旧版本整体改名
  `…bak-<时间戳>` 备份；登记写入后做 JSON 校验，失败自动回滚。
- **幂等与防重**：重复点击不会造成 `duplicate loader entry id` 启动失败。
- **无任何运行时依赖**：自包含，嵌入全部插件文件，拷到任意电脑双击即用。

## 使用方法

1. 双击根目录的 `无限三代-一键安装器.exe`。
2. 从下拉框选择目标实例（通常第一个即“桌面客户端·当前运行"）。
3. 点 **「一键安装 / 修复」**；卸载则点 **「卸载」**。
4. 若目标是当前运行的 DSH，安装完成后**重启桌面客户端**以加载插件。

## 命令行（可选）

```
无限三代-一键安装器.exe --selfcheck
```

自检：在临时目录完整跑一遍「登记 / 移除 + 解压载荷」并校验，结果写入
`%USERPROFILE%\无限三代-自检结果.log`。无副作用，可随时运行。

## 重新构建（当插件更新后）

前置条件：本机装有 .NET Framework 4.x（Windows 自带，无需安装）。

```
powershell -ExecutionPolicy Bypass -File .\installer\Build.ps1
```

脚本会自动：
1. 把仓库内的插件文件（index.js/client.js/prompts/tests/scripts…，不含 installer 自身）
   打包成 zip，并以 `pluginroot/` 嵌入 EXE；
2. 生成嵌入源 `BundleData.g.cs`；
3. 用系统自带 Csc 编译为单文件 EXE `无限三代-一键安装器.exe`。

更新插件 == 用新源码目录再跑一次 Build.ps1 即可。

## 文件清单（installer 文件夹）

| 文件 | 说明 |
|---|---|
| `Build.ps1` | 构建脚本（打包 + 嵌入 + 编译） |
| `InstallerMain.cs` | 引擎层：实例检测、部署、bundles 登记/移除（JSON 校验回滚）、自检 |
| `InstallerForm.cs` | WinForms 图形界面 |
| `BundleData.g.cs` | 构建时自动生成的嵌入载荷（勿手改） |

> 说明：两处源码一律使用 C# 5 兼容语法，配合 Windows 自带的 .NET Framework Csc
> 直接编译，从而得到一个**任意 Windows 都能无依赖运行**的独立 EXE。

## 常见问题

- **提示“未检测到实例”**：本工具面向 DeepSeek Harness 本体（桌面版占 `%APPDATA%\@deepseek-ai\...`
  或 CLI 版占 `~\.dsh`）。请先安装任一并产生过 profiles 后再运行。
- **装了但启动报 duplicate**：多为 profile 的 `cordis.patch.yml` 里历史残留了手工登记的
  `- id:` 行。请把该文件的插入行还原为 `[]`，仅保留 bundles 登记即可（见主仓库 README）。
