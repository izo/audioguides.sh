# CLAUDE.md

This file provides guidance for AI assistants working with this codebase.

## Project Overview

**audioguides.sh** is a single-file Bash application for the [Audioguid.es](https://www.audioguid.es) photography project. It provides a terminal-based UI (whiptail) for selecting `.wav` files and decoding tar archives that have been embedded as 1200-baud modem tones inside them.

The entire application lives in `audioguides.sh` (≈230 lines). There is no build system, no test suite, and no package manager — changes are made directly to the script.

## Repository Structure

```
audioguides.sh/
├── audioguides.sh      # The entire application (Bash script)
├── README.md           # User-facing documentation
├── CLAUDE.md           # AI assistant guidelines (this file)
├── LICENSE             # GPL-3.0
├── renovate.json       # Renovate bot config (extends config:base)
├── .gitignore          # Python-flavored ignore rules (legacy)
├── .gitattributes      # LF normalization for text files
└── .github/
    └── FUNDING.yml     # Ko-fi sponsorship: mdrouet
```

## Technical Details

### Language & Runtime

- **Language**: Bash (uses arrays, `mapfile`-style loops, `${var##*/}` etc. — requires Bash 4.0+)
- **Strict mode**: `set -euo pipefail` is enabled at the top of the script
- **Signal handling**: `trap` on `INT`/`TERM` exits cleanly with code 130
- **User-facing language**: All dialog and CLI text is in **French**. Comments are in French.

### Required External Tools

| Tool | Used for |
|------|----------|
| `whiptail` | All UI dialogs (menus, msgbox, yesno, infobox) |
| `minimodem` | Decoding 1200-baud audio modem signal from `.wav` |
| `tar` | Extracting the gzipped tar stream produced by minimodem |
| `mktemp`, `find`, `mv`, `rm`, `ls` | Standard POSIX utilities |

`check_dependencies()` enforces the first three at startup.

### Decoding Pipeline

```
minimodem -r 1200 -f <file.wav> --rx-one  |  tar -C <tmpdir> -xzf -
```

1. `find -maxdepth 1 -type f -name "*.wav" -print0 | sort -z` enumerates WAV files in `work_dir` (non-recursive, sorted).
2. User picks one via `whiptail --menu`.
3. A secure temp dir is created with `mktemp -d "${TMPDIR:-/tmp}/audioguides.XXXXXX"`.
4. The pipeline above runs. On success, contents of the temp dir are moved into `work_dir` with `mv "$extract_dir"/* "$work_dir/"`.
5. Temp dir is always cleaned up via `rm -rf` whether the pipeline succeeds or fails.

### Script Layout (top to bottom)

| Section | Purpose |
|---------|---------|
| Constants | `VERSION`, `SCRIPT_NAME`, `BAUD_RATE` (all `readonly`) |
| `trap` | Handles Ctrl+C / SIGTERM, exits 130 |
| `show_help()` | Prints CLI usage (French) |
| `show_version()` | Prints `<name> version <VERSION>` |
| `check_dependencies()` | Aborts with exit 1 if any tool is missing |
| `NEWT_COLORS` export | Red/white whiptail theme |
| `display_welcome_screen()` | `whiptail --msgbox` welcome |
| `display_disclaimer()` | Project notice |
| `open_local_file()` | Core loop: list → select → confirm → decode → extract |
| `display_contact_info()` | `--yesno` where "Yes" = Quit (exits 0) |
| `display_credits()` | Final credits dialog |
| `main()` | Argument parsing + infinite outer loop |

### CLI Interface

```
Usage: audioguides.sh [OPTIONS] [DIR]

Options:
  -h, --help      Show help and exit
  -v, --version   Show version and exit
  -d, --dir DIR   Directory containing WAV files (default: .)
```

Notes:
- A bare positional argument is also accepted as the working directory (handled by the `*)` case in `main()`'s argument parser); the help text only documents `-d/--dir`.
- Unknown options starting with `-` produce an error and exit 1.
- A non-existent `work_dir` produces an error and exit 1.

### Main Loop Behavior

`main()` runs `while true` over `welcome → disclaimer → open_local_file → contact_info → credits`. The only ways to exit are:
- Selecting "Quitter" in the contact dialog (`exit 0`)
- Sending SIGINT/SIGTERM (Ctrl+C) → trap exits 130
- A startup error (missing dir or dependency) → exit 1

`open_local_file()` itself loops until the user either successfully decodes a file, declines to retry after cancelling, or there are no WAV files in the directory.

### UI Theming

A multi-line `NEWT_COLORS` value is exported before any whiptail call, giving every dialog the project's red/white palette. Do not remove or simplify this block when refactoring — it is the project's visual identity.

### Key Constants

- `VERSION` (currently `1.1.0`) — bump on every user-visible change
- `BAUD_RATE` (`1200`) — must match the encoder used to produce the WAV files
- `SCRIPT_NAME` — derived from `$0` so help text reflects the invoked name

## Development Guidelines

### Running

```bash
chmod +x audioguides.sh
./audioguides.sh                # current directory
./audioguides.sh -d ~/audio     # explicit directory
./audioguides.sh ~/audio        # positional (also works)
./audioguides.sh --help
./audioguides.sh --version
```

### Testing

There is no automated test suite. To validate changes:
1. Run `bash -n audioguides.sh` to syntax-check.
2. Run `shellcheck audioguides.sh` if available — fix or justify every warning.
3. Manually exercise:
   - Empty directory (no WAV files)
   - Directory with one or more valid encoded WAVs
   - A corrupt or non-modem WAV (decode should fail gracefully)
   - Missing one of the three required tools (clear error, exit 1)
   - `-h`, `-v`, unknown flag, non-existent `-d` argument
   - Ctrl+C during the menu and during decoding

### Code Style

- `set -euo pipefail` — keep it; do not weaken error handling.
- No `function` keyword — define functions as `name() { ... }`.
- Always declare function-scoped variables with `local`.
- Constants use `readonly`.
- Quote every variable expansion. Use `"${var}"` and `"$var"` consistently.
- Use `[[ ... ]]` for tests, never `[ ... ]`.
- All user-facing strings stay in **French**.
- Use whiptail for all interaction; reserve `echo` for stderr error output (which goes to the terminal before whiptail starts or after a fatal error).

### When Adding Features

1. Keep the single-file structure — do not split into multiple scripts.
2. Add new behavior as a new function and wire it into `main()` or `open_local_file()`.
3. Preserve the `NEWT_COLORS` block.
4. Use consistent whiptail dimensions (most dialogs are `10 60` or `12 60`).
5. Always extract untrusted archives into `mktemp -d` before moving into `work_dir`.
6. Bump `VERSION` for any user-visible change.
7. Update both `README.md` (English, user-facing) and `CLAUDE.md` (this file) when behavior or CLI surface changes.

### Security Considerations

- The decoded payload is an arbitrary tar archive. Extracting directly into `work_dir` would be a path-traversal risk; the script extracts into a per-invocation `mktemp -d` first and only then moves the result. Keep this two-step pattern.
- All `find` / `mv` / `rm` paths are double-quoted to handle spaces and special characters.
- `minimodem` and `tar` stderr are redirected to `/dev/null` to keep the TUI clean — but the pipeline's exit status (via `pipefail`) is what determines success/failure, so do not silence that.
- Never `eval` user input or filename data.

### Git Workflow

- Default branch: `main`.
- Feature branches follow the pattern `claude/<topic>-<suffix>` (see `git log` for examples).
- Commit messages in this repo are short and may be in French or English; match the surrounding history.
- Open PRs against `main`.

## License

GPL-3.0 (GNU General Public License v3) — see `LICENSE`.

## Author

- **Mathieu Drouet** ([@izo](https://github.com/izo))
- Website: <https://www.audioguid.es>
- Email: mathieu@drouet.io
- Sponsor: [Ko-fi](https://ko-fi.com/U6U621SO3)
