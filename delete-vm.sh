#!/usr/bin/env bash

# Set Colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
TEAL=$(tput setaf 14)
NC=$(tput sgr0)

# Define script dependencies
# neededSoftware=(git ansible)

# # Check if software is installed and install with APT if needed
# function checkInstalled() {
#     dpkg -s "$1" 2>/dev/null >/dev/null || sudo apt -y install "$1"
# }

function printYellow() {
    # Used http://shapecatcher.com/ to get the unicode
    printf "$GREEN \u2799 $NC %1s \n" "$YELLOW $1 $NC"
}

function printGreen() {
    printf "$YELLOW \u2799 $NC %1s \n" "$GREEN $1 $NC"
}

function showTitle() {
    echo
    printf "$TEAL \u232a\u232a\u232a $NC %1s \n" "$TEAL $1 $NC"
    echo
}

function showDone() {
    printf "$GREEN \u2713  %1s\n" "Done $NC"
}

function showFail() {
    printf "$RED \u2694 %1s \n" "Failed $NC"
    exit 1
}

clear

# What VMs exist?
#sudo virsh list --all

if [ $# -eq 0 ]; then
    showTitle "It looks like you did not include a VM name."
    echo "If you do not know the VM name, run the command:"
    echo
    printYellow "virsh list --all"
    echo
    echo "Please include the vm as an argument."
    echo
    showFail
    exit 1
fi

showTitle "Getting ready to delete vm"

printGreen "THIS WILL DELETE ALL ASSOCIATED VM STORAGE!!!"
read -p "Press [ENTER] to continue, or [Ctrl-C] to exit."
echo

virsh undefine --domain ${1} --delete-snapshots --remove-all-storage

exit 0
