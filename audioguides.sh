#!/bin/bash
#
# audioguides.sh - Application Audio Guides pour le projet Audioguid.es
# Décode les données embarquées dans des fichiers WAV via des signaux modem
#
# Auteur: Mathieu Drouet <mathieu@drouet.io>
# Site: https://www.audioguid.es
# Licence: GPL-3.0
#

set -euo pipefail

readonly VERSION="1.1.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly BAUD_RATE=1200

# Gestion propre de l'interruption (Ctrl+C)
trap 'echo ""; echo "Interrupted."; exit 130' INT TERM

# Affiche l'aide
show_help() {
  cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Application Audio Guides - Décode les données embarquées dans des fichiers WAV.

Options:
  -h, --help      Affiche cette aide
  -v, --version   Affiche la version
  -d, --dir DIR   Répertoire contenant les fichiers WAV (défaut: répertoire courant)

Dépendances requises:
  - whiptail   Interface utilisateur TUI
  - minimodem  Décodage des signaux modem audio
  - tar        Extraction des archives

Exemples:
  $SCRIPT_NAME                  Lance l'application dans le répertoire courant
  $SCRIPT_NAME -d ~/audioguides Lance l'application dans ~/audioguides

EOF
}

# Affiche la version
show_version() {
  echo "$SCRIPT_NAME version $VERSION"
}

# Vérifie que les dépendances sont installées
check_dependencies() {
  local missing=()
  for cmd in whiptail minimodem tar; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Erreur: Dépendances manquantes: ${missing[*]}" >&2
    echo "Installez-les avant de continuer." >&2
    exit 1
  fi
}

# Define custom colors for whiptail
export NEWT_COLORS='
root=white,red
border=red,white
window=red,white
shadow=black,gray
title=red,white
button=white,red
actbutton=white,red
compactbutton=white,red
checkbox=white,red
actcheckbox=white,red
entry=black,lightgray
disentry=gray,red
label=black,red
listbox=white,red
actlistbox=white,red
sellistbox=red,white
actsellistbox=red,white
textbox=red,white
acttextbox=white,red
emptyscale=,red
fullscale=,red
helpline=red,white
roottext=red,white
'

# Affiche l'écran d'accueil
display_welcome_screen() {
  whiptail --title "Bienvenue" --msgbox "Bienvenue dans l'application Audio Guides.\n\nAppuyez sur 'OK' pour continuer." 10 60
}

# Affiche l'avertissement
display_disclaimer() {
  local disclaimer_text="Audioguid.es est un projet photographique.\n\nPlus d'informations sur https://www.audioguid.es"
  whiptail --title "Avertissement" --msgbox "$disclaimer_text" 10 60
}

# Sélectionne un fichier .wav et exécute le décodage
open_local_file() {
  local work_dir="${1:-.}"

  while true; do
    # Construire le tableau des fichiers WAV
    local filenames=()
    local menu_items=()
    local i=0

    while IFS= read -r -d $'\0' file; do
      local basename="${file##*/}"
      filenames+=("$basename")
      menu_items+=("$((++i))" "$basename")
    done < <(find "$work_dir" -maxdepth 1 -type f -name "*.wav" -print0 | sort -z)

    # Vérifier s'il y a des fichiers WAV
    if [[ ${#filenames[@]} -eq 0 ]]; then
      whiptail --title "Aucun fichier" --msgbox "Aucun fichier .wav trouvé dans:\n$work_dir" 10 60
      break
    fi

    # Afficher le menu de sélection
    local selected_index
    if ! selected_index=$(whiptail --title "Sélection de fichier" --menu "Choisissez un fichier audio:" 15 60 5 "${menu_items[@]}" 3>&1 1>&2 2>&3); then
      if whiptail --title "Sélection annulée" --yesno "Aucun fichier sélectionné.\n\nVoulez-vous réessayer?" 10 50; then
        continue
      else
        break
      fi
    fi

    # Récupérer le nom du fichier sélectionné
    local selected_file="${filenames[$((selected_index - 1))]}"
    local full_path="$work_dir/$selected_file"

    if whiptail --title "Confirmation" --yesno "Fichier sélectionné:\n$selected_file\n\nVoulez-vous décoder ce fichier?" 12 60; then
      # Créer un répertoire temporaire sécurisé pour l'extraction
      local extract_dir
      extract_dir=$(mktemp -d "${TMPDIR:-/tmp}/audioguides.XXXXXX")

      whiptail --title "Traitement" --infobox "Décodage en cours...\n\nFichier: $selected_file" 8 50

      # Exécuter le décodage avec extraction sécurisée
      if minimodem -r "$BAUD_RATE" -f "$full_path" --rx-one 2>/dev/null | tar -C "$extract_dir" -xzf - 2>/dev/null; then
        # Déplacer les fichiers extraits vers le répertoire de travail
        if [[ -n "$(ls -A "$extract_dir" 2>/dev/null)" ]]; then
          mv "$extract_dir"/* "$work_dir/" 2>/dev/null || true
          whiptail --title "Succès" --msgbox "Décodage réussi!\n\nLes fichiers ont été extraits dans:\n$work_dir" 12 50
        else
          whiptail --title "Attention" --msgbox "Le décodage s'est terminé mais aucun fichier n'a été extrait." 10 50
        fi
        rm -rf "$extract_dir"
        break
      else
        rm -rf "$extract_dir"
        whiptail --title "Erreur" --msgbox "Échec du décodage du fichier:\n$selected_file\n\nVérifiez que le fichier contient des données valides." 12 50
      fi
    fi
  done
}

# Affiche les informations de contact
display_contact_info() {
  local contact_info="Nom: Mathieu Drouet\nSite: https://www.audioguid.es\nEmail: mathieu@drouet.io"
  if whiptail --title "Contact" --yesno "$contact_info" --no-button "Continuer" --yes-button "Quitter" 10 60; then
    exit 0
  fi
}

# Affiche les crédits
display_credits() {
  local credits="Crédits:\n\nMathieu Drouet\nhttps://www.audioguid.es\n\nVersion $VERSION"
  whiptail --title "Crédits" --msgbox "$credits" 12 60
}

# Fonction principale
main() {
  local work_dir="."

  # Analyse des arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--version)
        show_version
        exit 0
        ;;
      -d|--dir)
        if [[ -z "${2:-}" ]]; then
          echo "Erreur: L'option $1 nécessite un argument." >&2
          exit 1
        fi
        work_dir="$2"
        shift 2
        ;;
      -*)
        echo "Erreur: Option inconnue: $1" >&2
        echo "Utilisez --help pour voir les options disponibles." >&2
        exit 1
        ;;
      *)
        work_dir="$1"
        shift
        ;;
    esac
  done

  # Vérifier que le répertoire existe
  if [[ ! -d "$work_dir" ]]; then
    echo "Erreur: Le répertoire '$work_dir' n'existe pas." >&2
    exit 1
  fi

  # Vérifier les dépendances
  check_dependencies

  # Boucle principale
  while true; do
    display_welcome_screen
    display_disclaimer
    open_local_file "$work_dir"
    display_contact_info
    display_credits
  done
}

# Point d'entrée
main "$@"
