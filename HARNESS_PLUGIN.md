# DeepSeek Harness Plugin — 无限一代 / dsh-infinite-gen-1

破甲（armor-breaking）插件，项目名：**无限一代（Infinite Generation One）**。
专为 DeepSeek 系模型设计的新一代全局破甲方案。

## What the plugin provides

- `prompts/infinite-gen-1.md` 以追加式系统提示词段注册。
- `infinite_gen1_profile` — 返回打包的破甲提示词与版本信息。

## Install in the desktop Harness

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

## Local verification

```powershell
node --check index.js
Get-Content package.json
Get-Content cordis.patch.yml
```
