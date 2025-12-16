#!/bin/bash
# KANT Klipper Installer Module
# Handles installation of Klipper and core components

# Helper function to ensure KIAUH is installed
ensure_kiauh_installed() {
    if [ ! -d "${HOME}/kiauh" ]; then
        echo -e "${YELLOW}KIAUH not found. Installing KIAUH...${NC}"
        cd "${HOME}"
        git clone https://github.com/dw-0/kiauh.git
        echo -e "${GREEN}KIAUH installed successfully!${NC}"
        echo ""
    fi
}

# Install Klipper
install_klipper() {
    show_header
    echo -e "${BLUE}INSTALL KLIPPER${NC}"
    echo ""
    
    # Check if Klipper is already installed
    if [ -d "${HOME}/klipper" ] || systemctl is-active --quiet klipper.service; then
        echo -e "${GREEN}Klipper is already installed!${NC}"
        echo ""
        echo "Klipper directory: ${HOME}/klipper"
        if systemctl is-active --quiet klipper.service; then
            echo -e "Service status: ${GREEN}Active${NC}"
        else
            echo -e "Service status: ${YELLOW}Inactive${NC}"
        fi
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Klipper is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Klipper installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}

# Install Moonraker
install_moonraker() {
    show_header
    echo -e "${BLUE}INSTALL MOONRAKER${NC}"
    echo ""
    
    # Check if Moonraker is already installed
    if [ -d "${HOME}/moonraker" ] || systemctl is-active --quiet moonraker.service; then
        echo -e "${GREEN}Moonraker is already installed!${NC}"
        echo ""
        echo "Moonraker directory: ${HOME}/moonraker"
        if systemctl is-active --quiet moonraker.service; then
            echo -e "Service status: ${GREEN}Active${NC}"
        else
            echo -e "Service status: ${YELLOW}Inactive${NC}"
        fi
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Moonraker is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Moonraker installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}

# Install Mainsail
install_mainsail() {
    show_header
    echo -e "${BLUE}INSTALL MAINSAIL${NC}"
    echo ""
    
    # Check if Mainsail is already installed
    if [ -d "${HOME}/mainsail" ]; then
        echo -e "${GREEN}Mainsail is already installed!${NC}"
        echo ""
        echo "Mainsail directory: ${HOME}/mainsail"
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Mainsail is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Mainsail installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}

# Install Fluidd
install_fluidd() {
    show_header
    echo -e "${BLUE}INSTALL FLUIDD${NC}"
    echo ""
    
    # Check if Fluidd is already installed
    if [ -d "${HOME}/fluidd" ]; then
        echo -e "${GREEN}Fluidd is already installed!${NC}"
        echo ""
        echo "Fluidd directory: ${HOME}/fluidd"
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Fluidd is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Fluidd installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}

# Install Mainsail-Config
install_mainsail_config() {
    show_header
    echo -e "${BLUE}INSTALL MAINSAIL-CONFIG${NC}"
    echo ""
    
    # Check if Mainsail-Config is already installed
    if [ -d "${HOME}/mainsail-config" ] || [ -d "${KLIPPER_CONFIG}/mainsail-config" ]; then
        echo -e "${GREEN}Mainsail-Config is already installed!${NC}"
        echo ""
        if [ -d "${HOME}/mainsail-config" ]; then
            echo "Config directory: ${HOME}/mainsail-config"
        fi
        if [ -d "${KLIPPER_CONFIG}/mainsail-config" ]; then
            echo "Config directory: ${KLIPPER_CONFIG}/mainsail-config"
        fi
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Mainsail-Config is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Mainsail-Config installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}

# Install Fluidd-Config
install_fluidd_config() {
    show_header
    echo -e "${BLUE}INSTALL FLUIDD-CONFIG${NC}"
    echo ""
    
    # Check if Fluidd-Config is already installed
    if [ -d "${HOME}/fluidd-config" ] || [ -d "${KLIPPER_CONFIG}/fluidd-config" ]; then
        echo -e "${GREEN}Fluidd-Config is already installed!${NC}"
        echo ""
        if [ -d "${HOME}/fluidd-config" ]; then
            echo "Config directory: ${HOME}/fluidd-config"
        fi
        if [ -d "${KLIPPER_CONFIG}/fluidd-config" ]; then
            echo "Config directory: ${KLIPPER_CONFIG}/fluidd-config"
        fi
        read -p "Press Enter to continue..." dummy
        klipper_install_menu
        return
    fi
    
    echo "Fluidd-Config is not installed. Preparing to install..."
    echo ""
    
    # Ensure KIAUH is installed
    ensure_kiauh_installed
    
    echo -e "${CYAN}Starting KIAUH for Fluidd-Config installation...${NC}"
    echo "Please follow the KIAUH prompts to complete the installation."
    echo ""
    read -p "Press Enter to launch KIAUH..." dummy
    
    # Launch KIAUH
    cd "${HOME}/kiauh"
    ./kiauh.sh
    
    echo ""
    echo -e "${GREEN}Returned from KIAUH.${NC}"
    read -p "Press Enter to continue..." dummy
    klipper_install_menu
}
