#!/bin/sh
set -eu

# pstack-opencode installer. Idempotent: re-running skips work already done.
#
# Installs the whole pstack setup for OpenCode:
#   1. skills       ~/.agents/skills/<name>        symlinks into this clone
#   2. agents       ~/.config/opencode/agents/*.md OpenCode-format subagent copies
#   3. plugin       ~/.config/opencode/plugins/pstack-routing.js
#   4. sheet        ~/.config/opencode/pstack-models.md   (only if missing)
#   5. instructions the sheet path appended to opencode.json's instructions array
#   6. routing      the poteto-mode standing instruction in ~/.config/opencode/AGENTS.md
#
# Uninstalling: remove the symlinks and files this script prints, delete the
# marked block in AGENTS.md, and drop the sheet path from the instructions
# array. See docs/opencode.md.

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILLS_SRC="$REPO/plugins/pstack/skills"
SKILLS_DIR="${PSTACK_SKILLS_DIR:-$HOME/.agents/skills}"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SHEET="$OPENCODE_DIR/pstack-models.md"
MARKER_BEGIN="<!-- pstack-opencode:begin -->"
MARKER_END="<!-- pstack-opencode:end -->"

log() { printf 'install: %s\n' "$*"; }

# 1. Skills. OpenCode reads Agent Skills from ~/.agents/skills; symlinks keep
#    `git pull` in this clone as the update path, as upstream's README prescribes.
mkdir -p "$SKILLS_DIR"
for src_dir in "$SKILLS_SRC"/*/; do
  name=$(basename "$src_dir")
  target="$SKILLS_DIR/$name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    log "skill $name: already present at $target, leaving as is"
  else
    ln -s "$src_dir" "$target"
    log "skill $name: linked"
  fi
done

# 2. Agents. OpenCode reads global subagents from ~/.config/opencode/agents,
#    filename = agent name. These are copies, not links: each carries OpenCode
#    frontmatter (mode: subagent) and OpenCode paths, so upstream's Agent-tool
#    wording does not leak through. Re-copy on every run so an updated clone
#    refreshes them.
#    Agents from other installs (GSD, hand-written) sit alongside these; only
#    the four pstack names are touched.
mkdir -p "$OPENCODE_DIR/agents"
for agent in "$REPO"/opencode/agents/*.md; do
  cp -f "$agent" "$OPENCODE_DIR/agents/$(basename "$agent")"
  log "agent $(basename "$agent" .md): installed"
done

# 3. Plugin. OpenCode auto-loads every JS file in ~/.config/opencode/plugins.
#    The plugin injects the poteto-mode mandate at session start, the same job
#    the upstream SessionStart hook does on the other runtimes.
mkdir -p "$OPENCODE_DIR/plugins"
cp -f "$REPO/opencode/pstack-routing.js" "$OPENCODE_DIR/plugins/pstack-routing.js"
log "plugin pstack-routing.js: installed (restart OpenCode to load it)"

# 4. Sheet. setup-pstack owns this file afterwards; the template only seeds a
#    fresh install so the role lines exist before the first run.
if [ -e "$SHEET" ]; then
  log "sheet $SHEET: already present, leaving as is"
else
  cp "$REPO/opencode/pstack-models.md" "$SHEET"
  log "sheet $SHEET: seeded from template (run setup-pstack to pick real models)"
fi

# 5. Instructions. OpenCode has no @-include; the sheet loads through the
#    `instructions` array in opencode.json. Needs python3 or node for a safe
#    JSON edit; without either, the manual line is printed.
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
  if command -v python3 >/dev/null 2>&1 && python3 - "$OPENCODE_DIR/opencode.json" "$SHEET" <<'PY'
import json, sys
path, sheet = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f)
inst = cfg.setdefault("instructions", [])
if sheet in inst:
    print("install: instructions: already lists the sheet")
    sys.exit(0)
inst.append(sheet)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("install: instructions: added " + sheet)
PY
  then :
  elif command -v node >/dev/null 2>&1 && node -e '
    const fs = require("fs");
    const [path, sheet] = process.argv.slice(2);
    const cfg = JSON.parse(fs.readFileSync(path, "utf8"));
    const inst = cfg.instructions || (cfg.instructions = []);
    if (inst.includes(sheet)) { console.log("install: instructions: already lists the sheet"); process.exit(0); }
    inst.push(sheet);
    fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + "\n");
    console.log("install: instructions: added " + sheet);
  ' "$OPENCODE_DIR/opencode.json" "$SHEET"
  then :
  else
    log "opencode.json: no python3 or node found; add \"$SHEET\" to the instructions array by hand"
  fi
else
  log "opencode.json: none at $OPENCODE_DIR; add \"instructions\": [\"$SHEET\"] when you create one"
fi

# 6. Routing. The plugin covers running sessions once OpenCode restarts; the
#    AGENTS.md block also covers sessions where the plugin is unavailable, and
#    is the upstream-prescribed fallback for hookless runtimes.
AGENTS="$OPENCODE_DIR/AGENTS.md"
if [ -f "$AGENTS" ] && grep -qF "$MARKER_BEGIN" "$AGENTS"; then
  log "AGENTS.md: routing instruction already present"
else
  {
    printf '\n%s\n' "$MARKER_BEGIN"
    cat "$REPO/opencode/routing-instruction.md"
    printf '%s\n' "$MARKER_END"
  } >> "$AGENTS"
  log "AGENTS.md: appended the poteto-mode routing instruction"
fi

log "done. Restart OpenCode, then check /models and run setup-pstack to pin per-role models."
