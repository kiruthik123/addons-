#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Blueprint repository base URL (using RAW GitHub URLs)
BLUEPRINT_REPO_BASE="https://raw.githubusercontent.com/kiruthik123/addons-/main"

# List of available blueprints
BLUEPRINTS=(
    "activitypurges.blueprint"
    "console.logs.blueprint"
    "huxregister.blueprint"
    "laravellogs.blueprint"
    "lyrdyannounce.blueprint"
    "mdlogs.blueprint"
    "modrinthbrowser.blueprint"
    "nightadmin.blueprint"
    "resourcealerts.blueprint"
    "resourcemanager.blueprint"
    "serverbackgrounds.blueprint"
    "shownodeids.blueprint"
    "simplefooters.blueprint"
    "translations.blueprint"
    "urldownloader.blueprint"
    "votifiertester.blueprint"
)

# Display banner
display_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   Pterodactyl Panel Addons Installer                     ║"
    echo "║   Created by kiruthik123                                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if blueprint command exists
check_blueprint_installation() {
    if ! command -v blueprint &> /dev/null; then
        echo -e "${RED}Error: blueprint command not found!${NC}"
        echo -e "${YELLOW}Please install blueprint-cli first:${NC}"
        echo "npm install -g @pterodactyl/blueprint-cli"
        echo -e "${YELLOW}Or visit: https://docs.blueprint.zip${NC}"
        
        read -p "Do you want to install blueprint-cli now? (y/n): " install_bp
        if [[ $install_bp == "y" || $install_bp == "Y" ]]; then
            install_blueprint_cli
        else
            echo -e "${YELLOW}You can install it manually later.${NC}"
            echo -e "${YELLOW}Continuing with installation...${NC}"
        fi
    fi
}

# Install blueprint-cli
install_blueprint_cli() {
    echo -e "${YELLOW}Installing blueprint-cli...${NC}"
    
    # Check if npm exists
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm not found! Installing Node.js and npm...${NC}"
        
        # Detect OS and install Node.js
        if [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif [[ -f /etc/redhat-release ]]; then
            # RHEL/CentOS/Fedora
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs
        elif [[ $(uname) == "Darwin" ]]; then
            # macOS
            brew install node
        else
            echo -e "${RED}Unsupported OS. Please install Node.js manually.${NC}"
            echo "Visit: https://nodejs.org/"
            return 1
        fi
    fi
    
    # Install blueprint-cli globally
    echo -e "${YELLOW}Installing @pterodactyl/blueprint-cli via npm...${NC}"
    sudo npm install -g @pterodactyl/blueprint-cli
    
    if command -v blueprint &> /dev/null; then
        echo -e "${GREEN}✓ blueprint-cli installed successfully!${NC}"
    else
        echo -e "${RED}Failed to install blueprint-cli. Please install manually.${NC}"
    fi
}

# Display main menu
main_menu() {
    display_banner
    echo -e "${GREEN}Main Menu:${NC}"
    echo -e "${YELLOW}1.${NC} Install Addons"
    echo -e "${YELLOW}2.${NC} View Available Blueprints"
    echo -e "${YELLOW}3.${NC} Check Blueprint Installation"
    echo -e "${YELLOW}4.${NC} Update Installer Script"
    echo -e "${YELLOW}5.${NC} Exit"
    echo ""
    read -p "Select an option (1-5): " main_choice

    case $main_choice in
        1)
            install_addons_menu
            ;;
        2)
            view_blueprints
            ;;
        3)
            check_blueprint
            ;;
        4)
            update_installer
            ;;
        5)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 2
            main_menu
            ;;
    esac
}

# Display install addons menu
install_addons_menu() {
    display_banner
    echo -e "${GREEN}Install Addons:${NC}"
    
    # Display all blueprints with numbers
    for i in "${!BLUEPRINTS[@]}"; do
        blueprint_name="${BLUEPRINTS[$i]%.blueprint}"
        echo -e "${YELLOW}$((i+1)).${NC} ${blueprint_name}"
    done
    
    echo -e "${YELLOW}$((${#BLUEPRINTS[@]}+1)).${NC} Install All Blueprints"
    echo -e "${YELLOW}$((${#BLUEPRINTS[@]}+2)).${NC} Custom Blueprint URL"
    echo -e "${YELLOW}$((${#BLUEPRINTS[@]}+3)).${NC} Back to Main Menu"
    echo ""
    
    read -p "Select blueprint to install (1-$((${#BLUEPRINTS[@]}+3))): " choice
    
    if [[ $choice -eq $((${#BLUEPRINTS[@]}+1)) ]]; then
        install_all_blueprints
    elif [[ $choice -eq $((${#BLUEPRINTS[@]}+2)) ]]; then
        install_custom_blueprint
    elif [[ $choice -eq $((${#BLUEPRINTS[@]}+3)) ]]; then
        main_menu
    elif [[ $choice -ge 1 && $choice -le ${#BLUEPRINTS[@]} ]]; then
        install_single_blueprint $((choice-1))
    else
        echo -e "${RED}Invalid selection!${NC}"
        sleep 2
        install_addons_menu
    fi
}

# Install a single blueprint
install_single_blueprint() {
    local index=$1
    local blueprint_file="${BLUEPRINTS[$index]}"
    local blueprint_name="${blueprint_file%.blueprint}"
    local blueprint_url="${BLUEPRINT_REPO_BASE}/${blueprint_file}"
    
    display_banner
    echo -e "${GREEN}Installing: ${blueprint_name}${NC}"
    echo -e "${YELLOW}Blueprint URL: ${blueprint_url}${NC}"
    echo ""
    
    echo -e "${YELLOW}Step 1: Downloading blueprint from GitHub...${NC}"
    
    # Create temp directory
    TEMP_DIR="/tmp/pterodactyl-addons"
    mkdir -p "$TEMP_DIR"
    
    # Download the blueprint file
    if curl -s -f -L "$blueprint_url" -o "$TEMP_DIR/$blueprint_file"; then
        echo -e "${GREEN}✓ Blueprint downloaded successfully!${NC}"
        echo -e "${YELLOW}Step 2: Installing with blueprint command...${NC}"
        
        # Check if blueprint command exists
        if ! command -v blueprint &> /dev/null; then
            echo -e "${RED}Blueprint command not found!${NC}"
            read -p "Do you want to install blueprint-cli now? (y/n): " install_now
            if [[ $install_now == "y" || $install_now == "Y" ]]; then
                install_blueprint_cli
                if ! command -v blueprint &> /dev/null; then
                    echo -e "${RED}Cannot continue without blueprint command.${NC}"
                    read -p "Press Enter to continue..."
                    return
                fi
            else
                echo -e "${YELLOW}Skipping installation. You can install manually later.${NC}"
                echo -e "${YELLOW}Blueprint saved at: $TEMP_DIR/$blueprint_file${NC}"
                read -p "Press Enter to continue..."
                return
            fi
        fi
        
        # Install using blueprint command
        echo -e "${YELLOW}Running: blueprint -i \"$TEMP_DIR/$blueprint_file\"${NC}"
        if blueprint -i "$TEMP_DIR/$blueprint_file"; then
            echo -e "${GREEN}✓ Successfully installed ${blueprint_name}!${NC}"
        else
            echo -e "${RED}✗ Failed to install ${blueprint_name}${NC}"
            echo -e "${YELLOW}You can try installing manually:${NC}"
            echo "blueprint -i \"$TEMP_DIR/$blueprint_file\""
        fi
        
        # Ask if user wants to keep the blueprint file
        echo ""
        read -p "Keep the downloaded blueprint file? (y/n): " keep_file
        if [[ $keep_file != "y" && $keep_file != "Y" ]]; then
            rm -f "$TEMP_DIR/$blueprint_file"
            echo -e "${YELLOW}Blueprint file removed.${NC}"
        fi
        
    else
        echo -e "${RED}✗ Failed to download ${blueprint_file}${NC}"
        echo -e "${YELLOW}Possible issues:${NC}"
        echo "1. Internet connection"
        echo "2. File doesn't exist in repository: ${blueprint_url}"
        echo "3. GitHub rate limiting"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    install_addons_menu
}

# Install all blueprints
install_all_blueprints() {
    display_banner
    echo -e "${GREEN}Installing All Blueprints${NC}"
    echo -e "${YELLOW}This will install ${#BLUEPRINTS[@]} blueprints${NC}"
    echo ""
    read -p "Are you sure? (y/n): " confirm
    
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        install_addons_menu
        return
    fi
    
    # Check blueprint command
    if ! command -v blueprint &> /dev/null; then
        echo -e "${RED}Blueprint command not found!${NC}"
        read -p "Do you want to install blueprint-cli now? (y/n): " install_now
        if [[ $install_now == "y" || $install_now == "Y" ]]; then
            install_blueprint_cli
            if ! command -v blueprint &> /dev/null; then
                echo -e "${RED}Cannot continue without blueprint command.${NC}"
                read -p "Press Enter to continue..."
                return
            fi
        else
            echo -e "${YELLOW}Cannot install blueprints without blueprint command.${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    fi
    
    # Create temp directory
    TEMP_DIR="/tmp/pterodactyl-addons"
    mkdir -p "$TEMP_DIR"
    
    success_count=0
    fail_count=0
    
    for blueprint_file in "${BLUEPRINTS[@]}"; do
        local blueprint_name="${blueprint_file%.blueprint}"
        local blueprint_url="${BLUEPRINT_REPO_BASE}/${blueprint_file}"
        
        echo ""
        echo -e "${BLUE}Installing: ${blueprint_name}${NC}"
        echo -e "${YELLOW}Downloading from: ${blueprint_url}${NC}"
        
        # Download the blueprint file
        if curl -s -f -L "$blueprint_url" -o "$TEMP_DIR/$blueprint_file"; then
            # Install using blueprint command
            if blueprint -i "$TEMP_DIR/$blueprint_file" &> /dev/null; then
                echo -e "${GREEN}✓ ${blueprint_name} installed${NC}"
                ((success_count++))
            else
                echo -e "${RED}✗ ${blueprint_name} failed to install${NC}"
                ((fail_count++))
            fi
            
            # Clean up
            rm -f "$TEMP_DIR/$blueprint_file"
        else
            echo -e "${RED}✗ ${blueprint_name} failed to download${NC}"
            ((fail_count++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "Successfully installed: ${success_count}"
    echo -e "Failed: ${fail_count}"
    echo ""
    
    # Clean temp directory if empty
    if [ -z "$(ls -A $TEMP_DIR)" ]; then
        rmdir "$TEMP_DIR"
    fi
    
    read -p "Press Enter to continue..."
    install_addons_menu
}

# Install custom blueprint from URL
install_custom_blueprint() {
    display_banner
    echo -e "${GREEN}Custom Blueprint Installation${NC}"
    echo ""
    echo -e "${YELLOW}Enter the full URL to a blueprint file:${NC}"
    read -p "URL: " custom_url
    
    if [[ -z "$custom_url" ]]; then
        echo -e "${RED}No URL provided!${NC}"
        sleep 2
        install_addons_menu
        return
    fi
    
    # Extract filename from URL
    blueprint_file=$(basename "$custom_url")
    
    echo ""
    echo -e "${YELLOW}Downloading: ${blueprint_file}${NC}"
    
    # Create temp directory
    TEMP_DIR="/tmp/pterodactyl-addons"
    mkdir -p "$TEMP_DIR"
    
    # Download the blueprint file
    if curl -s -f -L "$custom_url" -o "$TEMP_DIR/$blueprint_file"; then
        echo -e "${GREEN}✓ Blueprint downloaded successfully!${NC}"
        
        # Check if blueprint command exists
        if ! command -v blueprint &> /dev/null; then
            echo -e "${RED}Blueprint command not found!${NC}"
            echo -e "${YELLOW}Blueprint saved at: $TEMP_DIR/$blueprint_file${NC}"
            echo -e "${YELLOW}Install blueprint-cli first, then run:${NC}"
            echo "blueprint -i \"$TEMP_DIR/$blueprint_file\""
            read -p "Press Enter to continue..."
            return
        fi
        
        # Install using blueprint command
        echo -e "${YELLOW}Installing with blueprint command...${NC}"
        if blueprint -i "$TEMP_DIR/$blueprint_file"; then
            echo -e "${GREEN}✓ Successfully installed custom blueprint!${NC}"
        else
            echo -e "${RED}✗ Failed to install blueprint${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to download from URL${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    install_addons_menu
}

# View available blueprints
view_blueprints() {
    display_banner
    echo -e "${GREEN}Available Blueprints:${NC}"
    echo ""
    
    for blueprint_file in "${BLUEPRINTS[@]}"; do
        blueprint_name="${blueprint_file%.blueprint}"
        blueprint_url="${BLUEPRINT_REPO_BASE}/${blueprint_file}"
        echo -e "  ${YELLOW}●${NC} ${blueprint_name}"
        echo -e "     ${BLUE}URL: ${blueprint_url}${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}Total: ${#BLUEPRINTS[@]} blueprints available${NC}"
    echo ""
    read -p "Press Enter to return to main menu..."
    main_menu
}

# Check blueprint installation
check_blueprint() {
    display_banner
    echo -e "${GREEN}Blueprint Installation Check:${NC}"
    echo ""
    
    if command -v blueprint &> /dev/null; then
        echo -e "${GREEN}✓ blueprint command is available${NC}"
        blueprint_version=$(blueprint --version 2>/dev/null || echo "unknown")
        echo -e "  Version: ${blueprint_version}"
    else
        echo -e "${RED}✗ blueprint command not found${NC}"
        echo ""
        echo -e "${YELLOW}To install blueprint-cli:${NC}"
        echo "npm install -g @pterodactyl/blueprint-cli"
    fi
    
    echo ""
    echo -e "${YELLOW}Repository Information:${NC}"
    echo "  URL: https://github.com/kiruthik123/addons-"
    echo "  Blueprints: ${#BLUEPRINTS[@]} files"
    echo ""
    read -p "Press Enter to return to main menu..."
    main_menu
}

# Update installer script
update_installer() {
    display_banner
    echo -e "${GREEN}Update Installer Script${NC}"
    echo ""
    
    SCRIPT_URL="https://raw.githubusercontent.com/kiruthik123/addons-/main/install.sh"
    
    echo -e "${YELLOW}Current script: $0${NC}"
    echo -e "${YELLOW}Update from: $SCRIPT_URL${NC}"
    echo ""
    read -p "Update installer script? (y/n): " confirm_update
    
    if [[ $confirm_update == "y" || $confirm_update == "Y" ]]; then
        echo -e "${YELLOW}Downloading latest version...${NC}"
        
        # Download to temporary file first
        if curl -s -f -L "$SCRIPT_URL" -o "/tmp/install.sh.new"; then
            # Make it executable
            chmod +x "/tmp/install.sh.new"
            
            # Replace current script
            mv "/tmp/install.sh.new" "$0"
            
            echo -e "${GREEN}✓ Installer updated successfully!${NC}"
            echo -e "${YELLOW}Restarting installer...${NC}"
            echo ""
            
            # Restart the script
            exec "$0"
        else
            echo -e "${RED}✗ Failed to download update${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
    main_menu
}

# Main script execution
main() {
    # Check for dependencies
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is not installed!${NC}"
        echo "Install it with: sudo apt-get install curl"
        exit 1
    fi
    
    # Create temp directory
    mkdir -p /tmp/pterodactyl-addons
    
    # Start the menu system
    main_menu
}

# Run main function
main
