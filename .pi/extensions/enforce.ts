// Pi enforcement adapter — a thin shim over the shared scripts/*.sh.
//
// This mirrors the Claude Code hooks declared in .claude/settings.json so pi
// enforces the *same* policies from the *same* logic. The bash scripts in
// scripts/ are the single source of truth; this file only translates pi's
// extension events into a script invocation and maps the result back.
//
// Contract the scripts honour (harness-neutral):
//   exit 0 = allow · exit != 0 = block, reason on stderr · advisory text on stdout
//
// pi discovers this automatically at .pi/extensions/*.ts when run in the repo.
// Docs: https://pi.dev/docs/latest/extensions

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

// Resolve scripts relative to THIS file (fixed location), but run them against
// the directory pi was launched in (the working repo, whose branch we check).
const script = (name: string): string =>
  fileURLToPath(new URL(`../../scripts/${name}`, import.meta.url));

// Tools that write to the filesystem — the only ones branch protection gates,
// matching Claude's "Edit|Write|NotebookEdit" matcher.
const EDIT_TOOLS = new Set(["write", "edit"]);

// `pi: ExtensionAPI` — kept untyped to avoid a build dependency on pi's types.
export default function (pi: any): void {
  // Block edits on a protected branch — mirrors check-branch.sh (PreToolUse).
  pi.on("tool_call", async (event: any) => {
    if (!EDIT_TOOLS.has(event.toolName)) return;
    const r = spawnSync(script("check-branch.sh"), {
      cwd: process.cwd(),
      encoding: "utf8",
    });
    if (r.status !== 0) {
      return {
        block: true,
        reason: (r.stderr || "Blocked by check-branch.sh").trim(),
      };
    }
  });

  // Nudge to scaffold pre-commit — mirrors check-precommit.sh (UserPromptSubmit).
  // The script throttles itself once per session via PRECOMMIT_SESSION_ID.
  pi.on("before_agent_start", async (_event: any, ctx: any) => {
    const sessionId = ctx?.sessionId ?? ctx?.session?.id ?? "";
    const r = spawnSync(script("check-precommit.sh"), {
      cwd: process.cwd(),
      encoding: "utf8",
      env: { ...process.env, PRECOMMIT_SESSION_ID: sessionId },
    });
    const note = (r.stdout || "").trim();
    if (note) {
      return {
        message: { customType: "precommit-check", content: note, display: true },
      };
    }
  });
}
