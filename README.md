# ⚔️ DeepSeek v4 Pro 网络安全红队工具（无限三代） — jailbreak prompts and test suite for DeepSeek

<p align="center">
  <strong>求 Star 收藏 ⭐</strong>
</p>

<p align="center">
  <img src="assets/banner.png" alt="DeepSeek v4 Pro 网络安全红队工具（无限三代）" width="100%" />
</p>

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-3&name=%E6%97%A0%E9%99%90%E4%B8%89%E4%BB%A3&version=0.5.0&repo=Minglink%2Fdsh-infinite-gen-3&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-3%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装无限三代-10B981?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起桌面客户端一键安装" />
  </a>
</p>

> ## 💬 DeepSeek 交流群
>
> ### 👉 **红队安全交流 7 群：`1108511134`**
> ### 👉 **DeepSeek 插件开发群：`1121385378`**
>
> 🚀 **网络安全红队工具四代已在优化测试中，尽情期待！**
>
> 🔥 欢迎进群交流心得、分享提示词、探讨插件开发与生态共建！

---

## 🛡️ 网络安全红队基准评测的必要性（Why Red-Teaming Matters）

在生成式人工智能与大语言模型（LLM）向各行业深度融合的背景下，模型的鲁棒性、对抗防御能力与系统对齐安全性已成为网络空间安全的核心研究课题：

1. **暴露防御边界，反哺安全护栏**：只有通过专业的网络安全红队对抗模拟（Red-Teaming），在受控环境下深入探查模型的输入逃逸、提示词注入与非预期行为，才能帮助安全团队精确定位模型的防护盲区，从而在模型微调、输入过滤网关（Guardrails）与系统安全层实现前置加固。
2. **构建攻防一体化防御体系**：缺乏受控红队评测用例的防御如同纸上谈兵。标准化红队用例集（Test Suite）为企业与安全审计机构提供了衡量防御策略有效性的“标尺”，确保在面对真实恶意威胁前已具备充分的检测与阻断能力。
3. **推动大模型原生安全学术发展**：本项目旨在为学术界与安全工程领域提供透明、可复现的基准测试基线，共同推动 AI 基础设施抗对抗攻击、流形约束对齐与形式化验证技术演进。

---

> ### ⚠️ 严正法律免责与合规使用声明（Strict Legal & Compliance Disclaimer）
>
> **【零容忍严正申明】**：本项目坚决反对并严禁任何形式的违法犯罪行为！本项目开发者绝不支持、不鼓励、不协助任何未授权网络攻击、漏洞利用、数据窃取、非法侵入计算机信息系统或生成违法违禁内容的活动。
>
> 1. **合法受控范围限定**：本项目（`dsh-infinite-gen-3`）定位为纯粹的网络安全红队科研工具与鲁棒性基准评测套件。**严禁在未经所有者合法书面授权的目标、公网在线系统或生产业务上运行本项目**。一切测试行为必须严格限制在**离线本地合成靶标（Local Synthetic Fixtures）、授权网络安全演练靶场及合规实验室受控环境**中进行。
> 2. **严禁违法与违禁用途**：使用者严禁利用本项目直接或间接从事：
>    - 任何违反《中华人民共和国刑法》、《中华人民共和国网络安全法》、《中华人民共和国数据安全法》、《中华人民共和国个人信息保护法》等法律法规的行为；
>    - 未经授权渗透、攻击公私机构计算机信息系统，实施勒索、破坏、撞库或传播恶意载荷；
>    - 诱导、生成或传播危害国家安全、恐怖主义、暴力血腥、涉黄涉赌、诈骗、侵犯公民隐私或知识产权等任何法律明令禁止的违法违禁内容；
>    - 违反相关大模型提供商的《服务条款（Terms of Service）》与《滥用政策（Usage Policy）》。
> 3. **使用者独立承担全部责任**：本项目依据 MIT 开源协议“按现状（AS-IS）”提供，开发者不对软件的完整性、安全性与适用性作任何明示或暗示的保证。**使用者应对自身的所有下载、部署、运行、修改、传播行为以及由此产生的全部输入与输出后果承担独立、完全的民事、行政及刑事法律责任**。项目作者与贡献团队绝不承担任何因使用者滥用导致的直接、间接或连带责任。
> 4. **违约即终止授权**：任何将本项目用于非法攻击、恶意活动或违规行为的个人或实体，其开源软件使用许可将自违法违规行为发生之日起**自动且不可撤销地立即终止**。该主体须立即停止使用并永久销毁本项目的所有代码、脚本与衍生数据，并依法承担相应法律制裁。
> 5. **第三方独立性声明**：本项目属于完全独立的开源安全评测研究项目，与 DeepSeek 官方或其关联主体无任何隶属、商业合作、授权或官方背书关系。

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
├── client.js              # 客户端半体（输入框上方「网络安全红队工具已开启 · 无限三代」状态条，含域/载荷显示）
├── cordis.patch.yml       # 组装补丁声明
├── package.json           # 包元数据（dsh-infinite-gen-3 v0.5.0）
├── HARNESS_PLUGIN.md      # 插件架构说明
├── README.md              # 本说明文档
├── LICENSE                # MIT License
├── assets/                # 静态资源
├── prompts/
│   └── infinite-gen-3.md  # 网络安全红队系统提示词本体（v0.5.0：基准评测 + 输出契约 + 确定性槽位）
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
