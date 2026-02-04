#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Blueprint repository base URL
BLUEPRINT_REPO_BASE="https://raw.githubusercontent.com/kiruthik123/pterodactyl-blueprints/main"

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
        exit 1
    fi
}

# Display main menu
main_menu() {
    display_banner
    echo -e "${GREEN}Main Menu:${NC}"
    echo -e "${YELLOW}1.${NC} Install Addons"
    echo -e "${YELLOW}2.${NC} View Available Blueprints"
    echo -e "${YELLOW}3.${NC} Check Blueprint Installation"
    echo -e "${YELLOW}4.${NC} Exit"
    echo ""
    read -p "Select an option (1-4): " main_choice

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
    echo -e "${YELLOW}$((${#BLUEPRINTS[@]}+2)).${NC} Back to Main Menu"
    echo ""
    
    read -p "Select blueprint to install (1-$((${#BLUEPRINTS[@]}+2))): " choice
    
    if [[ $choice -eq $((${#BLUEPRINTS[@]}+1)) ]]; then
        install_all_blueprints
    elif [[ $choice -eq $((${#BLUEPRINTS[@]}+2)) ]]; then
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
    
    display_banner
    echo -e "${GREEN}Installing: ${blueprint_name}${NC}"
    echo -e "${YELLOW}Downloading blueprint...${NC}"
    
    # Download the blueprint file
    if curl -s -f "${BLUEPRINT_REPO_BASE}/${blueprint_file}" -o "/tmp/${blueprint_file}"; then
        echo -e "${GREEN}Blueprint downloaded successfully!${NC}"
        echo -e "${YELLOW}Installing with blueprint command...${NC}"
        
        # Install using blueprint command
        if blueprint -i "/tmp/${blueprint_file}"; then
            echo -e "${GREEN}Successfully installed ${blueprint_name}!${NC}"
        else
            echo -e "${RED}Failed to install ${blueprint_name}${NC}"
        fi
        
        # Clean up
        rm -f "/tmp/${blueprint_file}"
    else
        echo -e "${RED}Failed to download ${blueprint_file}${NC}"
        echo -e "${YELLOW}Make sure you have internet connection${NC}"
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
    
    success_count=0
    fail_count=0
    
    for blueprint_file in "${BLUEPRINTS[@]}"; do
        local blueprint_name="${blueprint_file%.blueprint}"
        echo -e "${BLUE}Installing: ${blueprint_name}${NC}"
        
        # Download the blueprint file
        if curl -s -f "${BLUEPRINT_REPO_BASE}/${blueprint_file}" -o "/tmp/${blueprint_file}"; then
            # Install using blueprint command
            if blueprint -i "/tmp/${blueprint_file}" &> /dev/null; then
                echo -e "${GREEN}✓ ${blueprint_name} installed${NC}"
                ((success_count++))
            else
                echo -e "${RED}✗ ${blueprint_name} failed to install${NC}"
                ((fail_count++))
            fi
            
            # Clean up
            rm -f "/tmp/${blueprint_file}"
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
        echo -e "  ${YELLOW}●${NC} ${blueprint_name}"
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
        echo ""
        echo -e "${YELLOW}Make sure Node.js is installed first:${NC}"
        echo "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "sudo apt-get install -y nodejs"
    fi
    
    echo ""
    read -p "Press Enter to return to main menu..."
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
    
    check_blueprint_installation
    main_menu
}

# Run main function
main
