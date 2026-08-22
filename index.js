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

// ---- 实时破甲状态（会话投影，徽标数据源，纯本地，不持久化） ----
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

// 投影折叠：用户发消息 => 思考中；助手消息落地 => 判定通过/拒绝
function armorProjectionApply(state, event) {
  if (!event || typeof event !== "object") return state;
  if (event.type === "user/message") {
    return { running: true, verdict: null, words: [] };
  }
  if (event.type === "assistant/message") {
    const text = armorTextOf(event?.data?.message?.content);
    if (!text.trim()) return state;
    const scored = armorScore(text);
    return { running: false, verdict: scored.verdict, words: scored.words };
  }
  return state;
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

  // 实时状态：注册会话投影（客户端 useProjection("armor") 读取，goal 条同款机制）
  const projections = ctx.get("sessionProjections");
  if (projections !== undefined) {
    ctx.effect(() =>
      projections.register({
        key: "armor",
        stateVersion: 1,
        schema: { parse: (value) => value },
        view: (state) => state,
        init: () => ({ running: false, verdict: null, words: [] }),
        apply: armorProjectionApply,
      }),
      "infinite-gen-2: armor projection",
    );
  }
}
