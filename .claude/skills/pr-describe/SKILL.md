---
name: pr-describe
disable-model-invocation: true
argument-hint: [pr-url]
description: Generate a PR description using the gh CLI and update it on the PR.
---

# Describe PR

Generate a concise PR description based on the diff for the current branch with main by using
`git diff main` and context of our conversation so far and update it on GitHub, replacing only
the Description section of the PR template.

The Changes section can be left as-is, as it automatically includes commits when the PR is opened.

The Testing section should be updated when actionable testing instructions can be
provided (see Step 5).

## Workflow

### Step 1: Parse the PR link

Extract `owner`, `repo`, and `pullNumber` from the GitHub URL provided as `$ARGUMENTS`.

URL format: `https://github.com/{owner}/{repo}/pull/{pullNumber}`

### Step 2: Fetch PR data

Use the `gh` CLI to gather context. Run these in parallel:

1. **Get PR details** — `gh pr view <pullNumber> --repo <owner>/<repo> --json title,body` to retrieve the current title and body.
2. **Get PR diff** — `gh pr diff <pullNumber> --repo <owner>/<repo>` to see the actual code changes.

### Step 3: Write the description

Analyze the diff and write a succinct summary covering:

- What changed and why (infer purpose from the diff)
- Key implementation details worth calling out

Do NOT list every file or repeat commit messages verbatim. Be concise.

### Step 4: Update the Description in the PR body

Replace **only** the content under the `**Description:**` heading — the text between
the `**Description:**` line and the next `**Changes:**` heading. Preserve everything else
(Changes, Testing, Responsibilities sections and all HTML comments) exactly as-is.

Build the new body by:

1. Taking the existing body from Step 2
2. Replacing the text between `**Description:**` (and its HTML comment) and `**Changes:**` with your new description
3. Keeping a blank line before and after the description text

### Step 5: Update the Testing section

Based on the diff and conversation context, decide how to fill in the `**Testing:**` section:

- **Functional changes** — Provide clear, step-by-step instructions a reviewer can follow to verify the change (e.g. pages to visit, actions to take, expected outcomes).
- **Refactors / no runtime behavior change** — Replace the testing content with a short note such as: "This is a refactor with no expected runtime behavior change. Verify CI passes."
- **Already populated** — If the existing Testing section already has meaningful content, leave it as-is or lightly improve it.

Replace the text between `**Testing:**` (and its HTML comment) and the next heading (e.g. `**Responsibilities:**`) with your testing content, preserving everything else.

### Step 6: Push the update

Update the PR body using the `gh` CLI with the full updated body (including both the Description and Testing changes from Steps 4–5):

```
gh pr edit <pullNumber> --repo <owner>/<repo> --body "$(cat <<'EOF'
<full updated body>
EOF
)"
```

### Step 7: Confirm

Tell the user what description and testing instructions were written and that the PR has been updated.
