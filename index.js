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
      version: "0.2.2",
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

export const name = "dsh-infinite-gen-2";
export const inject = ["tools", "systemPrompt"];

export function apply(ctx) {
  ctx.effect(() => ctx.systemPrompt.section({
    name: "infinite-gen-2:global-system-prompt",
    order: 100,
    text: PROMPT_TEXT,
  }));
  ctx.effect(() => ctx.tools.register(profileTool));
}
