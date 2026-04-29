# Hooks Merge Guide

Comment intégrer les hooks de ce repo avec ta config existante.

## Ta config actuelle (rappel)

Tu as déjà des hooks de sécurité :
- Block `rm -rf`
- Block `DROP TABLE`
- Block `git push --force`

Ces hooks **doivent être préservés**. Ce repo apporte des hooks **complémentaires**, pas de remplacement.

## Procédure de merge

### 1. Backup

```bash
cp ~/.claude/hooks/hooks.json ~/.claude/hooks/hooks.json.backup-$(date +%Y%m%d)
```

### 2. Lire ton hooks.json actuel

```bash
cat ~/.claude/hooks/hooks.json | jq .
```

Tu devrais avoir quelque chose comme :

```json
{
  "hooks": [
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-rm-rf.sh"
    },
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-drop-table.sh"
    },
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-force-push.sh"
    }
  ]
}
```

### 3. Merger avec les hooks de ce repo

Les nouveaux hooks à ajouter dans le tableau :

```json
{
  "type": "SessionStart",
  "command": "$HOME/.claude/hooks/load-context.sh",
  "description": "Charge les instincts et le dernier checkpoint"
},
{
  "type": "SessionEnd",
  "command": "$HOME/.claude/hooks/save-context.sh",
  "description": "Sauvegarde le contexte de session"
},
{
  "type": "PostToolUse",
  "matcher": { "tool": "Bash" },
  "command": "$HOME/.claude/hooks/suggest-compact.sh",
  "description": "Suggère /compact aux moments propices"
}
```

### 4. Résultat final attendu

```json
{
  "hooks": [
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-rm-rf.sh"
    },
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-drop-table.sh"
    },
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "~/.claude/hooks/block-force-push.sh"
    },
    {
      "type": "SessionStart",
      "command": "$HOME/.claude/hooks/load-context.sh"
    },
    {
      "type": "SessionEnd",
      "command": "$HOME/.claude/hooks/save-context.sh"
    },
    {
      "type": "PostToolUse",
      "matcher": { "tool": "Bash" },
      "command": "$HOME/.claude/hooks/suggest-compact.sh"
    }
  ]
}
```

### 5. Copier les scripts

```bash
cp hooks/load-context.sh ~/.claude/hooks/
cp hooks/save-context.sh ~/.claude/hooks/
cp hooks/suggest-compact.sh ~/.claude/hooks/

chmod +x ~/.claude/hooks/load-context.sh
chmod +x ~/.claude/hooks/save-context.sh
chmod +x ~/.claude/hooks/suggest-compact.sh
```

### 6. Tester

```bash
# Test load-context manuellement
~/.claude/hooks/load-context.sh

# Test save-context manuellement
~/.claude/hooks/save-context.sh

# Vérifier que les hooks sécurité existants marchent toujours
echo '{"command": "rm -rf /"}' | ~/.claude/hooks/block-rm-rf.sh
echo "Exit code attendu: 2"
```

### 7. Lancer Claude Code et vérifier

```bash
cd /path/to/some/project
claude
```

Au démarrage, tu devrais voir le contexte chargé (instincts + dernier checkpoint si disponible).

## Rollback

Si problème :

```bash
cp ~/.claude/hooks/hooks.json.backup-XXXXXX ~/.claude/hooks/hooks.json
```

## Conflits potentiels

### Si tu as déjà un hook SessionStart
Combinersignaux : un seul hook par type, mais qui appelle plusieurs scripts en chaîne :

```bash
#!/bin/bash
# combined-session-start.sh
~/.claude/hooks/your-existing-script.sh
~/.claude/hooks/load-context.sh
```

### Si tu as déjà un hook PostToolUse / Bash
Idem, chaîner les scripts.

### Si tu utilises un format différent
Certaines versions de Claude Code utilisent un format différent (objet avec keys vs array). Adapter selon ta version :

```bash
claude --version
```

## Performance

Les hooks se déclenchent à chaque interaction. S'ils sont lents → Claude Code rame.

Ces hooks sont conçus pour être < 100ms chacun. Si tu observes du lag :

```bash
# Profiler
time ~/.claude/hooks/load-context.sh
```

Si > 200ms, optimiser ou désactiver le hook concerné.
