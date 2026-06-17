#!/usr/bin/env bash
# dev-workflow-skills — optional SessionStart hook.
#
# Emits a SHORT pointer telling Claude that the skills library is installed and
# to consult the skill-router before substantial SDLC work. This is deliberately
# lightweight: it does NOT force a skill check on every turn (unlike heavier
# bootstraps). The user's instructions always take precedence.
#
# Claude Code calls this on SessionStart and reads JSON on stdout. The
# `additionalContext` string is injected into the session.

set -euo pipefail

read -r -d '' CONTEXT <<'EOF' || true
This project has the dev-workflow skills library installed.

Before substantial software work — planning a feature, making a structural or
data-model decision, implementing, debugging, reviewing, or shipping — check
whether a dedicated skill applies and invoke it. If you're unsure which one
fits, invoke the `skill-router` skill: it maps intents to skills and lays out
the Golden Path workflow chains.

This is a nudge, not a gate. Skip it for trivial or conversational requests, and
always follow the user's explicit instructions over this guidance.
EOF

# Emit Claude Code SessionStart hook output.
CONTEXT="$CONTEXT" python3 - <<'PY' 2>/dev/null || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "\"$(printf '%s' "$CONTEXT" | sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g')\""
import json, os
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ["CONTEXT"],
    }
}))
PY
