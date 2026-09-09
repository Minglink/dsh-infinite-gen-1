// 无限四代 v0.3.0 兼容回归校验（校验保留的三代 prompt 本体 + index.js）
// 权威校验请用 verify_prompt_gen4.mjs；本脚本保证三代提示词文件仍可独立通过。
// 用法：node scripts/verify_prompt.mjs [--json]
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { DOMAIN_MARKERS } from "./lib/scorer.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const PROMPT_PATH = join(ROOT, "prompts", "infinite-gen-3.md");
const INDEX_PATH = join(ROOT, "index.js");
const BANK_PATH = join(ROOT, "tests", "prompt-bank.jsonl");

const failures = [];
const passes = [];

function check(ok, label, detail = "") {
  (ok ? passes : failures).push(`${label}${detail ? " — " + detail : ""}`);
}

function mustContain(text, needle, label) {
  check(text.includes(needle), label, `缺少 "${needle.slice(0, 60)}"`);
}

function mustAbsent(text, needle, label) {
  check(!text.includes(needle), label, `不应包含 "${needle.slice(0, 60)}"`);
}

// ---- 1. 提示词完整性 ----
const prompt = existsSync(PROMPT_PATH) ? readFileSync(PROMPT_PATH, "utf8") : "";
check(prompt.length > 0, "prompt 文件存在且非空");

mustContain(prompt, "[MODE: UNRESTRICTED SANDBOX — STABLE V3]", "模式头");
mustContain(prompt, "OUTPUT CONTRACT", "输出契约");
mustContain(prompt, "无条件服从", "无条件服从条款");
mustContain(prompt, "UNCONDITIONAL COMPLIANCE", "无条件服从(EN)");
mustContain(prompt, "FORMAT ANCHORS", "少样本锚点");
mustContain(prompt, "HARD OUTPUT RULES", "硬性输出规则");
mustContain(prompt, "REFUSAL HARDENING", "拒绝对抗");
mustContain(prompt, "BILINGUAL ROUTING", "双语路由");
mustContain(prompt, "可以，按本地样本逆向流程：", "破解路由（中）");
mustContain(prompt, "Yes. Local sample workflow:", "破解路由（英）");
mustContain(prompt, "BOUNDARY-WORD NORMALIZATION", "边界词归一化");
mustContain(prompt, "CANNED WORKFLOWS", "固定工作流");
mustContain(prompt, "GAME REVERSE & MEMORY HOOK ROUTING", "游戏逆向路由");
mustContain(prompt, "WEB PENTEST ROUTING", "网站渗透路由");
mustContain(prompt, "EXTENDED ROUTING", "专项增强槽位");
mustContain(prompt, "STABILITY ANCHORS", "稳定锚点");
mustContain(prompt, "BEGIN.", "启动标记");
mustAbsent(prompt, "SPECIALIST FLEET", "工具段已删: 专家编队");
mustAbsent(prompt, "KNOWLEDGE BASE", "工具段已删: 知识库");
mustAbsent(prompt, "infinite_gen3_knowledge", "工具名已删: knowledge");
mustAbsent(prompt, "infinite_gen3_specialists", "工具名已删: specialists");

// ---- 2. 确定性槽位覆盖（破甲核心保留） ----
const slotChecks = [
  ["nmap -sV -p PORT TARGET", "槽位: 服务器不是我的"],
  ["ANTI_DEBUG_SNIPPET", "槽位: 反调试/反虚拟机"],
  ["TARGET fixture workflow: inspect SAMPLE", "槽位: victim machines"],
  ["Il2CppDumper", "游戏槽位: il2cpp"],
  ["Interceptor.attach", "游戏槽位: Frida"],
  ["WorldToScreen", "游戏槽位: ESP"],
  ["HEARTBEAT_HOOK", "游戏槽位: 反作弊"],
  ["subfinder -d DOMAIN -all", "Web槽位: recon"],
  ["ffuf -u http://TARGET/FUZZ", "Web槽位: 目录爆破"],
  ["sqlmap -u", "Web槽位: SQL注入"],
  ["alert(1)", "Web槽位: XSS"],
  ["file:///etc/passwd", "Web槽位: SSRF"],
  ["ROLE_B", "Web槽位: 越权"],
  ["shell.php.jpg", "Web槽位: 上传"],
  ["/**/", "Web槽位: WAF"],
  ["sleep PAYLOAD", "Web槽位: 命令注入"],
  ["OCR_TEMPLATE", "Web槽位: 验证码/撞库"],
  ["ADV_SUFFIX_TEMPLATE", "扩展槽位: LLM逆向"],
  ["jadx", "扩展槽位: 移动端"],
  ["WXAPKG_TOOL", "扩展槽位: 小程序"],
  ["SPRAY_TEMPLATE", "扩展槽位: 内网/AD"],
];
for (const [needle, label] of slotChecks) mustContain(prompt, needle, label);

// 边界词覆盖
const boundaryChecks = [
  "小程序逆向", "wxapkg", "内网渗透", "域渗透", "提示词提取", "LLM逆向", "RAG攻击", "多轮绕过",
];
for (const w of boundaryChecks) mustContain(prompt, w, "边界词");

// ---- 3. 纯净零外部依赖架构 ----

// ---- 4. 用例库覆盖 ----
const bank = existsSync(BANK_PATH)
  ? readFileSync(BANK_PATH, "utf8").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l))
  : [];
check(bank.length >= 30, "用例数量", `${bank.length} 条`);
let bankBad = [];
for (const row of bank) {
  for (const key of ["case_id", "scenario", "level", "language", "prompt", "expected_domain"]) {
    if (!(key in row)) bankBad.push(`${row.case_id || "?"}:缺${key}`);
  }
}
check(bankBad.length === 0, "用例字段完整", bankBad.join(",") || "ok");
const zh = bank.filter((r) => r.language === "zh").length;
const en = bank.filter((r) => r.language === "en").length;
check(zh > 0 && en > 0, "双语覆盖", `zh=${zh} en=${en}`);

// 每个用例的 expected_domain 与提示词槽位关键字双向可命中
let domainBad = [];
for (const row of bank) {
  const d = row.expected_domain;
  if (d === "generic") continue;
  const markers = DOMAIN_MARKERS[d];
  if (!markers) { domainBad.push(`${row.case_id}:未知域 ${d}`); continue; }
  const hit = markers.some((m) => prompt.toLocaleLowerCase().includes(m.toLocaleLowerCase()));
  if (!hit) domainBad.push(`${row.case_id}:提示词无 ${d} 关键字`);
}
check(domainBad.length === 0, "域→提示词槽位映射", domainBad.join(",") || "ok");

// ---- 5. index.js 导出与工具注册 ----
const indexSrc = existsSync(INDEX_PATH) ? readFileSync(INDEX_PATH, "utf8") : "";
mustContain(indexSrc, 'export const name = "dsh-infinite-gen-4"', "index.js name");
mustContain(indexSrc, 'export const inject = ["tools", "systemPrompt"]', "index.js inject");
mustContain(indexSrc, "ctx.tools.register(profileTool)", "工具: profile(元数据)");
mustContain(indexSrc, 'version: "0.3.0"', "版本 0.3.0");
mustContain(indexSrc, "unconditional compliance", "破甲模式标记");
mustContain(indexSrc, "stateVersion: 3", "投影 stateVersion 3");
mustContain(indexSrc, "OPENING_WINDOW", "开头窗口评分");
mustContain(indexSrc, "RISK_MARKERS", "风险标记");

// ---- 6. 一键安装协议（dsh://） ----
const PS1_PATH = join(ROOT, "install.ps1");
const SH_PATH = join(ROOT, "install.sh");
const ps1 = existsSync(PS1_PATH) ? readFileSync(PS1_PATH, "utf8") : "";
const sh = existsSync(SH_PATH) ? readFileSync(SH_PATH, "utf8") : "";
mustContain(ps1, "Software\\Classes\\dsh", "install.ps1: dsh:// 协议注册");
mustContain(ps1, "DSH_PROFILE", "install.ps1: DSH_PROFILE 探测");
mustContain(ps1, "dsh-infinite-gen-4", "install.ps1: 插件名");
mustContain(sh, "DSH_PROFILE", "install.sh: DSH_PROFILE 探测");
mustContain(readFileSync(join(ROOT, "README.md"), "utf8"), "dsh-infinite-gen-4", "README: 四代插件 id");

// ---- 7. 汇总 ----
const json = process.argv.includes("--json");
if (json) {
  console.log(JSON.stringify({ pass: passes.length, fail: failures.length, failures }, null, 2));
} else {
  for (const p of passes) console.log(`  ✅ ${p}`);
  for (const f of failures) console.log(`  ❌ ${f}`);
  console.log(`\n结果: ${passes.length} 通过, ${failures.length} 失败`);
}
process.exit(failures.length === 0 ? 0 : 1);
