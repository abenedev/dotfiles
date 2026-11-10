#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [--noapps] [--minimal] [--help]"
    echo
    echo "Options:"
    echo "  --noapps   Skip the installation of desktop applications."
    echo "  --minimal         Skip the installation of both desktop environment packages (Hyprland) and desktop applications."
    echo "  --help            Display this help message."
    exit 0
}

# Parse arguments
INSTALL_DESKTOP_ENV=true
INSTALL_APPS=true

for arg in "$@"; do
    case $arg in
        --noapps)
            INSTALL_APPS=false
            ;;
        --minimal)
            INSTALL_DESKTOP_ENV=false
            INSTALL_APPS=false
            ;;
        --help)
            usage
            ;;
        *)
            echo "Invalid option: $arg"
            usage
            ;;
    esac
    shift
done

# Replace the Neovim config, keeping the previous one as a timestamped backup
install_nvim_config() {
    echo "Setting up Neovim..."
    mkdir -p ~/.config
    if [ -d ~/.config/nvim ]; then
        mv ~/.config/nvim ~/.config/nvim.bak."$(date +%s)"
    fi
    cp -r home/user/.config/nvim ~/.config
}

# WSL (Ubuntu): the Arch packages, services & desktop below don't apply.
# Neovim itself isn't installed here: the apt version is too old for LazyVim.
if command -v apt-get > /dev/null; then
    echo "Installing Neovim dependencies..."
    sudo apt-get update
    sudo apt-get install -y ripgrep fd-find
    # Ubuntu names the binary fdfind; nvim pickers look for fd
    mkdir -p ~/.local/bin
    ln -sf "$(command -v fdfind)" ~/.local/bin/fd
    install_nvim_config
    echo "Done."
    exit 0
fi

echo "Installing Yay..."
sudo pacman -Syu --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin
yay -Y --gendb --noconfirm
yay -Syu --devel --noconfirm
yay -Y --devel --save --noconfirm
yay -Fy --noconfirm

echo "Configuring mirrors..."
yay -S --needed --noconfirm reflector
sudo cp etc/xdg/reflector/reflector.conf /etc/xdg/reflector
sudo systemctl start reflector.service
sudo systemctl enable --now reflector.timer

echo "Clearing Neovim plugins & state..."
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim
install_nvim_config

echo "Installing minimal packages..."
minimal_packages=(
    bluez
    bluez-utils
    btop
    eza  # Blazing fast `ls`
    fd  # Fast `find`, used by nvim pickers
    fzf  # Zoxide auto-completion dependency
    gcc
    github-cli
    gnome-keyring  # Secret service (gh token, Brave)
    less  # Pager with Vim keys
    libsecret
    make
    megacmd
    neofetch
    neovim
    powertop  # Power usage analysis
    ripgrep
    tlp  # Battery power saving
    tree
    unzip
    vim
    wget
    zoxide  # Blazing fast `cd`
    zsh
    zsh-completions
)
yay -Syu --needed --noconfirm "${minimal_packages[@]}"

echo "Setting up bluetooth..."
sudo systemctl enable --now bluetooth.service

echo "Setting up power saving..."
sudo mkdir -p /etc/tlp.d
sudo cp etc/tlp.d/01-battery.conf /etc/tlp.d
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
sudo systemctl enable --now tlp.service
sudo tlp start
# Start these on demand instead of at boot (docker.socket still starts docker when needed)
sudo systemctl disable docker.service containerd.service

echo "Setting up Zsh..."
chsh -s /usr/bin/zsh

echo "Setting up Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp home/user/.zshrc ~/
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "Setting up GPG & SSH..."
mkdir -p ~/.gnupg ~/.ssh ~/.local/bin
chmod 700 ~/.gnupg ~/.ssh
cp home/user/.gnupg/gpg-agent.conf ~/.gnupg
cp home/user/.local/bin/pinentry-wayland.sh ~/.local/bin
cp home/user/.ssh/config ~/.ssh
gpgconf --kill gpg-agent
systemctl --user enable --now ssh-agent.socket
echo "Unlocking gnome-keyring on TTY login (the keyring must use your login password)..."
grep -q pam_gnome_keyring /etc/pam.d/login || sudo sed -i \
    -e '/^auth .*system-local-login/a auth       optional     pam_gnome_keyring.so' \
    -e '/^session .*system-local-login/a session    optional     pam_gnome_keyring.so auto_start' \
    /etc/pam.d/login

echo "Setting up Claude Code settings, hooks & skills..."
mkdir -p ~/.claude/skills ~/.claude/hooks
cp -r home/user/.claude/skills/commit-and-push ~/.claude/skills
cp home/user/.claude/settings.json home/user/.claude/statusline-command.sh ~/.claude
cp home/user/.claude/hooks/notify.sh ~/.claude/hooks

echo "Setting up Vim..."
cp home/user/.vimrc ~
cp -r home/user/.vim ~

echo "Setting up KEEBD Corne keyboard rules..."
sudo cp -r etc/udev /etc
sudo udevadm control --reload
sudo udevadm trigger

if [ "$INSTALL_DESKTOP_ENV" = true ]; then
    echo "Installing desktop environment packages..."
    desktop_environment_packages=(
        alacritty
        brightnessctl
        dunst  # Notifications manager
        libnotify  # notify-send, used by the Claude Code notification hook
        evince  # PDF viewer
        hypridle  # Idle management daemon
        hyprland
        hyprlock  # Lock screen
        hyprpaper  # Wallpaper manager
        hyprshot  # Screenshot tool
        hyprsunset  # Blue light filter
        jq  # For volume control
        nautilus  # File explorer
        noto-fonts-emoji
        pamixer  # For volume control
        parallel  # For volume control
        ttf-jetbrains-mono-nerd
        uwsm  # Universal Wayland Session Manager
        vlc
        waybar
        wl-clipboard  # Clipboard for Neovim
        wofi  # Application launcher
    )
    yay -Syu --needed --noconfirm "${desktop_environment_packages[@]}"

    echo "Copying wallpapers..."
    mkdir -p ~/Pictures
    cp -r home/user/Pictures/Wallpapers ~/Pictures

    echo "Installing fonts..."
    sudo cp -r usr/share/fonts /usr/share
    fc-cache

    echo "Setting up Alacritty..."
    cp -r home/user/.config/alacritty ~/.config

    echo "Setting up Hyprland..."
    cp -r home/user/.config/hypr ~/.config
    cp -r home/user/.local/bin ~/.local
    mkdir -p ~/.local/share/themes
    cp -r home/user/.local/share/themes/Adwaita-dark ~/.local/share/themes

    echo "Setting up Dunst..."
    cp -r home/user/.config/dunst ~/.config

    echo "Setting up Gnome theme..."
    sudo cp gnome-shell-theme.gresource /usr/share/gnome-shell

    echo "Setting up Powerlevel10k..."
    cp home/user/.p10k.zsh ~
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

    echo "Setting up UWSM..."
    cp -r home/user/.config/uwsm ~/.config

    echo "Setting up Waybar..."
    cp -r home/user/.config/waybar ~/.config

    echo "Setting up Wofi..."
    cp -r home/user/.config/wofi ~/.config
fi

if [ "$INSTALL_APPS" = true ]; then
    echo "Installing desktop applications packages..."
    apps_packages=(
        blueman
        ecosia-browser-bin
        discord
        gimp
        signal-desktop
    )
    yay -Syu --needed --noconfirm "${apps_packages[@]}"

    echo "Fixing scaling for Electron apps..."
    cp home/user/.local/share/applications ~/.local/share
fi

echo "Done."
