#!/bin/bash

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

# Function to display a welcome screen
function display_welcome_screen() {
  whiptail --title "Welcome" --msgbox "Welcome to the Audio Guides Application. Press 'OK' to continue." 8 60
}

# Function to display a disclaimer
function display_disclaimer() {
  local disclaimer_text="Audioguid.es est un projet photographique. Plus d'information sur audioguid.es."
  whiptail --title "Disclaimer" --msgbox "$disclaimer_text" 10 60
}

# Function to select a .wav file from the script's directory and execute a custom command
function open_local_file() {
  while true; do
    local files=()
    local i=0
    while IFS= read -r -d $'\0' file; do
      files+=("$((++i))" "${file##*/}")
    done < <(find . -maxdepth 1 -type f -name "*.wav" -print0)

    # Check if there are any .wav files before attempting to display them in a menu
    if [ ${#files[@]} -eq 0 ]; then
      whiptail --title "No Files" --msgbox "There are no .wav files in the current directory." 10 60
      break
    fi

    local selected_file_index=$(whiptail --title "File Selector" --menu "Choose a file:" 15 60 5 "${files[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
      local selected_file=${files[2*$selected_file_index-1]}
      if (whiptail --title "Confirmation" --yesno "You selected '$selected_file'. Press 'Y' to execute the command." 10 60); then
        echo "Executing command on '$selected_file'..."

        # Execute the command and check its result
        if (minimodem -r 1200 -f "$selected_file" --rx-one | tar -C ./ -xzvf -); then
          # Show a message when the execution is complete
          whiptail --title "Result" --msgbox "Command executed on '$selected_file'." 8 40
          break
        else
          whiptail --title "Error" --msgbox "Failed to execute command on '$selected_file'." 8 40
        fi
      else
        echo "User chose not to execute the command."
      fi
    else
      if (whiptail --title "File selection" --yesno "No file selected. Would you like to try again?" 8 40); then
        continue
      else
        break
      fi
    fi
  done
}

# Function to display contact information
function display_contact_info() {
  local contact_info="Name: Mathieu Drouet \nWebsite: https://www.audioguid.es\nEmail: mathieu@drouet.io"
  whiptail --title "Contact Information" --yesno "$contact_info" --no-button "Continue" --yes-button "Quit" 10 60
  if [ $? -eq 0 ]; then
    exit 1
  fi
}

# Function to display credits
function display_credits() {
  local credits="Crédits : \nMathieu Drouet\nhttps://www.audioguid.es"
  whiptail --title "Credits" --msgbox "$credits" 10 60
}

# Main script loop. This will continue to run the script until the user chooses to quit
while true; do
  display_welcome_screen
  display_disclaimer
  open_local_file
  display_contact_info
  display_credits
done
