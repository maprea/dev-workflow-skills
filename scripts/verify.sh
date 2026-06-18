#!/usr/bin/env bash
# End-to-end verification for name-only-baseline + orchestrator activation.
# Runs offline (no API key). Exits non-zero on the first failure.
#
#   scripts/verify.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pass() { printf '  ok: %s\n' "$1"; }
fail() { printf '  FAIL: %s\n' "$1" >&2; exit 1; }

echo "1. roles.json integrity"
python3 scripts/resolve.py validate skills >/dev/null || fail "resolve.py validate"
pass "every referenced skill exists; no orphans"

echo "2. generator + catalog + JSON validity"
node scripts/build-plugins.mjs >/dev/null || fail "build-plugins.mjs"
while IFS= read -r f; do
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || fail "invalid JSON: $f"
done < <(find plugins .claude-plugin -name '*.json'; echo catalog.json)
python3 - <<'PY' || fail "catalog completeness"
import json, os
cat = {s["name"] for s in json.load(open("catalog.json"))["skills"]}
disk = {e for e in os.listdir("skills") if os.path.isdir(os.path.join("skills", e))}
assert cat == disk, f"catalog != skills on disk: {cat ^ disk}"
assert all(s["description"] for s in json.load(open("catalog.json"))["skills"]), "empty description"
PY
pass "marketplace + catalog.json valid; catalog covers every skill"

echo "3. override computation"
python3 - <<'PY' || fail "overrides policy"
import json, subprocess, os
skills = "\n".join(e for e in os.listdir("skills") if os.path.isdir("skills/"+e))
def ov(*a):
    return json.loads(subprocess.run(["python3","scripts/resolve.py","overrides",*a],
        input=skills, capture_output=True, text=True).stdout)
base = ov()                       # baseline: only pinned on
assert "skill-router" not in base and "tdd-workflow" not in base, "pinned must stay on"
assert base.get("api-design") == "name-only"
pm = ov("pm")                     # pm: pm set + pinned on
assert "prd-writing" not in pm, "in-role skill must be on"
assert pm.get("api-design") == "name-only"
PY
pass "baseline crops all non-pinned; role promotes its set"

echo "4. apply merges into settings, preserving keys"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills"; for s in $(ls skills); do mkdir -p "$TMP/skills/$s"; done
printf '{"model":"opus","skillOverrides":{"external":"off"}}' > "$TMP/s.json"
python3 scripts/resolve.py apply "$TMP/s.json" "$TMP/skills" pm >/dev/null || fail "apply"
python3 - "$TMP/s.json" <<'PY' || fail "apply result"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["model"] == "opus", "preserve unrelated key"
assert d["skillOverrides"]["external"] == "off", "preserve unmanaged override"
assert "prd-writing" not in d["skillOverrides"], "pm skill should be on"
assert d["skillOverrides"]["api-design"] == "name-only"
PY
pass "settings merge preserves other keys + unmanaged overrides"

echo "5. install (default all + machinery + hook)"
./install.sh --hook --dir "$TMP/inst" >/dev/null 2>&1 || fail "install"
[[ $(find "$TMP/inst/skills" -maxdepth 1 -mindepth 1 -type d | wc -l) -eq 42 ]] || fail "expected 42 skills"
for f in skills/.roles.json skills/.catalog.json hooks/resolve.py hooks/session-start.sh commands/role.md; do
  [[ -f "$TMP/inst/$f" ]] || fail "missing $f"
done
grep -q '@@' "$TMP/inst/commands/role.md" && fail "unsubstituted placeholders in role.md"
pass "42 skills + catalog/roles markers + resolve.py + hook + /role command"

echo "6. SessionStart hook writes baseline + reloadSkills (preserving keys)"
printf '{"model":"x"}' > "$TMP/inst/settings.local.json"
OUT="$("$TMP/inst/hooks/session-start.sh" </dev/null)" || fail "hook run"
echo "$OUT" | python3 -c "import sys,json;d=json.load(sys.stdin)['hookSpecificOutput'];assert d['reloadSkills'] is True;assert d['additionalContext']" || fail "hook JSON"
python3 - "$TMP/inst/settings.local.json" <<'PY' || fail "hook baseline"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["model"] == "x", "hook must preserve other settings keys"
n = sum(1 for v in d["skillOverrides"].values() if v == "name-only")
assert n == 36, f"expected 36 name-only at baseline, got {n}"
assert "skill-router" not in d["skillOverrides"], "router stays on"
PY
pass "hook writes 36 name-only baseline, reloadSkills, valid JSON, preserves keys"

echo "7. /role command flow (set + reset)"
runrole() { sed -n '/```bash/,/```/p' "$TMP/inst/commands/role.md" | sed "1d;\$d; s/\$ARGUMENTS/$1/" | bash >/dev/null 2>&1; }
runrole pm || fail "/role pm"
[[ "$(cat "$TMP/inst/skills/.active-role")" == "pm" ]] || fail ".active-role not set"
python3 -c "import json;ov=json.load(open('$TMP/inst/settings.local.json'))['skillOverrides'];assert 'prd-writing' not in ov" || fail "pm not promoted"
runrole none || fail "/role none"
[[ ! -f "$TMP/inst/skills/.active-role" ]] || fail ".active-role not cleared"
pass "/role sets role + promotes set; /role none resets to baseline"

echo ""
echo "ALL CHECKS PASSED"
