# GitLab MR Revert Tool

Interactive Bash tool for safely reverting a merged GitLab MR through the environment branch chain:

```text
develop → staging → demo_pkg → uat → main
```

If you select `main`, the tool plans a revert on **all five branches**. If you select `uat`, it plans `develop → staging → demo_pkg → uat` and does not touch `main`.

## What it does

1. Prompts for a GitLab MR URL.
2. Prompts for the highest branch that should be reverted.
3. Verifies the MR exists, is merged, and targets `develop`.
4. Gets the MR's commit list from GitLab.
5. Fetches each target branch.
6. Finds the corresponding cherry-picked commits on downstream branches using stable Git patch IDs first, with conservative commit-message fallbacks.
7. Refuses to guess if a corresponding commit cannot be uniquely identified.
8. Prints a complete plan.
9. In dry-run mode, stops after the plan.
10. In execute mode, asks for confirmation, creates a revert branch from each target branch, performs the revert, pushes it, and creates a GitLab MR back to that target branch.
11. If `git revert` encounters a conflict, it runs `git revert --abort` and stops immediately.
12. After every requested branch has succeeded and its Revert MR has been created, replaces **all labels on the original MR** with exactly one label: `Reverted`.
13. Creates the project label `Reverted` automatically if it does not already exist.
14. Writes an audit plan/results under `.revert-state/mr-<iid>/`.

## Requirements

- Bash 4+ recommended
- Git
- curl
- jq
- GitLab API token with `api` scope (Personal Access Token or Project Access Token)
- Git remote with push permission

On macOS, install `jq` if needed:

```bash
brew install jq
```

## Setup

```bash
cp .env.example .env
chmod 700 revert-mr.sh
```

Edit `.env`:

```bash
GITLAB_URL="https://gitlab.company.com"
GITLAB_TOKEN="glpat-xxxxxxxx"
```

Never commit `.env`.

The token is passed only as an HTTP header and is never intentionally printed by the script.

## Recommended first run

Keep:

```bash
DRY_RUN=true
```

Then:

```bash
./revert-mr.sh
```

Example:

```text
GitLab MR Revert Tool v1.1.0

GitLab Merge Request URL: https://gitlab.company.com/team/backend/-/merge_requests/123

Revert target:
  1) develop
  2) staging
  3) demo_pkg
  4) uat
  5) main
Select [1-5]: 5

Revert plan
...

DRY RUN complete.
```

When the plan looks correct, set:

```bash
DRY_RUN=false
```

and run it again.

## Result

For a target of `main`, the tool creates one revert branch/MR per environment:

```text
revert/mr-123-develop-...
    → develop

revert/mr-123-staging-...
    → staging

revert/mr-123-demo_pkg-...
    → demo_pkg

revert/mr-123-uat-...
    → uat

revert/mr-123-main-...
    → main
```

It does not push directly to protected branches.

## Important assumptions

### 1. Original MR target

The original MR must target `develop`.

### 2. Downstream propagation

The implementation assumes the same logical change is propagated by cherry-pick. Cherry-pick creates a different SHA, so the script does **not** require SHA equality.

It first compares stable Git patch IDs. If that cannot identify the commit, it tries conservative commit-message matching. Ambiguous or missing matches cause the operation to stop before mutation.

### 3. Multiple commits

All commits returned by the GitLab MR commits API are considered. Reverts are attempted in reverse order.

### 4. Merge commits

This version uses `git revert -m 1` for each commit. Your repository should be tested with a representative MR before production use, especially if your GitLab merge strategy creates non-trivial merge commits. Squash merging or linear history makes the lineage considerably easier to reason about.

## Original MR labels

After **all** requested revert branches have been processed successfully, the original MR is updated so that its label set contains exactly:

```text
Reverted
```

Existing labels are intentionally removed. If a conflict occurs, a push fails, or a Revert MR cannot be created, the original MR labels are not changed. The tool stores the post-update MR response at:

```text
.revert-state/mr-<iid>/original-mr-after-label-update.json
```

The `Reverted` project label is created automatically if it does not already exist.

## Conflict behavior

If a conflict happens:

```text
[staging] conflict while reverting <sha>
```

The script executes:

```bash
git revert --abort
```

and exits. It does not continue to later branches.

Because each branch is processed in a fresh local branch and the push occurs only after a successful revert, the currently failing branch is not pushed.

Earlier branches may already have been pushed if the failure happens later in the chain. This is why the generated state directory records the work already performed.

## State and audit

State is stored in:

```text
.revert-state/mr-123/
├── plan.json
└── results/
    ├── develop.mr-url
    ├── staging.mr-url
    └── ...
```

`.revert-state/` is ignored by Git.

## Security notes

- Do not put the token in the script.
- Do not commit `.env`.
- Prefer a Project Access Token with the smallest project scope needed.
- Use a token belonging to a bot/service account if your organization supports it.
- Keep protected branches protected. The tool intentionally creates MRs instead of direct pushes.

## Validation before production

Use a non-critical test MR and verify:

1. MR commit list is correct.
2. The patch ID finds the expected cherry-pick on `staging`.
3. The generated revert branch contains exactly the intended inverse patch.
4. The generated MR targets the correct branch.
5. A deliberately conflicting test MR stops and aborts cleanly.

## ShellCheck

Run:

```bash
shellcheck revert-mr.sh
```

## Future hardening

Recommended next improvements for a production-grade internal tool:

- GitLab API pagination beyond 100 MR commits.
- Detect whether the original MR was squash-merged and use the squash commit where appropriate.
- Use GitLab's merge request `revert` API where its semantics match the desired workflow.
- Add a `--resume` command that resumes only after a human reviews a stopped operation.
- Add a `--plan-only` command-line mode in addition to interactive prompts.
- Add server-side merge request labels/assignees.
- Add CI tests against a temporary Git repository containing simulated cherry-picks and conflicts.
