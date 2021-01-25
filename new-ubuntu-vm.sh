#!/usr/bin/env bash

# Based on: https://medium.com/@yping88/use-ubuntu-server-20-04-cloud-image-to-create-a-kvm-virtual-machine-with-fixed-network-properties-62ecae025f6c

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
    # Used http://shapecatcher.com/ to get the unicode
    printf "$YELLOW \u2799 $NC %1s \n" "$GREEN $1 $NC"
}

function printTitle() {
    echo
    # Used http://shapecatcher.com/ to get the unicode
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

# Generate random MAC to use
# For KVM VMs it is required that the first 3 pairs in the MAC address be the sequence 52:54:00:
printTitle "generating random KVM MAC address"
export MAC_ADDR=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
showDone

printTitle "Please enter the needed info below:"

printYellow "Hostname of your new vm: "
read -p "" HOST
printYellow "Number of vCPUs: "
read -p "" VCPU
printYellow "Amount of ram (MB): "
read -p "" RAM
printYellow "Disk size (GB): "
read -p "" DISKGB
printYellow "Username: "
read -p "" USERID

# export HOST=test2
export DOM=mylo
export IMAGE_FLDR="/var/lib/libvirt/images"
export WRK_FLDR="/home/dustin/kvm/base"
# Go to work dir
cd ${WRK_FLDR}

printTitle "creating disk"
# Create the disk
sudo qemu-img create -F qcow2 -b ${WRK_FLDR}/focal-server-cloudimg-amd64.img -f qcow2 ${IMAGE_FLDR}/${HOST}.qcow2 ${DISKGB}G
showDone

printTitle "creating network-config"
# Config network with cloud-init
cat >network-config <<EOFN
ethernets:
    all:
        dhcp4: true
        match:
            name: en*
        nameservers:
            search: [mylo]
            addresses:
            - 10.0.0.33
version: 2

EOFN
showDone

# Main cloud-init

# ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}'

printTitle "creating user-data"
cat >user-data <<EOFU
#cloud-config

## Set Hostname
hostname: ${HOST}
fqdn: ${HOST}.${DOM}
manage_etc_hosts: true

# Enable password authentication with the SSH daemon
ssh_pwauth: true
disable_root: false

## Install additional packages on first boot
packages:
- zsh
- curl
- tmux
- vim-nox
- qemu-guest-agent

users:
  - name: ${USERID}
    gecos: ${USERID}
    primary_group: ${USERID}
    groups: users, admin, sudo
    shell: /usr/bin/zsh
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1ukcZU9jVoqmn9+acVwExfw24vAZ53HyQh3VT9aXRYKhLbfMOU2tvRlgIX+znOE4Uc3goFhRB/Qes/NchS6IQf2lfbHBUXoVtzl2gxMfMh49lecoYsv24NtnBLw9QGv/HfhqBR/8ZZbI3vE2XPEEyJDZDTl96iimX/DvxIjRoFowQtfhe4S5zYK7Km6RMEOCWLEt7FApIs1oezylUgGb4k0SAJTOWUT9It8j0BX7ydvPlvKWrJQsVpgw54iyDNj9GiM8qNIt/ziWEAmFj/sqW80lngkXyDJymyan31ijlDvoksEQY+e7BqzA+6IEu0QUCD55NO8ewaRZFTtUTGLIxND/FIR/jir0II0Qnoq4iJWIWls/2G51cKUjc0nkdD+qjXcdaHVJj/1mMxAq7iUWj9RPkKWllYKIV6m1vZV9rBWY++O8JBeSZKofIydNDyUUyx+YCmSOICDYQ2Y0H2W10b+K08OlFeHzzrppePnCN5xw8VlDbhxDLxREJ6t6lYwi1cWOMZ6pj4yJ3i+HcsJVw7V8IB+/QVKmD8SWNi3Ez6He9Thhq4HiqnKOA2FvakClQUZHOuCtT9HQbSOn+30oeF2WHZugpnEaH8hTx1yyyrSzPncc+QbYsxs49w1AREOjZIRUbY5dR4ljx7WxII735yGPCELPBoZIvre/rAr4Jw== dustin@bashfulrobot.com
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
# Set user password
chpasswd:
    list: |
        ${USERID}:${USERID}
    expire: false
## Update apt database and upgrade packages on first boot
package_update: true
package_upgrade: true

runcmd:
 - [ systemctl, start, qemu-guest-agent ]

# written to /var/log/cloud-init-output.log in VM
final_message: "W00T, We should be up and ready after $UPTIME seconds at $TIMESTAMP"
EOFU
showDone

# Create meta-data
printTitle "creating meta-data"
touch meta-data
showDone

# Create seed image
# Adding network-config causes logins to not work
printTitle "creating seed image"
sudo cloud-localds -v --network-config=network-config ${IMAGE_FLDR}/${HOST}-seed.qcow2 user-data meta-data
showDone

# Ensure images have the proper permissions
printTitle "fixing permissions"
sudo chown -R libvirt-qemu:kvm ${IMAGE_FLDR}
showDone

# Create VM
printTitle "creating vm"
sudo virt-install --virt-type kvm --name ${HOST} --ram ${RAM} --vcpus=${VCPU} --os-type linux --os-variant ubuntu20.04 --disk path=${IMAGE_FLDR}/${HOST}.qcow2,device=disk --disk path=${IMAGE_FLDR}/${HOST}-seed.qcow2,device=disk --graphics=vnc --import --network bridge=br0,model=virtio,mac=${MAC_ADDR} --noautoconsole
showDone

printTitle "cleaning up"
sudo rm -f ${WRK_FLDR}/network-config
sudo rm -f ${WRK_FLDR}/user-data
sudo rm -f ${WRK_FLDR}/meta-data
showDone

printGreen "success! vm has been deployed."
