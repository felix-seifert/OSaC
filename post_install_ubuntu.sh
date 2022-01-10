#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

read -p "Did you already set up the internet connection? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


##### Manual Todos #####
# * Set DE and US keyboard
# * Adjust gnome-tweaks
# * Add CPU and RAM percentage to top bar (see gnome-tweaks > extensions > system-monitor
# * Add email accounts, signatures and PGP
# * Add Browser extensions for KeePassXC (install from within application) and for Mendeley


adjust_system_settings() {
	echo "Turn off automatic brightness"
	gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

	echo "Set screen blanking in seconds"
	gsettings set org.gnome.desktop.session idle-delay 600

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
	echo "file:///home/felix-seifert/GitHub" >> ~/.config/gtk-3.0/bookmarks
	mkdir -p ~/Dropbox/KTH
	echo "file:///home/felix-seifert/Dropbox/KTH" >> ~/.config/gtk-3.0/bookmarks
}


add_repositories() {
	echo "Add software repositories"
	# Repository for Microsoft fonts
	sudo add-apt-repository multiverse
	# Repository for gnome-tweaks
	sudo add-apt-repository universe
	# Repository for GitHub desktop (might not work because too many requests, PackageCloud)
	wget -qO - https://packagecloud.io/shiftkey/desktop/gpgkey | sudo tee /etc/apt/trusted.gpg.d/shiftkey-desktop.asc > /dev/null
	sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/shiftkey/desktop/any/ any main" > /etc/apt/sources.list.d/packagecloud-shiftkey-desktop.list'
	# Repository for OpenJDK
	sudo add-apt-repository -y ppa:openjdk-r/ppa
	# Repository for Spotify
	curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
	# Repository for Vagrant
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
}


install_apt_apps() {
	echo "Upgrade system"
	sudo apt update && sudo apt upgrade -y

	echo "Install fonts"
	sudo apt install -y ttf-mscorefonts-installer
	sudo fc-cache -f -v

	echo "Install apt apps"
	sudo apt install  -y \
		vim \
		curl \
		jq \
		less \
		tree \
		htop \
		mlocate \
		dislocker \
		gnome-tweaks \
		gnome-shell-extension \
		gnome-shell-extension-system-monitor \
		virtualbox \
		vagrant \
		keepassxc \
		vlc \
		gimp \
		filezilla \
		pdftk \
		xournal \
		pdfarranger \
		calibre \
		spotify-client \
		git \
		github-desktop
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


install_docker() {
        echo "Install Docker and Docker Compose"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh ./get-docker.sh

        # Install Docker Compose directly from website (consider to update)
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
}


set_terminal() {
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
	sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose)/' ~/.zshrc

	source ~/.zshrc

	# Copy config for Terminator
	cat <<- END> ~/.config/terminator/config
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


install_java() {
        echo "Install several Java versions and jEnv"

        sudo apt install -y \
                openjdk-11-jdk \
                openjdk-17-jdk
        # Download current GraalVM version (consider to update)
        wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.3.0/graalvm-ce-java17-linux-amd64-21.3.0.tar.gz
        sudo tar -xvzf graalvm-ce-java17-linux-amd64-21.3.0.tar.gz

        # Install and initialise jEnv
        git clone https://github.com/jenv/jenv.git ~/.jenv
        echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(jenv init -)"' >> ~/.zshrc
        source ~/.zshrc
        jenv add /usr/lib/jvm/java-17-openjdk-amd64
        jenv add /usr/lib/jvm/java-11-openjdk-amd64
        jenv add /usr/lib/jvm/graalvm-ce-java17-21.3.0
        jenv enable-plugin export
        jenv global graalvm64-17.0.1

	# Install native-image function of GraalVM
        gu install native-image
}


install_maven() {
	echo "Install package manager Maven"

        # Install Maven directly (consider to update)
        wget https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
        sudo tar xf apache-maven-3.8.4-bin.tar.gz -C /opt

	# Create script to set Maven environment variables
        cat <<- END> /etc/profile.d/maven.sh
        export MAVEN_HOME=/opt/apache-maven-3.8.4
        export M3_HOME=/opt/apache-maven-3.8.4
        export PATH=/opt/apache-maven-3.8.4/bin:${PATH}
        END
        sudo chmod +x /etc/profile.d/maven.sh
        source /etc/profile.d/maven.sh
}


set_dev_env() {
	echo "Set up development environment"

	install_java
	install_maven

	echo "Install IntelliJ IDEA from snap to receive updates"
	sudo snap install intellij-idea-ultimate --classic
}


install_meeting_software() {
	echo "Install meeting software"
	# Automatically download latest version of Zoom
	wget https://zoom.us/client/latest/zoom_amd64.deb
	sudo apt install -y ./zoom_amd64.deb

	echo "Install Google Chrome for MS Teams"
	# Automatically download latest version of Chrome
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	sudo dpkg -i google-chrome-stable_current_amd64.deb
}


set_us_and_german_keyboard() {
	cat << END> /etc/default/keyboard
	XKBLAYOUT=us,de
	XKBVARIANT=,
	BACKSPACE=guess
	END
}


install_dropbox() {
	echo "Install Dropbox"
	cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
	~/.dropbox-dist/dropboxd
}


adjust_remaining_settings() {
	echo "Set favorite apps in dock"
	# Execute `gsettings get org.gnome.shell favorite-apps` to get existing favourites
	gsettings set org.gnome.shell favorite-apps "['thunderbird.desktop', 'firefox.desktop', 'org.gnome.Nautilus.desktop', 'terminator.desktop', 'github-desktop.desktop']"

	echo "Lock screen when lid is closed"
	echo "HandleLidSwitch=lock" | sudo tee -a /etc/systemd/logind.conf > /dev/null
}


adjust_system_settings
adjust_folder_structure
install_apt_apps
configure_git
set_terminal
set_dev_env
install_meeting_software
# For now, set several keyboards manually under Settings > Region & Language > Add Input Source
# set_us_and_german_keyboard
install_dropbox
adjust_remaining_settings


echo "Please restart session through logout and login"
