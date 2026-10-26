# pstack on OpenCode

This repository is the OpenCode-focused distribution of pstack. It tracks [michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude) — Michael Denyer's port of Lauren Tan's [pstack](https://github.com/cursor/plugins/tree/main/pstack) — and carries the whole setup unchanged: every skill, agent, hook, and tool under `plugins/pstack/`. On top of that it adds the OpenCode packaging upstream ships without, because upstream's OpenCode install is the hookless "other harnesses" path.

Upstream verified OpenCode as a pstack runtime on version 2.0.30: skill discovery and loading work, and delegation runs through OpenCode's Task tool. This packaging is tested on 2.0.32.

## What this repo adds

| Piece | Where it lands | What it does |
| --- | --- | --- |
| Skills | `~/.agents/skills/<name>` → symlink into the clone | The whole pstack skill set, the path OpenCode reads |
| Subagents | `~/.config/opencode/agents/*.md` | `poteto-agent`, `comment-sicko`, and the two thermo-nuclear reviewers, in OpenCode's agent format |
| Routing plugin | `~/.config/opencode/plugins/pstack-routing.js` | Injects the poteto-mode mandate at session start — the job the upstream SessionStart hook does on Claude Code, Codex, Copilot, and Muse |
| Model sheet | `~/.config/opencode/pstack-models.md` | Per-role model overrides, seeded on first install, owned by `setup-pstack` afterwards |
| Sheet wiring | `instructions` array in `opencode.json` | Loads the sheet's role lines as context in every session |
| Standing instruction | `~/.config/opencode/AGENTS.md` | The poteto-mode routing block, which also covers sessions where the plugin is not loaded |

Run `./install.sh` from a clone to do all of this. It is idempotent: existing symlinks, sheets, and settings are left alone, agents and the plugin are refreshed from the clone on every run.

## Install and update

```shell
git clone https://github.com/huyhuyhuy8s/pstack-opencode
cd pstack-opencode
./install.sh
```

Restart OpenCode so the plugin and skills load. Then run the `setup-pstack` skill in a session to pick real per-role models: it lists what OpenCode offers via `/models` and rewrites the sheet. Until then every role runs on the session's model (`auto`).

To update, `git pull` in the clone. Skill symlinks point into the clone, so pulled skill updates apply immediately; re-run `./install.sh` to refresh the agents, the plugin, and to link skills added since the last run.

## Uninstall

Remove the skill symlinks (`~/.agents/skills/<name>` for every pstack skill), `~/.config/opencode/agents/poteto-agent.md` and the three review agents, `~/.config/opencode/plugins/pstack-routing.js`, the marked `pstack-opencode` block in `~/.config/opencode/AGENTS.md`, the sheet path from the `instructions` array in `opencode.json`, and the sheet itself if you no longer want it.

## Runtime notes

- **Delegation.** pstack's skills speak of an `Agent` tool; on OpenCode that is the Task tool, and the four agents in `opencode/agents/` are the spawn targets. `poteto-agent` reads `poteto-mode`'s SKILL.md from `~/.agents/skills/`, replacing upstream's Claude plugin-cache search.
- **Routing.** The plugin pushes the mandate through OpenCode's session context hook. `session hook: off` in the sheet turns it off, matching the other runtimes. The AGENTS.md block says the same thing in instruction form, so routing survives even without the plugin; the two coexisting is harmless.
- **Models.** OpenCode has no per-dispatch model parameter on its Task tool, so panel fan-out is one subagent per Task call on the session's model, and `@<level>` reasoning-effort suffixes are recorded but inert. The sheet stays the record of your choices and becomes live if you move it to a runtime with per-dispatch models.
- **Skills boundary.** OpenCode consumes the skills natively — no per-runtime substitutions are generated for it, the same as Prime Agent and Gemini CLI.

## Provenance and syncing

Everything outside `opencode/`, `install.sh`, and `docs/opencode.md` is upstream, kept as close to verbatim as the git history allows — the branch shares history with `michael-denyer/pstack-claude`, so upstream attribution, licenses, and notices travel with it. Sync upstream and keep the OpenCode packaging:

```shell
git remote add upstream https://github.com/michael-denyer/pstack-claude
git fetch upstream
git merge upstream/main   # re-run ./install.sh afterwards if skills or agents changed
```

`tools/upstream.json` still records the upstream release this tree tracks.
