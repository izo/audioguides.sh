# SPEC.md — audioguides.sh v2

Document de spécification cible pour la prochaine génération d'`audioguides.sh`.
S'applique aux versions `2.x`. La version `1.x` actuelle reste documentée dans `CLAUDE.md` et `README.md`.

> **Statut** : proposition. À valider avec le mainteneur avant implémentation.

---

## 1. Vision

`audioguides.sh` doit passer d'un script de démonstration mono-fichier à un **outil ligne de commande robuste, testé et distribuable**, tout en restant :

- **Un seul fichier exécutable** Bash (zéro étape de build pour l'utilisateur final).
- **Léger** : pas plus de 3 dépendances système obligatoires.
- **Lisible** : un développeur Bash doit comprendre l'intégralité du script en moins de 30 minutes.
- **Fidèle à son identité visuelle** : palette rouge/blanc whiptail (`NEWT_COLORS` préservé).

L'outil reste destiné au projet artistique [Audioguid.es](https://www.audioguid.es). Aucune ambition de devenir un cadre généraliste de stéganographie audio.

---

## 2. Périmètre fonctionnel

### 2.1 Modes d'exécution

| Mode | Déclencheur | Description |
|------|-------------|-------------|
| **Interactif (TUI)** | aucun argument ou `--tui` | Mode actuel, dialogues whiptail. Reste le défaut. |
| **Batch** | `--batch` | Décode tous les `.wav` du répertoire, sans interaction. Sortie sur stdout/stderr. |
| **Single-shot** | `--decode <file.wav>` | Décode un fichier précis et sort. |
| **Dry-run** | `--dry-run` | N'écrit rien sur disque, rapporte ce qui serait fait. Compatible avec les autres modes. |
| **Verbose / quiet** | `-v`, `-q` | Contrôlent la verbosité du logger. |

### 2.2 Décodage

- Baud rate configurable via `--baud <n>` (défaut `1200`, conservé pour la rétrocompatibilité).
- Validation de l'archive **avant extraction** : vérifier la signature gzip + tar (`file -`/magic bytes) sur le flux capturé.
- Limite de taille extraite (`AUDIOGUIDES_MAX_BYTES`, défaut **50 MiB**) pour prévenir les bombes tar.
- Gestion des collisions à l'extraction : `--on-conflict=ask|skip|overwrite|rename` (défaut `ask` en TUI, `skip` en batch).
- Codes de sortie normalisés (cf. §6).

### 2.3 Sortie & journalisation

- **stdout** : réservé aux données structurées (JSON si `--json`, sinon une ligne par fichier décodé).
- **stderr** : logs humains, niveaux `ERROR|WARN|INFO|DEBUG`.
- **TUI** : interaction utilisateur uniquement.
- `--log-file <path>` : duplique les logs vers un fichier.
- Plus de redirection aveugle vers `/dev/null` : les erreurs `minimodem`/`tar` sont capturées et remontées au niveau `DEBUG` (visibles avec `-v`).

### 2.4 Internationalisation

- Français (défaut) **et** anglais.
- Sélection : `--lang fr|en`, sinon détection via `$LANG` (`fr*` ⇒ français, sinon anglais).
- Implémentation : table associative Bash par langue, **dans le même fichier** (pas de fichiers `.po`/gettext).
- Toute nouvelle chaîne doit avoir ses deux variantes ou la PR est refusée.

### 2.5 Configuration

Ordre de précédence (du plus fort au plus faible) :
1. Arguments CLI
2. Variables d'environnement `AUDIOGUIDES_*`
3. Fichier `${XDG_CONFIG_HOME:-$HOME/.config}/audioguides/config`
4. Valeurs par défaut codées en dur

Le fichier de config est un simple sourcing de variables shell (`KEY=value`), pas de parseur INI/YAML.

### 2.6 Compatibilité

- Bash **4.0+** requis (idem v1).
- Plateformes supportées : Linux, macOS. WSL au mieux. **Pas** de support Windows natif.
- Pas de portabilité POSIX `sh` : on assume Bash.

---

## 3. Architecture

### 3.1 Découpage interne

Toujours un seul fichier. À l'intérieur, sections clairement délimitées par des bandeaux de commentaires :

```
============================================================
== Constants & traps
== I18n strings
== Logging
== Config loading
== Argument parsing
== Dependency checks
== Core: decode pipeline
== Core: extraction & conflict resolution
== UI: whiptail wrappers
== UI: screens (welcome, disclaimer, picker, contact, credits)
== Main
============================================================
```

### 3.2 Règles de découpage

- Chaque fonction a **une** responsabilité.
- Les fonctions « cœur » (décodage, extraction, parsing) **ne touchent pas à whiptail**, pour pouvoir être testées en isolation.
- Les fonctions UI **n'effectuent pas** d'I/O fichier directement : elles appellent les fonctions cœur.
- Toute variable mutée par effet de bord est explicitement passée par référence (`local -n`) ou retournée via stdout.

### 3.3 État global toléré

Limité à :
- Constantes `readonly` du haut de fichier.
- `NEWT_COLORS` (export requis par whiptail).
- Tableau `MSG[...]` de l'i18n, peuplé une fois au démarrage.

---

## 4. Qualité & tests

### 4.1 Outillage obligatoire

| Outil | Rôle | Bloquant CI ? |
|-------|------|---------------|
| `bash -n` | Vérification syntaxique | Oui |
| `shellcheck` | Linter Bash | Oui (zéro warning, exceptions justifiées par `# shellcheck disable=...`) |
| `bats-core` | Tests unitaires & intégration | Oui |
| `shfmt` | Formatage | Optionnel mais recommandé |

### 4.2 Couverture cible

- 100 % des fonctions de **parsing** et de **gestion de conflits**.
- Les fonctions de décodage sont testées avec un `minimodem` mocké (PATH override).
- Les écrans whiptail ne sont **pas** testés unitairement (testés manuellement, cf. checklist `CLAUDE.md`).

### 4.3 CI

GitHub Actions, déclenché sur `push` et `pull_request` :
- Matrice : Ubuntu 22.04 + macOS 14.
- Étapes : `shellcheck`, `bash -n`, `bats tests/`.
- Une release est publiée automatiquement quand un tag `v*` est poussé.

---

## 5. Sécurité

| Vecteur | Mitigation |
|---------|------------|
| Path traversal via tar | Extraction dans `mktemp -d`, refus de tout chemin contenant `..`/absolu, puis `mv` contrôlé |
| Tar bomb / disk fill | `AUDIOGUIDES_MAX_BYTES` + `--no-overwrite-dir` |
| Injection shell via nom de fichier | Aucun `eval`. Toutes les expansions de variables quotées |
| Dépendance manquante | `check_dependencies()` en tout début de `main()`, message clair, code 2 |
| Privilèges | L'outil refuse de tourner en `root` sauf `--allow-root` |

---

## 6. Codes de sortie

| Code | Signification |
|------|---------------|
| `0`  | Succès |
| `1`  | Erreur générique (décodage, extraction) |
| `2`  | Erreur d'usage (mauvais argument, flag inconnu) |
| `3`  | Dépendance manquante |
| `4`  | Répertoire ou fichier introuvable |
| `5`  | Conflit non résolu (mode batch) |
| `130`| Interrompu (SIGINT/SIGTERM, conservé) |

Toute valeur non listée est un bug.

---

## 7. Distribution

| Cible | Mécanisme |
|-------|-----------|
| Tarball release | GitHub Releases, signé GPG |
| Homebrew | Formule dans tap dédié `izo/homebrew-audioguides` |
| AUR | `PKGBUILD` maintenu en dépôt séparé |
| Debian | `.deb` produit avec `nfpm` dans la CI release |
| Page man | `audioguides.1` générée depuis `--help` (script `tools/gen-man.sh`) |

Pas de paquet snap/flatpak (overkill pour un script).

---

## 8. Documentation

- `README.md` bilingue (FR + EN), avec capture animée (asciinema) du flux nominal.
- `CHANGELOG.md` au format [Keep a Changelog](https://keepachangelog.com/) + SemVer strict.
- `CONTRIBUTING.md` : style de code, comment lancer les tests, conventions de commit.
- `CLAUDE.md` : maintenu à jour à chaque changement de surface CLI (cf. règle existante).
- Page man installée par les packages.

---

## 9. Non-objectifs (explicitement hors périmètre v2)

- ❌ Réécriture dans un autre langage (Go, Rust, Python).
- ❌ Interface graphique (GTK, Qt, Electron).
- ❌ Mode serveur / API HTTP.
- ❌ Encodeur intégré (la production des `.wav` reste un autre outil).
- ❌ Support de formats audio autres que `.wav` PCM.
- ❌ Cryptographie de bout en bout sur les payloads.

Ces points peuvent être réévalués pour une v3 mais ne doivent pas alourdir la v2.

---

## 10. Critères d'acceptation v2.0.0

La version `2.0.0` peut être taguée quand :

1. Tous les modes du §2.1 fonctionnent.
2. CI verte sur Ubuntu et macOS, suite BATS > 30 tests.
3. `shellcheck` propre.
4. Bilingue FR/EN opérationnel.
5. Au moins **un** canal de distribution (Homebrew **ou** `.deb`) publie automatiquement sur tag.
6. `CHANGELOG.md` documente toutes les ruptures depuis v1.
7. Migration v1→v2 documentée dans le README (rétrocompat des flags principaux).
