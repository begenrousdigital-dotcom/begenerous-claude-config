# Hooks Claude Code

Conventions et bonnes pratiques pour les hooks de configuration `~/.claude/hooks/`.

## Types de hooks

| Hook | Quand | Usage typique |
|---|---|---|
| `SessionStart` | Démarrage de session | Charger contexte projet, instincts |
| `SessionEnd` | Fin de session | Sauvegarder état, suggérer learn |
| `UserPromptSubmit` | Avant traitement du prompt user | Filtrage, enrichissement |
| `PreToolUse` | Avant exécution d'un tool | Bloquer commandes dangereuses |
| `PostToolUse` | Après exécution d'un tool | Logging, vérifications |

## Configuration

`~/.claude/hooks/hooks.json` :

```json
{
  "hooks": [
    {
      "type": "PreToolUse",
      "matcher": { "tool": "Bash" },
      "command": "/path/to/script.sh",
      "description": "Block dangerous commands"
    }
  ]
}
```

## Hooks de sécurité (essentiels)

### Block rm -rf
```bash
#!/bin/bash
# hooks/block-rm-rf.sh
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

if echo "$COMMAND" | grep -qE 'rm\s+-rf?\s+/'; then
  echo "❌ Bloqué : rm -rf / interdit"
  exit 2  # exit code 2 bloque l'exécution
fi
```

### Block DROP TABLE prod
```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE|SCHEMA)'; then
  echo "⚠️ Détecté : DROP statement. Confirme manuellement."
  exit 2
fi
```

### Block git push --force
```bash
if echo "$COMMAND" | grep -qE 'git\s+push\s+(-f|--force)'; then
  echo "❌ Bloqué : force push interdit"
  exit 2
fi
```

## Hooks utilitaires

### Memory persistence
```bash
#!/bin/bash
# hooks/save-context.sh - SessionEnd
PROJECT=$(basename "$(pwd)")
DATE=$(date +%Y%m%d-%H%M)
SESSION_DIR="$HOME/.claude/sessions/$PROJECT"

mkdir -p "$SESSION_DIR"

# Sauvegarder un résumé
cat > "$SESSION_DIR/last-session.md" << EOL
# Session du $DATE
## Branch
$(git branch --show-current)
## Last commit
$(git log -1 --pretty=format:'%h %s')
## Modified files
$(git status -s)
EOL
```

### Suggest compact
```bash
#!/bin/bash
# hooks/suggest-compact.sh - PostToolUse
# Si conversation > 50% context, suggérer compact aux moments propices

CONTEXT_PCT=$(...) # extraire du metadata

if [ "$CONTEXT_PCT" -gt 50 ]; then
  LAST_TOOL=$(...) 
  if [ "$LAST_TOOL" = "Bash" ]; then
    echo "💡 Bon moment pour /compact"
  fi
fi
```

## Bonnes pratiques

### ✅ Do
- Hooks **idempotents** : peuvent s'exécuter plusieurs fois sans casser
- **Fail safe** : en cas d'erreur du hook, ne pas bloquer l'utilisateur sauf danger réel
- **Logging** : tracer les actions du hook dans un fichier dédié
- **Performance** : < 100ms par hook (sinon ça ralentit chaque action)
- **Idempotents** : pas d'effet de bord cumulatif

### ❌ Don't
- Hooks qui font des appels réseau lents
- Hooks qui modifient le code source
- Hooks qui demandent input utilisateur (pas interactif)
- Hooks fragiles qui crashent l'expérience Claude Code

## Exit codes

| Code | Effet |
|---|---|
| 0 | OK, continuer |
| 1 | Erreur du hook (ne bloque pas, juste log) |
| 2 | Bloquer l'action (utilisé pour sécurité) |

## Debugging

```bash
# Tester un hook manuellement
echo '{"command": "rm -rf /"}' | bash hooks/block-rm-rf.sh
echo "Exit code: $?"

# Logs Claude Code
tail -f ~/.claude/logs/hooks.log
```

## Cohabitation

Si tu reçois une nouvelle config de hooks d'une autre source, **ne pas écraser** tes hooks existants :
1. Backup : `cp ~/.claude/hooks/hooks.json{,.bak}`
2. Merger manuellement les nouveaux hooks dans le tableau `hooks: [...]`
3. Vérifier qu'aucun hook ne fait doublon ou contradiction
4. Tester avec un script test après merge

## Sécurité des hooks

⚠️ Les hooks ont **plein accès** à ton système. Avant d'installer un hook tiers :
- Lire le code en entier
- Vérifier qu'il ne fait pas d'appels réseau louches
- Vérifier qu'il ne touche pas à des fichiers sensibles
- Tester en sandbox d'abord
