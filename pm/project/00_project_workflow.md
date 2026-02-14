# getJila Project #5 (“Jila”) — Lightweight Workflow

Purpose: keep the Project as the **cross-repo center** for context, while keeping maintenance **simple**.

## What goes in the Project

- **All roadmap work** should be represented as **repo Issues** (or PRs when appropriate).
- The Project is the single place to understand:
  - what the work is,
  - why it exists (value prop + docs),
  - where it’s implemented (repo/PR links),
  - how it relates to other work (parent/dependencies).

## Project fields: what’s authoritative vs derived

### Authoritative in the Project (portfolio-level decisions)

These fields are **owned at the Project level** to avoid conflicting truth across repos:
- `Status` (Todo / In progress / Done)
- `Priority` (P0 / P1 / P2)
- `Iteration` (the roadmap/timebox)
- Optional: `Target date` (only when a date is truly committed)
- Optional: `Size` / `Estimate` (only when you’re using them consistently)

### Authoritative in the Issue (repo-level, created where the work happens)

These should live in the Issue body/labels, because Issues are created in repos and travel with the work:
- **Doc anchor**: one canonical link that explains “why / contract / scope”
- **Product classification**: put in labels so the Project can filter without custom fields
  - exactly one `pillar:*` label (Reliability / Marketplace / Evidence / Cross-cutting)
  - exactly one `type:*` label (Feature / Bug / Tech-debt / Discovery)
- **Repo-local constraints**: team-specific details that don’t belong in a central PM field

## Prefer built-in connections over extra fields

Use these GitHub primitives to keep linkage easy to maintain:
- **Parent issue** + sub-issues: express epics and decomposition.
- **Issue links** (“blocked by”, “depends on”, “relates to”): express dependencies.
- **Linked pull requests**: connect implementation to the issue.

Avoid adding fields like “Dependencies”, “Epic”, “PR links” — GitHub already provides them and they stay accurate.

## Issue intake

For issues in **jilaPortalFrontend**, use the GitHub issue template at 
`.github/ISSUE_TEMPLATE/feature.yml`. This consolidated template includes:

- **Summary, Motivation** — what and why
- **Pillar** and **Type** dropdowns — auto-labeled by GitHub Action
- **Doc Anchor** — canonical justification (PRD section, decision register, audit item)
- **Connections** — parent, dependencies, related issues
- **Files Affected** — for parallel execution planning
- **Acceptance Criteria** — definition of done
- **Execution Mode** — parallel vs sequential

The template consolidates both portfolio tracking needs (pillar/type/doc-anchor) and 
parallel execution needs (files-affected/execution-mode). Labels are automatically 
applied by `.github/workflows/auto-label-issues.yml`.

### Label requirements

Each issue should have:
- Exactly one `pillar:*` label (reliability, marketplace, evidence, cross-cutting)
- Exactly one `type:*` label (feature, bug, tech-debt, discovery)

These enable filtering in the org-wide Project view.

## Roadmapping (simple rule of thumb)

- Use `Iteration` as the roadmap driver:
  - **This iteration**: committed work
  - **Next iteration**: likely work
  - **Later**: backlog (no iteration assigned)
- Use `Priority` as the tie-breaker inside an iteration (P0 > P1 > P2).
