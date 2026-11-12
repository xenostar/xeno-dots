---
name: pr-review
disable-model-invocation: true
argument-hint: [pr-url]
description: Thoroughly review a pull request and present findings for triage. Gathers full context (description, diff, discussions, linked Jira tickets), analyzes it deeply, and lists findings with file/line references. Does NOT comment on the PR or make code changes. Use when the user runs /pr-review or asks for a thorough review of a PR.
---

# Review PR

Thoroughly review a pull request and present findings as a list for triage.

**Critical constraints:**

- Do **NOT** comment on, review, or approve the PR on GitHub.
- Do **NOT** make, ship, or commit any code changes.
- Do **NOT** modify the local checkout: never run `git checkout`, `switch`, `stash`,
  `reset`, or `pull`, and never read PR code from the working tree or `FETCH_HEAD`.
  Other reviews may be running in parallel in the same repo.
- Only gather context, analyze, and present findings. The user decides which
  findings to act on afterward.

## Workflow

### Step 1: Parse the PR link

Extract `owner`, `repo`, and `pullNumber` from the GitHub URL provided as `$ARGUMENTS`.

URL format: `https://github.com/{owner}/{repo}/pull/{pullNumber}`

### Step 2: Gather full context

Use the `gh` CLI. Run these in parallel:

1. **PR metadata** — title, body, author, base/head branches and SHAs, state, labels,
   draft status:
   ```
   gh pr view <pullNumber> --repo <owner>/<repo> --json title,body,author,baseRefName,headRefName,headRefOid,baseRefOid,isCrossRepository,state,isDraft,labels,additions,deletions,changedFiles
   ```
   `headRefOid` (`headSha`) and `baseRefOid` (`baseSha`) pin every later code read.
2. **PR diff** — the actual code changes:
   ```
   gh pr diff <pullNumber> --repo <owner>/<repo>
   ```
3. **Files changed** — a scoped list to reason about structure:
   ```
   gh pr view <pullNumber> --repo <owner>/<repo> --json files
   ```
4. **Open discussions** — review comments and their threads:
   ```
   gh api repos/<owner>/<repo>/pulls/<pullNumber>/comments --paginate
   ```
5. **Issue-level comments** — general PR conversation:
   ```
   gh api repos/<owner>/<repo>/issues/<pullNumber>/comments --paginate
   ```
6. **CI status** — surface failing checks as potential findings:
   ```
   gh pr checks <pullNumber> --repo <owner>/<repo>
   ```

For unresolved vs. resolved review threads, use the GraphQL `reviewThreads` query
(see [pr-feedback](../pr-feedback/SKILL.md) Step 3) if thread resolution state matters.

### Step 3: Prepare to read PR code

All code reads are pinned to `headSha` or `baseSha` so parallel reviews in the same
repo never share git state.

1. **Find the local repo.** The working directory may be `~/code` or an unrelated
   repo. Look for `~/code/<repo>` and confirm it matches the PR's repo:
   ```
   git -C <dir> remote get-url origin
   ```
2. **If it matches**, fetch the PR's objects without writing any refs or `FETCH_HEAD`
   (works for fork PRs too; retry once on "cannot lock ref"):
   ```
   git -C <dir> fetch --no-write-fetch-head origin pull/<pullNumber>/head
   ```
   Then read and search by SHA:
   - `git -C <dir> show <headSha>:<path>` — the PR's version of a file
   - `git -C <dir> show <baseSha>:<path>` — the original version
   - `git -C <dir> grep <pattern> <headSha>` — search the PR's tree (e.g. callers of a
     changed function)
3. **If there is no matching local repo**, read files through the API:
   ```
   gh api "repos/<owner>/<repo>/contents/<path>?ref=<sha>" -H "Accept: application/vnd.github.raw"
   ```

If you write a scratch file (e.g. a saved diff), create it with `mktemp`; never use a
fixed path like `/tmp/pr.diff`.

### Step 4: Pull in linked Jira tickets

Identify Jira ticket references from the PR title, branch name, and body
(Turo format: `<JIRA-ID>: Brief description`, e.g. `CPL-365`). For each ticket ID
found, use the Atlassian MCP to fetch the ticket so you understand the intended
scope and acceptance criteria:

- `getJiraIssue` — fetch the ticket's summary, description, status, and acceptance criteria.
- If the PR references Confluence pages (RFCs, design docs), fetch them with
  `getConfluencePage` to understand the intended approach.

Use this to judge whether the PR **actually accomplishes what the ticket asked**
and whether it stays within scope.

### Step 5: Understand before critiquing

Before listing findings, form a clear mental model:

- What is this PR trying to do, and why (from ticket + description)?
- What is the overall approach, and is it sound?
- Which files carry the core logic vs. incidental churn?

If the diff references existing code you haven't seen, read the surrounding files at
`headSha` (or `baseSha` for the pre-change version) using the commands from Step 3,
so findings are grounded in reality, not guesses. Never read the working tree; it may
be on another branch or have uncommitted changes.

### Step 6: Deep review (optionally parallelize with subagents)

For small PRs, review directly. For **large or multi-concern PRs**, spin up
`explore` or `generalPurpose` subagents in parallel, each focused on one lens, then
aggregate their findings. Give each subagent the PR diff/context and ask it to
return findings in the format from Step 7.

Subagents don't inherit this skill, so each subagent prompt must include:

- The local repo directory (or that it must use the `gh api` fallback), `headSha`,
  and `baseSha`.
- The exact read commands from Step 3.
- The rule against modifying the checkout: no `checkout`, `switch`, `stash`, `reset`,
  or `pull`, and no reading PR code from the working tree or `FETCH_HEAD`.

Review lenses to cover:

- **Correctness & bugs** — logic errors, edge cases, off-by-one, null/undefined
  handling, race conditions, incorrect assumptions.
- **Approach & design** — is the overall strategy sound? Simpler alternative?
  Does it fit existing patterns? Scope creep or missing scope vs. the ticket?
- **Security** — injection, authz/authn gaps, secrets, unsafe input handling,
  SSRF/XSS, unsafe deserialization.
- **Error handling** — silent failures, swallowed exceptions, missing logging,
  unhandled rejections.
- **Tests** — adequate coverage for new/changed behavior, meaningful assertions,
  missing edge-case tests.
- **Readability & maintainability** — naming, dead code, duplicated logic, overly
  complex functions, unclear comments (or comment rot).
- **Performance** — N+1 queries, unnecessary work in hot paths, large allocations.
- **Consistency** — adherence to repo conventions (check `CLAUDE.md`/`AGENTS.md`,
  `.cursor/rules`, linters, existing style).
- **Docs & translations** — updated docs, i18n strings handled correctly.
- **Unaddressed discussion** — open review comments or Jira notes not yet resolved
  by the current diff.

### Step 7: Present findings

Present findings as a **numbered list**, grouped by severity (highest first):

- 🔴 **Critical** — bugs, security issues, or scope misses that should block merge.
- 🟡 **Important** — should fix, but not necessarily blocking.
- 🟢 **Minor / nit** — suggestions, style, nice-to-haves.
- 💬 **Question** — needs clarification from the author.

For **each** finding include:

1. **Location** — `path/to/file.ext:L<line>` (or line range) when it maps to a
   specific spot in the diff. For findings that apply to the whole PR (e.g. an
   issue with the overall approach, missing tests across the board, scope
   mismatch vs. the ticket), mark the location as **General**.
2. **Finding** — a clear, specific description of the issue.
3. **Why it matters** — the impact or reasoning.
4. **Suggested action** — concrete recommendation (or a proposed change described
   in words — do not apply it).

Use this template per item:

```markdown
N. [🔴/🟡/🟢/💬] <path:line | General> — <short title>
   - Finding: <what the issue is>
   - Why: <impact / reasoning>
   - Suggested action: <recommendation>
```

End with a brief **summary**: overall assessment, whether the PR accomplishes the
ticket's goal, count of findings by severity, and anything the PR does well.

### Step 8: Hand off for triage

Stop after presenting findings. Wait for the user to decide which findings to act
on. Do not comment on the PR, post a review, or change code unless the user
explicitly asks in a follow-up.

When the user does choose which findings to follow up on, post those as comments
or a review on the PR using the `gh` CLI (e.g. `gh pr comment`, `gh pr review`, or
the `gh api` review-comment/reply endpoints). See
[pr-feedback](../pr-feedback/SKILL.md) for the reply flow.
