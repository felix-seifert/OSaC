#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

read -p "Did you already set up the WiFi connection? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

read -p "Did you already connect to your Nextcloud instance? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


adjust_system_settings() {
	echo "Turn off automatic brightness"
	gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

	echo "Change to dark mode"
	gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"

	echo "Set keyboard shortcuts"
	gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Control><Alt>w']"
	gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Control><Alt>f']"
	gsettings set org.gnome.settings-daemon.plugins.media-keys email "['<Control><Alt>e']"
	gsettings set org.gnome.settings-daemon.plugins.media-keys calculator "['<Control><Alt>c']"
}


adjust_folder_structure() {
	echo "Adjust folder structure"
	mkdir ~/GitHub
	echo "file://home/felix-seifert/GitHub" >> ~/.config/gtk-3.0/bookmarks
	# Symlink to Nextcloud (check location)
	ln -s /run/user/1000/gvfs/dav:host=gohfert.duckdns.org,ssl=true,user=felix-seifert,prefix=%2Fremote.php%2Fwebdav ~/Nextcloud
}


add_repositories() {
	echo "Add software repositories"
	# Repository for Microsoft fonts
	sudo add-apt-repository multiverse
	# Repository for GitHub desktop (might not work because too many requests, PackageCloud)
	wget -qO - https://packagecloud.io/shiftkey/desktop/gpgkey | sudo tee /etc/apt/trusted.gpg.d/shiftkey-desktop.asc > /dev/null
	sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/shiftkey/desktop/any/ any main" > /etc/apt/sources.list.d/packagecloud-shiftkey-desktop.list'
}


install_apt_apps() {
	echo "Upgrade system"
	sudo apt update && sudo apt upgrade -y

	echo "Install fonts"
	sudo apt install -y ttf-mscorefonts-installer
	sudo fc-cache -f -v

	echo "Install basic apps"
	sudo apt install  -y \
		vim \
		curl \
		jq \
		less \
		tree \
		htop \
		mlocate \
		dislocker \
		github-desktop \
		git
	# Load latest .deb for github-desktop from https://github.com/shiftkey/desktop/releases if not available
}


configure_git() {
	echo "Configure Git"

	echo "Enter global Git username: "
	read GIT_USER
	git config --global user.name "${GIT_USER}"

	echo "Enter global Git email address: "
	read GIT_EMAIL
	git config --global user.email "${GIT_EMAIL}"
}


set_up_terminal() {
	echo "Set up terminal"
	sudo apt install -y \
		terminator \
		zsh

	# Make zsh standard shell
	chsh -s $(which zsh)

	# Instal omz via curl
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	omz theme set agnoster
	sudo apt install -y powerline fonts-powerline

	# Download plugins
	git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
	# Add plugins by replacing standard plugins in .zshrc
	sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

	source ~/.zshrc

	# Copy config for Terminator
	cat <<- END > ~/.config/terminator/config
        [global_config]
        [keybindings]
        [profiles]
          [[default]]
            background_color = "#300a24"
            cursor_color = "#aaaaaa"
            foreground_color = "#ffffff"
            show_titlebar = False
            scrollback_lines = 1000
            copy_on_selection = True
        [layouts]
          [[default]]
            [[[window0]]]
              type = Window
              parent = ""
            [[[child1]]]
              type = Terminal
              parent = window0
        [plugins]
        END
}


set_us_and_german_keyboard() {
	cat << END > /etc/default/keyboard
	XKBLAYOUT=us,de
	XKBVARIANT=,
	BACKSPACE=guess
	END
}


adjust_remaining_settings() {
	echo "Set favorite apps in dock"
	# Execute `gsettings get org.gnome.shell favorite-apps` to get existing favourites
	gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'terminator.desktop', 'github-desktop.desktop']"

	echo "Lock screen when lid is closed"
	echo "HandleLidSwitch=lock" | sudo tee -a /etc/systemd/logind.conf > /dev/null
}


adjust_system_settings
adjust_folder_structure
install_apt_apps
configure_git
set_up_terminal
# For now, set several keyboards manually under Settings > Region & Language > Add Input Source
# set_us_and_german_keyboard
adjust_remaining_settings


echo "Please restart session through logout and login"
