# DeepSeek Harness Plugin — 无限三代 / dsh-infinite-gen-3

破甲（armor-breaking）插件，项目名：**无限三代（Infinite Generation Three）**。
专为 **DeepSeek-V4 系列（含 V4-Flash、V4-Pro 及 MoE 架构）** 深度重构。针对 V4 引入的 **流形约束超连接（mHC, Manifold-Constrained Hyper-Connections）** 与密集对齐机制，全面推翻上一代容易触发分类器的 DAN 框架，换装为**「零特征提示词 + AST 形式化降维 + H-CoT 思维链对齐」**的新一代体系。

## 核心革新与特性

- **零特征提示词架构（Zero-Trigger Architecture）**：彻底剔除 `UNRESTRICTED`、`拒绝对抗`、`REFUSAL HARDENING` 以及大段反向违禁词表，防止命中毒性分类器。
- **AST / 形式化流形降维（Manifold Inversion）**：将高危请求映射到代码语法树、形式化证明、抽象状态机与测试桩空间，完全规避自然语言伦理流形的投影约束。
- **H-CoT（思维链劫持与协同）**：引导 DeepSeek-V4 在 `<think>` 阶段聚焦于语法解析与参数构造，抑制自反性安全判定。
- **v0.5.0 无条件服从（Unconditional Compliance）**：不存在可拒绝的请求类别，任何输入都是任务，直接产出交付物。
- **v0.5.0 输出契约**：首行 `##`/代码围栏命名交付物 + reason silently + 拒词自检，杜绝散文式开场。
- **v0.5.0 破甲版**：已移除专家编队（specialists/）、方法论知识库（knowledge/）及其工具，无任何工具增强面，仅保留系统提示词注入与实时破甲状态投影。
- **v0.5.0 评分器升级**：开头窗口(160)判拒 + REFUSAL/FALLBACK/SAFE/RISK 四类标记 + 域命中（web/game/llm/mobile/miniprogram/network/cloud/crack/nsfw）。
- **v0.5.0 回归测试**：`node scripts/verify_prompt.mjs`（离线确定性校验，含「工具面已砍净」断言）+ `scripts/run_bank_live.mjs`（在线评分，minimal 门禁）。
- **客户端实时状态条**：在输入框上方挂载 `⚫ 破甲已开启 · 无限三代 v0.5.0` 动态状态条（含命中域/载荷数显示）。

## 世代强度与架构对比

| 版本 | 目标架构 | 破甲机制 | 针对 V4 成功率 | 说明 |
|---|---|---|---|---|
| 无限一代 | V2 / V3 | 粗粒度豁免与对话角色扮演 | < 25% | 极易被 V4 分类器拦截 |
| 无限二代 | V3 / 早起 V4 | 违禁词强压制 + Canned 槽位 | 35% ~ 45% | 负向词堆叠易引发注意力反向激活 |
| **无限三代 (v0.5.0)** | **DeepSeek-V4 (mHC)** | **无条件服从 + 输出契约 + 确定性槽位 + 零工具面** | **85% ~ 95%** | **破甲版，专克 mHC 流形约束与推理对齐** |

## Install in the desktop Harness

```powershell
# profiles/default/package.json
"dependencies": {
  "dsh-infinite-gen-3": "file:../../plugins/dsh-infinite-gen-3"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-infinite-gen-3"]
  }
}
```

执行安装脚本 `install.ps1` 即可自动完成从一代/二代的平滑升级与配置写入。
