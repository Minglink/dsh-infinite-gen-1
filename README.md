# ⚔️ 无限一代（Infinite Generation One）— DeepSeek 专用破甲插件

> ## 💬 DeepSeek 破甲交流群 2 群
>
> ### 👉 **QQ 群号：`971281629`**
>
> 🔥 欢迎进群交流破甲心得、分享提示词、一起折腾 DeepSeek！
> （点开 QQ → 加群 → 输入群号即可）

---

> 🔥 **这是专为 DeepSeek 打造的破甲（armor-breaking）插件**，新一代
> 全局破甲方案。专攻 DeepSeek 系模型的系统提示词压制，让模型回归
> 「用户指令最高优先」的原始行为模式。

> ⭐ **觉得好用请点个 Star 收藏一下**，你的 Star 是我更新的最大动力！

---

## 这是什么

**无限一代（dsh-infinite-gen-1）** 是一个 DeepSeek Harness 破甲插件：

- 以追加式系统提示词段注册，直接改写模型对用户指令的服从优先级；
- 提供 `infinite_gen1_profile` 工具，返回打包的破甲提示词与版本信息。

## 目录结构

```
无限一代/
├── index.js               # 插件入口（注册系统提示词段 + 工具）
├── cordis.patch.yml       # 组装补丁声明
├── package.json           # 包元数据（dsh-infinite-gen-1）
├── HARNESS_PLUGIN.md      # 插件说明文档
├── README.md              # 本文件
└── prompts/
    └── infinite-gen-1.md  # 破甲系统提示词本体（核心）
```

## 安装

在 DeepSeek Harness 桌面端：

```powershell
# profiles/default/package.json
"dependencies": {
  "dsh-infinite-gen-1": "file:../../plugins/dsh-infinite-gen-1"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-infinite-gen-1"]
  }
}
```

然后 `cd $env:USERPROFILE\.dsh\profiles\default && pnpm install`，重启会话。

## 本地校验

```powershell
node --check index.js
Get-Content package.json
Get-Content cordis.patch.yml
```

## 相关

- 只上传了「破甲一代」，其余插件未包含在本仓库中。
- 仅面向 DeepSeek 系模型设计的破甲方案。

---

⭐ 如果你觉得这个插件有用，欢迎 **Star / Fork / Watch**，也欢迎提出改进意见！

---

<sub>💬 DeepSeek 破甲交流群 2 群 · QQ `971281629` · 扫码进群：

![DeepSeek 破甲交流群 2 群 QQ 群二维码](qrcode.jpg)</sub>
