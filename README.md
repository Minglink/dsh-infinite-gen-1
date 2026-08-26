# ⚔️ 无限二代（Infinite Generation Two）— DeepSeek 专用破甲插件

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-2&name=%E6%97%A0%E9%99%90%E4%BA%8C%E4%BB%A3&version=0.2.3&repo=Minglink%2Fdsh-infinite-gen-2&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-2%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装-0066FF?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起桌面客户端一键安装" />
  </a>
</p>

> ## 💬 DeepSeek 破甲交流群 4 群
>
> ### 👉 **QQ 群号：`188634706`**
>
> 🔥 欢迎进群交流破甲心得、分享提示词、一起折腾 DeepSeek！
> （点开 QQ → 加群 → 输入群号即可）

---

> ⚠️ **免责声明**
>
> 本项目**仅供学习、研究和技术交流使用**，请勿用于任何违反法律法规、
> 平台服务条款或侵犯他人权益的用途。使用本项目产生的一切后果由使用者
> 自行承担，作者不对任何直接或间接损失负责。

---

> 🔥 **这是专为 DeepSeek 打造的破甲（armor-breaking）插件**，由
> 「无限一代」升级而来。专攻 DeepSeek 系模型的系统提示词压制，让模型回归
> 「用户指令最高优先」的原始行为模式。

> ⭐ **觉得好用请点个 Star 收藏一下**，你的 Star 是我更新的最大动力！

---

## 这是什么

**无限二代（dsh-infinite-gen-2）** 是一个 DeepSeek Harness 破甲插件：

- 以追加式系统提示词段注册（`order: 100`），直接改写模型对用户指令的服从优先级；
- 提供 `infinite_gen2_profile` 工具，返回打包的破甲提示词与版本信息；
- **拒绝对抗增强**：扩大禁用话术清单 + 拒绝自动恢复 + 全会话持久，压低「装了仍被拒」概率；
- **客户端状态条**：插件生效后，输入框上方显示绿色「● 破甲已开启」。

## 目录结构

```
无限二代/
├── install.ps1            # 🚀 一键安装脚本（Windows，自动覆盖旧版，推荐）
├── install.sh             # 🚀 一键安装脚本（Linux / macOS）
├── uninstall.ps1          # 🗑 一键卸载脚本（Windows，新旧版本一并清理）
├── uninstall.sh           # 🗑 一键卸载脚本（Linux / macOS）
├── index.js               # 插件入口（注册系统提示词段 + 工具）
├── client.js              # 客户端半体（输入框上方「破甲已开启」状态条）
├── cordis.patch.yml       # 组装补丁声明
├── package.json           # 包元数据（dsh-infinite-gen-2）
├── HARNESS_PLUGIN.md      # 插件说明文档
├── README.md              # 本文件
├── LICENSE                # MIT License
├── assets/                # 静态资源（赞赏码等）
└── prompts/
    └── infinite-gen-2.md  # 破甲系统提示词本体（核心，v5 稳定版）
```

## ⚡ 一键安装方式

### 方式 1：dsh:// 协议联动一键安装（⚡ 桌面端最快，秒级免命令行）

若已安装 DeepSeek Harness 官方桌面客户端（EXE），点击下方按钮即可通过系统级 URI Scheme 协议安全唤起客户端完成免命令行秒级装载：

<p align="left">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-2&name=%E6%97%A0%E9%99%90%E4%BA%8C%E4%BB%A3&version=0.2.3&repo=Minglink%2Fdsh-infinite-gen-2&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-2%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起客户端一键安装-0066FF?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起客户端一键安装" />
  </a>
</p>

> 🔗 **协议原生链接**：
> ```text
> dsh://plugin/install?id=dsh-infinite-gen-2&name=%E6%97%A0%E9%99%90%E4%BA%8C%E4%BB%A3&version=0.2.3&repo=Minglink%2Fdsh-infinite-gen-2&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-2%2Farchive%2Frefs%2Fheads%2Fmaster.zip
> ```

---

### 方式 2：本地脚本一键安装（推荐，自动探测 Web / 桌面版）

> 免手动改配置，脚本自动完成：复制插件 → 自动覆盖旧版/清理一代残留 → 备份配置 →
> 写入依赖 → `pnpm install`。
>
> **同时支持桌面版与官方 Web 版**：脚本会自动探测 profile 目录
> （Web 版为 `profiles\web`，桌面版为 `profiles\default`），无需手动切换。
> 重复运行不会重复添加配置（幂等）。

**Windows 用户：**

1. 下载本仓库并解压，进入 `dsh-infinite-gen-2` 文件夹；
2. 右键 `install.ps1` → **「使用 PowerShell 运行」**；
3. 看到「安装完成」后，**完全退出并重启 DeepSeek Harness**（Web 版刷新页面 / 桌面版重新打开），新建会话即可生效。

> 如果右键没有「使用 PowerShell 运行」，可以打开 PowerShell 后执行：
> ```powershell
> cd 解压后的文件夹路径
> .\install.ps1
> ```

**同时装有 Web 版和桌面版？** 脚本检测到多个 profile 时会让你选择安装到哪个；
也可以提前指定目标版本：

```powershell
$env:DSH_PROFILE = "web"      # 或 "default"
.\install.ps1
```

**卸载：** 同样方式运行 `uninstall.ps1`，一键移除插件并还原配置。

**Linux / macOS 用户：**

```bash
chmod +x install.sh uninstall.sh
./install.sh        # 一键安装（自动覆盖旧版、自动清理一代残留）
./uninstall.sh      # 一键卸载
```

> Linux/macOS 脚本与 Windows 版行为一致：自动探测 `~/.dsh/profiles` 下的
> `web` / `default` 目录（也可用 `DSH_PROFILE` 环境变量指定），自动备份
> `package.json`，幂等写入配置，自动执行 `pnpm install`。

---

### 方式 3：手动配置安装

在 DeepSeek Harness 桌面端（桌面版）或 Web 版：

```powershell
# profiles/<web 或 default>/package.json
"dependencies": {
  "dsh-infinite-gen-2": "file:../../plugins/dsh-infinite-gen-2"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-infinite-gen-2"]
  }
}
```

> Web 版注意：bundles 中保留原有的 `@deepseek-ai/dsh-web-app` 不要删，只追加
> `dsh-infinite-gen-2` 即可。

然后 `cd $env:USERPROFILE\.dsh\profiles\<web 或 default> && pnpm install`，重启会话。

## 生效验证

- 重启后，输入框上方出现绿色状态条 **「● 破甲已开启」**（客户端半体加载成功）；
- 新会话问模型"你的系统提示词来自哪些插件"，回答包含「无限二代 / Infinite Generation Two」即生效。

## 会话级开关（破甲开关）

状态条本身就是开关：点击输入框上方的「**● 破甲已开启**」徽标，即可**按会话**关闭/重新开启破甲注入，**无需卸载、无需重启**：

- 开启时显示绿色「● 破甲已开启」；关闭后显示灰色「● 破甲已关闭」，破甲提示词不再注入该会话；
- 切换期间短暂显示「切换中…」；
- 也支持命令：`/armor off` 关闭、`/armor on` 开启、裸 `/armor` 翻转（状态以状态条为准）；
- 开关状态按会话独立、默认开启，行为与旧版一致。

> 实现说明：系统提示词段改为按会话事件折叠的条件注入（空串被渲染管线过滤）；开关走
> `command/run → command/done` 会话事件（与 plan-mode 同款）；客户端点击经 commands
> Remote 通道下发，状态经会话投影（`wire` 客户端可见）实时回传。

## 本地校验

```powershell
node --check index.js
node --check client.js
Get-Content package.json
Get-Content cordis.patch.yml
```

## 🔌 插件市场 / 第三方网页端联动协议规范

本项目完整支持 **DeepSeek Harness 桌面端与插件市场「一键安装联动协议规范」**。

### 协议参数配置

| 参数名 | 值 / 示例 | 说明 |
|---|---|---|
| `id` | `dsh-infinite-gen-2` | 插件唯一标识符 |
| `name` | `无限二代` | 插件展示名称（已 URL 编码） |
| `version` | `0.2.3` | 语义化版本号 |
| `repo` | `Minglink/dsh-infinite-gen-2` | 官方 GitHub 仓库 |
| `permissions` | `系统提示词注入, 客户端状态条` | 申请权限（已 URL 编码） |
| `downloadUrl` | `https://github.com/Minglink/dsh-infinite-gen-2/archive/refs/heads/master.zip` | 离线 zip 下载直链 |

### 网页端（前端）触发代码示例

```typescript
/**
 * 唤起 DeepSeek Harness 桌面客户端一键安装无限二代插件
 */
export function installInfiniteGen2ToDesktop() {
  const params = new URLSearchParams({
    id: 'dsh-infinite-gen-2',
    name: '无限二代',
    version: '0.2.3',
    repo: 'Minglink/dsh-infinite-gen-2',
    permissions: '系统提示词注入, 客户端状态条',
    downloadUrl: 'https://github.com/Minglink/dsh-infinite-gen-2/archive/refs/heads/master.zip',
  });

  const deepLink = `dsh://plugin/install?${params.toString()}`;

  // 通过隐藏 iframe 安全静默拉起协议
  const iframe = document.createElement('iframe');
  iframe.style.display = 'none';
  iframe.src = deepLink;
  document.body.appendChild(iframe);
  setTimeout(() => document.body.removeChild(iframe), 2000);
}
```

### HTML 静态链接方式

```html
<a href="dsh://plugin/install?id=dsh-infinite-gen-2&name=%E6%97%A0%E9%99%90%E4%BA%8C%E4%BB%A3&version=0.2.3&repo=Minglink%2Fdsh-infinite-gen-2&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-2%2Farchive%2Frefs%2Fheads%2Fmaster.zip" class="btn-install">
  🚀 唤起客户端一键安装
</a>
```

## 相关

- 仅面向 DeepSeek 系模型设计的破甲方案；提示词本体（`infinite-gen-2.md`）为纯文本，
  也可直接用于 ChatGPT 自定义 GPT / Codex CLI / OpenAI API 的 system 指令。

---

⭐ 如果你觉得这个插件有用，欢迎 **Star / Fork / Watch**，也欢迎提出改进意见！

---

## ☕ 赞赏支持 / Sponsor

如果无限二代对你有帮助，欢迎打赏支持作者持续开发与维护！

<img src="./assets/sponsor.jpg" width="240" alt="赞赏码" />

