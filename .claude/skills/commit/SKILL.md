---
name: commit
disable-model-invocation: true
argument-hint: [plan | single | guidance]
description: Group uncommitted changes into logical conventional commits, ensuring pre-commit hooks pass for each. Never pushes.
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git add:*), Bash(git restore --staged:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git branch:*)
---

# Commit

Split the current uncommitted changes into logical conventional commits, so the history reads like
it was committed by hand, step by step.

## Arguments

- **`plan`** — Propose the commits, then stop without committing.
- **`single`** — Make one commit with all changes.
- **Anything else** — Extra guidance for grouping or messages.

## Rules

- Never push, amend, rebase, or use `--no-verify`.
- Never edit file contents. Only stage and commit what already exists.
- Stage files by explicit path. Never use `git add .` or `git commit -a`.
- Conventional commit headers under 100 characters, matching the repo's style in `git log`.
- Do not mention Claude/AI or add a `Co-Authored-By` trailer.

## Workflow

1. **Gather context.** Record the starting `HEAD` SHA. Review all staged, unstaged, and untracked
   changes, and recent commit history.
2. **Exclude** secrets, build output, scratch/debug files, or anything unrelated to the work. Leave
   them uncommitted.
3. **Group by logical change**, using conversation context (e.g. the steps of an implemented plan).
   - Order so dependencies come first.
   - Keep tests, translations, and lockfiles with the change they belong to.
   - Separate refactors from behavior changes.
   - Don't over-split: one logical change is one commit.
   - Stage whole files only.
4. **Show the plan** (message and files per commit). Stop here if the argument is `plan`; otherwise
   continue without waiting.
5. **Commit each group** in order, verifying only that group's files are staged first.
6. **If a pre-commit hook fails:**
   - If the hook itself reformatted files, re-stage them and retry.
   - If the failure is caused by a dependency in a later group, reorder or merge the groups and retry.
   - Otherwise, stop. Leave the remaining changes uncommitted and report the hook output.

## Summary

When finished, report:

- Each commit created, in order, with its message and the files it contains
  (`git log --name-status <starting-sha>..HEAD`)
- Files left uncommitted and why
- If stopped early, which commit failed and the hook output
- The undo command: `git reset --soft <starting-sha>`
