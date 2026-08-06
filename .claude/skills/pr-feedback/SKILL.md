---
name: pr-feedback
disable-model-invocation: true
argument-hint: [pr-url]
description: Pull in unresolved PR feedback from GitHub and list it for triage.
---

# Feedback PR

Fetch open review feedback from a pull request using the `gh` CLI and present it
for triage. Do NOT reply to any comments on the PR — only list what's unresolved so
we can decide together how to address each item.

## Workflow

### Step 1: Parse the PR link

Extract `owner`, `repo`, and `pullNumber` from the GitHub URL provided as `$ARGUMENTS`.

URL format: `https://github.com/{owner}/{repo}/pull/{pullNumber}`

### Step 2: Fetch review comments

Use the `gh` CLI to fetch all review comments on the PR:

```
gh api repos/<owner>/<repo>/pulls/<pullNumber>/comments --paginate
```

This returns all review comments including their file path, line, body, user, and metadata.

### Step 3: Filter to open feedback

From the returned comments, keep only those that are unresolved. Comments that are
part of a resolved review thread (where the thread has been marked as resolved on
GitHub) should be excluded.

To check for resolved threads, you can also fetch the review threads via the GraphQL API if needed:

```
gh api graphql -f query='
  query {
    repository(owner: "<owner>", name: "<repo>") {
      pullRequest(number: <pullNumber>) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 10) {
              nodes {
                body
                author { login }
                path
                line
              }
            }
          }
        }
      }
    }
  }
'
```

### Step 4: Present the feedback

For each open thread, display a numbered list with:

1. **File & line** — the file path and line range the comment targets.
2. **Reviewer** — who left the comment.
3. **Comment** — the reviewer's feedback.
4. **Suggested action** — your brief recommendation: code change, reply to clarify,
   or acknowledge/no action needed.

If there are no open threads, let the user know the PR has no unresolved feedback.

### Step 5: Triage

Wait for the user to decide how to handle each item. Do not take action until
instructed. Common next steps the user may request:

- Make a code change to address a comment.
- Draft a reply to a comment using the `gh` CLI:
  ```
  gh api repos/<owner>/<repo>/pulls/comments/<comment-id>/replies -f body="<reply text>"
  ```
- Dismiss a comment as already addressed or not applicable.
