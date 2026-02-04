#!/bin/bash

#######################################
# Pterodactyl Blueprint Installer
# Author: kiruthik123
# Description: Install Blueprint addons from GitHub repository
#######################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script variables
SCRIPT_VERSION="1.0.0"
PTERODACTYL_DIR="/var/www/pterodactyl"
GITHUB_USER="kiruthik123"
GITHUB_REPO="addons-"  # Your repository name from the image
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# Addon list from your repository (corrected names from the image)
ADDONS=(
    "activitypugress.blueprint"
    "console.logs.blueprint"
    "huregister.blueprint"
    "brawelogs.blueprint"
    "lydynamous.blueprint"
    "mcdogs.blueprint"
    "modrinthbrowser.blueprint"
    "nighthawk.in.blueprint"
    "resources.lints.blueprint"
    "resource.manager.blueprint"
    "serverbackgrounds.blueprint"
    "showmodels.blueprint"
    "sim.pfefooters.blueprint"
    "transitions.blueprint"
    "urldownloader.blueprint"
    "votifilter.blueprint"
)

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

check_pterodactyl() {
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        print_error "Pterodactyl not found at $PTERODACTYL_DIR"
        exit 1
    fi
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint framework not found!"
        print_info "Please install Blueprint first:"
        print_info "1. Go to your Pterodactyl panel"
        print_info "2. Navigate to Admin > Blueprint"
        print_info "3. Install the framework"
        exit 1
    fi
}

download_addon() {
    local addon="$1"
    local url="${BASE_URL}/${addon}"
    local output="/tmp/${addon}"
    
    print_info "Downloading ${addon}..."
    
    if curl -s -f -L "$url" -o "$output"; then
        print_success "Downloaded ${addon}"
        return 0
    else
        print_error "Failed to download ${addon}"
        return 1
    fi
}

install_addon() {
    local addon="$1"
    
    # Download the addon
    if ! download_addon "$addon"; then
        return 1
    fi
    
    # Navigate to Pterodactyl directory
    cd "$PTERODACTYL_DIR" || return 1
    
    # Install using blueprint.sh
    if [ -f "/tmp/${addon}" ]; then
        print_info "Installing ${addon}..."
        if bash .blueprint/blueprint.sh -i "/tmp/${addon}"; then
            print_success "Installed ${addon}"
            rm -f "/tmp/${addon}"
            return 0
        else
            print_error "Failed to install ${addon}"
            return 1
        fi
    fi
    
    return 1
}

list_addons() {
    echo -e "${CYAN}Available Blueprint Addons:${NC}"
    echo ""
    local i=1
    for addon in "${ADDONS[@]}"; do
        echo -e "${GREEN}${i}.${NC} ${addon}"
        ((i++))
    done
    echo ""
}

install_single() {
    list_addons
    
    read -p "Enter addon number (or 0 to cancel): " choice
    
    if [[ "$choice" == "0" ]]; then
        return
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ADDONS[@]}" ]; then
        local index=$((choice-1))
        local selected_addon="${ADDONS[$index]}"
        
        echo ""
        print_info "Selected: ${selected_addon}"
        
        install_addon "$selected_addon"
        
        if [ $? -eq 0 ]; then
            print_success "Installation completed!"
            print_info "Please check your Pterodactyl panel for the new addon."
        fi
    else
        print_error "Invalid selection!"
    fi
}

install_all() {
    echo -e "${PURPLE}Installing all Blueprint addons...${NC}"
    echo ""
    
    local success=0
    local failed=0
    
    for addon in "${ADDONS[@]}"; do
        echo -e "${CYAN}────────────────────────────────────${NC}"
        if install_addon "$addon"; then
            ((success++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}Successfully installed: ${success}${NC}"
    echo -e "${RED}Failed to install: ${failed}${NC}"
    echo -e "${CYAN}Total addons: ${#ADDONS[@]}${NC}"
    echo ""
}

show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    Pterodactyl Blueprint Addon Manager ║${NC}"
    echo -e "${CYAN}║        GitHub: kiruthik123/addons-     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} List all available addons"
    echo -e "${GREEN}2.${NC} Install single addon"
    echo -e "${GREEN}3.${NC} Install all addons"
    echo -e "${GREEN}4.${NC} Check Blueprint installation"
    echo -e "${GREEN}0.${NC} Exit"
    echo ""
}

check_blueprint() {
    echo -e "${CYAN}Blueprint Framework Check:${NC}"
    echo ""
    
    if [ -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_success "Blueprint framework is installed"
        if [ -f "$PTERODACTYL_DIR/.blueprint/blueprint.sh" ]; then
            print_success "Blueprint script is available"
        else
            print_error "Blueprint script not found!"
        fi
    else
        print_error "Blueprint framework not installed!"
        print_info "Please install Blueprint first from your Pterodactyl panel."
    fi
    
    echo ""
    print_info "Pterodactyl directory: $PTERODACTYL_DIR"
    print_info "Total addons available: ${#ADDONS[@]}"
}

main() {
    check_root
    check_pterodactyl
    
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                clear
                list_addons
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            2)
                clear
                install_single
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            3)
                clear
                install_all
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            4)
                clear
                check_blueprint
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            0)
                echo ""
                print_info "Thank you for using Blueprint Addon Manager!"
                exit 0
                ;;
            *)
                print_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Run the main function
main
