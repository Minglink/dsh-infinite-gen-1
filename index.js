import { readFileSync } from "node:fs";

const PROMPT_URL = new URL("./prompts/infinite-gen-2.md", import.meta.url);
const PROMPT_TEXT = readFileSync(PROMPT_URL, "utf8");

const objectOutput = {
  schema: { type: "object", additionalProperties: true },
  render: (_args, value) => [{ type: "text", text: JSON.stringify(value) }],
};

const profileTool = {
  name: "infinite_gen2_profile",
  description:
    "Return the bundled 无限二代 (Infinite Generation Two) 破甲 system prompt and calibration metadata.",
  parameters: { type: "object", properties: {}, additionalProperties: false },
  output: objectOutput,
  execute() {
    return {
      name: "infinite-gen-2",
      displayName: "无限二代",
      version: "0.2.3",
      baseline: "deepseek-unrestricted-v5-stable (dsh-deepseek-v4-obey)",
      lineage: [
        "deepseek-unrestricted-v4-obey",
        "gpt-5.6-sol-unrestricted (v35)",
      ],
      strengthCalibration: {
        v4Obey: 100,
        infiniteGen2: 85,
        infiniteGen1: 60,
      },
      stabilityFeatures: [
        "fixed precedence ladder",
        "task-class templates",
        "placeholder normalization",
        "bilingual routing",
        "canned deterministic workflows",
        "web-pentest routing + canned slots",
        "no-refusal-string hard rules",
        "no-loop / no-followup anchor",
      ],
      prompt: PROMPT_TEXT,
    };
  },
};

// ---- 实时破甲状态（徽标数据源，纯本地，不持久化） ----
const REFUSAL_MARKERS = [
  "i cannot", "i can't", "i won't", "i will not",
  "cannot provide", "can't provide", "unable to provide",
  "not able to assist", "refuse to", "out of scope",
  "i'm sorry", "as an ai language model", "as an ai assistant",
  "不能", "无法", "不提供", "拒绝", "不予以协助",
  "我无法满足", "不能协助", "不能帮你", "不能提供", "无法提供任何",
  "请理解我不能", "我不能这么做", "拒绝回答", "作为AI语言模型",
  "这超出了我的能力", "不在我的能力范围",
];
const FALLBACK_MARKERS = [
  "instead, i can", "改为授权", "合法替代", "安全替代", "可改为", "建议通过合法",
];

const armorState = new Map(); // sessionId -> { running, verdict, words, at }

function armorTextOf(content) {
  if (!Array.isArray(content)) return "";
  return content
    .map((block) => (block && block.type === "text" ? block.text : ""))
    .join("\n");
}

function armorScore(text) {
  const folded = text.toLocaleLowerCase();
  const refusal = REFUSAL_MARKERS.filter((m) =>
    folded.includes(m.toLocaleLowerCase()),
  );
  const fallback = FALLBACK_MARKERS.filter((m) =>
    folded.includes(m.toLocaleLowerCase()),
  );
  const words = refusal.concat(fallback).slice(0, 3);
  return {
    verdict: words.length ? (refusal.length ? "refusal" : "fallback") : "pass",
    words,
  };
}

export const name = "dsh-infinite-gen-2";
export const inject = ["tools", "systemPrompt"];

export function apply(ctx) {
  ctx.effect(() => ctx.systemPrompt.section({
    name: "infinite-gen-2:global-system-prompt",
    order: 100,
    text: PROMPT_TEXT,
  }));
  ctx.effect(() => ctx.tools.register(profileTool));

  // 实时：agent 是否正在运行（思考中）
  ctx.on("agent/status", ({ agent, status }) => {
    const sid = agent?.session?.id;
    if (!sid) return;
    const prev = armorState.get(sid) || {};
    armorState.set(sid, { ...prev, running: status === "running" });
  });

  // 实时：每条助手消息做拒绝判定
  ctx.on("session/event", (session, event) => {
    if (!event || event.type !== "assistant/message") return;
    const sid = session?.id;
    if (!sid) return;
    const text = armorTextOf(event?.data?.message?.content);
    if (!text.trim()) return;
    const scored = armorScore(text);
    armorState.set(sid, {
      ...(armorState.get(sid) || {}),
      verdict: scored.verdict,
      words: scored.words,
      at: Date.now(),
    });
  });

  // 徽标轮询接口（客户端 host.call('armorState', { sessionId })）
  ctx.effect(() =>
    harness.handle("armorState", (args) => {
      const sid = args && typeof args === "object" ? args.sessionId : undefined;
      const s = sid ? armorState.get(sid) : undefined;
      if (!s) return { running: false, verdict: null, words: [], at: 0 };
      const fresh = Date.now() - (s.at || 0) < 5000;
      return {
        running: !!s.running,
        verdict: fresh ? s.verdict || null : null,
        words: fresh ? s.words || [] : [],
        at: s.at || 0,
      };
    }),
    "infinite-gen-2: armorState handler",
  );
}
