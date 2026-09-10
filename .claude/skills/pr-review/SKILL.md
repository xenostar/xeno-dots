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
- Only gather context, analyze, and present findings. The user decides which
  findings to act on afterward.

## Workflow

### Step 1: Parse the PR link

Extract `owner`, `repo`, and `pullNumber` from the GitHub URL provided as `$ARGUMENTS`.

URL format: `https://github.com/{owner}/{repo}/pull/{pullNumber}`

### Step 2: Gather full context

Use the `gh` CLI. Run these in parallel:

1. **PR metadata** — title, body, author, base/head branches, state, labels, draft status:
   ```
   gh pr view <pullNumber> --repo <owner>/<repo> --json title,body,author,baseRefName,headRefName,state,isDraft,labels,additions,deletions,changedFiles
   ```
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

### Step 3: Pull in linked Jira tickets

Identify Jira ticket references from the PR title, branch name, and body
(Turo format: `<JIRA-ID>: Brief description`, e.g. `CPL-365`). For each ticket ID
found, use the Atlassian MCP to fetch the ticket so you understand the intended
scope and acceptance criteria:

- `getJiraIssue` — fetch the ticket's summary, description, status, and acceptance criteria.
- If the PR references Confluence pages (RFCs, design docs), fetch them with
  `getConfluencePage` to understand the intended approach.

Use this to judge whether the PR **actually accomplishes what the ticket asked**
and whether it stays within scope.

### Step 4: Understand before critiquing

Before listing findings, form a clear mental model:

- What is this PR trying to do, and why (from ticket + description)?
- What is the overall approach, and is it sound?
- Which files carry the core logic vs. incidental churn?

If the diff references existing code you haven't seen, read the surrounding files
in the repo (clone/checkout not required — use `gh api .../contents` or read local
files if the repo is checked out) so findings are grounded in reality, not guesses.

### Step 5: Deep review (optionally parallelize with subagents)

For small PRs, review directly. For **large or multi-concern PRs**, spin up
`explore` or `generalPurpose` subagents in parallel, each focused on one lens, then
aggregate their findings. Give each subagent the PR diff/context and ask it to
return findings in the format from Step 6.

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

### Step 6: Present findings

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

### Step 7: Hand off for triage

Stop after presenting findings. Wait for the user to decide which findings to act
on. Do not comment on the PR, post a review, or change code unless the user
explicitly asks in a follow-up.

When the user does choose which findings to follow up on, post those as comments
or a review on the PR using the `gh` CLI (e.g. `gh pr comment`, `gh pr review`, or
the `gh api` review-comment/reply endpoints). See
[pr-feedback](../pr-feedback/SKILL.md) for the reply flow.
