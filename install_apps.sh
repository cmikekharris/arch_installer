#!/bin/bash

name=$(cat /tmp/user_name)

apps_path="/tmp/apps.csv"

curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_bluetooth.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_core.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_fish.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_git.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_i3.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_neovim.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_network.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_notifier.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_terminal.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_tmux.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_tools.csv >> $apps_path
curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/apps/apps_web_browsers.csv >> $apps_path

dialog --title "Welcome!" \
--msgbox "Welcome to the install script for your apps and dotfiles!" \
    10 60

# Allow the user to select the group of packages he (or she) wants to install.
apps=(
  "bluetooth" "BlueTooth" on
  "core" "Core" on
  "fish" "Fish" on
  "git" "Git" on
  "i3" "i3 Window Manager" on
  "neovim" "Neovim" on
  "network" "Network" on
  "notifier" "Notifier" on
  "terminal" "Terminal" on
  "tmux" "Tmux" on
  "tools" "Tools" on
  "web_browsers" "Web Browsers" on
)

dialog --checklist \
"You can now choose what group of applications you want to install. \n\n\
You can select an option with SPACE and submit your choices with ENTER." \
0 0 0 \
"${apps[@]}" 2> app_choices
choices=$(cat app_choices) && rm app_choices

# Create a regex to only select the packages we want
selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

pacman -Syu --noconfirm

rm -f /tmp/aur_queue

dialog --title "Let's go!" --msgbox \
"The system will now install everything you need.\n\n\
It will take some time.\n\n " \
13 60

c=0
echo "$packages" | while read -r line; do
    c=$(( "$c" + 1 ))

    dialog --title "Arch Linux Installation" --infobox \
    "Downloading and installing program $c out of $count: $line..." \
    8 70

    ((pacman --noconfirm --needed -S "$line" > /tmp/arch_install 2>&1) \
    || echo "$line" >> /tmp/aur_queue) \
    || echo "$line" >> /tmp/arch_install_failed
done

# Set default terminal for the user
#    chsh -s "$(which zsh)" "$name"
chsh -s "$(which fish)" "$name"

# Enable network manager
systemctl enable NetworkManager.service

# Enable bluetooth
systemctl enable bluetooth.service

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

curl https://raw.githubusercontent.com/cmikekharris/arch_installer/master/install_user.sh > /tmp/install_user.sh;

# Switch user and run the final script
sudo -u "$name" sh /tmp/install_user.sh
