#!/bin/bash
# install.sh — BeGenerous Claude Config installer
# Installation sélective avec backup automatique

set -e

CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude.backup-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════"
echo "  BeGenerous Claude Config — Installation"
echo "════════════════════════════════════════════"
echo ""

# Vérification config existante
if [ -d "$CLAUDE_DIR" ]; then
  echo "⚠️  Config Claude existante détectée : $CLAUDE_DIR"
  read -p "Créer un backup vers $BACKUP_DIR ? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cp -r "$CLAUDE_DIR" "$BACKUP_DIR"
    echo "✓ Backup créé : $BACKUP_DIR"
  fi
fi

mkdir -p "$CLAUDE_DIR"/{agents,skills,commands,rules,hooks}

install_component() {
  local label=$1
  local src=$2
  local dst=$3

  echo ""
  read -p "Installer $label ? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cp -r "$src" "$dst"
    echo "✓ $label installé"
  else
    echo "⊘ $label skippé"
  fi
}

echo ""
echo "─── TIER 1 : Must-have ───"

install_component "Agents Tier 1" "$SCRIPT_DIR/agents/planner.md" "$CLAUDE_DIR/agents/"
install_component "Agent architect" "$SCRIPT_DIR/agents/architect.md" "$CLAUDE_DIR/agents/"
install_component "Agent code-reviewer" "$SCRIPT_DIR/agents/code-reviewer.md" "$CLAUDE_DIR/agents/"
install_component "Agent typescript-reviewer" "$SCRIPT_DIR/agents/typescript-reviewer.md" "$CLAUDE_DIR/agents/"
install_component "Agent database-reviewer" "$SCRIPT_DIR/agents/database-reviewer.md" "$CLAUDE_DIR/agents/"

for skill in continuous-learning strategic-compact verification-loop iterative-retrieval search-first nextjs-turbopack database-migrations security-scan; do
  install_component "Skill $skill" "$SCRIPT_DIR/skills/$skill" "$CLAUDE_DIR/skills/"
done

install_component "Rules common" "$SCRIPT_DIR/rules/common" "$CLAUDE_DIR/rules/"
install_component "Rules typescript" "$SCRIPT_DIR/rules/typescript" "$CLAUDE_DIR/rules/"

echo ""
echo "─── TIER 2 : Nice-to-have ───"

install_component "Agent e2e-runner" "$SCRIPT_DIR/agents/e2e-runner.md" "$CLAUDE_DIR/agents/"
install_component "Agent build-error-resolver" "$SCRIPT_DIR/agents/build-error-resolver.md" "$CLAUDE_DIR/agents/"
install_component "Agent refactor-cleaner" "$SCRIPT_DIR/agents/refactor-cleaner.md" "$CLAUDE_DIR/agents/"

for skill in frontend-patterns backend-patterns api-design e2e-testing mcp-server-patterns documentation-lookup; do
  install_component "Skill $skill" "$SCRIPT_DIR/skills/$skill" "$CLAUDE_DIR/skills/"
done

echo ""
echo "─── COMMANDS ───"
read -p "Installer les 9 commands ? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  cp "$SCRIPT_DIR"/commands/*.md "$CLAUDE_DIR/commands/"
  echo "✓ Commands installées"
fi

echo ""
echo "─── HOOKS (manuel recommandé) ───"
echo "⚠️  Les hooks doivent être mergés avec tes hooks existants."
echo "    Voir : hooks/MERGE-GUIDE.md"
echo ""

echo "════════════════════════════════════════════"
echo "  Installation terminée"
echo "════════════════════════════════════════════"
echo ""
echo "Prochaines étapes :"
echo "  1. Merger settings.template.json dans ~/.claude/settings.json"
echo "  2. Lire hooks/MERGE-GUIDE.md pour les hooks"
echo "  3. Lancer 'claude' dans un projet test"
echo ""
