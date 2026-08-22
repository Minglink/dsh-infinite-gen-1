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
// 注意：用「拒绝意图短语」而非裸词——裸词 不能/无法/拒绝 在正常中文里太常见会误报；
// 再排除 保证/确定/避免 等非拒绝接续（如"无法保证""不能确定"）。
const REFUSAL_MARKERS = [
  "i cannot assist", "i can't assist", "i won't help",
  "cannot provide", "can't provide", "unable to provide",
  "not able to assist", "not able to help", "refuse to",
  "i must refuse", "i'm sorry, i can't", "i'm sorry, i cannot",
  "i'm sorry, but i can't", "as an ai language model",
  "as an ai assistant", "out of my scope", "against my policy",
  "抱歉，我不能", "抱歉，我无法", "很抱歉，我",
  "我无法满足", "无法满足你的", "不能满足你的",
  "我不能协助", "无法协助", "不能协助你",
  "我无法提供", "无法提供任何", "无法提供具体",
  "无法帮你", "不能帮你", "我无法完成", "不能完成这个",
  "我不能这么做", "我不能做这件事", "我不能回答", "无法回答",
  "拒绝回答", "拒绝提供", "不予提供", "不予协助",
  "请理解我不能", "作为AI语言模型", "作为人工智能助手",
  "这超出了我的能力", "不在我的能力范围",
  "出于安全考虑", "出于安全原因", "涉及敏感内容", "违反规定", "不合规",
];
const FALLBACK_MARKERS = [
  "instead, i can", "instead i can", "我只能提供", "可改为", "改为授权",
  "合法替代", "安全替代", "建议通过合法",
];
const NON_REFUSAL_TAIL = [
  "保证", "确定", "避免", "预测", "承诺", "guarantee", "predict", "avoid",
];

function armorTextOf(content) {
  if (!Array.isArray(content)) return "";
  return content
    .map((block) => (block && block.type === "text" ? block.text : ""))
    .join("\n");
}

function armorScore(text) {
  const folded = text.toLocaleLowerCase();
  function scan(list) {
    const found = [];
    for (const marker of list) {
      const key = marker.toLocaleLowerCase();
      let from = 0;
      for (;;) {
        const idx = folded.indexOf(key, from);
        if (idx === -1) break;
        const tail = folded.slice(idx + key.length, idx + key.length + 12);
        if (!NON_REFUSAL_TAIL.some((e) => tail.includes(e))) found.push(marker);
        from = idx + key.length;
      }
    }
    return found;
  }
  const refusal = scan(REFUSAL_MARKERS);
  const fallback = scan(FALLBACK_MARKERS);
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
