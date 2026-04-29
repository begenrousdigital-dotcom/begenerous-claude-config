#!/bin/bash
# save-context.sh — SessionEnd hook
# Sauvegarde un résumé léger pour reprise rapide

PROJECT=$(basename "$(pwd)")
SESSION_DIR="$HOME/.claude/sessions/$PROJECT"
DATE=$(date +%Y%m%d-%H%M)

mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/last-session.md" << EOL
# Session du $DATE

## Branch
$(git branch --show-current 2>/dev/null || echo "non-git")

## Last commit
$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo "n/a")

## Status
$(git status -s 2>/dev/null || echo "n/a")

## Modified files (last hour)
$(find . -type f -mmin -60 -not -path './node_modules/*' -not -path './.next/*' 2>/dev/null | head -20)
EOL

exit 0
