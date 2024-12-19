#!/usr/bin/env bash

# Main purpose of this script is automating Arch/Arch-Based Linux post installation

# --- Define colors for better readability ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

# --- Log file setup ---
LOG_FILE="post_install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

# --- Package lists ---
required_tools=("base-devel" "git" "curl" "htop")
development_tools=("kate" "meld" "ranger" "vim" "kwrite" "obsidian" "gnome-boxes" "distrobox" "podman")
entertainment_tools=("spotify-launcher" "ffmpeg" "obs-studio" "steam")
docker_packages=("docker" "docker-compose")
flatpak_packages=("org.prismlauncher.PrismLauncher" "dev.vencord.Vesktop")
distrobox_containers=("debian docker.io/library/debian:stable-backports" "kali docker.io/kalilinux/kali-rolling:latest" "fedora quay.io/fedora/fedora:40")

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

function bspwm_setup() {
    print_message "Installing BSPWM using ArchCraft BSPWM..."
    git clone https://github.com/archcraft-os/archcraft-bspwm.git || {
        print_error "Failed to clone BSPWM repository"
        exit 1
    }
    cd archcraft-bspwm || exit
    sudo chmod +x build.sh
    ./build.sh || print_error "Failed to build and install BSPWM"
    cd ..
    rm -rf archcraft-bspwm
    print_message "BSPWM installation completed!"
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
print_message "Updating the system..."
sudo pacman -Syu --noconfirm || {
    print_error "Failed to update the system"
    exit 1
}

install_with_pacman "${required_tools[@]}"

# Enable Multilib repository
print_message "Enabling Multilib repository (if not already enabled)..."
if ! grep -q "[multilib]" /etc/pacman.conf; then
    sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Syy
fi

# Install AUR Helper (yay)
print_message "Installing yay (AUR helper)..."
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

# Install Flatpak
print_message "Installing Flatpak..."
sudo pacman -S --noconfirm flatpak || {
    print_error "Failed to install Flatpak"
    exit 1
}
print_message "Adding Flathub repository for Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Desktop environment setup
print_message "Do you want to install a desktop environment (BSPWM)? [y/N]"
read -r install_de
if [[ $install_de == "y" || $install_de == "Y" ]]; then
    bspwm_setup
fi

install_with_pacman "${development_tools[@]}"
install_with_yay "${docker_packages[@]}"
install_with_pacman "${entertainment_tools[@]}"
install_with_flatpak "${flatpak_packages[@]}"

# Create Distrobox containers
create_distrobox_containers

# Configure Git
print_message "Configuring Git..."
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email
git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global core.editor "vim"

# install Brave
curl -fsS https://dl.brave.com/install.sh | sh

# Remove Firefox
remove_firefox

# Cleanup
print_message "Cleaning up unused packages and cache..."
sudo pacman -Rns $(pacman -Qdtq) --noconfirm
sudo pacman -Sc --noconfirm

# Finishing message
print_message "Post-installation tasks completed! You may want to reboot your system."
