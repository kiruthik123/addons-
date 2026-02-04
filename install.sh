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
SCRIPT_VERSION="1.1.0"
PTERODACTYL_DIR="/var/www/pterodactyl"
BLUEPRINT_DIR="${PTERODACTYL_DIR}/.blueprint"
TEMP_DIR="/tmp/blueprint-addons"
LOG_FILE="/var/log/blueprint-installer.log"

# GitHub configuration
GITHUB_USER="kiruthik123"
GITHUB_REPO="blueprintmain"
GITHUB_BRANCH="main"

#######################################
# Utility Functions
#######################################

# Initialize log file
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Blueprint Installer Log - $(date) ===" > "$LOG_FILE"
}

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      Pterodactyl Blueprint Installer v${SCRIPT_VERSION}     ║${NC}"
    echo -e "${CYAN}║            Author: kiruthik123                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    log_message "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    log_message "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    log_message "WARNING" "$1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    log_message "INFO" "$1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        echo "Please run with: sudo $0"
        exit 1
    fi
}

check_pterodactyl() {
    if [ ! -d "$PTERODACTYL_DIR" ]; then
        print_error "Pterodactyl installation not found at $PTERODACTYL_DIR"
        print_info "Please install Pterodactyl Panel first:"
        echo "  https://pterodactyl.io/panel/1.0/getting_started.html"
        exit 1
    fi
    
    # Check if Pterodactyl is properly installed
    if [ ! -f "${PTERODACTYL_DIR}/artisan" ]; then
        print_error "Pterodactyl artisan file not found. Installation may be incomplete."
        exit 1
    fi
    
    print_success "Pterodactyl installation found and verified"
}

check_internet() {
    print_info "Checking internet connection..."
    if ! ping -c 1 -W 2 github.com > /dev/null 2>&1; then
        print_error "No internet connection. Please check your network."
        return 1
    fi
    print_success "Internet connection verified"
    return 0
}

press_any_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo -e "\n"
}

#######################################
# Installation Functions
#######################################

install_dependencies() {
    print_info "Installing required dependencies..."
    
    # Update package list
    if ! apt-get update -qq; then
        print_error "Failed to update package list"
        return 1
    fi
    
    # Install dependencies
    local dependencies=("git" "curl" "wget" "zip" "unzip" "jq" "nodejs" "npm")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" > /dev/null 2>&1; then
            print_info "Installing $dep..."
            if ! apt-get install -y "$dep" > /dev/null 2>&1; then
                print_warning "Failed to install $dep, attempting to continue..."
            fi
        fi
    done
    
    print_success "Dependencies installed successfully"
    return 0
}

install_blueprint() {
    print_header
    echo -e "${PURPLE}Installing Blueprint Framework...${NC}"
    echo ""
    
    # Check prerequisites
    check_pterodactyl
    check_internet || return 1
    
    # Install dependencies
    if ! install_dependencies; then
        print_error "Failed to install dependencies"
        press_any_key
        return 1
    fi
    
    # Navigate to Pterodactyl directory
    if ! cd "$PTERODACTYL_DIR"; then
        print_error "Failed to access Pterodactyl directory"
        return 1
    fi
    
    # Backup existing Blueprint if exists
    if [ -d ".blueprint" ]; then
        print_warning "Existing Blueprint installation found"
        local backup_dir=".blueprint-backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Creating backup at ${backup_dir}"
        cp -r .blueprint "$backup_dir"
        print_success "Backup created: $backup_dir"
    fi
    
    # Download Blueprint
    print_info "Downloading Blueprint framework..."
    
    # Remove existing directory if exists
    [ -d ".blueprint" ] && rm -rf .blueprint
    
    # Clone the repository
    if ! git clone https://github.com/BlueprintFramework/framework.git .blueprint > /dev/null 2>&1; then
        print_error "Failed to clone Blueprint repository"
        print_info "Alternative: Downloading from mirror..."
        # Try alternative download method
        if ! wget -q https://github.com/BlueprintFramework/framework/archive/main.tar.gz -O /tmp/blueprint.tar.gz; then
            print_error "Failed to download Blueprint framework"
            press_any_key
            return 1
        fi
        
        mkdir -p .blueprint
        tar -xzf /tmp/blueprint.tar.gz -C .blueprint --strip-components=1
        rm -f /tmp/blueprint.tar.gz
    fi
    
    print_success "Blueprint downloaded successfully"
    
    # Verify download
    if [ ! -f ".blueprint/blueprint.sh" ]; then
        print_error "Blueprint installation script not found"
        return 1
    fi
    
    # Set permissions
    print_info "Setting permissions..."
    chown -R www-data:www-data "$PTERODACTYL_DIR"
    chmod -R 755 "$PTERODACTYL_DIR"
    chmod +x .blueprint/blueprint.sh
    
    # Install Blueprint
    print_info "Running Blueprint installation..."
    cd .blueprint || return 1
    
    if [ -f "blueprint.sh" ]; then
        if bash blueprint.sh --install; then
            print_success "Blueprint installation completed!"
            
            # Clear Laravel cache
            print_info "Clearing Laravel cache..."
            cd "$PTERODACTYL_DIR" && php artisan cache:clear > /dev/null 2>&1
            php artisan view:clear > /dev/null 2>&1
            
            print_success "Blueprint framework installed successfully!"
            print_info "You can now install addons from the 'Manage Addons' menu"
        else
            print_error "Blueprint installation script failed"
            return 1
        fi
    else
        print_error "Blueprint installation script not found"
        return 1
    fi
    
    press_any_key
    return 0
}

#######################################
# Addons Management Functions
#######################################

list_available_addons() {
    print_header
    echo -e "${PURPLE}Available Blueprint Extensions:${NC}"
    echo ""
    
    # Define addons with descriptions
    declare -A addons=(
        ["activitypurges.blueprint"]="Activity Purges - Clean up old activity logs"
        ["consolelogs.blueprint"]="Console Logs - Enhanced console logging"
        ["huxregister.blueprint"]="Hux Register - User registration system"
        ["laravellogs.blueprint"]="Laravel Logs - View Laravel application logs"
        ["lyrdyannounce.blueprint"]="Lyrdy Announce - Announcement system"
        ["mclogs.blueprint"]="MC Logs - Minecraft server log viewer"
        ["modrinthbrowser.blueprint"]="Modrinth Browser - Browse Modrinth mods"
        ["nightsadmin.blueprint"]="Nights Admin - Admin tools and utilities"
        ["resourcealerts.blueprint"]="Resource Alerts - Server resource monitoring"
        ["resourcemanager.blueprint"]="Resource Manager - Manage server resources"
        ["serverbackgrounds.blueprint"]="Server Backgrounds - Custom server backgrounds"
        ["shownodeids.blueprint"]="Show Node IDs - Display node identifiers"
        ["simplefooters.blueprint"]="Simple Footers - Custom footer text"
        ["translations.blueprint"]="Translations - Multi-language support"
        ["urldownloader.blueprint"]="URL Downloader - Download files from URLs"
        ["votifiertester.blueprint"]="Votifier Tester - Test Votifier connections"
    )
    
    local i=1
    for file in "${!addons[@]}"; do
        printf "${GREEN}%2d.${NC} %-25s ${CYAN}(%s)${NC}\n" "$i" "${addons[$file]%% -*}" "$file"
        printf "     %s\n" "${addons[$file]#* - }"
        ((i++))
    done
    
    echo ""
    echo -e "${YELLOW}Total: ${#addons[@]} extensions available${NC}"
}

get_addon_by_index() {
    local index="$1"
    declare -A addons=(
        ["activitypurges.blueprint"]="Activity Purges"
        ["consolelogs.blueprint"]="Console Logs"
        ["huxregister.blueprint"]="Hux Register"
        ["laravellogs.blueprint"]="Laravel Logs"
        ["lyrdyannounce.blueprint"]="Lyrdy Announce"
        ["mclogs.blueprint"]="MC Logs"
        ["modrinthbrowser.blueprint"]="Modrinth Browser"
        ["nightsadmin.blueprint"]="Nights Admin"
        ["resourcealerts.blueprint"]="Resource Alerts"
        ["resourcemanager.blueprint"]="Resource Manager"
        ["serverbackgrounds.blueprint"]="Server Backgrounds"
        ["shownodeids.blueprint"]="Show Node IDs"
        ["simplefooters.blueprint"]="Simple Footers"
        ["translations.blueprint"]="Translations"
        ["urldownloader.blueprint"]="URL Downloader"
        ["votifiertester.blueprint"]="Votifier Tester"
    )
    
    local i=1
    for file in "${!addons[@]}"; do
        if [ "$i" -eq "$index" ]; then
            echo "$file"
            return 0
        fi
        ((i++))
    done
    return 1
}

download_addon() {
    local addon_file="$1"
    local addon_name="${addon_file%.blueprint}"
    
    print_info "Downloading ${addon_name}..."
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Try multiple download methods
    local download_urls=(
        "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${addon_file}"
        "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/master/${addon_file}"
        "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/raw/${GITHUB_BRANCH}/${addon_file}"
    )
    
    local downloaded=0
    for url in "${download_urls[@]}"; do
        print_info "Trying: $url"
        if wget -q --timeout=10 --tries=2 --show-progress "$url" -O "${TEMP_DIR}/${addon_file}" 2>&1; then
            downloaded=1
            break
        fi
    done
    
    if [ "$downloaded" -eq 0 ]; then
        print_error "Failed to download ${addon_file}"
        print_info "Please check:"
        echo "  1. GitHub repository exists: ${GITHUB_USER}/${GITHUB_REPO}"
        echo "  2. File exists in repository: ${addon_file}"
        echo "  3. You have internet connection"
        return 1
    fi
    
    # Verify the downloaded file
    if [ ! -s "${TEMP_DIR}/${addon_file}" ]; then
        print_error "Downloaded file is empty"
        return 1
    fi
    
    print_success "Download completed: ${addon_file}"
    return 0
}

install_addon() {
    local addon_file="$1"
    
    print_info "Installing ${addon_file%.blueprint}..."
    
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint not installed. Please install Blueprint first."
        return 1
    fi
    
    if [ ! -f "${TEMP_DIR}/${addon_file}" ]; then
        print_error "Addon file not found: ${addon_file}"
        return 1
    fi
    
    cd "$PTERODACTYL_DIR" || return 1
    
    # Install using blueprint.sh
    if bash .blueprint/blueprint.sh -i "${TEMP_DIR}/${addon_file}"; then
        print_success "${addon_file%.blueprint} installed successfully!"
        
        # Clear Laravel cache
        php artisan cache:clear > /dev/null 2>&1
        php artisan view:clear > /dev/null 2>&1
        
        # Clean up
        rm -f "${TEMP_DIR}/${addon_file}"
        return 0
    else
        print_error "Failed to install ${addon_file}"
        print_info "The downloaded file is available at: ${TEMP_DIR}/${addon_file}"
        return 1
    fi
}

install_single_addon() {
    print_header
    list_available_addons
    
    echo ""
    read -rp "Enter addon number to install (or 0 to cancel): " addon_choice
    
    # Validate input
    if ! [[ "$addon_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid input. Please enter a number."
        press_any_key
        return 1
    fi
    
    if [ "$addon_choice" -eq 0 ]; then
        print_info "Installation cancelled"
        return 0
    fi
    
    local total_addons=16
    if [ "$addon_choice" -lt 1 ] || [ "$addon_choice" -gt "$total_addons" ]; then
        print_error "Invalid selection. Please choose between 1 and $total_addons."
        press_any_key
        return 1
    fi
    
    # Get selected addon filename
    local selected_addon
    selected_addon=$(get_addon_by_index "$addon_choice")
    
    if [ -z "$selected_addon" ]; then
        print_error "Failed to get addon information"
        return 1
    fi
    
    print_header
    echo -e "${PURPLE}Installing: ${selected_addon%.blueprint}${NC}"
    echo ""
    
    # Download the addon
    if ! download_addon "$selected_addon"; then
        press_any_key
        return 1
    fi
    
    # Install the addon
    if install_addon "$selected_addon"; then
        echo ""
        print_success "Installation completed successfully!"
    else
        echo ""
        print_error "Installation failed"
    fi
    
    press_any_key
}

install_all_addons() {
    print_header
    echo -e "${PURPLE}Installing All Addons from GitHub...${NC}"
    echo ""
    
    print_warning "This will download and install all 16 blueprint extensions"
    print_warning "This may take several minutes..."
    echo ""
    read -rp "Do you want to continue? (yes/no): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy](es)?$ ]]; then
        print_info "Installation cancelled"
        press_any_key
        return
    fi
    
    # Check if Blueprint is installed
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint not installed. Please install Blueprint first."
        press_any_key
        return 1
    fi
    
    # Define all addons
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
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    local success_count=0
    local fail_count=0
    local skip_count=0
    
    for addon in "${addons[@]}"; do
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────${NC}"
        print_info "Processing: ${addon%.blueprint}"
        
        # Download addon
        if download_addon "$addon"; then
            # Install addon
            if install_addon "$addon"; then
                ((success_count++))
            else
                ((fail_count++))
            fi
        else
            ((skip_count++))
        fi
        
        # Small delay to avoid rate limiting
        sleep 1
    done
    
    # Clean up temporary directory
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    
    # Print summary
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            Installation Summary                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓ Successfully installed:${NC} $success_count"
    echo -e "${RED}✗ Failed to install:${NC}      $fail_count"
    echo -e "${YELLOW}⚠ Skipped:${NC}             $skip_count"
    echo -e "${BLUE}📊 Total processed:${NC}      ${#addons[@]}"
    echo ""
    
    if [ "$success_count" -gt 0 ]; then
        print_info "Clearing Laravel cache..."
        cd "$PTERODACTYL_DIR" && php artisan cache:clear > /dev/null 2>&1
        print_success "Cache cleared"
    fi
    
    press_any_key
}

remove_addon() {
    print_header
    print_info "Listing installed extensions..."
    echo ""
    
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint not installed"
        press_any_key
        return
    fi
    
    cd "$PTERODACTYL_DIR" || return 1
    
    # Run blueprint.sh to list extensions
    bash .blueprint/blueprint.sh -l
    
    echo ""
    read -rp "Enter extension identifier to remove (or 0 to cancel): " ext_id
    
    if [ -z "$ext_id" ] || [ "$ext_id" = "0" ]; then
        print_info "Operation cancelled"
        press_any_key
        return
    fi
    
    # Confirm removal
    read -rp "Are you sure you want to remove extension '$ext_id'? (yes/no): " confirm
    if [[ "$confirm" =~ ^[Yy](es)?$ ]]; then
        print_info "Removing extension: $ext_id"
        if bash .blueprint/blueprint.sh -r "$ext_id"; then
            print_success "Extension removed successfully!"
            
            # Clear cache
            print_info "Clearing cache..."
            php artisan cache:clear > /dev/null 2>&1
            php artisan view:clear > /dev/null 2>&1
        else
            print_error "Failed to remove extension"
        fi
    else
        print_info "Removal cancelled"
    fi
    
    press_any_key
}

list_installed_addons() {
    print_header
    echo -e "${PURPLE}Installed Blueprint Extensions:${NC}"
    echo ""
    
    if [ ! -d "$PTERODACTYL_DIR/.blueprint" ]; then
        print_error "Blueprint framework not installed"
        press_any_key
        return
    fi
    
    cd "$PTERODACTYL_DIR" || return 1
    
    # Check if blueprint.sh exists
    if [ ! -f ".blueprint/blueprint.sh" ]; then
        print_error "Blueprint script not found"
        press_any_key
        return
    fi
    
    # Execute the blueprint list command
    bash .blueprint/blueprint.sh -l
    
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
        echo -e "${GREEN}6.${NC} Check Addon Updates"
        echo -e "${GREEN}0.${NC} Back to Main Menu"
        echo ""
        read -rp "Enter your choice: " addon_menu_choice
        
        case $addon_menu_choice in
            1)
                list_available_addons
                press_any_key
                ;;
            2)
                install_single_addon
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
            6)
                check_addon_updates
                ;;
            0)
                break
                ;;
            *)
                print_error "Invalid option"
                sleep 2
                ;;
        esac
    done
}

check_addon_updates() {
    print_header
    echo -e "${PURPLE}Checking for Addon Updates${NC}"
    echo ""
    print_info "This feature is under development..."
    print_info "Coming soon: Automatic update checking for installed addons"
    press_any_key
}

#######################################
# Main Menu Functions
#######################################

update_blueprint() {
    print_header
    echo -e "${PURPLE}Updating Blueprint Framework...${NC}"
    echo ""
    
    if [ ! -d "$BLUEPRINT_DIR" ]; then
        print_error "Blueprint not installed. Please install it first."
        press_any_key
        return
    fi
    
    check_internet || return 1
    
    print_info "Backing up current installation..."
    local backup_dir=".blueprint-backup-$(date +%Y%m%d-%H%M%S)"
    cp -r "$BLUEPRINT_DIR" "$PTERODACTYL_DIR/$backup_dir"
    print_success "Backup created: $backup_dir"
    
    cd "$BLUEPRINT_DIR" || return 1
    
    print_info "Pulling latest changes from repository..."
    if git pull origin main; then
        print_success "Updates downloaded successfully"
        
        print_info "Running update script..."
        if bash blueprint.sh --update; then
            print_success "Blueprint updated successfully!"
            
            # Clear Laravel cache
            print_info "Clearing cache..."
            cd "$PTERODACTYL_DIR" && php artisan cache:clear > /dev/null 2>&1
            php artisan view:clear > /dev/null 2>&1
        else
            print_error "Update script failed"
            print_info "Restoring from backup..."
            cd "$PTERODACTYL_DIR" && rm -rf .blueprint && cp -r "$backup_dir" .blueprint
        fi
    else
        print_error "Failed to pull updates"
        print_info "Please check your internet connection and try again"
    fi
    
    press_any_key
}

uninstall_blueprint() {
    print_header
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    echo -e "${RED}          Uninstall Blueprint Framework          ${NC}"
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -d "$BLUEPRINT_DIR" ]; then
        print_error "Blueprint is not installed"
        press_any_key
        return
    fi
    
    print_warning "⚠  WARNING: This will remove Blueprint and all installed extensions!"
    print_warning "   This action cannot be undone!"
    echo ""
    print_info "A backup will be created before uninstallation"
    echo ""
    
    read -rp "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Uninstallation cancelled"
        press_any_key
        return
    fi
    
    # Create backup
    print_info "Creating backup..."
    local backup_dir="/var/backups/blueprint-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$BLUEPRINT_DIR" "$backup_dir/"
    print_success "Backup created at: $backup_dir"
    
    # Run uninstall script if exists
    if [ -f "$BLUEPRINT_DIR/blueprint.sh" ]; then
        print_info "Running uninstall script..."
        cd "$BLUEPRINT_DIR" && bash blueprint.sh --uninstall
    fi
    
    # Remove blueprint directory
    print_info "Removing Blueprint files..."
    rm -rf "$BLUEPRINT_DIR"
    
    # Clear Laravel cache
    print_info "Clearing Laravel cache..."
    cd "$PTERODACTYL_DIR" && php artisan cache:clear > /dev/null 2>&1
    php artisan view:clear > /dev/null 2>&1
    
    print_success "Blueprint framework uninstalled successfully!"
    print_info "Backup is available at: $backup_dir"
    
    press_any_key
}

show_system_info() {
    print_header
    echo -e "${PURPLE}System Information${NC}"
    echo ""
    
    # OS Information
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${CYAN}OS:${NC} $PRETTY_NAME"
    else
        echo -e "${CYAN}OS:${NC} $(uname -o)"
    fi
    
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Architecture:${NC} $(uname -m)"
    
    # Pterodactyl Information
    echo -e "${CYAN}Pterodactyl Directory:${NC} $PTERODACTYL_DIR"
    
    if [ -d "$PTERODACTYL_DIR" ]; then
        if [ -f "$PTERODACTYL_DIR/artisan" ]; then
            echo -e "${CYAN}Pterodactyl Status:${NC} ${GREEN}Installed${NC}"
        else
            echo -e "${CYAN}Pterodactyl Status:${NC} ${YELLOW}Directory exists but may be incomplete${NC}"
        fi
    else
        echo -e "${CYAN}Pterodactyl Status:${NC} ${RED}Not Found${NC}"
    fi
    
    # Blueprint Information
    if [ -d "$BLUEPRINT_DIR" ]; then
        echo -e "${CYAN}Blueprint Status:${NC} ${GREEN}Installed${NC}"
        if [ -f "$BLUEPRINT_DIR/blueprint.sh" ]; then
            echo -e "${CYAN}Blueprint Version:${NC} $(grep -i version "$BLUEPRINT_DIR/blueprint.sh" 2>/dev/null | head -1 | cut -d'=' -f2 | tr -d '\" ' || echo "Unknown")"
        fi
    else
        echo -e "${CYAN}Blueprint Status:${NC} ${RED}Not Installed${NC}"
    fi
    
    # Disk space
    echo -e "${CYAN}Available Disk Space:${NC} $(df -h "$PTERODACTYL_DIR" | tail -1 | awk '{print $4}')"
    
    # Script information
    echo ""
    echo -e "${CYAN}Script Version:${NC} $SCRIPT_VERSION"
    echo -e "${CYAN}Log File:${NC} $LOG_FILE"
    
    echo ""
    press_any_key
}

main_menu() {
    while true; do
        print_header
        echo -e "${PURPLE}Main Menu${NC}"
        echo ""
        
        # Show installation status
        if [ -d "$BLUEPRINT_DIR" ]; then
            echo -e "${GREEN}●${NC} Blueprint Framework: ${GREEN}INSTALLED${NC}"
        else
            echo -e "${RED}●${NC} Blueprint Framework: ${RED}NOT INSTALLED${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}1.${NC} Install Blueprint Framework"
        echo -e "${GREEN}2.${NC} Manage Addons/Extensions"
        echo -e "${GREEN}3.${NC} Update Blueprint"
        echo -e "${GREEN}4.${NC} Uninstall Blueprint"
        echo -e "${GREEN}5.${NC} System Information"
        echo -e "${GREEN}6.${NC} View Installation Log"
        echo -e "${GREEN}0.${NC} Exit"
        echo ""
        read -rp "Enter your choice: " choice
        
        case $choice in
            1)
                install_blueprint
                ;;
            2)
                if [ ! -d "$BLUEPRINT_DIR" ]; then
                    print_error "Please install Blueprint framework first!"
                    sleep 2
                else
                    manage_addons
                fi
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
            6)
                view_log_file
                ;;
            0)
                print_info "Thank you for using Blueprint Installer!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

view_log_file() {
    print_header
    echo -e "${PURPLE}Installation Log${NC}"
    echo ""
    
    if [ ! -f "$LOG_FILE" ]; then
        print_error "Log file not found: $LOG_FILE"
        press_any_key
        return
    fi
    
    # Show last 50 lines of log
    echo -e "${CYAN}Showing last 50 lines of log:${NC}"
    echo ""
    tail -50 "$LOG_FILE"
    
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  1. View full log"
    echo "  2. Clear log file"
    echo "  3. Download log file"
    echo "  0. Back"
    echo ""
    read -rp "Enter choice: " log_choice
    
    case $log_choice in
        1)
            clear
            echo -e "${PURPLE}Full Installation Log${NC}"
            echo ""
            cat "$LOG_FILE"
            press_any_key
            ;;
        2)
            echo -n "" > "$LOG_FILE"
            print_success "Log file cleared"
            sleep 1
            ;;
        3)
            cp "$LOG_FILE" "/tmp/blueprint-installer.log"
            print_info "Log file copied to: /tmp/blueprint-installer.log"
            sleep 1
            ;;
    esac
}

#######################################
# Main Script Execution
#######################################

# Initialize
init_log

# Check if running as root
check_root

# Welcome message
print_header
print_info "Starting Pterodactyl Blueprint Installer v${SCRIPT_VERSION}"
log_message "INFO" "Script started"

# Trap for cleanup on exit
trap 'log_message "INFO" "Script exited"; echo ""' EXIT

# Start main menu
main_menu
