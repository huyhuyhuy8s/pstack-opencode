// pstack routing for OpenCode. Injects the poteto-mode mandate into every
// session's system prompt — the same job the pstack plugin's SessionStart hook
// does on Claude Code, Codex, GitHub Copilot, and Muse. `session hook: off` in
// the pstack-models.md sheet silences it. Beyond this file and what OpenCode
// itself provides, there are no dependencies.
import { Plugin } from "@opencode/plugin";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";

const { define } = Plugin;

// Adapted from the upstream plugin's hooks/session-start-context.md. Skill ids
// are unqualified: on OpenCode the skills load globally from ~/.agents/skills.
const MANDATE = `<EXTREMELY_IMPORTANT>
You have pstack.

Invoke the \`poteto-mode\` skill and follow its instructions when a task meets any of these:

- it touches more than one file, or changes a signature other files call
- it involves a design or architecture choice
- it is a bug whose cause is not yet known, or a performance issue

It routes to the right pstack skill from there. For smaller tasks, such as a contained change to one file with an obvious test, a question, or a one-line edit, work directly and verify on the real artifact.

When the intent is already specific, enter that skill directly: \`tdd\`, \`architect\`, \`how\`, \`why\`, \`arena\`, \`interrogate\`.

User instructions (AGENTS.md, direct requests) take precedence. Other session-start mandates still apply. Their skill checks run as before, and when a task meets the criteria above they route implementation through poteto-mode.
</EXTREMELY_IMPORTANT>`;

// The sheet lives next to opencode.json; setup-pstack owns it, install.sh only
// seeds it. The `instructions` array loads the sheet's role lines, so this
// plugin reads it only for the hook switch.
function sheetPath() {
  const base = process.env.XDG_CONFIG_HOME || `${homedir()}/.config`;
  return `${base}/opencode/pstack-models.md`;
}

// A sheet that cannot be read counts as absent, so injection stays on — the
// same policy as the upstream SessionStart hooks.
function hookDisabled() {
  try {
    return /^session\s+hook:\s*off\s*$/im.test(readFileSync(sheetPath(), "utf8"));
  } catch {
    return false;
  }
}

export default define({
  id: "pstack-routing",
  setup: async (ctx) => {
    await ctx.session.hook("context", async (input) => {
      if (hookDisabled()) return;
      if (!Array.isArray(input.system)) return;
      input.system.push({ type: "text", text: MANDATE });
    });
  },
});
