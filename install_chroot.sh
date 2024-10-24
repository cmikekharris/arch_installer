#!/bin/bash

uefi=$(cat /var_uefi); hd=$(cat /var_hd);

cat /comp > /etc/hostname && rm /comp

pacman -S --noconfirm dialog

pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
    pacman -S --noconfirm efibootmgr
    grub-install --target=x86_64-efi \
        --bootloader-id=GRUB \
        --efi-directory=/boot/efi
else
    grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Set hardware clock from system clock
hwclock --systohc

# To list the timezones: `timedatectl list-timezones`
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# You can run `cat /etc/locale.gen` to see all the locales available
cp /etc/locale.gen /etc/locale.gen_all
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Keyboard layout
printf "KEYMAP=uk\n" > /etc/vconsole.conf
printf "XKBLAYOUT=gb\n" >> /etc/vconsole.conf
printf "XKBMODEL=pc105\n" >> /etc/vconsole.conf
printf "XKBOPTIONS=terminate:ctrl_alt_bksp\n" >> /etc/vconsole.conf

# No argument: ask for a username.
# One argument: use the username passed as argument.
function config_user() {
    if [ -z "$1" ]; then
        dialog --no-cancel --inputbox "Please enter your username." \
            10 60 2> name
    else
        echo "$1" > name
    fi
    dialog --no-cancel --passwordbox "Enter your password." \
        10 60 2> pass1
    dialog --no-cancel --passwordbox "Confirm your password." \
        10 60 2> pass2
    while [ "$(cat pass1)" != "$(cat pass2)" ]
    do
        dialog --no-cancel --passwordbox \
            "Passwords do not match.\n\nEnter password again." \
            10 60 2> pass1
        dialog --no-cancel --passwordbox \
            "Retype your password." \
            10 60 2> pass2
    done

    name=$(cat name) && rm name
    pass1=$(cat pass1) && rm pass1 pass2

    # Create user if doesn't exist
    if [[ ! "$(id -u "$name" 2> /dev/null)" ]]; then
        dialog --infobox "Adding user $name..." 4 50
        useradd -m -g wheel -s /bin/bash "$name"
    fi

    # Add password to user
    echo "$name:$pass1" | chpasswd
}

dialog --title "root password" \
    --msgbox "It's time to add a password for the root user" \
    10 60
config_user root

dialog --title "Add User" \
    --msgbox "Let's create another user." \
    10 60
config_user

# Save your username for the next script.
echo "$name" > /tmp/user_name

# Ask to install all your apps / dotfiles.
dialog --title "Continue installation" --yesno \
"Do you want to install all your apps and your dotfiles?" \
10 60 \
&& curl https://raw.githubusercontent.com/cmikekharris\
/arch_installer/master/install_apps.sh > /tmp/install_apps.sh \
&& bash /tmp/install_apps.sh
