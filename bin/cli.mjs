#!/usr/bin/env node
// swe-workflow-skills — npm CLI entry point. Dispatches subcommands to the
// installer/uninstaller so `npx swe-workflow-skills install` reads naturally.
// Runs on Linux, macOS, and Windows (the one runtime Claude Code already requires).
//
//   npx swe-workflow-skills install [--global|--dir DIR|--role R|--no-hook|...]
//   npx swe-workflow-skills uninstall [--global|--dir DIR|--dry-run|--yes]

import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { readFileSync } from "node:fs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const [sub, ...rest] = process.argv.slice(2);

const HELP = `swe-workflow-skills <command> [options]

Commands:
  install      Install skills into a Claude config dir (passes flags to install.mjs)
  uninstall    Remove the library (passes flags to uninstall.mjs)

Examples:
  npx swe-workflow-skills install --global
  npx swe-workflow-skills install --role pm
  npx swe-workflow-skills uninstall --global --dry-run

Run a command with --help to see its full option list.`;

if (sub === "install" || sub === "uninstall") {
  const script = join(ROOT, sub === "install" ? "install.mjs" : "uninstall.mjs");
  // stdio inherited so install output and uninstall's confirm prompt pass through.
  const res = spawnSync(process.execPath, [script, ...rest], { stdio: "inherit" });
  process.exit(res.status ?? 1);
} else if (sub === "-v" || sub === "--version" || sub === "version") {
  process.stdout.write(readFileSync(join(ROOT, "VERSION"), "utf-8"));
  process.exit(0);
} else if (!sub || sub === "-h" || sub === "--help" || sub === "help") {
  process.stdout.write(HELP + "\n");
  process.exit(sub ? 0 : 1); // bare invocation is a usage error; explicit help is success
} else {
  process.stderr.write(`Unknown command: ${sub}\n\n${HELP}\n`);
  process.exit(1);
}
