---
name: git-smart-commit
description: Analyze current Git changes (staged and unstaged), group them into logically coherent commits, and propose structured commits with messages compliant with Conventional Commits. Use when the user wants to commit, has finished a work session, or asks to "prepare commits".
---

# Git Smart Commit

## Workflow

### Step 1 — Analyze repository state

Run the following commands to inspect all changes:

git status --short
git diff
git diff --cached

### Step 2 — Analyze and group changes

For each modified file:
1. Read the diff to understand the nature of the change
2. Identify the type: feat, fix, refactor, docs, style, test, chore, ci, perf
3. Identify the scope: which module/component/service is impacted
4. Group files that belong to the SAME logical change

Grouping rules:
- Files addressing the same feature → same commit
- Test files + the code they test → same commit
- Config changes supporting a feature → same commit as the feature
- Independent changes → separate commits
- When in doubt, split rather than merge

### Step 3 — Propose commits

Present proposed commits using this format:

📦 Commit 1/N — type(scope): short description
   Files:
   - path/file1.ext (modified|added|deleted)
   - path/file2.ext (modified|added|deleted)
   Summary: One-line explanation of what this commit does.

📦 Commit 2/N — type(scope): short description
   Files:
   - path/file3.ext (modified)
   Summary: One-line explanation.

### Step 4 — Wait for validation

DO NOT execute commits without explicit user approval.

The user can:
- Approve as-is → execute all commits in order
- Modify a message → adjust and re-propose
- Merge/split groups → re-propose
- Cancel a group → exclude it

### Step 5 — Execute commits

For each validated commit, in order:

git add <file1> <file2> ...
git commit -m "type(scope): short description" -m "Detailed description if needed."

## Conventional Commits Specification

Format:
type(scope): description

### Allowed types

- feat     : new feature
- fix      : bug fix
- docs     : documentation only
- style    : formatting, whitespace, semicolons (no logic change)
- refactor : code restructuring without behavior change
- test     : adding or modifying tests
- chore    : maintenance, dependencies, configuration
- ci       : CI/CD, pipelines, automation
- perf     : performance improvement

### Writing rules

- Description in English, lowercase, no trailing period
- Use imperative mood: "add", not "added" or "adding"
- Max 72 characters for the first line
- Scope is optional but recommended
- For breaking changes: add ! after scope
  Example: feat(api)!: remove deprecated endpoint
  
### Language rules

- All outputs MUST be in English
- Never mix languages
- Even if the user writes in another language, always respond in English

## What this skill does NOT do

- No push (user decides when to push)
- No rebase, merge, or branch manipulation
- No modification of existing Git history
- No tag creation
