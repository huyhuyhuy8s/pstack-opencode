# pstack model configuration

Per-role model overrides for pstack skills, OpenCode runtime. Each pstack SKILL.md names its defaults in a Models section; the values here override those defaults. Delete a line to fall back to the skill default. A value of `inherit-parent` or `auto` runs that role on the parent session's model (the Task call omits the model), and an alias entry in a panel list still counts toward that panel's fan-out. OpenCode has no per-dispatch reasoning effort, so `@<level>` suffixes are recorded but inert; `default effort` is kept for the sheet to stay valid across runtimes. `session hook: off` stops the pstack-routing plugin from injecting the poteto-mode mandate; any other value, or no line, leaves it on.

OpenCode loads this file through the `instructions` array in `opencode.json` (the installer wires it), so the role lines are context in every session. List the models OpenCode offers with the `/models` command, then re-run the `setup-pstack` skill to write real choices; `auto` keeps every role on the session's model.

feature, refactoring: auto
bug-fix: auto
perf-issue: auto
hillclimb: auto
judgment and prose: auto
strongest judgment: auto
how explorer: auto
how explainer: auto
why investigators: auto
why synthesizer: auto
reflect tooling: auto
reflect judgment, divergent, synthesizer: auto
arena runners: auto
arena cross-judge pool: auto
swarm workers: auto
architect runners: auto
interrogate reviewers: auto

default effort: session
session hook: on
