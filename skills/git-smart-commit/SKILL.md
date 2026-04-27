---
name: git-smart-commit
description: Analyze current Git changes (staged, unstaged, and untracked), group them into logically coherent commits, and execute them as Conventional Commits after user validation. Triggers include phrases like "commit my work", "prepare commits", "commit these changes", "clean up git status", end-of-session commit requests, or any time working tree changes need to be organized into atomic commits. Do NOT use for push, pull, rebase, merge, branch operations, tag creation, or rewriting existing history.
---

# Git Smart Commit

Organize working tree changes into atomic, well-scoped Conventional Commits — written in English — after explicit user validation.

## Workflow

### Step 0 — Preflight checks

Before anything else, verify the repo is in a safe state to commit:

```
git rev-parse --is-inside-work-tree
git status --short --branch
git rev-parse --verify MERGE_HEAD 2>/dev/null || true
git rev-parse --verify REBASE_HEAD 2>/dev/null || true
```

Abort the workflow (with a clear message) if:
- Not inside a Git repo
- A merge, rebase, cherry-pick, or bisect is in progress
- HEAD is detached (warn and ask for confirmation before continuing)
- Working tree is clean → stop politely: "Nothing to commit."

Also check for hooks that may block commits:
- If `.husky/pre-commit`, `.git/hooks/pre-commit`, or commitlint config exists, mention it to the user so they're not surprised if a commit is rejected.
- If `AGENTS.md` exists, read it for repo-specific commit message constraints (e.g. scope format, allowed characters).

### Step 1 — Inspect repository state

Run:

```
git status --short
git diff --stat
git diff --cached --stat
```

**Diff size guard** — If the combined diff exceeds ~500 lines:
1. Use the `--stat` output as overview
2. Fetch full diffs per file with `git diff -- <file>`, prioritizing smaller files
3. Warn the user if some diffs had to be truncated for analysis

Otherwise, fetch full diffs:

```
git diff
git diff --cached
```

**Untracked files** — List them separately. Before grouping, ask the user:
> "Found N untracked file(s): [list]. Include them in the commits? (all / select / skip)"

Do NOT silently add untracked files.

### Step 2 — Analyze and group changes

For each changed file:
1. Read the diff to understand the nature of the change
2. Identify type: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `ci`, `perf`, `build`, `revert`
3. Identify scope (see **Scope rules** below)
4. **Detect breaking changes proactively**: removed public APIs, changed signatures, renamed exported symbols, removed config keys, changed DB schema. Flag with `!` in the type/scope.
5. Group files belonging to the same logical change

**Grouping rules**:
- Same feature across multiple files → one commit
- Test files + the code they test → same commit
- Config/docs supporting a feature → same commit as the feature
- Independent concerns → separate commits
- When in doubt, split rather than merge (atomic commits > large commits)

**Scope rules**:
- Change targets a clear module, component, or package → use scope: `feat(auth): add token refresh`
- Change is cross-cutting (global rename, dep bump, full format) → no scope: `chore: upgrade lodash to 4.17.21`
- Small or flat repo with no clear module boundaries → no scope
- Before formatting the scope, check `AGENTS.md` or remote hooks for constraints (some repos reject hyphens, special chars, etc.)

### Step 3 — Propose commits

Use this compact format. When a commit has a body, display it under the rationale with proper formatting (the way it will actually appear in `git log`):

```
[1/N] type(scope): short description
      file/path/one.ext (A) file/path/two.ext (M)
      → One-line rationale

[2/N] type(scope)!: short description
      other/file.ext (M)
      → One-line rationale

      ┌─ Body ─────────────────────────────────────────────────────
      │ Explanation of what and why, wrapped at 72 chars.
      │
      │ - Key change 1
      │ - Key change 2
      │
      │ Closes: #456
      │ BREAKING CHANGE: what breaks and migration path
      └────────────────────────────────────────────────────────────
```

Legend: `A` = added, `M` = modified, `D` = deleted, `R` = renamed.

**When to include a body**:
- Breaking changes (mandatory — use `BREAKING CHANGE:` footer)
- Non-obvious rationale ("why" isn't clear from the diff)
- Complex refactors touching multiple concerns
- References to issues, RFCs, tickets, or related commits

**When to skip the body**: trivial commits where the subject is self-explanatory (`docs: fix typo`, `chore: bump lodash`, `style: format with prettier`).

After the list, print the exact commands that will run. For commits with bodies, show the full heredoc so the user can validate the final output precisely:

```
Commands to execute:
  git add -- "src/auth/oauth.ts" "src/auth/pkce.ts"
  git commit -F - <<'EOF'
feat(auth): add OAuth2 PKCE flow

Implements PKCE per RFC 7636 for public clients.

Closes: #142
EOF

  git add -- "src/api/user.ts"
  git commit -m "fix(api): handle null response in user endpoint"
```

**Important**: heredoc content and closing `EOF` must be flush-left (no leading spaces), only the `git` commands themselves are indented for readability.

### Step 4 — Wait for explicit validation

**DO NOT execute any commit without explicit user approval.**

The user can:
- Approve as-is → proceed to Step 5
- Edit a message → adjust and re-propose
- Merge or split groups → re-propose
- Drop a group → exclude from execution
- Reorder groups → re-propose sequence

### Step 5 — Execute commits

For each validated commit, in order:

```
git add -- <file1> <file2> ...
```

Then commit using the strategy matching the message complexity:

**Strategy A — Subject only (no body)**: single `-m`.
```
git commit -m "type(scope): short description"
```

**Strategy B — Subject + body + footer**: use a heredoc with `git commit -F -`. This is the default whenever a body is present, to preserve line breaks, bullet lists, and proper 72-char wrapping.

```
git commit -F - <<'EOF'
type(scope): short description

Body paragraph explaining what and why, wrapped at 72 characters per
line. Multiple paragraphs are fine, separated by blank lines.

- Bullet points are allowed
- They render correctly in git log and most tools

Refs: #123
Closes: #456
BREAKING CHANGE: description of what breaks and the migration path
EOF
```

**Heredoc safety**: always use `<<'EOF'` (single-quoted) to prevent shell expansion. Avoid backticks, `$(...)`, `${...}`, and literal `EOF` on its own line inside the message body. Rewrite if needed.

**Body formatting rules**:
- Blank line between subject and body (mandatory — parsers rely on it)
- Wrap body lines at 72 characters
- Use paragraphs for narrative, bullets (`-`) for enumerations
- Footers go at the end, separated by a blank line from the body
- One footer per line, format `Token: value` (e.g. `Refs: #123`, `Closes: #456`, `Co-authored-by: Name <email>`)
- `BREAKING CHANGE:` footer is recognized by the Conventional Commits spec and tooling

**General execution rules**:
- Always use `git add -- <path>` (the `--` prevents issues with paths starting with `-` or containing special characters)
- Always quote paths that contain spaces or special characters
- If a commit fails (hook rejection, etc.): STOP, report the error, do not continue with subsequent commits

After all commits succeed, print:

```
git log --oneline -N   ← where N is the number of commits just created
```

so the user sees the final state. Remind them: **no push is performed** — they decide when to push.

## Conventional Commits — Rules

All commits **MUST** follow [Conventional Commits](https://www.conventionalcommits.org/).

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`, `revert`.

### Writing rules

- **Language: English only** — regardless of conversation language
- Imperative mood, lowercase, no trailing period: `add`, not `added` / `adds`
- First line ≤ 72 characters
- Body (when present): wrap at 72 chars, explain **what** and **why**, not how
- Footers: `Refs: #123`, `Closes: #456`, `Co-authored-by: ...`
- Breaking changes: use `!` after type/scope **and** `BREAKING CHANGE:` footer for high-impact changes

## Edge cases to handle

- **Nothing to commit** → stop with a clean message, don't force a workflow
- **Merge/rebase in progress** → refuse, explain, suggest `git status` to the user
- **Detached HEAD** → warn, ask for confirmation (commits will be orphaned)
- **Very large binary files or files > 100MB** → flag them, ask before adding (may need Git LFS)
- **Mixed concerns in a single file** → explain the limitation: a commit is file-level minimum. Suggest `git add -p` manually if the user wants finer granularity
- **Pre-commit hook rejects a commit** → stop the sequence, show hook output, let user fix before retrying
- **Commit signing configured (`commit.gpgsign=true`)** → no change needed, just be aware it may prompt for passphrase

## What this skill does NOT do

- No `git push` — user decides when and where to push
- No rebase, merge, cherry-pick, or branch manipulation
- No modification of existing Git history (no `--amend`, no `reset`)
- No tag creation
- No remote operations (fetch, pull, etc.)
- No `git add -p` interactive splitting (suggest it to the user if needed)
