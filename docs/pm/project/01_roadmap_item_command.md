# Roadmap items — Codex command

This repo is the canonical place to create cross-repo **roadmap items** as GitHub Issues.

When you create the Issue in `getJila/JilaDocuments`, the org workflow auto-adds it to **getJila Project #5 (“Jila”)**.

## Prereqs

- GitHub CLI installed: `gh --version`
- Authenticated to GitHub: `gh auth status`
- In `getJila/JilaDocuments`, the `Auto-add issues/PRs to project` workflow is enabled and the repo has `PROJECT_WORKFLOW_PAT` set.

## Command

From this repo root:

```bash
./pm/project/roadmap-create.sh \
  --title "Standardize GitHub issue metadata across repos" \
  --pillar cross-cutting \
  --type discovery \
  --doc-anchor "docs/pm/project/00_project_workflow.md" \
  --summary "Define and automate a standard label/milestone taxonomy across repos (no custom issue forms)." \
  --acceptance "- [ ] Canonical labels defined\n- [ ] Labels sync automation exists\n- [ ] Milestone convention defined\n- [ ] Milestone sync automation exists\n- [ ] Docs + rollout checklist"
```

## What it does

- Creates a new Issue in `getJila/JilaDocuments` with:
  - Title prefixed with `Roadmap: `
  - Required labels: `pillar:*` and `type:*`
  - A structured body containing Summary, Doc anchor, Connections, Acceptance criteria, Notes
- Relies on the repo workflow to auto-add the issue to the org Project.

## Notes

- If you need the roadmap item to live in a different repo (because the work is truly repo-specific), pass `--repo owner/name`.
- Keep `Doc anchor` to one canonical link/path so future agents can quickly ground the work.

