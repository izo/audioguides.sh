# CLAUDE.md

This file provides guidance for AI assistants working with this codebase.

## Project Overview

**audioguides.sh** is a Bash script application for the [Audioguid.es](https://www.audioguid.es) photography project. It provides a terminal-based UI for selecting and decoding data embedded in WAV audio files using modem tones.

## Repository Structure

```
audioguides.sh/
├── audioguides.sh      # Main Bash script (the entire application)
├── README.md           # User documentation
├── LICENSE             # GPL-3.0 license
├── renovate.json       # Renovate bot configuration
├── .gitignore          # Git ignore rules (Python-focused, likely template)
├── .gitattributes      # Git attributes
└── .github/
    └── FUNDING.yml     # GitHub sponsorship configuration (Ko-fi: mdrouet)
```

## Technical Details

### Language & Dependencies

- **Language**: Bash shell script
- **Required utilities**:
  - `whiptail` - TUI dialog boxes for user interaction
  - `minimodem` - Decodes audio modem signals from WAV files
  - `tar` - Extracts archives from decoded data

### How It Works

The script decodes data hidden in audio files:
1. Scans current directory for `.wav` files
2. User selects a file via whiptail menu
3. Runs: `minimodem -r 1200 -f <file> --rx-one | tar -C ./ -xzvf -`
   - Receives 1200 baud modem data from the audio file
   - Pipes to tar for extraction

### Script Structure

The main script contains these functions:

| Function | Purpose |
|----------|---------|
| `display_welcome_screen()` | Shows welcome message |
| `display_disclaimer()` | Displays project disclaimer |
| `open_local_file()` | Core file selection and processing loop |
| `display_contact_info()` | Shows contact info with quit option |
| `display_credits()` | Displays project credits |

The script runs in an infinite loop through these functions until the user quits.

### UI Theming

Custom whiptail colors are defined via `NEWT_COLORS` environment variable with a red/white theme.

## Development Guidelines

### Running the Script

```bash
chmod +x audioguides.sh
./audioguides.sh
```

### Testing

- Requires `.wav` files with embedded modem data in the current directory
- Test with actual minimodem-encoded audio files

### Code Style Conventions

- Use Bash functions for modularity
- Use `local` keyword for function-scoped variables
- Use whiptail for all user interaction
- Handle errors with user-friendly dialog messages

### Making Changes

When modifying this script:
1. Maintain the existing function structure
2. Preserve the custom color scheme in `NEWT_COLORS`
3. Keep whiptail dialogs consistent in size/style
4. Handle edge cases (e.g., no WAV files found)
5. Test with both successful and failed command execution paths

## License

This project is licensed under **GPL-3.0** (GNU General Public License v3).

## Author

- **Mathieu Drouet** ([@izo](https://github.com/izo))
- Website: https://www.audioguid.es
- Email: mathieu@drouet.io
