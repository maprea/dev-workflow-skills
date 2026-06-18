#!/usr/bin/env python3
"""Resolve roles.json into skill lists and skillOverrides maps.

Single dependency-free helper shared by install.sh (and usable in CI). All
commands read roles.json from the repo root (the directory above scripts/),
or from $ROLES_JSON if set.

Usage:
  resolve.py roles                       List role keys + labels (TSV).
  resolve.py skills <role>               Resolved skill set for a role (one per line).
  resolve.py label  <role>               Human label for a role.
  resolve.py overrides [role]            Emit a skillOverrides JSON object marking
                                         every installed skill outside (pinned ∪ role)
                                         as "name-only". Installed skill names are read
                                         from stdin (newline-separated). No role => only
                                         the pinned set stays on (the baseline).
  resolve.py apply <settings.local.json> <skills_dir> [role]
                                         Merge the name-only baseline (for [role], or
                                         pinned-only) into the settings file's
                                         skillOverrides, preserving all other keys and
                                         any overrides for non-installed skills.
  resolve.py validate <skills_dir>       Integrity check: every referenced skill
                                         exists under <skills_dir>, and every
                                         non-meta skill belongs to >=1 role.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROLES_JSON = os.environ.get("ROLES_JSON", os.path.join(HERE, "..", "roles.json"))


def load():
    with open(ROLES_JSON, encoding="utf-8") as fh:
        return json.load(fh)


def die(msg, code=1):
    print(f"resolve.py: {msg}", file=sys.stderr)
    sys.exit(code)


def role_or_die(data, role):
    roles = data.get("roles", {})
    if role not in roles:
        die(f"unknown role '{role}' (known: {', '.join(sorted(roles))})")
    return roles[role]


def resolved_skills(data, role):
    """Role working set = its core set UNION its own skills, order-stable."""
    r = role_or_die(data, role)
    core = data.get("core", {}).get(r.get("core", "universal"), [])
    seen, out = set(), []
    for skill in list(core) + list(r.get("skills", [])):
        if skill not in seen:
            seen.add(skill)
            out.append(skill)
    return out


def cmd_roles(data, args):
    for key, r in data.get("roles", {}).items():
        print(f"{key}\t{r.get('label', key)}")


def cmd_skills(data, args):
    if not args:
        die("skills requires a <role>")
    for skill in resolved_skills(data, args[0]):
        print(skill)


def cmd_label(data, args):
    if not args:
        die("label requires a <role>")
    print(role_or_die(data, args[0]).get("label", args[0]))


def keep_on_set(data, role):
    """Skills that stay `on` (full description, auto-trigger): the pinned set,
    plus the active role's working set when a role is given."""
    keep = set(data.get("pinned", []))
    if role:
        keep |= set(resolved_skills(data, role))
    return keep


def nameonly_map(data, installed, role):
    keep_on = keep_on_set(data, role)
    return {s: "name-only" for s in installed if s not in keep_on}


def cmd_overrides(data, args):
    role = args[0] if args else None
    if role:
        role_or_die(data, role)
    installed = [ln.strip() for ln in sys.stdin if ln.strip()]
    print(json.dumps(nameonly_map(data, installed, role), indent=2, sort_keys=True))


def cmd_apply(data, args):
    if len(args) < 2:
        die("apply requires <settings.local.json> <skills_dir> [role]")
    settings_path, skills_dir = args[0], args[1]
    role = args[2] if len(args) > 2 else None
    if role and role not in ("all", "none"):
        role_or_die(data, role)
    if role in ("all", "none"):
        role = None

    installed = sorted(
        e for e in os.listdir(skills_dir)
        if os.path.isdir(os.path.join(skills_dir, e))
    )
    desired = nameonly_map(data, installed, role)  # {skill: "name-only"} for the tail

    # Read existing settings (tolerate missing / empty / malformed-as-empty).
    settings = {}
    if os.path.isfile(settings_path):
        try:
            with open(settings_path, encoding="utf-8") as fh:
                settings = json.load(fh) or {}
        except (OSError, ValueError):
            settings = {}

    existing = settings.get("skillOverrides", {})
    if not isinstance(existing, dict):
        existing = {}
    # Preserve overrides for skills we don't manage (not installed here); we own
    # every installed skill's entry: name-only for the tail, absent (=> on) otherwise.
    merged = {k: v for k, v in existing.items() if k not in installed}
    merged.update(desired)
    settings["skillOverrides"] = merged

    os.makedirs(os.path.dirname(os.path.abspath(settings_path)), exist_ok=True)
    with open(settings_path, "w", encoding="utf-8") as fh:
        json.dump(settings, fh, indent=2, sort_keys=True)
        fh.write("\n")
    on_count = len(installed) - len(desired)
    print(f"applied: {len(desired)} name-only, {on_count} on "
          f"(role={role or 'baseline'}) -> {settings_path}")


def cmd_validate(data, args):
    if not args:
        die("validate requires a <skills_dir>")
    skills_dir = args[0]
    errors = []

    # Collect every skill referenced anywhere in the SSOT.
    referenced = set(data.get("pinned", [])) | set(data.get("meta_only", []))
    for core in data.get("core", {}).values():
        referenced |= set(core)
    in_a_role = set()
    for role in data.get("roles", {}):
        skills = set(resolved_skills(data, role))
        referenced |= skills
        in_a_role |= skills

    # Every referenced skill must exist on disk.
    for skill in sorted(referenced):
        if not os.path.isdir(os.path.join(skills_dir, skill)):
            errors.append(f"referenced skill missing on disk: {skill}")

    # Every non-meta skill on disk must belong to >=1 role (no orphans).
    meta = set(data.get("meta_only", []))
    universal = set(data.get("core", {}).get("universal", []))
    technical = set(data.get("core", {}).get("technical", []))
    covered = in_a_role | universal | technical
    for entry in sorted(os.listdir(skills_dir)):
        if not os.path.isdir(os.path.join(skills_dir, entry)):
            continue
        if entry in meta:
            continue
        if entry not in covered:
            errors.append(f"orphan skill (in no role/core): {entry}")

    if errors:
        for e in errors:
            print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
    print(f"OK: roles.json integrity verified against {skills_dir}")


COMMANDS = {
    "roles": cmd_roles,
    "skills": cmd_skills,
    "label": cmd_label,
    "overrides": cmd_overrides,
    "apply": cmd_apply,
    "validate": cmd_validate,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        die(f"usage: resolve.py <{'|'.join(COMMANDS)}> [args]", code=2)
    COMMANDS[sys.argv[1]](load(), sys.argv[2:])


if __name__ == "__main__":
    main()
