#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Create a roadmap issue (defaults to getJila/JilaDocuments).

Usage:
  roadmap-create.sh \
    --title "..." \
    --pillar reliability|marketplace|evidence|cross-cutting \
    --type feature|bug|tech-debt|discovery \
    --doc-anchor "..." \
    --summary "..." \
    [--repo owner/repo] \
    [--connections "..."] \
    [--acceptance $'- [ ] ...\n- [ ] ...'] \
    [--notes "..."] \
    [--extra-label "label"] [--extra-label "label"] ...

Notes:
  - This command creates an Issue. The repo workflow auto-adds it to the org Project.
  - Requires GitHub CLI auth: gh auth status
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd gh

repo="getJila/JilaDocuments"
title=""
pillar=""
work_type=""
doc_anchor=""
summary=""
connections=""
acceptance=""
notes=""
extra_labels=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --title) title="$2"; shift 2 ;;
    --pillar) pillar="$2"; shift 2 ;;
    --type) work_type="$2"; shift 2 ;;
    --doc-anchor) doc_anchor="$2"; shift 2 ;;
    --summary) summary="$2"; shift 2 ;;
    --connections) connections="$2"; shift 2 ;;
    --acceptance) acceptance="$2"; shift 2 ;;
    --notes) notes="$2"; shift 2 ;;
    --extra-label) extra_labels+=("$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$title" || -z "$pillar" || -z "$work_type" || -z "$doc_anchor" || -z "$summary" ]]; then
  echo "Missing required args. See --help." >&2
  exit 2
fi

case "$pillar" in
  reliability|marketplace|evidence|cross-cutting) ;;
  *) echo "Invalid --pillar: $pillar" >&2; exit 2 ;;
esac

case "$work_type" in
  feature|bug|tech-debt|discovery) ;;
  *) echo "Invalid --type: $work_type" >&2; exit 2 ;;
esac

if ! gh auth status >/dev/null 2>&1; then
  echo "Not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

if [[ "$title" != Roadmap:* ]]; then
  title="Roadmap: $title"
fi

body=$(
  cat <<EOF
## Summary
$summary

## Context (Doc anchor)
Doc anchor: $doc_anchor

## Connections
${connections:-Parent: #\nDepends on: #\nRelated: #}

## Acceptance criteria (Definition of Done)
${acceptance:-- [ ] ...}

## Notes / constraints
${notes:-...}
EOF
)

labels=("pillar:$pillar" "type:$work_type")
if (( ${#extra_labels[@]} )); then
  for label in "${extra_labels[@]}"; do
    labels+=("$label")
  done
fi

label_args=()
for label in "${labels[@]}"; do
  label_args+=(--label "$label")
done

echo "Creating roadmap issue in ${repo}..."
issue_url="$(gh issue create --repo "${repo}" --title "$title" --body "$body" "${label_args[@]}")"
echo "Created: $issue_url"

