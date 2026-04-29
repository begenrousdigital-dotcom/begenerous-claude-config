# Agents Claude Code

Conventions pour les agents personnalisés (`~/.claude/agents/`).

## Structure d'un agent

```markdown
---
name: agent-slug
description: Description courte (déclenche l'invocation auto)
tools: ["Read", "Bash", "Grep"]
model: sonnet | opus | haiku
---

# [Titre Agent]

Description du rôle.

## Méthode
[Workflow]

## Format de sortie
[Template]

## Règles
[Contraintes]
```

## Frontmatter

### `name`
- `kebab-case`
- Court, descriptif
- Unique dans `~/.claude/agents/`

### `description`
- Une phrase claire
- Inclure les déclencheurs : "à invoquer pour X", "à utiliser quand Y"
- Claude utilise cette description pour décider d'invoquer l'agent automatiquement

### `tools`
- Liste des outils auxquels l'agent a accès
- Limiter au minimum nécessaire (principe de least privilege)
- Choix : `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `WebFetch`, `WebSearch`, `Task`

### `model`
- `opus` : raisonnement profond, planning, architecture (cher)
- `sonnet` : usage standard (default)
- `haiku` : tâches simples, parallélisables, automatisables (rapide, peu cher)

## Quand créer un agent

### ✅ Bon usage
- Tâche **récurrente** avec processus standardisé (code review, planning)
- Contexte **spécialisé** qui nécessite un prompt long et précis
- Sortie **structurée** (formats définis)
- Délégation possible (l'agent peut être invoqué en background)

### ❌ Mauvais usage
- Tâche **one-off** → écrire le prompt directement
- Contexte qui change à chaque invocation
- Tâche qui nécessite trop de back-and-forth user

## Patterns d'agents

### Reviewer (lecture + analyse)
```yaml
tools: ["Read", "Grep", "Glob", "Bash"]
model: sonnet
```
Exemple : `code-reviewer`, `database-reviewer`

### Planner (raisonnement profond, peu d'exécution)
```yaml
tools: ["Read", "Grep", "Glob", "WebFetch"]
model: opus
```
Exemple : `planner`, `architect`

### Worker (exécute des actions concrètes)
```yaml
tools: ["Read", "Write", "Edit", "Bash"]
model: sonnet
```
Exemple : `e2e-runner`, `build-error-resolver`

### Cleaner (analyse + suggestions, pas de modif sans confirmation)
```yaml
tools: ["Read", "Grep", "Glob", "Bash"]
model: sonnet
```
Exemple : `refactor-cleaner`

## Règles d'écriture du prompt

### ✅ Spécifique
"Tu es un reviewer senior spécialisé Next.js + Supabase."
Pas : "Tu es un assistant utile."

### ✅ Méthode explicite
Lister les étapes en ordre. L'agent suit la méthode.

### ✅ Format de sortie défini
Template markdown ou JSON. L'agent ne doit pas improviser le format.

### ✅ Anti-patterns explicites
"Ne fais JAMAIS X." Plus efficace que "fais Y."

### ❌ Trop long
> 500 lignes de prompt = signal d'alarme. Décomposer en plusieurs agents si nécessaire.

### ❌ Vague
"Sois pertinent" → inutilisable.

## Modèle économique

| Modèle | Use case | Coût relatif |
|---|---|---|
| Opus | Raisonnement complexe, peu d'invocations | 5x |
| Sonnet | Standard, équilibré | 1x |
| Haiku | Tâches simples, hautes fréquences | 0.25x |

→ Pour les agents invoqués souvent (code-reviewer), préférer Sonnet.
→ Pour les agents rarement invoqués mais critiques (architect), Opus est OK.
→ Pour les sub-tasks simples (formatage, parsing), Haiku.

## Configuration globale

```json
// ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

→ Force tous les sub-agents à utiliser Haiku par défaut. Override via frontmatter `model:` si besoin.

## Cohabitation avec slash commands

- **Agent** : invoqué automatiquement OU manuellement (`@code-reviewer review this`)
- **Slash command** : toujours manuel (`/review`)

Si la tâche est :
- Récurrente avec processus → agent
- Action ponctuelle utilisateur → slash command

## Test

```bash
# Tester un agent en standalone
claude --agent code-reviewer "review src/lib/foo.ts"

# Vérifier l'agent dans la liste
claude agents list
```

## Anti-patterns

### ❌ Agent qui fait tout
Mauvais : `dev-helper` qui fait planning + code + review + deploy.
Bon : agents séparés par responsabilité.

### ❌ Tools trop larges
```yaml
tools: ["Read", "Write", "Edit", "Bash", "WebFetch"]
```
Pour un agent qui ne fait que de la review → seuls `Read`, `Grep` suffisent.

### ❌ Pas de format de sortie défini
L'output devient inconsistant entre invocations.

### ❌ Modèle trop puissant pour la tâche
Opus pour formater du JSON → gaspillage. Haiku suffit.
