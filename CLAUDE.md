# CLAUDE.md

This file provides guidance for AI assistants working with this codebase.

## Project Overview

**audioguides.sh** is a Bash script application for the [Audioguid.es](https://www.audioguid.es) photography project. It provides a terminal-based UI for selecting and decoding data embedded in WAV audio files using modem tones.

## Repository Structure

```
audioguides.sh/
├── audioguides.sh      # Main Bash script (the entire application)
├── README.md           # User documentation
├── CLAUDE.md           # AI assistant guidelines (this file)
├── LICENSE             # GPL-3.0 license
├── renovate.json       # Renovate bot configuration
├── .gitignore          # Git ignore rules
├── .gitattributes      # Git attributes
└── .github/
    └── FUNDING.yml     # GitHub sponsorship configuration (Ko-fi: mdrouet)
```

## Technical Details

### Language & Dependencies

- **Language**: Bash shell script (requires Bash 4.0+)
- **Required utilities**:
  - `whiptail` - TUI dialog boxes for user interaction
  - `minimodem` - Decodes audio modem signals from WAV files
  - `tar` - Extracts archives from decoded data

### How It Works

The script decodes data hidden in audio files:
1. Scans specified directory for `.wav` files
2. User selects a file via whiptail menu
3. Runs: `minimodem -r 1200 -f <file> --rx-one | tar -C <temp_dir> -xzf -`
   - Receives 1200 baud modem data from the audio file
   - Extracts to a secure temporary directory first
   - Moves extracted files to working directory on success

### Script Structure

The main script contains these functions:

| Function | Purpose |
|----------|---------|
| `show_help()` | Displays CLI usage information |
| `show_version()` | Shows version number |
| `check_dependencies()` | Verifies required tools are installed |
| `display_welcome_screen()` | Shows welcome message |
| `display_disclaimer()` | Displays project disclaimer |
| `open_local_file()` | Core file selection and processing loop |
| `display_contact_info()` | Shows contact info with quit option |
| `display_credits()` | Displays project credits |
| `main()` | Entry point with CLI argument parsing |

### CLI Options

```
Usage: audioguides.sh [OPTIONS]

Options:
  -h, --help      Show help message
  -v, --version   Show version number
  -d, --dir DIR   Specify directory containing WAV files (default: current directory)
```

### UI Theming

Custom whiptail colors are defined via `NEWT_COLORS` environment variable with a red/white theme.

### Key Constants

- `VERSION` - Current script version
- `BAUD_RATE` - Modem baud rate (1200)

## Development Guidelines

### Running the Script

```bash
chmod +x audioguides.sh
./audioguides.sh              # Run in current directory
./audioguides.sh -d ~/audio   # Run in specified directory
./audioguides.sh --help       # Show help
```

### Testing

- Requires `.wav` files with embedded modem data
- Test with actual minimodem-encoded audio files
- Test error cases: missing files, corrupt data, missing dependencies

### Code Style Conventions

- Use `set -euo pipefail` for strict error handling
- Use Bash functions for modularity (no `function` keyword)
- Use `local` keyword for function-scoped variables
- Use `readonly` for constants
- Use whiptail for all user interaction (no raw echo for UI)
- Handle errors with user-friendly dialog messages
- All user-facing text should be in French

### Making Changes

When modifying this script:
1. Maintain the existing function structure
2. Preserve the custom color scheme in `NEWT_COLORS`
3. Keep whiptail dialogs consistent in size/style
4. Handle edge cases (e.g., no WAV files found, invalid directory)
5. Test with both successful and failed command execution paths
6. Use secure temporary directories for file extraction
7. Update version number in `VERSION` constant

### Security Considerations

- Tar extraction uses a temporary directory to prevent path traversal attacks
- File paths are properly quoted to handle special characters
- Dependency checks prevent unclear error messages

## License

This project is licensed under **GPL-3.0** (GNU General Public License v3).

## Author

- **Mathieu Drouet** ([@izo](https://github.com/izo))
- Website: https://www.audioguid.es
- Email: mathieu@drouet.io
