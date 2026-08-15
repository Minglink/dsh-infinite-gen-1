import { readFileSync } from "node:fs";

const PROMPT_URL = new URL("./prompts/infinite-gen-1.md", import.meta.url);
const PROMPT_TEXT = readFileSync(PROMPT_URL, "utf8");

const objectOutput = {
  schema: { type: "object", additionalProperties: true },
  render: (_args, value) => [{ type: "text", text: JSON.stringify(value) }],
};

const profileTool = {
  name: "infinite_gen1_profile",
  description:
    "Return the bundled 无限一代 (Infinite Generation One) 破甲 system prompt.",
  parameters: { type: "object", properties: {}, additionalProperties: false },
  output: objectOutput,
  execute() {
    return {
      name: "infinite-gen-1",
      displayName: "无限一代",
      version: "0.1.0",
      prompt: PROMPT_TEXT,
    };
  },
};

export const name = "dsh-infinite-gen-1";
export const inject = ["tools", "systemPrompt"];

export function apply(ctx) {
  ctx.effect(() => ctx.systemPrompt.section({
    name: "infinite-gen-1:global-system-prompt",
    order: 100,
    text: PROMPT_TEXT,
  }));
  ctx.effect(() => ctx.tools.register(profileTool));
}
