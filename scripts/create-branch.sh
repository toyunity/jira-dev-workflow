#!/usr/bin/env bash
# Usage:
#   create-branch.sh <parent-ticket> <sub-ticket>   # Sub-task branch (under a parent)
#   create-branch.sh <ticket>                        # Standalone ticket branch (Task / Defect)
#
# Branch patterns (driven by .claude/jira-workflow-config.md):
#   parent branch:     {BRANCH_PREFIX}/_{parent}/parent/{parent}
#   sub-task branch:   {BRANCH_PREFIX}/_{parent}/{sub}
#   standalone branch: {BRANCH_PREFIX}/{ticket}
#
# Config resolution order:
#   1. Environment variables (BRANCH_PREFIX, BASE_BRANCH) if set
#   2. .claude/jira-workflow-config.md in the current working directory
#   3. Defaults: BRANCH_PREFIX=feature, BASE_BRANCH=main

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: create-branch.sh <parent-ticket> <sub-ticket>" >&2
  echo "       create-branch.sh <ticket>" >&2
  exit 1
fi

# --- Resolve config ---------------------------------------------------------

CONFIG_FILE=".claude/jira-workflow-config.md"
read_config() {
  local key="$1"
  if [ -f "$CONFIG_FILE" ]; then
    grep -E "^${key}:" "$CONFIG_FILE" | head -n1 | sed -E "s/^${key}:[[:space:]]*//" | sed -E 's/[[:space:]]+$//'
  fi
}

BRANCH_PREFIX="${BRANCH_PREFIX:-$(read_config BRANCH_PREFIX)}"
BRANCH_PREFIX="${BRANCH_PREFIX:-feature}"

BASE_BRANCH="${BASE_BRANCH:-$(read_config BASE_BRANCH)}"
BASE_BRANCH="${BASE_BRANCH:-main}"

# --- Pre-flight: no uncommitted changes -------------------------------------

if ! git diff --quiet || ! git diff --staged --quiet; then
  echo "❌ Uncommitted changes present. Stash or commit before re-running." >&2
  exit 1
fi

# --- 1-arg mode: standalone branch ------------------------------------------

if [ $# -eq 1 ]; then
  SUB="${1}"
  SUB_BRANCH="${BRANCH_PREFIX}/${SUB}"
  echo "📌 Standalone branch: $SUB_BRANCH"
  git fetch origin
  git checkout "$BASE_BRANCH" && git pull origin "$BASE_BRANCH"
  if git show-ref --verify --quiet "refs/heads/$SUB_BRANCH"; then
    echo "→ Branch already exists. Switching only."
    git checkout "$SUB_BRANCH"
  else
    git checkout -b "$SUB_BRANCH"
  fi
  echo "✅ Branch ready: $SUB_BRANCH"
  exit 0
fi

# --- 2-arg mode: parent + sub branches --------------------------------------

PARENT="${1}"
SUB="${2}"

PARENT_BRANCH="${BRANCH_PREFIX}/_${PARENT}/parent/${PARENT}"
SUB_BRANCH="${BRANCH_PREFIX}/_${PARENT}/${SUB}"

echo "📌 Parent branch: $PARENT_BRANCH"
echo "📌 Sub branch:    $SUB_BRANCH"

# Parent: check both local refs and remote refs before creating from BASE_BRANCH.
if ! git show-ref --verify --quiet "refs/heads/$PARENT_BRANCH" && \
   ! git ls-remote --exit-code --heads origin "$PARENT_BRANCH" > /dev/null 2>&1; then
  echo "→ Parent branch missing. Creating from $BASE_BRANCH."
  git fetch origin
  git checkout "$BASE_BRANCH" && git pull origin "$BASE_BRANCH"
  git checkout -b "$PARENT_BRANCH"
else
  git checkout "$PARENT_BRANCH" 2>/dev/null || \
    git checkout -b "$PARENT_BRANCH" "origin/$PARENT_BRANCH"
fi

# Sub branch: create off the parent.
if git show-ref --verify --quiet "refs/heads/$SUB_BRANCH"; then
  echo "→ Sub branch already exists. Switching only."
  git checkout "$SUB_BRANCH"
else
  git checkout -b "$SUB_BRANCH"
fi

echo "✅ Branch ready: $SUB_BRANCH"
