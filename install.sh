#!/bin/bash

#######################################
# Pterodactyl Blueprint Installer
# Author: kiruthik123
# Description: Installation script for Pterodactyl Blueprint Framework
#######################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_VERSION="1.0.0"
PTERODACTYL_DIR="/var/www/pterodactyl"
BLUEPRINT_DIR="${PTERODACTYL_DIR}/.blueprint"

#######################################
# Utility Functions
#######################################

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Pterodactyl Blueprint Installer     ║${NC}"
    echo -e "${CYAN}║            Version ${SCRIPT_VERSION}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

check_pterodactyl() {
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        print_error "Pterodactyl installation not found at $PTERODACTYL_DIR"
        print_info "Please install Pterodactyl Panel first"
        exit 1
    fi
    print_success "Pterodactyl installation found"
}

press_any_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo ""
}

#######################################
# Installation Functions
#######################################

install_dependencies() {
    print_info "Installing required dependencies..."
    
    apt-get update -qq
    apt-get install -y git curl wget zip unzip jq nodejs npm > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        return 1
    fi
}

install_blueprint() {
    print_header
    echo -e "${PURPLE}Installing Blueprint Framework...${NC}"
    echo ""
    
    check_pterodactyl
    
    # Install dependencies
    install_dependencies
    
    # Navigate to Pterodactyl directory
    cd "$PTERODACTYL_DIR" || exit 1
    
    # Download Blueprint
    print_info "Downloading Blueprint framework..."
    if [ -d ".blueprint" ]; then
        print_warning "Blueprint directory already exists. Removing..."
        rm -rf .blueprint
    fi
    
    git clone https://github.com/BlueprintFramework/framework.git .blueprint > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download Blueprint"
        press_any_key
        return 1
    fi
    
    print_success "Blueprint downloaded successfully"
    
    # Set permissions
    print_info "Setting permissions..."
    chown -R www-data:www-data "$PTERODACTYL_DIR"
    chmod -R 755 "$PTERODACTYL_DIR"
    
    # Install Blueprint
    print_info "Running Blueprint installation..."
    cd .blueprint || exit 1
    
    if [ -f "blueprint.sh" ]; then
        bash blueprint.sh --install
    else
        print_error "Blueprint installation script not found"
        press_any_key
        return 1
    fi
    
    print_success "Blueprint installation completed!"
    
    echo ""
    print_success "Blueprint framework installed successfully!"
    print_info "You can now install addons from the 'Manage Addons' menu"
    press_any_key
}

#######################################
# Addons Management Functions
#######################################

list_available_addons() {
    print_header
    echo -e "${PURPLE}Available Blueprint Extensions:${NC}"
    echo ""
    
    local addons=(
        "activitypurges.blueprint:Activity Purges"
        "consolelogs.blueprint:Console Logs"
        "huxregister.blueprint:Hux Register"
        "laravellogs.blueprint:Laravel Logs"
        "lyrdyannounce.blueprint:Lyrdy Announce"
        "mclogs.blueprint:MC Logs"
        "modrinthbrowser.blueprint:Modrinth Browser"
        "nightsadmin.blueprint:Nights Admin"
        "resourcealerts.blueprint:Resource Alerts"
        "resourcemanager.blueprint:Resource Manager"
        "serverbackgrounds.blueprint:Server Backgrounds"
        "shownodeids.blueprint:Show Node IDs"
        "simplefooters.blueprint:Simple Footers"
        "translations.blueprint:Translations"
        "urldownloader.blueprint:URL Downloader"
        "votifiertester.blueprint:Votifier Tester"
    )
    
    local i=1
    for addon in "${addons[@]}"; do
        IFS=':' read -r file name <<< "$addon"
        echo -e "${GREEN}${i}.${NC} ${name} ${CYAN}(${file})${NC}"
        ((i++))
    done
    
    echo ""
}

install_addon() {
    print_header
    list_available_addons
    
    echo ""
    read -p "Enter addon number to install (or 0 to cancel): " addon_choice
    
    if [ "$addon_choice" = "0" ]; then
        return
    fi
    
    local addons=(
        "activitypurges.blueprint"
        "consolelogs.blueprint"
        "huxregister.blueprint"
        "laravellogs.blueprint"
        "lyrdyannounce.blueprint"
        "mclogs.blueprint"
        "modrinthbrowser.blueprint"
        "nightsadmin.blueprint"
        "resourcealerts.blueprint"
        "resourcemanager.blueprint"
        "serverbackgrounds.blueprint"
        "shownodeids.blueprint"
        "simplefooters.blueprint"
        "translations.blueprint"
        "urldownloader.blueprint"
        "votifiertester.blueprint"
    )
    
    if [ "$addon_choice" -ge 1 ] && [ "$addon_choice" -le "${#addons[@]}" ]; then
        local selected_addon="${addons[$((addon_choice-1))]}"
        
        print_info "Downloading ${selected_addon} from GitHub..."
        
        # GitHub repository URL (update with your actual GitHub username/repo)
        local GITHUB_USER="kiruthik123"
        local GITHUB_REPO="blueprintmain"
        local GITHUB_BRANCH="main"
        local DOWNLOAD_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${selected_addon}"
        
        # Create temporary directory for downloads
        mkdir -p /tmp/blueprint-addons
        
        # Download the blueprint file
        wget -q --show-progress "${DOWNLOAD_URL}" -O "/tmp/blueprint-addons/${selected_addon}"
        
        if [ $? -ne 0 ]; then
            print_error "Failed to download ${selected_addon} from GitHub"
            print_info "URL: ${DOWNLOAD_URL}"
            print_warning "Please check if the file exists in your repository"
            press_any_key
            return 1
        fi
        
        print_success "Download completed!"
        print_info "Installing ${selected_addon}..."
        
        cd "$PTERODACTYL_DIR" || exit 1
        
        # Install the downloaded blueprint
        bash .blueprint/blueprint.sh -i "/tmp/blueprint-addons/${selected_addon}"
        
        if [ $? -eq 0 ]; then
            print_success "${selected_addon} installed successfully!"
            # Clean up downloaded file
            rm -f "/tmp/blueprint-addons/${selected_addon}"
        else
            print_error "Failed to install ${selected_addon}"
            print_info "Downloaded file is available at: /tmp/blueprint-addons/${selected_addon}"
        fi
    else
        print_error "Invalid selection"
    fi
    
    press_any_key
}

install_all_addons() {
    print_header
    echo -e "${PURPLE}Installing All Addons from GitHub...${NC}"
    echo ""
    
    print_warning "This will download and install all 16 blueprint extensions"
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Installation cancelled"
        press_any_key
        return
    fi
    
    local addons=(
        "activitypurges.blueprint"
        "consolelogs.blueprint"
        "huxregister.blueprint"
        "laravellogs.blueprint"
        "lyrdyannounce.blueprint"
        "mclogs.blueprint"
        "modrinthbrowser.blueprint"
        "nightsadmin.blueprint"
        "resourcealerts.blueprint"
        "resourcemanager.blueprint"
        "serverbackgrounds.blueprint"
        "shownodeids.blueprint"
        "simplefooters.blueprint"
        "translations.blueprint"
        "urldownloader.blueprint"
        "votifiertester.blueprint"
    )
    
    # GitHub repository URL
    local GITHUB_USER="kiruthik123"
    local GITHUB_REPO="blueprintmain"
    local GITHUB_BRANCH="main"
    
    # Create temporary directory for downloads
    mkdir -p /tmp/blueprint-addons
    
    local success_count=0
    local fail_count=0
    
    for addon in "${addons[@]}"; do
        echo ""
        print_info "Processing ${addon}..."
        
        local DOWNLOAD_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${addon}"
        
        # Download the blueprint file
        wget -q --show-progress "${DOWNLOAD_URL}" -O "/tmp/blueprint-addons/${addon}" 2>&1
        
        if [ $? -ne 0 ]; then
            print_error "Failed to download ${addon}"
            ((fail_count++))
            continue
        fi
        
        # Install the downloaded blueprint
        cd "$PTERODACTYL_DIR" || exit 1
        bash .blueprint/blueprint.sh -i "/tmp/blueprint-addons/${addon}" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            print_success "${addon} installed successfully!"
            ((success_count++))
            rm -f "/tmp/blueprint-addons/${addon}"
        else
            print_error "Failed to install ${addon}"
            ((fail_count++))
        fi
        
        sleep 1
    done
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Installation Summary            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}Successful:${NC} ${success_count}"
    echo -e "${RED}Failed:${NC} ${fail_count}"
    echo ""
    
    press_any_key
}

manage_addons() {
    while true; do
        print_header
        echo -e "${PURPLE}Addon Management${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} List Available Addons"
        echo -e "${GREEN}2.${NC} Install Single Addon"
        echo -e "${GREEN}3.${NC} Install All Addons"
        echo -e "${GREEN}4.${NC} Remove Addon"
        echo -e "${GREEN}5.${NC} List Installed Addons"
        echo -e "${GREEN}0.${NC} Back to Main Menu"
        echo ""
        read -p "Enter your choice: " addon_menu_choice
        
        case $addon_menu_choice in
            1)
                list_available_addons
                press_any_key
                ;;
            2)
                install_addon
                ;;
            3)
                install_all_addons
                ;;
            4)
                remove_addon
                ;;
            5)
                list_installed_addons
                ;;
            0)
                break
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

remove_addon() {
    print_header
    print_info "Listing installed extensions..."
    
    cd "$PTERODACTYL_DIR" || exit 1
    
    if [ ! -f ".blueprint/blueprint.sh" ]; then
        print_error "Blueprint not installed"
        press_any_key
        return
    fi
    
    bash .blueprint/blueprint.sh -l
    
    echo ""
    read -p "Enter extension identifier to remove (or 0 to cancel): " ext_id
    
    if [ "$ext_id" != "0" ]; then
        bash .blueprint/blueprint.sh -r "$ext_id"
        
        if [ $? -eq 0 ]; then
            print_success "Extension removed successfully!"
        else
            print_error "Failed to remove extension"
        fi
    fi
    
    press_any_key
}

list_installed_addons() {
    print_header
    echo -e "${PURPLE}Installed Extensions:${NC}"
    echo ""
    
    cd "$PTERODACTYL_DIR" || exit 1
    
    if [ ! -f ".blueprint/blueprint.sh" ]; then
        print_error "Blueprint not installed"
        press_any_key
        return
    fi
    
    bash .blueprint/blueprint.sh -l
    
    press_any_key
}

#######################################
# Main Menu
#######################################

main_menu() {
    while true; do
        print_header
        echo -e "${PURPLE}Main Menu${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} Install Blueprint Framework"
        echo -e "${GREEN}2.${NC} Manage Addons/Extensions"
        echo -e "${GREEN}3.${NC} Update Blueprint"
        echo -e "${GREEN}4.${NC} Uninstall Blueprint"
        echo -e "${GREEN}5.${NC} System Information"
        echo -e "${GREEN}0.${NC} Exit"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                install_blueprint
                ;;
            2)
                manage_addons
                ;;
            3)
                update_blueprint
                ;;
            4)
                uninstall_blueprint
                ;;
            5)
                show_system_info
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

update_blueprint() {
    print_header
    echo -e "${PURPLE}Updating Blueprint Framework...${NC}"
    echo ""
    
    cd "$PTERODACTYL_DIR/.blueprint" || exit 1
    
    print_info "Pulling latest changes..."
    git pull
    
    print_info "Running update..."
    bash blueprint.sh --update
    
    print_success "Blueprint updated successfully!"
    press_any_key
}

uninstall_blueprint() {
    print_header
    echo -e "${RED}Uninstall Blueprint Framework${NC}"
    echo ""
    print_warning "This will remove Blueprint and all installed extensions!"
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        cd "$PTERODACTYL_DIR" || exit 1
        
        if [ -f ".blueprint/blueprint.sh" ]; then
            bash .blueprint/blueprint.sh --uninstall
            print_success "Blueprint uninstalled successfully!"
        else
            print_error "Blueprint not found"
        fi
    else
        print_info "Uninstall cancelled"
    fi
    
    press_any_key
}

show_system_info() {
    print_header
    echo -e "${PURPLE}System Information${NC}"
    echo ""
    
    echo -e "${CYAN}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Pterodactyl Directory:${NC} $PTERODACTYL_DIR"
    
    if [ -d "$BLUEPRINT_DIR" ]; then
        echo -e "${CYAN}Blueprint Status:${NC} ${GREEN}Installed${NC}"
    else
        echo -e "${CYAN}Blueprint Status:${NC} ${RED}Not Installed${NC}"
    fi
    
    echo ""
    press_any_key
}

#######################################
# Main Script Execution
#######################################

# Check if running as root
check_root

# Start main menu
main_menu
