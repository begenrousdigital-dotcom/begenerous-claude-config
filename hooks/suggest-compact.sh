#!/bin/bash
# suggest-compact.sh — PostToolUse hook
# Suggère /compact après un Bash réussi quand context est chargé

# Lire l'input JSON depuis stdin
INPUT=$(cat)

# Heuristique simple : suggérer après un commit (signal de fin de milestone)
if echo "$INPUT" | grep -qE '"command":"git commit'; then
  echo "💡 Bon moment pour /compact si tu as terminé un milestone"
fi

exit 0
