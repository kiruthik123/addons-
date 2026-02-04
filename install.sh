#!/bin/bash

#######################################
# Pterodactyl Blueprint Addon Installer
# Author: kiruthik123
# Description: Install Blueprint addons from kiruthik123/addons- repository
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
GITHUB_REPO="addons-"
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

# Function to print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_header() { echo -e "${CYAN}$1${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        echo "Please run with: sudo $0"
        exit 1
    fi
}

check_pterodactyl() {
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        print_error "Pterodactyl directory not found at: $PTERODACTYL_DIR"
        return 1
    fi
    return 0
}

check_blueprint() {
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint framework not found!"
        print_info "Blueprint must be installed first through Pterodactyl panel."
        return 1
    fi
    
    if [ ! -f "$PTERODACTYL_DIR/.blueprint/blueprint.sh" ]; then
        print_error "Blueprint script not found!"
        return 1
    fi
    
    return 0
}

check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        print_error "No internet connection detected!"
        return 1
    fi
    return 0
}

download_addon() {
    local addon="$1"
    local url="${BASE_URL}/${addon}"
    local output="/tmp/${addon}"
    
    print_info "Downloading: $addon"
    
    # Try wget first, then curl
    if command -v wget > /dev/null 2>&1; then
        if wget -q --timeout=10 --tries=2 "$url" -O "$output"; then
            return 0
        fi
    fi
    
    if command -v curl > /dev/null 2>&1; then
        if curl -s -f -L "$url" -o "$output"; then
            return 0
        fi
    fi
    
    print_error "Failed to download: $addon"
    return 1
}

install_addon() {
    local addon="$1"
    
    if ! download_addon "$addon"; then
        return 1
    fi
    
    # Check if blueprint is available
    if ! check_blueprint; then
        print_error "Cannot install addons. Blueprint framework not available."
        return 1
    fi
    
    cd "$PTERODACTYL_DIR" || {
        print_error "Cannot access Pterodactyl directory"
        return 1
    }
    
    print_info "Installing: $addon"
    
    if [ -f "/tmp/$addon" ]; then
        if bash .blueprint/blueprint.sh -i "/tmp/$addon" 2>/dev/null; then
            print_success "Successfully installed: $addon"
            rm -f "/tmp/$addon"
            return 0
        else
            print_error "Blueprint installation failed for: $addon"
            print_info "You can try installing it manually from the Pterodactyl panel"
            return 1
        fi
    else
        print_error "Addon file not found: /tmp/$addon"
        return 1
    fi
}

list_addons() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Available Blueprint Addons         ║${NC}"
    echo -e "${CYAN}║        (Total: ${#ADDONS[@]} addons)          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    local i=1
    for addon in "${ADDONS[@]}"; do
        printf "${GREEN}%2d.${NC} %s\n" "$i" "$addon"
        ((i++))
    done
    
    echo ""
}

install_single_addon() {
    list_addons
    
    echo ""
    read -p "Enter addon number (1-${#ADDONS[@]}) or 0 to cancel: " choice
    
    if [[ "$choice" == "0" ]]; then
        print_info "Installation cancelled."
        return
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        print_error "Please enter a valid number!"
        sleep 2
        return
    fi
    
    if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#ADDONS[@]}" ]; then
        print_error "Invalid number! Please choose between 1 and ${#ADDONS[@]}"
        sleep 2
        return
    fi
    
    local index=$((choice-1))
    local selected_addon="${ADDONS[$index]}"
    
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Installing: $selected_addon$(printf '%*s' $((31-${#selected_addon})) '')║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if install_addon "$selected_addon"; then
        echo ""
        print_success "Addon installation completed!"
        print_info "Please check your Pterodactyl panel to see the new addon."
    else
        echo ""
        print_error "Failed to install addon!"
    fi
    
    echo ""
    read -p "Press any key to continue..." -n1 -s
    echo ""
}

install_all_addons() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Installing ALL Addons              ║${NC}"
    echo -e "${CYAN}║        (${#ADDONS[@]} addons total)             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    print_warning "This will install all ${#ADDONS[@]} addons. This may take a few minutes."
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Installation cancelled."
        return
    fi
    
    # Check internet connection
    if ! check_internet; then
        print_error "Cannot proceed without internet connection."
        return
    fi
    
    local success=0
    local failed=0
    
    for addon in "${ADDONS[@]}"; do
        echo ""
        echo -e "${CYAN}────────────────────────────────────${NC}"
        
        if install_addon "$addon"; then
            ((success++))
        else
            ((failed++))
        fi
        
        # Small delay to avoid rate limiting
        sleep 1
    done
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Installation Summary:${NC}"
    echo -e "${GREEN}  Successfully installed: $success${NC}"
    echo -e "${RED}  Failed to install: $failed${NC}"
    echo -e "${BLUE}  Total addons processed: ${#ADDONS[@]}${NC}"
    echo ""
    
    if [ $success -gt 0 ]; then
        print_success "Some addons were installed successfully!"
        print_info "Please refresh your Pterodactyl panel to see the new addons."
    fi
    
    echo ""
    read -p "Press any key to continue..." -n1 -s
    echo ""
}

check_system_status() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     System Status Check               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check Pterodactyl
    if check_pterodactyl; then
        print_success "Pterodactyl found at: $PTERODACTYL_DIR"
    else
        print_error "Pterodactyl not found at: $PTERODACTYL_DIR"
    fi
    
    # Check Blueprint
    if check_blueprint; then
        print_success "Blueprint framework is installed"
    else
        print_warning "Blueprint framework is NOT installed"
        print_info "You need to install Blueprint from your Pterodactyl panel first."
        print_info "Go to: Admin → Extensions → Blueprint"
    fi
    
    # Check internet
    if check_internet; then
        print_success "Internet connection is available"
    else
        print_warning "No internet connection detected"
    fi
    
    # Check required tools
    if command -v wget > /dev/null 2>&1 || command -v curl > /dev/null 2>&1; then
        print_success "Download tools are available"
    else
        print_error "No download tools found (wget or curl)"
        print_info "Please install wget or curl: apt-get install wget"
    fi
    
    echo ""
    print_info "Available addons in repository: ${#ADDONS[@]}"
    print_info "GitHub Repository: ${GITHUB_USER}/${GITHUB_REPO}"
    
    echo ""
    read -p "Press any key to continue..." -n1 -s
    echo ""
}

show_main_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    Pterodactyl Blueprint Addon Manager ║${NC}"
    echo -e "${CYAN}║        GitHub: kiruthik123/addons-     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} List all available addons"
    echo -e "${GREEN}2.${NC} Install single addon"
    echo -e "${GREEN}3.${NC} Install all addons"
    echo -e "${GREEN}4.${NC} Check system status"
    echo -e "${GREEN}5.${NC} Check Blueprint installation"
    echo -e "${GREEN}0.${NC} Exit"
    echo ""
}

main() {
    # Check if running as root
    check_root
    
    # Check if Pterodactyl exists (but don't exit if not)
    if ! check_pterodactyl; then
        echo ""
        print_warning "Pterodactyl not found at the default location."
        print_info "If Pterodactyl is installed elsewhere, please update the script."
        echo ""
    fi
    
    # Main menu loop
    while true; do
        show_main_menu
        read -p "Enter your choice (0-5): " choice
        
        case $choice in
            1)
                list_addons
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            2)
                install_single_addon
                ;;
            3)
                install_all_addons
                ;;
            4)
                check_system_status
                ;;
            5)
                # Just check blueprint status
                clear
                if check_blueprint; then
                    print_success "Blueprint is properly installed!"
                else
                    print_error "Blueprint is NOT installed or has issues."
                fi
                echo ""
                read -p "Press any key to continue..." -n1 -s
                ;;
            0)
                echo ""
                print_info "Thank you for using Blueprint Addon Manager!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid option! Please choose 0-5"
                sleep 2
                ;;
        esac
    done
}

# Run the script
main
