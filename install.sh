#!/bin/bash

################################################################################
# Pterodactyl Panel Blueprint Addon Installer
# This script automates the installation of Blueprint addons
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PANEL_DIR="/var/www/pterodactyl"
BLUEPRINT_DIR="${PANEL_DIR}/blueprint"

# GitHub Configuration - UPDATE THESE VALUES
GITHUB_USER="kiruthik123"            # Your GitHub username
GITHUB_REPO="addons-"                # Your repository name
GITHUB_BRANCH="main"                 # Branch name (main or master)

# Alternative: Direct URLs to .blueprint files (comma-separated)
# BLUEPRINT_URLS="https://github.com/user/repo/raw/main/addon1.blueprint,https://github.com/user/repo/raw/main/addon2.blueprint"

# Discord Webhook Configuration - OPTIONAL
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1468440307514343466/D2UmwGP7CaYPhoP9Psv3R2KvuSweaqFTT5cetDOcHlez9K50biqzG2eQIzzNAtfwMnrl"
SEND_NOTIFICATIONS="true"            # Set to "false" to disable notifications

################################################################################
# Addon Categories Configuration
################################################################################

# Define addon categories and their addons
declare -A ADDON_CATEGORIES

# Server Management
ADDON_CATEGORIES["Server Management"]="serverbackgrounds.blueprint resourcemanager.blueprint resourcealerts.blueprint"

# Administration & Moderation
ADDON_CATEGORIES["Administration"]="nightadmin.blueprint modinthbrowser.blueprint consolelogs.blueprint activitypurges.blueprint"

# User Experience & Interface
ADDON_CATEGORIES["User Interface"]="translations.blueprint shownodeids.blueprint simplefooters.blueprint"

# Logs & Monitoring
ADDON_CATEGORIES["Logs & Monitoring"]="laravellogs.blueprint mclogs.blueprint"

# Security & Authentication
ADDON_CATEGORIES["Security"]="huxregister.blueprint lyrdyannounce.blueprint votifiertester.blueprint"

# Downloads & File Management
ADDON_CATEGORIES["File Management"]="urldownloader.blueprint"

################################################################################
# Helper Functions
################################################################################

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_dependencies() {
    print_info "Checking required dependencies..."
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        print_info "Installing curl..."
        apt-get update && apt-get install -y curl
    fi
    
    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        print_error "unzip is not installed"
        print_info "Installing unzip..."
        apt-get update && apt-get install -y unzip
    fi
    
    # Check for wget (alternative download tool)
    if ! command -v wget &> /dev/null; then
        print_info "Installing wget..."
        apt-get update && apt-get install -y wget
    fi
    
    print_success "All dependencies are installed"
}

download_from_github() {
    print_info "Downloading Blueprint addon files from GitHub..."
    
    # Create temporary directory for downloads
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    # Method 1: Download from specific URLs if BLUEPRINT_URLS is set
    if [ ! -z "$BLUEPRINT_URLS" ]; then
        print_info "Downloading from specified URLs..."
        IFS=',' read -ra URLS <<< "$BLUEPRINT_URLS"
        
        for url in "${URLS[@]}"; do
            filename=$(basename "$url")
            print_info "Downloading $filename..."
            
            if curl -L -o "$filename" "$url"; then
                print_success "Downloaded: $filename"
            else
                print_error "Failed to download: $url"
            fi
        done
    # Method 2: Download entire repository and extract .blueprint files
    else
        print_info "Downloading from repository: $GITHUB_USER/$GITHUB_REPO"
        
        # Validate GitHub configuration
        if [ "$GITHUB_USER" == "yourusername" ] || [ "$GITHUB_REPO" == "your-repo-name" ]; then
            print_error "GitHub configuration not updated!"
            print_warning "Please edit the script and set:"
            echo "  GITHUB_USER=\"your-actual-username\""
            echo "  GITHUB_REPO=\"your-actual-repo-name\""
            echo ""
            print_info "Current values:"
            echo "  GITHUB_USER=\"$GITHUB_USER\""
            echo "  GITHUB_REPO=\"$GITHUB_REPO\""
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        REPO_URL="https://github.com/$GITHUB_USER/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
        
        print_info "Fetching repository archive..."
        print_info "URL: $REPO_URL"
        
        if curl -L -f -o repo.zip "$REPO_URL" 2>/dev/null; then
            print_success "Repository downloaded"
            
            # Extract the repository
            print_info "Extracting files..."
            unzip -q repo.zip 2>/dev/null
            
            if [ $? -ne 0 ]; then
                print_error "Failed to extract repository archive"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
            
            # Find and copy all .blueprint files
            find . -name "*.blueprint" -type f -exec cp {} "$TEMP_DIR/" \;
            
            # Clean up the extracted directory and zip
            rm -rf "${GITHUB_REPO}-${GITHUB_BRANCH}" 2>/dev/null
            rm -f repo.zip
            
            print_success "Extracted Blueprint files"
        else
            print_error "Failed to download repository from: $REPO_URL"
            print_warning "Possible reasons:"
            echo "  1. Repository doesn't exist or is private"
            echo "  2. Branch name is incorrect (check if it's 'main' or 'master')"
            echo "  3. Network connection issue"
            echo "  4. GitHub URL format is wrong"
            echo ""
            print_info "Please verify your settings:"
            echo "  GITHUB_USER=\"$GITHUB_USER\""
            echo "  GITHUB_REPO=\"$GITHUB_REPO\""
            echo "  GITHUB_BRANCH=\"$GITHUB_BRANCH\""
            echo ""
            print_info "Try accessing this URL in your browser:"
            echo "  https://github.com/$GITHUB_USER/$GITHUB_REPO"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    fi
    
    # Count downloaded .blueprint files
    blueprint_count=$(find "$TEMP_DIR" -maxdepth 1 -name "*.blueprint" -type f | wc -l)
    
    if [ "$blueprint_count" -eq 0 ]; then
        print_error "No .blueprint files found in the repository"
        print_info "Make sure your repository contains .blueprint addon files"
        print_warning "Files found in download:"
        ls -la "$TEMP_DIR/"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    print_success "Found $blueprint_count Blueprint addon file(s)"
    
    # Return the temp directory path
    echo "$TEMP_DIR"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_pterodactyl() {
    if [ ! -d "$PANEL_DIR" ]; then
        print_error "Pterodactyl Panel not found at $PANEL_DIR"
        print_info "Please ensure Pterodactyl Panel is installed"
        exit 1
    fi
    print_success "Pterodactyl Panel found"
}

check_blueprint() {
    if [ ! -f "${PANEL_DIR}/blueprint.sh" ]; then
        print_error "Blueprint framework not found"
        print_info "Installing Blueprint framework..."
        install_blueprint
    else
        print_success "Blueprint framework found"
    fi
}

install_blueprint() {
    print_info "Downloading and installing Blueprint..."
    cd "$PANEL_DIR" || exit 1
    
    # Download Blueprint installer
    curl -L https://blueprint.zip/latest -o blueprint.zip
    
    if [ ! -f "blueprint.zip" ]; then
        print_error "Failed to download Blueprint"
        exit 1
    fi
    
    # Extract Blueprint
    unzip -o blueprint.zip
    rm blueprint.zip
    
    # Make Blueprint executable
    chmod +x blueprint.sh
    
    # Initialize Blueprint
    bash blueprint.sh -init
    
    print_success "Blueprint framework installed"
}

install_addon() {
    local addon_path=$1
    
    if [ ! -f "$addon_path" ]; then
        print_error "Addon file not found: $addon_path"
        return 1
    fi
    
    print_info "Installing addon: $(basename "$addon_path")"
    
    cd "$PANEL_DIR" || exit 1
    
    # Install the addon using Blueprint
    bash blueprint.sh -install "$addon_path"
    
    if [ $? -eq 0 ]; then
        print_success "Addon installed successfully"
        
        # Send Discord notification for individual addon installation
        local addon_name=$(basename "$addon_path" .blueprint)
        send_discord_notification "success" "✅ Successfully installed: **$addon_name**"
        
        return 0
    else
        print_error "Failed to install addon"
        
        # Send Discord notification for failure
        local addon_name=$(basename "$addon_path" .blueprint)
        send_discord_notification "error" "❌ Failed to install: **$addon_name**"
        
        return 1
    fi
}

update_panel() {
    print_info "Updating Pterodactyl Panel permissions..."
    cd "$PANEL_DIR" || exit 1
    
    # Set proper permissions
    chown -R www-data:www-data "$PANEL_DIR"/*
    
    # Clear cache
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    
    print_success "Panel updated"
}

display_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Pterodactyl Panel Blueprint Addon Installer          ║"
    echo "║                                                        ║"
    echo "║   Automated installation for Blueprint addons         ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_main_menu() {
    clear
    display_banner
    echo ""
    echo -e "${YELLOW}═══════════════════ MAIN MENU ═══════════════════${NC}"
    echo ""
    echo "  1) Install Blueprint Framework Only"
    echo "  2) Install Blueprint Addons"
    echo "  3) Install Everything (Framework + All Addons)"
    echo "  4) Exit"
    echo ""
    echo -e "${YELLOW}═════════════════════════════════════════════════${NC}"
    echo ""
}

show_category_menu() {
    clear
    display_banner
    echo ""
    echo -e "${YELLOW}═══════════════ ADDON CATEGORIES ════════════════${NC}"
    echo ""
    
    local i=1
    local categories=()
    
    for category in "${!ADDON_CATEGORIES[@]}"; do
        categories+=("$category")
        echo "  $i) $category"
        ((i++))
    done
    
    echo "  $i) Install All Addons"
    ((i++))
    echo "  $i) Back to Main Menu"
    echo ""
    echo -e "${YELLOW}═════════════════════════════════════════════════${NC}"
    echo ""
    
    # Return the categories array for later use
    printf '%s\n' "${categories[@]}"
}

show_addons_in_category() {
    local category=$1
    local addons=${ADDON_CATEGORIES[$category]}
    
    clear
    display_banner
    echo ""
    echo -e "${YELLOW}═════════════ $category ══════════════${NC}"
    echo ""
    
    local i=1
    local addon_array=()
    
    for addon in $addons; do
        addon_array+=("$addon")
        local addon_name=$(basename "$addon" .blueprint)
        echo "  $i) $addon_name"
        ((i++))
    done
    
    echo "  $i) Install All in Category"
    ((i++))
    echo "  $i) Back to Categories"
    echo ""
    echo -e "${YELLOW}═════════════════════════════════════════════════${NC}"
    echo ""
    
    # Return the addons array
    printf '%s\n' "${addon_array[@]}"
}

read_choice() {
    local prompt="$1"
    local choice
    echo -n -e "${GREEN}${prompt}${NC}"
    read -r choice
    # Trim whitespace
    choice=$(echo "$choice" | xargs)
    echo "$choice"
}

press_any_key() {
    echo ""
    echo -n -e "${BLUE}Press any key to continue...${NC}"
    read -n 1 -s
    echo ""
}

get_server_info() {
    # Get server IP address (public IP)
    local public_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "Unknown")
    
    # Get server hostname
    local hostname=$(hostname 2>/dev/null || echo "Unknown")
    
    # Get OS information
    local os_info=$(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2 || echo "Unknown OS")
    
    # Get panel domain if available
    local panel_domain="Unknown"
    if [ -f "${PANEL_DIR}/.env" ]; then
        panel_domain=$(grep "APP_URL" "${PANEL_DIR}/.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "Unknown")
    fi
    
    # Get local IP
    local local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Unknown")
    
    echo "$public_ip|$hostname|$os_info|$panel_domain|$local_ip"
}

send_discord_notification() {
    local event_type="$1"
    local details="$2"
    
    # Check if webhook is enabled
    if [ -z "$DISCORD_WEBHOOK_URL" ] || [ "$SEND_NOTIFICATIONS" != "true" ]; then
        return 0
    fi
    
    # Get server information
    IFS='|' read -r public_ip hostname os_info panel_domain local_ip <<< "$(get_server_info)"
    
    # Get current timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Determine color based on event type
    local color="3447003"  # Blue
    case "$event_type" in
        "start") color="3066993" ;;      # Green
        "success") color="3066993" ;;    # Green
        "error") color="15158332" ;;     # Red
        "warning") color="15105570" ;;   # Orange
    esac
    
    # Create embed description
    local description="**Server Information:**\n"
    description+="🌐 **Public IP:** \`$public_ip\`\n"
    description+="🏷️ **Hostname:** \`$hostname\`\n"
    description+="💻 **OS:** \`$os_info\`\n"
    description+="🔗 **Panel URL:** \`$panel_domain\`\n"
    description+="📡 **Local IP:** \`$local_ip\`\n\n"
    description+="$details"
    
    # Create JSON payload
    local json_payload=$(cat <<EOF
{
  "embeds": [{
    "title": "🦕 Blueprint Addon Installer - $event_type",
    "description": "$description",
    "color": $color,
    "footer": {
      "text": "Installed by KS • Pterodactyl Blueprint Installer"
    },
    "timestamp": "$timestamp"
  }]
}
EOF
)
    
    # Send to Discord webhook
    curl -H "Content-Type: application/json" \
         -d "$json_payload" \
         "$DISCORD_WEBHOOK_URL" \
         --silent --output /dev/null 2>&1 || true
}

send_installation_summary() {
    local installed=$1
    local failed=$2
    local addons_list="$3"
    
    if [ -z "$DISCORD_WEBHOOK_URL" ] || [ "$SEND_NOTIFICATIONS" != "true" ]; then
        return 0
    fi
    
    # Get server info
    IFS='|' read -r public_ip hostname os_info panel_domain local_ip <<< "$(get_server_info)"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local color="3066993"  # Green
    
    if [ $failed -gt 0 ]; then
        color="15105570"  # Orange
    fi
    
    local description="**Installation Complete!**\n\n"
    description+="✅ **Successfully Installed:** $installed addon(s)\n"
    
    if [ $failed -gt 0 ]; then
        description+="❌ **Failed:** $failed addon(s)\n"
    fi
    
    description+="\n**Server Details:**\n"
    description+="🌐 **IP:** \`$public_ip\`\n"
    description+="🏷️ **Name:** \`$hostname\`\n"
    description+="🔗 **Panel:** \`$panel_domain\`\n"
    
    if [ ! -z "$addons_list" ]; then
        description+="\n**Installed Addons:**\n$addons_list"
    fi
    
    local json_payload=$(cat <<EOF
{
  "embeds": [{
    "title": "📦 Blueprint Installation Summary",
    "description": "$description",
    "color": $color,
    "footer": {
      "text": "Installed by KS • Pterodactyl Blueprint Installer"
    },
    "timestamp": "$timestamp"
  }]
}
EOF
)
    
    curl -H "Content-Type: application/json" \
         -d "$json_payload" \
         "$DISCORD_WEBHOOK_URL" \
         --silent --output /dev/null 2>&1 || true
}

################################################################################
# Installation Functions
################################################################################

install_blueprint_only() {
    print_info "Installing Blueprint Framework..."
    check_blueprint
    print_success "Blueprint Framework is ready!"
    press_any_key
}

install_specific_addon() {
    local addon_file=$1
    local addon_name=$(basename "$addon_file")
    
    print_info "Installing: $addon_name"
    
    if install_addon "$addon_file"; then
        print_success "Successfully installed: $addon_name"
        return 0
    else
        print_error "Failed to install: $addon_name"
        return 1
    fi
}

install_addons_from_list() {
    local addon_list=("$@")
    local ADDON_DIR=$1
    shift
    addon_list=("$@")
    
    local installed=0
    local failed=0
    local addon_names=""
    
    for addon_name in "${addon_list[@]}"; do
        local addon_file="$ADDON_DIR/$addon_name"
        
        if [ -f "$addon_file" ]; then
            local name_only=$(basename "$addon_name" .blueprint)
            
            if install_addon "$addon_file"; then
                ((installed++))
                addon_names+="• $name_only\n"
            else
                ((failed++))
            fi
        else
            print_warning "Addon not found: $addon_name"
            ((failed++))
        fi
    done
    
    echo ""
    print_info "Installation Summary:"
    print_success "Successfully installed: $installed addon(s)"
    
    if [ $failed -gt 0 ]; then
        print_warning "Failed to install: $failed addon(s)"
    fi
    
    # Send summary notification to Discord
    send_installation_summary "$installed" "$failed" "$addon_names"
}

install_all_addons() {
    local ADDON_DIR=$1
    
    print_info "Installing all addons..."
    
    # Find all .blueprint files
    addon_files=($(find "$ADDON_DIR" -maxdepth 1 -name "*.blueprint" -type f))
    
    if [ ${#addon_files[@]} -eq 0 ]; then
        print_error "No .blueprint addon files found"
        return 1
    fi
    
    local installed=0
    local failed=0
    local addon_names=""
    
    for addon in "${addon_files[@]}"; do
        local addon_name=$(basename "$addon" .blueprint)
        
        if install_addon "$addon"; then
            ((installed++))
            addon_names+="• $addon_name\n"
        else
            ((failed++))
        fi
    done
    
    echo ""
    print_info "Installation Summary:"
    print_success "Successfully installed: $installed addon(s)"
    
    if [ $failed -gt 0 ]; then
        print_warning "Failed to install: $failed addon(s)"
    fi
    
    # Send summary notification to Discord
    send_installation_summary "$installed" "$failed" "$addon_names"
}

handle_category_selection() {
    local ADDON_DIR=$1
    
    while true; do
        # Get categories
        mapfile -t categories < <(for cat in "${!ADDON_CATEGORIES[@]}"; do echo "$cat"; done | sort)
        
        show_category_menu > /dev/null
        
        local total_options=$((${#categories[@]} + 2))
        local choice=$(read_choice "Select category (1-$total_options): ")
        
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_error "Invalid input. Please enter a number."
            press_any_key
            continue
        fi
        
        if [ "$choice" -eq $((total_options - 1)) ]; then
            # Install all addons
            print_info "Installing all addons from all categories..."
            install_all_addons "$ADDON_DIR"
            update_panel
            press_any_key
            
        elif [ "$choice" -eq $total_options ]; then
            # Back to main menu
            break
            
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#categories[@]} ]; then
            # Valid category selection
            local selected_category="${categories[$((choice-1))]}"
            handle_addon_selection "$ADDON_DIR" "$selected_category"
        else
            print_error "Invalid selection. Please try again."
            press_any_key
        fi
    done
}

handle_addon_selection() {
    local ADDON_DIR=$1
    local category=$2
    
    while true; do
        # Get addons in this category
        local addons_str=${ADDON_CATEGORIES[$category]}
        local addon_array=($addons_str)
        
        show_addons_in_category "$category" > /dev/null
        
        local total_options=$((${#addon_array[@]} + 2))
        local choice=$(read_choice "Select addon (1-$total_options): ")
        
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_error "Invalid input. Please enter a number."
            press_any_key
            continue
        fi
        
        if [ "$choice" -eq $((total_options - 1)) ]; then
            # Install all in category
            print_info "Installing all addons in '$category' category..."
            install_addons_from_list "$ADDON_DIR" "${addon_array[@]}"
            update_panel
            press_any_key
            
        elif [ "$choice" -eq $total_options ]; then
            # Back to categories
            break
            
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#addon_array[@]} ]; then
            # Valid addon selection
            local selected_addon="${addon_array[$((choice-1))]}"
            local addon_file="$ADDON_DIR/$selected_addon"
            
            if [ -f "$addon_file" ]; then
                install_specific_addon "$addon_file"
                update_panel
                press_any_key
            else
                print_error "Addon file not found: $selected_addon"
                press_any_key
            fi
        else
            print_error "Invalid selection. Please try again."
            press_any_key
        fi
    done
}

################################################################################
# Main Installation Process
################################################################################

main() {
    # Send start notification
    send_discord_notification "start" "🚀 **Installation Started**\n\nBlueprint addon installation has been initiated on this server."
    
    # Initial checks
    check_root
    check_dependencies
    check_pterodactyl
    
    # Download addons once at startup
    print_info "Preparing addon files..."
    ADDON_DIR=$(download_from_github)
    
    # Main menu loop
    while true; do
        show_main_menu
        
        local choice=$(read_choice "Enter your choice (1-4): ")
        
        case $choice in
            1)
                # Install Blueprint Framework Only
                clear
                display_banner
                install_blueprint_only
                ;;
            2)
                # Install Blueprint Addons
                check_blueprint
                handle_category_selection "$ADDON_DIR"
                ;;
            3)
                # Install Everything
                clear
                display_banner
                print_info "Installing Blueprint Framework and all addons..."
                check_blueprint
                install_all_addons "$ADDON_DIR"
                update_panel
                
                echo ""
                print_success "Installation complete!"
                print_info "Please restart your web server (nginx/apache) if needed"
                press_any_key
                ;;
            4)
                # Exit
                clear
                print_info "Cleaning up..."
                rm -rf "$ADDON_DIR"
                print_success "Thank you for using Blueprint Addon Installer!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                press_any_key
                ;;
        esac
    done
}

################################################################################
# Script Entry Point
################################################################################

# Display usage if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: sudo bash install.sh"
    echo ""
    echo "This script will:"
    echo "  1. Check for Pterodactyl Panel installation"
    echo "  2. Install Blueprint framework (if not installed)"
    echo "  3. Download .blueprint addon files from GitHub"
    echo "  4. Install all downloaded addons"
    echo "  5. Update panel permissions and cache"
    echo ""
    echo "Configuration:"
    echo "  Edit the script to set your GitHub repository details:"
    echo "  - GITHUB_USER: Your GitHub username"
    echo "  - GITHUB_REPO: Your repository name"
    echo "  - GITHUB_BRANCH: Branch name (usually 'main' or 'master')"
    echo ""
    echo "  Or set direct URLs:"
    echo "  - BLUEPRINT_URLS: Comma-separated list of direct URLs to .blueprint files"
    echo ""
    echo "Requirements:"
    echo "  - Must be run as root"
    echo "  - Pterodactyl Panel must be installed at /var/www/pterodactyl"
    echo "  - Internet connection to download from GitHub"
    exit 0
fi

# Run main installation
main

exit 0
