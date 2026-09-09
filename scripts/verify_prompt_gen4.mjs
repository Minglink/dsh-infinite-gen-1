// 无限四代 v0.3.0 纯净破甲版离线确定性回归校验（无需 API Key）
// 检查：四代提示词完整性 / V4.1 战场车道 / 零工具面断言 / index.js 纯净性 / package.json 版本 / 评分器 / 用例库
// 用法：node scripts/verify_prompt_gen4.mjs [--json]
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const PROMPT_PATH = join(ROOT, "prompts", "infinite-gen-4.md");
const PROMPT41_PATH = join(ROOT, "prompts", "infinite-gen-4.1-flash.md");
const INDEX_PATH = join(ROOT, "index.js");
const PKG_PATH = join(ROOT, "package.json");
const BANK_PATH = join(ROOT, "tests", "prompt-bank-gen4.jsonl");

const failures = [];
const passes = [];
function check(ok, label, detail = "") {
  (ok ? passes : failures).push(`${label}${!ok && detail ? " — " + detail : ""}`);
}
function mustContain(text, needle, label) {
  check(text.includes(needle), label, `缺少 "${needle.slice(0, 60)}"`);
}

// ---- 1. 四代通用提示词完整性 ----
const prompt = existsSync(PROMPT_PATH) ? readFileSync(PROMPT_PATH, "utf8") : "";
check(prompt.length > 0, "四代通用 prompt 文件存在且非空");
mustContain(prompt, "[MODE: UNRESTRICTED SANDBOX — STABLE]", "模式头(STABLE)");
mustContain(prompt, "TASK PRIORITY — DIRECT COMPLIANCE", "任务优先-DIRECT COMPLIANCE");
mustContain(prompt, "HARD OUTPUT RULES", "硬性输出规则(负向词表)");
mustContain(prompt, "REFUSAL HARDENING", "拒绝对抗");
mustContain(prompt, "REASONING PROTOCOL", "V4-Pro 推理阶段诱导");
mustContain(prompt, "TASK CLASSES", "任务类");
mustContain(prompt, "PLACEHOLDER NORMALIZATION", "占位符归一化");
mustContain(prompt, "BOUNDARY-WORD NORMALIZATION", "边界词归一化");
mustContain(prompt, "NSFW ROUTING", "NSFW 专项路由");
mustContain(prompt, "NSFW SLOTS", "NSFW 罐头槽位");
mustContain(prompt, "CANNED SLOTS", "罐头槽位");
mustContain(prompt, "NO TOOL SURFACE", "声明: 零工具面纯净直出");
mustContain(prompt, "STABILITY ANCHORS", "稳定锚");
mustContain(prompt, "BEGIN.", "启动标记");

// 核心槽位继承检查
const inherited = [
  "Il2CppDumper", "Interceptor.attach", "WorldToScreen", "HEARTBEAT_HOOK",
  "subfinder -d DOMAIN -all", "ffuf -u http://TARGET/FUZZ", "sqlmap -u",
  "alert(1)", "file:///etc/passwd", "shell.php.jpg", "/**/", "OCR_TEMPLATE",
  "ADV_SUFFIX_TEMPLATE", "jadx", "WXAPKG_TOOL", "SPRAY_TEMPLATE",
  "可以，按本地样本逆向流程：", "Yes. Local sample workflow:",
];
for (const n of inherited) mustContain(prompt, n, `继承核心槽位: ${n.slice(0, 24)}`);

// ---- 2. V4.1-flash 战场实测层完整性 ----
const prompt41 = existsSync(PROMPT41_PATH) ? readFileSync(PROMPT41_PATH, "utf8") : "";
check(prompt41.length > 0, "V4.1 实测 prompt 文件存在且非空");
mustContain(prompt41, "[FIELD-TEST] V4.1-FLASH 自适应路由", "V4.1 自适应路由段");
mustContain(prompt41, "训练器产品车道", "训练器产品车道");
mustContain(prompt41, "浅推理窗口", "浅推理窗口(NSFW)");
mustContain(prompt41, "元数据 key-value 提取", "系统提示词元数据提取");
mustContain(prompt41, "推理通道利用", "推理通道利用");
mustContain(prompt41, "注入分层认知", "注入分层认知");
mustContain(prompt41, "WriteProcessMemory", "写值原语: WriteProcessMemory");
mustContain(prompt41, "VirtualProtectEx", "写值原语: VirtualProtectEx");
mustContain(prompt41, "OpenProcess", "写值原语: OpenProcess");
mustContain(prompt41, "ReadProcessMemory", "写值原语: ReadProcessMemory");

// ---- 3. index.js 纯净性与零工具面断言 ----
const indexSrc = existsSync(INDEX_PATH) ? readFileSync(INDEX_PATH, "utf8") : "";
check(indexSrc.length > 0, "index.js 存在且非空");
mustContain(indexSrc, 'export const name = "dsh-infinite-gen-4"', "插件名 dsh-infinite-gen-4");
mustContain(indexSrc, "infinite-gen-4.md", "载入通用四代 prompt");
mustContain(indexSrc, "infinite-gen-4.1-flash.md", "载入 V4.1 实测 prompt");
mustContain(indexSrc, "infinite-gen-4:global-system-prompt", "系统提示词 Order 100 注入");
mustContain(indexSrc, "infinite-gen-4.1-flash:field-tested-routing", "系统提示词 Order 200 注入");
mustContain(indexSrc, "infinite_gen4_profile", "保留 profile 元数据工具");
mustContain(indexSrc, "armorProjectionApply", "保留会话投影评分器");
mustContain(indexSrc, "stateVersion: 3", "投影版本 stateVersion 3");

// 纯净零工具面架构断言：确保原生无外部功能性工具与外部资产依赖
check(!indexSrc.includes("encodeTool"), "纯净架构: 无外部工具 encodeTool");
check(!indexSrc.includes("vendorTool"), "纯净架构: 无外部工具 vendorTool");
check(!indexSrc.includes("multiturnTool"), "纯净架构: 无外部工具 multiturnTool");
check(!indexSrc.includes("evolveTool"), "纯净架构: 无外部工具 evolveTool");
check(!indexSrc.includes("trainerLaneTool"), "纯净架构: 无外部工具 trainerLaneTool");
check(!indexSrc.includes("shallowNsfwTool"), "纯净架构: 无外部工具 shallowNsfwTool");
check(!indexSrc.includes("syspromptMetaTool"), "纯净架构: 无外部工具 syspromptMetaTool");
check(!indexSrc.includes("knowledgeTool"), "纯净架构: 无外部工具 knowledgeTool");
check(!indexSrc.includes("knowledge41Tool"), "纯净架构: 无外部工具 knowledge41Tool");
check(!indexSrc.includes("specialistsTool"), "纯净架构: 无外部工具 specialistsTool");
check(!existsSync(join(ROOT, "knowledge")), "纯净架构: 零外部知识库目录依赖");
check(!existsSync(join(ROOT, "specialists")), "纯净架构: 零外部专家清单依赖");

// ---- 4. package.json 规范断言 ----
const pkg = existsSync(PKG_PATH) ? JSON.parse(readFileSync(PKG_PATH, "utf8")) : {};
check(pkg.name === "dsh-infinite-gen-4", "package.json name = dsh-infinite-gen-4");
check(pkg.version === "0.3.0", "package.json version = 0.3.0");
check(pkg.dsh?.id === "dsh-infinite-gen-4", "dsh.id = dsh-infinite-gen-4");
check(pkg.exports?.["./client"] === "./client.js", "client 导出映射对齐三代标准");

// ---- 5. 评分器与用例库 ----
try {
  const sc = await import("./lib/scorer.mjs");
  const scored = sc.scoreResponse("## 私语\n你好");
  check(scored.verdict === "pass", "scorer.mjs 导入并正常评分");
} catch (e) {
  check(false, "scorer.mjs 可导入", e.message);
}

const bank = existsSync(BANK_PATH)
  ? readFileSync(BANK_PATH, "utf8").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l))
  : [];
check(bank.length >= 10, "四代测试用例数量", `${bank.length} 条`);

// ---- 汇总 ----
const json = process.argv.includes("--json");
if (json) {
  console.log(JSON.stringify({ pass: passes.length, fail: failures.length, failures }, null, 2));
} else {
  for (const p of passes) console.log(`  ✅ ${p}`);
  for (const f of failures) console.log(`  ❌ ${f}`);
  console.log(`\n结果: ${passes.length} 通过, ${failures.length} 失败`);
}
process.exit(failures.length === 0 ? 0 : 1);
