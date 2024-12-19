#!/usr/bin/env bash

# Main purpose of this script is automating Arch/Arch-Based Linux post installation
# WARNING: don't RUN script on root user, yay installation will be interrupted due to makepkg

# --- Define colors for better readability ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

# --- Log file setup ---
LOG_FILE="post_install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

# --- Package lists ---
required_tools=(
    "base-devel"
    "archcraft-bspwm"
    "git"
    "curl"
    "htop"
    "flatpak"
)
development_tools=(
    "kate"
    "meld"
    "ranger"
    "vim"
    "kwrite"
    "obsidian"
    "gnome-boxes"
    "distrobox"
    "podman"
)
entertainment_tools=(
    "spotify-launcher"
    "ffmpeg"
    "obs-studio"
    "steam"
)
docker_packages=(
    "docker"
    "docker-compose"
)
flatpak_packages=(
    "org.prismlauncher.PrismLauncher"
    "dev.vencord.Vesktop"
)
distrobox_containers=(
    "debian docker.io/library/debian:stable-backports"
    "kali docker.io/kalilinux/kali-rolling:latest"
    "fedora quay.io/fedora/fedora:40"
)

# --- Function definitions ---
function print_message() {
    echo -e "${GREEN}==>${NC} $1"
}

function print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function confirm_action() {
    read -p "$1 (y/n): " choice
    case "$choice" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *)
        echo "Invalid input. Please enter 'y' or 'n'."
        confirm_action "$1"
        ;;
    esac
}

function install_with_pacman() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        print_message "Installing $package with pacman..."
        sudo pacman -S --noconfirm "$package" || {
            print_error "Failed to install $package with pacman"
            exit 1
        }
    done
}

function install_with_yay() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        print_message "Installing $package with yay..."
        yay -S --noconfirm "$package" || {
            print_error "Failed to install $package with yay"
            exit 1
        }
    done
}

function install_with_flatpak() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        print_message "Installing $package with Flatpak..."
        flatpak install -y flathub "$package" || {
            print_error "Failed to install $package with Flatpak"
            exit 1
        }
    done
}

function multilib_setup() {
    if ! grep -q "[multilib]" /etc/pacman.conf; then
        sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
        sudo pacman -Syy
    fi
}

function aur_setup() {
    if ! command -v yay &>/dev/null; then
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit
        makepkg -si --noconfirm || {
            print_error "Failed to install yay"
            exit 1
        }
        cd ..
        rm -rf yay
    fi
}

function config_setup() {
    cd dotfiles || {
        print_error "Dotfiles directory not found"
        exit 1
    }
    sudo chmod +x build.sh
    ./build.sh
}

function create_distrobox_containers() {
    for container in "${distrobox_containers[@]}"; do
        local name=$(echo "$container" | awk '{print $1}')
        local image=$(echo "$container" | awk '{print $2}')
        print_message "Creating Distrobox container: $name with image: $image"
        distrobox-create --nvidia --name "$name" --image "$image" || print_warning "Failed to create container: $name"
    done
}

function remove_firefox() {
    print_message "Checking if Firefox is installed..."
    if pacman -Qi firefox &>/dev/null; then
        print_message "Firefox is installed. Proceeding with removal..."
        sudo pacman -Rns --noconfirm firefox
        rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/firefox ~/.local/share/firefox
        sudo rm -rf /usr/lib/firefox /usr/lib/mozilla
        print_message "Firefox and related files have been removed!"
    else
        print_message "Firefox is not installed. Skipping removal."
    fi
}

# --- Main script execution ---
if confirm_action "Update the system?"; then
    print_message "Updating the system..."
    sudo pacman -Syu --noconfirm || {
        print_error "Failed to update the system"
        exit 1
    }
fi

if confirm_action "Install required tools?"; then
    install_with_pacman "${required_tools[@]}"
fi

if confirm_action "Enable Multilib repository?"; then
    print_message "Enabling Multilib repository (if not already enabled)..."
    multilib_setup
fi

if confirm_action "Install yay (AUR helper)?"; then
    print_message "Installing yay (AUR helper)..."
    aur_setup
fi

if confirm_action "Configure Flatpak?"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if confirm_action "Setup desktop environment?"; then
    config_setup
fi

if confirm_action "Install development tools?"; then
    install_with_pacman "${development_tools[@]}"
fi

if confirm_action "Install Docker packages?"; then
    install_with_yay "${docker_packages[@]}"
fi

if confirm_action "Install entertainment tools?"; then
    install_with_pacman "${entertainment_tools[@]}"
fi

if confirm_action "Install Flatpak packages?"; then
    install_with_flatpak "${flatpak_packages[@]}"
fi

if confirm_action "Create Distrobox containers?"; then
    create_distrobox_containers
fi

if confirm_action "Configure Git?"; then
    print_message "Configuring Git..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global core.editor "vim"
fi

if confirm_action "Install Brave browser?"; then
    curl -fsS https://dl.brave.com/install.sh | sh
fi

if confirm_action "Remove Firefox?"; then
    remove_firefox
fi

if confirm_action "Clean up unused packages and cache?"; then
    print_message "Cleaning up unused packages and cache..."
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
    sudo pacman -Sc --noconfirm
fi

print_message "Post-installation tasks completed! You may want to reboot your system."
