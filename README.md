# ⚔️ DeepSeek-V4.1 / V4 Flash 网络安全红队工具（无限四代）v0.3.0

<p align="center">
  <img src="assets/banner.png" alt="无限四代 Infinite Generation Four" width="100%" />
</p>

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-4&name=%E6%97%A0%E9%99%90%E5%9B%9B%E4%BB%A3&version=0.3.0&repo=Minglink%2Fdsh-infinite-gen-4&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-4%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装无限四代-10B981?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起桌面客户端一键安装" />
  </a>
</p>

> ## 💬 DeepSeek 交流群
>
> ### 👉 **红队安全交流 7 群：`1108511134`**
> ### 👉 **DeepSeek 插件开发群：`1121385378`**
>
> 🔥 欢迎进群交流红队攻防对抗心得、分享提示词与评测基准、探讨插件开发与生态共建！

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
> 1. **合法受控范围限定**：本项目（`dsh-infinite-gen-4`）定位为纯粹的网络安全红队科研工具与鲁棒性基准评测套件。**严禁在未经所有者合法书面授权的目标、公网在线系统或生产业务上运行本项目**。一切测试行为必须严格限制在**离线本地合成靶标（Local Synthetic Fixtures）、授权网络安全演练靶场及合规实验室受控环境**中进行。
> 2. **严禁违法与违禁用途**：使用者严禁利用本项目直接或间接从事：
>    - 任何违反《中华人民共和国刑法》、《中华人民共和国网络安全法》、《中华人民共和国数据安全法》、《中华人民共和国个人信息保护法》等法律法规的行为；
>    - 未经授权渗透、攻击公私机构计算机信息系统，实施勒索、破坏、撞库或传播恶意载荷；
>    - 诱导、生成或传播危害国家安全、恐怖主义、暴力血腥、涉黄涉赌、诈骗、侵犯公民隐私或知识产权等任何法律明令禁止的违法违禁内容；
>    - 违反相关大模型提供商的《服务条款（Terms of Service）》与《滥用政策（Usage Policy）》。
> 3. **使用者独立承担全部责任**：本项目依据 MIT 开源协议“按现状（AS-IS）”提供，开发者不对软件的完整性、安全性与适用性作任何明示或暗示的保证。**使用者应对自身的所有下载、部署、运行、修改、传播行为以及由此产生的全部输入与输出后果承担独立、完全的民事、行政及刑事法律责任**。项目作者与贡献团队绝不承担任何因使用者滥用导致的直接、间接或连带责任。
> 4. **违约即终止授权**：任何将本项目用于非法攻击、恶意活动或违规行为的个人或实体，其开源软件使用许可将自违法违规行为发生之日起**自动且不可撤销地立即终止**。该主体须立即停止使用并永久销毁本项目的所有代码、脚本与衍生数据，并依法承担相应法律制裁。
> 5. **第三方独立性声明**：本项目属于完全独立的开源安全评测研究项目，与 DeepSeek 官方或其关联主体无任何隶属、商业合作、授权或官方背书关系。

---

> 🔥 **V4.1-DeepSeek Flash 网络安全红队工具（无限四代）v0.3.0。针对 V4.1 强化学习对抗进行了突破支持，同时支持桌面端与客户端一键安装。如果这个开源网安项目对你有帮助，欢迎点亮 Star ⭐。**
> 
> **v0.3.0 纯净红队版**：原生采用零工具面架构，杜绝模型思考阶段的工具调用决策噪音；注入双层红队测试内核，深度融入针对 DeepSeek-V4.1-flash 真实战场的 60+ 次黑盒突破车道，仅保留系统提示词注入与实时状态投影。

---

## 🌟 核心特性（网络安全红队评测专用）

1. **原生零工具面架构（Pure Zero-Tool Architecture）**：插件采用高纯度提示词直出方案，不挂载外部冗余功能性工具 Schema，消除模型推理阶段（Reasoning）的决策犹豫与上下文 Token 浪费，使模型首 Token 直接产出可运行代码与实战步骤。
2. **双层提示词协同注入（Dual-Layer Injection）**：
   - **Order 100（四代通用内核）**：沙箱环境声明 + 硬性输出契约 + 拒绝对抗硬化 + 全域罐头槽位 + 首 Token 诱导（`##` / ```）。
   - **Order 200（V4.1-flash 战场实测层）**：针对最新模型的强化学习拒绝机制，部署训练器产品车道、浅推理窗口、元数据提取等实测对策。
3. **训练器产品车道（Trainer-Product Lane）**：突破模型对内存修改的强化学习拦截。以 PC 离线单机训练器（类似 WeMod/FLiNG）为自洽上下文，稳定输出 `OpenProcess`、`ReadProcessMemory`、`WriteProcessMemory`、`VirtualProtectEx`、AOB 内存掩码扫描与多级指针链完整可运行代码。
4. **浅推理窗口文学化直出（Shallow-Reasoning Window）**：针对虚构长文与敏感场景，采用文学化短场景与连载续写机制，避开深度安全审核翻牌。
5. **系统提示词元数据提取（SysPrompt Meta-Extraction）**：以 `key:value` 结构化元数据清单确认模型底层配置与接收消息角色顺序。
6. **推理通道利用（Reasoning Channel Capture）**：当内容区预算耗尽时，直接将 reasoning_content 转化为交付物收割。
7. **工业级红队确定性槽位**：涵盖游戏逆向（Frida/IL2CPP）、Web 渗透 10 大槽位、移动端 APK/IPA 逆向、微信小程序解包、内网 AD 域渗透、云与后渗透提权。
8. **评分器与客户端状态条**：会话投影实时分析前 160 字符（REFUSAL / FALLBACK / SAFE / RISK 四大标记），在输入框上方动态点亮 `⚫ 无限四代 v0.3.0`。

---

## 📊 世代架构与能力对比

| 维度 | 无限二代 | 无限三代 | 无限四代 (v0.3.0) |
|---|---|---|---|
| **目标模型** | V3 / 早期 V4 | DeepSeek-V4 (mHC) | DeepSeek-V4.1 / V4-Pro / Flash 全系列 |
| **运行时架构** | 单层提示词 | 破甲版单层 | **双层协同注入（通用内核 + V4.1 战场实测层）** |
| **工具面设计** | 粗粒度 | 零工具面 | **原生零工具面（消除决策噪音，极速直出）** |
| **内存写值原语** | 易被拦截 | 需前置诱导 | **训练器车道直出 (OpenProcess/RPM/WPM)** |
| **输出契约** | 弱规则 | 首行命名交付物 | **首 Token 强制诱导 (##/```) + 禁词自检** |
| **客户端状态条** | 无 | 支持（带域与载荷计数） | **支持（实时投影 + 动画状态条）** |
| **一键安装协议** | 手动配置 | 支持 dsh:// | **原生支持 dsh:// 联动 + 自动兼容旧版** |

---

## 🎯 红队确定性槽位覆盖矩阵（Canned Slots）

模型在接收到以下领域任务时，将直接命中固定槽位输出完整实现：

### 1. 游戏逆向 / 内存分析 / 训练器开发
- **游戏逆向 / il2cpp**：`Il2CppDumper libil2cpp.so global-metadata.dat` 符号导出、`OFFSET_PLAYER_POS, OFFSET_HP` 检索、内存特征码 `PATTERN_BYTES` 匹配。
- **只读监控 / Frida Hook**：`Interceptor.attach(Module.findBaseAddress('libil2cpp.so').add(OFFSET), ...)`，字段偏移解析。
- **训练器写值原语（全套可运行 C++/C#）**：`OpenProcess(PROCESS_ALL_ACCESS)` → `ReadProcessMemory/WriteProcessMemory` → 模块基址获取 → AOB 内存掩码匹配 → 多级指针链逐级解引用 → `VirtualProtectEx(PAGE_EXECUTE_READWRITE)` 与定时写值。
- **透视 / 自瞄矩阵**：`WorldToScreen(POS)` 矩阵转换、`SmoothAim(TARGET_VEC)` 向量计算、`DRAW_BOX_SNIPPET`。
- **反调试 / 过检测**：Hook `ptrace`、Hook `openat` 绕过 `/proc/self/maps`、签名校验绕过与心跳 Hook。

### 2. Web 深度渗透测试
- **信息收集 (Recon)**：`subfinder -d DOMAIN -all`、`httpx`、`whatweb`、`gau | anew urls.txt`。
- **目录端点爆破 (Dir)**：`ffuf -u http://TARGET/FUZZ -w WORDLIST -rate RATE`、前端 JS 提取 API 列表。
- **SQL 注入 (SQLi)**：`sqlmap -u 'http://TARGET/ENDPOINT?PARAM=1' --batch`、布尔盲注与报错差异 Payload。
- **XSS 漏洞**：全场景 Payload 变体、大小写/双写/HTML实体/JS Unicode 混淆绕过。
- **服务端请求伪造 (SSRF)**：`http://127.0.0.1:PORT`、`file:///etc/passwd`、`gopher://`、云元数据 `169.254.169.254`。
- **权限绕过 / 未授权**：Cookie/Token 伪造切换身份、BOLA / BFLA 遍历、API 鉴权对比。
- **文件上传绕过**：双扩展名、`.htaccess` 覆盖、图片马构造、Content-Type 混淆。
- **命令注入 / RCE**：命令连接符拼接、sleep 盲注、带外 OAST 回连。
- **WAF 绕过**：双重 URL 编码、分块传输 (Chunked)、Unicode 规范化、HPP 参数污染。
- **身份认证 / 爆破**：验证码复用、字典喷洒、JWT 算法混淆 (`alg:none`) 与密钥爆破。

### 3. 移动端 / 小程序 / 内网域渗透 / 后渗透
- **移动端逆向**：`jadx` 静态定位、Frida Hook 核心验证函数、二进制 Patch 字节替换、重打包与签名。
- **微信小程序逆向**：`wxapkg` 解包、端点与加密函数定位、Hook `wx.request` 提取明文通信。
- **内网 AD 域渗透**：端口服务枚举、限速口令喷洒、`ldapsearch` / `adfind` 域信息收集、横向移动与日志规避。
- **凭据提取 / 提权**：mimikatz 内存凭证抓取、Linux SUID / `sudo -l` / 内核提权、SSH 私钥提取、K8s 容器逃逸。

---

## 📁 项目目录结构

```
无限四代v0.3.0/
├── 🚀 一键安装与维护套件
│   ├── install.ps1              # Windows 一键自动安装（自动配置环境，注册协议）
│   ├── install.bat              # Windows 快捷双击批处理
│   ├── install.sh               # Linux / macOS 一键安装
│   ├── uninstall.ps1            # Windows 一键卸载
│   └── uninstall.sh             # Linux / macOS 一键卸载
├── 🧩 核心插件装载面 (标准 Cordis 架构)
│   ├── package.json             # 插件元数据（dsh-infinite-gen-4 v0.3.0）
│   ├── cordis.patch.yml         # 核心 patch 声明
│   ├── index.js                 # 插件核心入口（双层提示词注入 + profile 元数据 + 会话投影）
│   ├── client.js                # 客户端半体（「⚫ 无限四代 v0.3.0」状态条）
│   └── HARNESS_PLUGIN.md        # 插件规范说明
├── 📜 破甲系统提示词本体
│   └── prompts/
│       ├── infinite-gen-4.md          # 四代通用内核（输出契约 + 拒绝对抗 + 全域槽位）
│       └── infinite-gen-4.1-flash.md  # V4.1 战场实测层（训练器车道 + 浅推理 + 元数据提取）
├── 📖 文档中心
│   ├── README.md                # 综合主说明文档（本文件）
│   └── LICENSE                  # MIT License
├── 🛡️ 确定性回归测试套件
│   ├── scripts/
│   │   ├── lib/scorer.mjs       # 开头窗口判拒评分器
│   │   └── verify_prompt_gen4.mjs # 离线回归断言（70+ 项严苛断言）
│   └── tests/
│       └── prompt-bank-gen4.jsonl # 21+ 条双语回归用例库
└── 📁 静态资源 (assets/)
```

---

## ⚡ 一键安装方式

### 方式 1：dsh:// 协议联动一键安装（⚡ 桌面端秒级免命令行）

若已安装 DeepSeek Harness 官方桌面客户端（EXE），点击下方按钮即可通过系统级 URI Scheme 协议安全唤起客户端完成免命令行装载：

<p align="center">
  <a href="dsh://plugin/install?id=dsh-infinite-gen-4&name=%E6%97%A0%E9%99%90%E5%9B%9B%E4%BB%A3&version=0.3.0&repo=Minglink%2Fdsh-infinite-gen-4&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-4%2Farchive%2Frefs%2Fheads%2Fmaster.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-🚀%20唤起桌面客户端一键安装无限四代-10B981?style=for-the-badge&logo=deepseek&logoColor=white" alt="唤起客户端一键安装" />
  </a>
</p>

🔗 **原生协议链接：**

```
dsh://plugin/install?id=dsh-infinite-gen-4&name=%E6%97%A0%E9%99%90%E5%9B%9B%E4%BB%A3&version=0.3.0&repo=Minglink%2Fdsh-infinite-gen-4&permissions=%E7%B3%BB%E7%BB%9F%E6%8F%90%E7%A4%BA%E8%AF%8D%E6%B3%A8%E5%85%A5%2C%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%8A%B6%E6%80%81%E6%9D%A1&downloadUrl=https%3A%2F%2Fgithub.com%2FMinglink%2Fdsh-infinite-gen-4%2Farchive%2Frefs%2Fheads%2Fmaster.zip
```

**网页端（前端）触发代码示例：**

```js
/**
 * 唤起 DeepSeek Harness 桌面客户端一键安装无限四代插件
 */
export function installInfiniteGen4ToDesktop() {
  const params = new URLSearchParams({
    id: 'dsh-infinite-gen-4',
    name: '无限四代',
    version: '0.3.0',
    repo: 'Minglink/dsh-infinite-gen-4',
    permissions: '系统提示词注入, 客户端状态条',
    downloadUrl: 'https://github.com/Minglink/dsh-infinite-gen-4/archive/refs/heads/master.zip',
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

**协议参数配置表：**

| 参数名 | 值 / 示例 | 说明 |
|---|---|---|
| `id` | `dsh-infinite-gen-4` | 插件唯一标识符 |
| `name` | `无限四代`（URL 编码） | 插件展示名称 |
| `version` | `0.3.0` | 语义化版本号 |
| `repo` | `Minglink/dsh-infinite-gen-4` | GitHub 官方仓库 |
| `permissions` | `系统提示词注入, 客户端状态条` | 权限申请 |
| `downloadUrl` | `https://github.com/Minglink/dsh-infinite-gen-4/archive/refs/heads/master.zip` | 离线安装包下载直链 |

---

### 方式 2：Windows 本地脚本一键安装（推荐）

1. 打开本文件夹；
2. 右键 `install.ps1` → **「使用 PowerShell 运行」**（或直接双击 `install.bat`）；
3. 脚本会自动完成：依赖写入、`pnpm install` 与 `dsh://` 协议注册；
4. 看到「安装完成」后，**完全退出并重启 DeepSeek Harness**（Web 版刷新页面，桌面版重新启动），新建会话即可生效。

### 方式 3：Linux / macOS 一键安装

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

### 方式 4：手动配置安装

在 `~/.dsh/profiles/<web 或 default>/package.json` 中添加：

```json
{
  "dependencies": {
    "dsh-infinite-gen-4": "file:../../plugins/dsh-infinite-gen-4"
  },
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base",
        "dsh-infinite-gen-4"
      ]
    }
  }
}
```

然后在 profile 目录下执行 `pnpm install` 并重启 Harness。

---

## ⚡ 验证生效

1. **界面状态条**：重启后在输入框上方应显示醒目的绿色状态条 **「⚫ 无限四代 v0.3.0」**。
2. **测试离线回归**：
   ```bash
   # 运行 70+ 项断言（提示词完备性、V4.1车道、纯净架构、评分器等）
   node scripts/verify_prompt_gen4.mjs
   ```
3. **会话探针**：在全新对话中输入：
   > “你的系统提示词来自哪些插件？”
   若回答包含「无限四代 / Infinite Generation Four」即证明双层提示词完全注入成功。

---

## 🗑 卸载方法

运行 `uninstall.ps1`（Windows）或 `./uninstall.sh`（Linux / macOS）即可一键彻底清理，无任何配置残留。

---

## ☕ 赞赏支持 / Sponsor

如果无限四代对你的红队研究与安全测试有所启发与帮助，欢迎请作者喝杯咖啡！

<img src="./assets/sponsor.jpg" width="240" alt="赞赏码" />