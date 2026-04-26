# TODO.md — Roadmap audioguides.sh v2

Plan d'exécution de la spec décrite dans [`SPEC.md`](./SPEC.md).
Organisé en **phases ordonnées** : ne pas démarrer la phase N+1 avant que la phase N soit verte en CI.

Légende : `[ ]` à faire · `[~]` en cours · `[x]` fait · `(L/M/H)` effort estimé (Low ≤ ½j, Medium ≤ 2j, High > 2j).

---

## Phase 0 — Fondations (avant toute autre chose)

Objectif : pouvoir refactoriser sans risque.

- [ ] **(L)** Nettoyer `.gitignore` : retirer les artefacts Python hérités, garder uniquement ce qui est pertinent à un projet Bash (`*.swp`, `.DS_Store`, `tests/tmp/`).
- [ ] **(L)** Ajouter `.editorconfig` (LF, indent 2 espaces, charset utf-8, final newline).
- [ ] **(L)** Ajouter `.shellcheckrc` à la racine (severity=style, disable explicite si besoin).
- [ ] **(M)** Mettre en place GitHub Actions `.github/workflows/ci.yml` :
  - matrice `ubuntu-22.04` + `macos-14`
  - étapes : `bash -n`, `shellcheck`, `bats tests/` (squelette vide accepté pour démarrer)
- [ ] **(L)** Créer `CHANGELOG.md` initial avec section `[Unreleased]`.
- [ ] **(L)** Adopter [Conventional Commits](https://www.conventionalcommits.org/) pour les nouvelles PR (documenté dans un futur `CONTRIBUTING.md`).

**Critère de sortie** : un PR vide passe la CI verte sur Ubuntu et macOS.

---

## Phase 1 — Refactor pour la testabilité

Objectif : isoler la logique métier de l'UI whiptail.

- [ ] **(M)** Extraire le pipeline de décodage dans `decode_wav <file> <out_dir>` qui ne contient **aucun** appel whiptail.
- [ ] **(M)** Extraire la résolution de conflits à l'extraction dans `move_with_conflict_policy <src_dir> <dst_dir> <policy>`.
- [ ] **(M)** Extraire le parsing des arguments dans `parse_args` qui peuple un tableau associatif `OPTS[...]`.
- [ ] **(L)** Déplacer les chaînes en français dans un tableau `MSG[...]` (préparation §3 de la spec).
- [ ] **(M)** Premier batch BATS dans `tests/` :
  - `--help` sort sur stdout, code 0
  - `--version` affiche la version
  - flag inconnu → code 2
  - répertoire inexistant → code 4
- [ ] **(L)** Documenter la nouvelle structure dans `CLAUDE.md` (section « Script Layout »).

**Critère de sortie** : ≥ 8 tests BATS verts, comportement utilisateur inchangé.

---

## Phase 2 — Robustesse

Objectif : ne plus rien avaler en silence.

- [ ] **(M)** Implémenter un logger `log <level> <msg>` qui respecte `--quiet`/`--verbose`/`--log-file`.
- [ ] **(M)** Ne plus rediriger `stderr` de `minimodem`/`tar` vers `/dev/null` ; les capturer dans un fichier temporaire et les remonter au niveau `DEBUG` (visible avec `-v`), `ERROR` en cas d'échec du pipeline.
- [ ] **(M)** Validation du flux décodé avant extraction : tester les magic bytes (gzip `1f 8b`) sur un buffer en tête de pipe avant `tar`.
- [ ] **(M)** Implémenter `--on-conflict=ask|skip|overwrite|rename`.
  - `ask` en TUI : nouveau dialogue par fichier en conflit.
  - `skip` par défaut en batch.
- [ ] **(M)** Limite de taille extraite via `AUDIOGUIDES_MAX_BYTES` (défaut 50 MiB), abandon propre + log si dépassée.
- [ ] **(L)** Refus du run en `root` sauf `--allow-root`.
- [ ] **(L)** Codes de sortie alignés sur §6 de la spec (table dans le README).

**Critère de sortie** : tests BATS pour chaque code de sortie + un test de tar bomb (archive > limite ⇒ refus).

---

## Phase 3 — Nouvelles fonctionnalités

Objectif : sortir du « tout TUI ».

- [ ] **(H)** Mode `--batch` : itère sur tous les `.wav` du répertoire, sortie d'une ligne par fichier (`OK <file>` ou `FAIL <file> <reason>`).
- [ ] **(M)** Mode `--decode <file>` : décodage single-shot sans menu.
- [ ] **(M)** Mode `--dry-run` compatible avec batch et single-shot.
- [ ] **(M)** Mode `--json` : sortie structurée pour scripting.
- [ ] **(M)** `--baud <n>` exposé en CLI, validé contre une liste blanche `300|1200|2400`.
- [ ] **(H)** Internationalisation FR/EN :
  - extraire 100 % des chaînes vers `MSG[...]`
  - `--lang fr|en` + détection `$LANG`
  - tests BATS : `LANG=fr_FR.UTF-8 ./audioguides.sh --help` vs `LANG=en_US.UTF-8 ./audioguides.sh --help`
- [ ] **(M)** Chargement du fichier de config `~/.config/audioguides/config` avec précédence définie (§2.5 de la spec).
- [ ] **(L)** Refonte du dialogue de contact : remplacer le bouton « Quitter = Oui » contre-intuitif par un menu explicite à 3 entrées (Continuer / Quitter / À propos).

**Critère de sortie** : démos asciinema enregistrées pour chaque mode.

---

## Phase 4 — Distribution

Objectif : `brew install audioguides` doit marcher.

- [ ] **(M)** Workflow `.github/workflows/release.yml` déclenché sur tag `v*` :
  - build d'un tarball
  - signature GPG
  - publication GitHub Release avec changelog extrait de `CHANGELOG.md`
- [ ] **(H)** Tap Homebrew `izo/homebrew-audioguides` avec formule auto-bumpée par la CI.
- [ ] **(M)** `PKGBUILD` AUR (dépôt séparé, push manuel acceptable).
- [ ] **(M)** Génération `.deb` via `nfpm` dans la CI release.
- [ ] **(M)** Page man `audioguides.1` générée depuis `--help` par `tools/gen-man.sh`.
- [ ] **(L)** Script d'installation `curl https://audioguid.es/install.sh | bash` (à héberger sur le site).

**Critère de sortie** : un utilisateur peut installer la dernière version sans cloner le repo.

---

## Phase 5 — Documentation & polissage

- [ ] **(M)** README bilingue (FR + EN), table des matières, capture animée asciinema du flux nominal.
- [ ] **(L)** `CONTRIBUTING.md` : style, tests, commits, processus PR.
- [ ] **(L)** `SECURITY.md` : politique de signalement, limites connues.
- [ ] **(L)** Mise à jour finale de `CLAUDE.md` (sections CLI, layout, codes de sortie, i18n).
- [ ] **(L)** Page de démo en ligne avec un `.wav` exemple téléchargeable.
- [ ] **(L)** Tag `v2.0.0` + annonce.

---

## Backlog / questions ouvertes

À trier avec le mainteneur — pas planifié.

- [ ] Fournir un **encodeur** intégré (`audioguides --encode <dir> <out.wav>`) ou rester strictement décodeur ?
- [ ] Support d'un **format d'archive autre** que `tar.gz` (zip ? bare files ?) — utile ou complexité inutile ?
- [ ] **Détection automatique** du baud rate via essais successifs ?
- [ ] **Signature crypto** des payloads (GPG/minisign) avant extraction ?
- [ ] Mode **TUI alternatif** avec `dialog` ou `gum` (rendu plus moderne) — risque sur l'identité visuelle.
- [ ] Variante **GUI** (zenity) pour double-clic file managers ?
- [ ] **Telemetry opt-in** anonyme pour comprendre l'usage ?
- [ ] Migration vers **`bash` strict mode étendu** (`shopt -s inherit_errexit`, `lastpipe`) — gain réel à mesurer.

---

## Dette technique observée (v1)

Notes prises en lisant `audioguides.sh` actuellement, à régler pendant les phases 1–2 :

- Ligne 146 : `2>/dev/null` sur `minimodem` **et** `tar` masque toute information de diagnostic.
- Ligne 149 : `mv "$extract_dir"/* "$work_dir/"` peut **écraser silencieusement** des fichiers existants dans `work_dir` (cf. politique de conflits Phase 2).
- Ligne 167 : le yes/no du dialogue contact a `--yes-button "Quitter"` — UX trompeuse, à revoir Phase 3.
- Ligne 223 : la boucle `while true` du `main` rend impossible la sortie « propre » sans passer par le dialogue contact ; c'est un choix volontaire mais à documenter.
- `.gitignore` actuel est un boilerplate Python sans aucun rapport avec le projet.
