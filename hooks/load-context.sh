#!/bin/bash
# load-context.sh — SessionStart hook
# Charge les instincts et le dernier checkpoint du projet courant

PROJECT_DIR=$(pwd)
PROJECT=$(basename "$PROJECT_DIR")
INSTINCTS_DIR="$HOME/.claude/instincts"
CHECKPOINTS_DIR="$HOME/.claude/checkpoints/$PROJECT"

# 1. Instincts globaux
if [ -d "$INSTINCTS_DIR/global" ]; then
  echo "## Instincts globaux actifs"
  ls "$INSTINCTS_DIR/global"/*.md 2>/dev/null | head -10 | while read f; do
    title=$(grep -m 1 "^title:" "$f" | sed 's/title: *//')
    echo "- $title"
  done
fi

# 2. Instincts projet
if [ -d "$INSTINCTS_DIR/projects/$PROJECT" ]; then
  echo ""
  echo "## Instincts $PROJECT"
  ls "$INSTINCTS_DIR/projects/$PROJECT"/*.md 2>/dev/null | while read f; do
    title=$(grep -m 1 "^title:" "$f" | sed 's/title: *//')
    echo "- $title"
  done
fi

# 3. Dernier checkpoint
if [ -d "$CHECKPOINTS_DIR" ]; then
  LAST=$(ls -t "$CHECKPOINTS_DIR"/*.md 2>/dev/null | head -1)
  if [ -n "$LAST" ]; then
    echo ""
    echo "## Dernier checkpoint"
    echo "Source : $LAST"
    head -20 "$LAST"
  fi
fi

exit 0
