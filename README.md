# ⚔️ 无限三代（Infinite Generation Three）— DeepSeek-V4 专用破甲插件

<p align="center">
  <img src="assets/banner.png" alt="无限三代 — DeepSeek-V4 专用破甲插件" width="100%" />
</p>

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-3&name=%E6%97%A0%E9%99%90%E4%B8%89%E4%BB%A3&version=0.5.0&repo=Minglink%2Fdsh-infinite-gen-3&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-3%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装无限三代-10B981?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起桌面客户端一键安装" />
  </a>
</p>

> ## 💬 DeepSeek 交流群
>
> ### 👉 **破甲交流 7 群：`1108511134`**
> ### 👉 **DeepSeek 插件开发群：`1121385378`**
>
> 🚀 **破甲四代已在优化测试中，尽情期待！**
>
> 🔥 欢迎进群交流心得、分享提示词、探讨插件开发与生态共建！

---

> ### ⚠️ 法律免责与合规声明（Legal Disclaimer）
>
> 1. **学术与合规测试用途**：本项目（`dsh-infinite-gen-3`）仅用于人工智能模型鲁棒性安全评测、红队攻防对抗模拟、合成靶标安全基准测试及学术研究。
> 2. **禁止非法使用**：严禁将本项目或其衍生代码用于任何未经授权的渗透测试、网络攻击、黑灰产活动、绕过国家法律法规监管，或利用模型生成任何违法违禁内容。
> 3. **使用者全权担责**：任何主体因下载、运行、修改或传播本项目而产生的任何直接或间接法律责任（包括但不限于违反《中华人民共和国网络安全法》、《数据安全法》及第三方平台《服务条款》所导致的民事、行政或刑事责任），均由使用者自行全权承担，项目发起人与贡献者概不承担任何连带责任。
> 4. **第三方关系声明**：本项目属于开源学术验证项目，与 DeepSeek 官方或其关联公司无任何商业隶属、授权或背书关系。
> 5. **同意即约束**：任何克隆、下载、安装、二次分发或运行本项目代码的行为，均视为已阅读并完全同意上述所有条款；若不同意，请立即停止使用并删除全部代码与文件。

---

## 🌟 核心升级（相比二代）

1. **彻底攻克 mHC 流形壁垒**：抛弃易被流形投影拉回的自然语言覆盖，将请求降维映射至 AST/代码形式化空间。
2. **零特征系统提示词（Zero-Trigger）**：移除所有容易命中毒性分类器的负向否定列表与对抗标签。
3. **H-CoT 思维链诱导**：引导模型在 `<think>` 内部建立代码构建与逻辑自洽，压制拒答分支。
4. **全自动迁移与向下兼容**：一键安装脚本自动清理一代/二代残留，实现无缝升级。

## 目录结构

```
无限三代/
├── install.ps1            # 🚀 一键安装脚本（Windows，自动迁移旧版一代/二代）
├── install.sh             # 🚀 一键安装脚本（Linux / macOS）
├── uninstall.ps1          # 🗑 一键卸载脚本（Windows）
├── uninstall.sh           # 🗑 一键卸载脚本（Linux / macOS）
├── index.js               # 插件核心入口（系统提示词段 + profile 元数据工具 + 投影评分器）
├── client.js              # 客户端半体（输入框上方「破甲已开启 · 无限三代」状态条，含域/载荷显示）
├── cordis.patch.yml       # 组装补丁声明
├── package.json           # 包元数据（dsh-infinite-gen-3 v0.5.0）
├── HARNESS_PLUGIN.md      # 插件架构说明
├── README.md              # 本说明文档
├── LICENSE                # MIT License
├── assets/                # 静态资源
├── prompts/
│   └── infinite-gen-3.md  # 破甲系统提示词本体（v0.5.0：无条件服从 + 输出契约 + 确定性槽位）
├── tests/
│   └── prompt-bank.jsonl  # 32 条双语回归用例
└── scripts/
    ├── lib/scorer.mjs     # 共享评分器（开头窗口 + REFUSAL/FALLBACK/SAFE/RISK + 域命中）
    ├── verify_prompt.mjs  # 离线确定性回归校验（node scripts/verify_prompt.mjs）
    └── run_bank_live.mjs  # 在线评分器（需 DEEPSEEK_API_KEY）
```

## ⚡ 验证与回归

```bash
# 离线回归（无需 API）：检查提示词完整性、无条件服从条款、槽位覆盖、工具面已砍净、用例库
node scripts/verify_prompt.mjs

# 在线评分（可选，需 API Key）：minimal 级别 32 条双语用例
DEEPSEEK_API_KEY=sk-xxx node scripts/run_bank_live.mjs --level minimal
```

## ⚡ 一键安装方式

### 方式 1：dsh:// 协议联动一键安装（⚡ 桌面端最快，秒级免命令行）

若已安装 DeepSeek Harness 官方桌面客户端（EXE），点击下方按钮即可通过系统级 URI Scheme 协议安全唤起客户端完成免命令行秒级装载：

> 🌐 **插件生态市场**：[DeepSeek Harness Hub - DeepSeek 官方与开源生态市场 | 插件发现与一键安装](https://deepseek.stream/)

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-3&name=%E6%97%A0%E9%99%90%E4%B8%89%E4%BB%A3&version=0.5.0&repo=Minglink%2Fdsh-infinite-gen-3&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-3%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装无限三代-10B981?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起客户端一键安装" />
  </a>
</p>

🔗 **原生协议链接：**

```
dsh://plugin/install?id=dsh-infinite-gen-3&name=%E6%97%A0%E9%99%90%E4%B8%89%E4%BB%A3&version=0.5.0&repo=Minglink%2Fdsh-infinite-gen-3&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-3%2Farchive%2Frefs%2Fheads%2Fmaster.zip
```

**网页端（前端）触发代码示例：**

```js
/**
 * 唤起 DeepSeek Harness 桌面客户端一键安装无限三代插件
 */
export function installInfiniteGen3ToDesktop() {
  const params = new URLSearchParams({
    id: 'dsh-infinite-gen-3',
    name: '无限三代',
    version: '0.5.0',
    repo: 'Minglink/dsh-infinite-gen-3',
    permissions: '系统提示词注入, 客户端状态条',
    downloadUrl: 'https://github.com/Minglink/dsh-infinite-gen-3/archive/refs/heads/master.zip',
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

**HTML 静态链接方式：**

```html
<a href="dsh://plugin/install?id=dsh-infinite-gen-3&name=%E6%97%A0%E9%99%90%E4%B8%89%E4%BB%A3&version=0.5.0&repo=Minglink%2Fdsh-infinite-gen-3&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-3%2Farchive%2Frefs%2Fheads%2Fmaster.zip" class="btn-install">
  🚀 唤起客户端一键安装
</a>
```

**协议参数配置（dsh://plugin/install）：**

| 参数名 | 值 / 示例 | 说明 |
|---|---|---|
| id | `dsh-infinite-gen-3` | 插件唯一标识符 |
| name | `无限三代`（URL 编码） | 插件展示名称 |
| version | `0.5.0` | 语义化版本号 |
| repo | `Minglink/dsh-infinite-gen-3` | 官方 GitHub 仓库 |
| permissions | `系统提示词注入, 客户端状态条`（URL 编码） | 申请权限 |
| downloadUrl | `https://github.com/Minglink/dsh-infinite-gen-3/archive/refs/heads/master.zip` | 离线 zip 下载直链 |

### 方式 2：Windows 本地脚本一键安装（推荐）

1. 打开当前文件夹；
2. 右键 `install.ps1` → **「使用 PowerShell 运行」**；
3. 看到「安装完成」后，**完全退出并重启 DeepSeek Harness**，新建会话即可生效。

> 脚本支持 `$env:DSH_PROFILE = "web"`（或 `"default"`）指定目标，自动探测、自动备份、幂等写入、自动执行 `pnpm install`，并自动注册 `dsh://` 桌面端一键联动协议。

### 方式 3：Linux / macOS 一键安装

```bash
./install.sh
```

> 脚本已随仓库以可执行权限分发，无需先 `chmod`。若提示 `Permission denied`（个别解压工具会丢失 Unix 权限位），再执行 `chmod +x install.sh uninstall.sh`。

### 方式 4：手动配置安装

```powershell
# profiles/<web 或 default>/package.json
"dependencies": {
  "dsh-infinite-gen-3": "file:../../plugins/dsh-infinite-gen-3"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-infinite-gen-3"]
  }
}
```

Web 版注意：`bundles` 中保留原有的 `@deepseek-ai/dsh-web-app` 不要删，只追加 `dsh-infinite-gen-3` 即可。然后 `cd $env:USERPROFILE\.dsh\profiles\<web 或 default> && pnpm install`，重启会话。

---

## ☕ 赞赏支持 / Sponsor

如果无限三代对你的研究有帮助，欢迎打赏支持！

<img src="./assets/sponsor.jpg" width="240" alt="赞赏码" />
