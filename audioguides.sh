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

display_welcome_screen() {
	whiptail --title "Welcome" --msgbox "Welcome to the Audio Guides Application. Press 'OK' to continue." 8 60
}

display_disclaimer() {
	disclaimer_text="Audioguid.es est un projet photographique. Plus d'information sur audioguid.es."
	whiptail --title "Disclaimer" --msgbox "$disclaimer_text" 10 60
}

# The open_local_file function allows the user to select a file from the script's directory
# using a whiptail menu. Once the user selects a file and confirms, the function compresses
# the selected file as a ZIP file using the 'zip' command. While the file is being compressed,
# a progress bar is displayed using a whiptail gauge. After the compression is complete,
# a message is shown to inform the user about the successful compression.

open_local_file() {
  files=()
  while IFS= read -r -d $'\0' file; do
	files+=("${file##*/}")
  done < <(find . -maxdepth 1 -type f -print0)

  selected_file=$(whiptail --title "File Selector" --menu "Choose a file:" 15 60 5 "${files[@]}" 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ]; then
	if (whiptail --title "Confirmation" --yesno "You selected '$selected_file'. Press 'Y' to compress it as a ZIP file." 10 60); then
	  echo "Compressing '$selected_file'..."

	  # Get the file size for the progress bar
	  file_size=$(stat -c%s "$selected_file")

	  # Compress the selected file as a ZIP file and display the progress bar
	  (pv -n -s "$file_size" "$selected_file" | zip "${selected_file}.zip" -) 2>&1 | whiptail --gauge "Please wait while the file is being compressed..." 6 50 0

	  # Show a message when the compression is complete
	  whiptail --title "Result" --msgbox "'$selected_file' has been compressed as '${selected_file}.zip'." 8 40
	else
	  echo "User chose not to compress the file."
	fi
  else
	whiptail --title "Result" --msgbox "User canceled the file selection." 8 40
  fi
}


	
display_contact_info() {
	contact_info="Name: Mathieu Drouet \nWebsite: https://www.audioguid.es\nEmail: mathieu@drouet.io"
	whiptail --title "Contact Information" --scrolltext --msgbox "$contact_info" 10 60
}


display_credits() {
	whiptail --title "Credits" --scrolltext --msgbox "Credits:\nThis script was created by Mathieu Drouet.\nSpecial thanks to: \n- Stephane Maguet \n- Meanignful \n- Agathe Vuachet \n- Olivier (DaffyDuke) Duquesne \n- Kamal Mostafa \n- Crumplepop \n- Robert Klebe \n- Mike Kohn" 17 60
}

# Replace while loop with main_menu function
main_menu() {
  while true; do
	action=$(whiptail --title "Main Menu" --menu "Choose an action:" 16 60 4 \
	  "1" "Display a disclaimer" \
	  "2" "Open a local file" \
	  "3" "Display contact information" \
	  "4" "Display credits" \
	  3>&1 1>&2 2>&3)

	exit_status=$?
	if [ $exit_status -eq 0 ]; then
	  case $action in
		1)
		  display_disclaimer
		  ;;
		2)
		  open_local_file
		  ;;
		3)
		  display_contact_info
		  ;;
		4)
		  display_credits
		  ;;
	  esac
	else
	  exit 0
	fi
  done
}

display_welcome_screen
main_menu