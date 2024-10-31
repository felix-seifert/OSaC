#!/bin/bash

sudo fdisk -l

echo -e "\nDecrypt your Bitlocker disk with Dislocker"

echo "Which disk do you want to decrypt?"
read DISK

echo "What is the password to decrypt your drive?"
read -s PASSWORD

# Create dirs to mount harddrive
sudo mkdir -p /media/bitlocker /media/mount

# Unmount if mounts exists
sudo umount /media/bitlocker 2>/dev/null
sudo umount /media/mount 2>/dev/null

# Decrypt and mount
sudo dislocker -r -V $DISK -u$PASSWORD -- /media/bitlocker
sudo mount -r -o loop /media/bitlocker/dislocker-file /media/mount

echo "Your Bitlocker encrypted disk is decrypted and mounted to /media/mount"
