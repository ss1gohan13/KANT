#!/bin/bash
# KANT Software Management Module
# Handles installation and management of Klipper software/plugins

# Note: The following functions are placeholders and need actual implementation
# based on the specific installation procedures for each software

install_kiauh() {
    show_header
    echo -e "${BLUE}INSTALLING KIAUH${NC}"
    echo "Installing Klipper Installation And Update Helper..."
    echo ""
    
    if [ -d "${HOME}/kiauh" ]; then
        echo -e "${YELLOW}KIAUH is already installed at ~/kiauh${NC}"
        read -p "Would you like to update it? (y/N): " update_choice
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            cd "${HOME}/kiauh"
            git pull
            echo -e "${GREEN}KIAUH updated successfully!${NC}"
        fi
    else
        cd "${HOME}"
        git clone https://github.com/dw-0/kiauh.git
        echo -e "${GREEN}KIAUH installed successfully!${NC}"
        echo "Run it with: ./kiauh/kiauh.sh"
    fi
    
    read -p "Press Enter to continue..." dummy
    core_software_menu
}

update_macros() {
    show_header
    echo -e "${BLUE}UPDATE KLIPPER MACROS${NC}"
    echo "This will download and install the latest version of KANT macros."
    echo ""
    
    read -p "Continue with update? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        check_klipper
        create_backup_dir
        stop_klipper
        backup_existing_macros
        install_macros
        start_klipper
        echo -e "${GREEN}Macros updated successfully!${NC}"
    else
        echo "Update cancelled."
    fi
    
    read -p "Press Enter to continue..." dummy
    core_software_menu
}

check_system_updates() {
    show_header
    echo -e "${BLUE}CHECK SYSTEM UPDATES${NC}"
    echo "Checking for available system updates..."
    echo ""
    
    sudo apt update
    echo ""
    echo "Available updates:"
    apt list --upgradable
    echo ""
    
    read -p "Would you like to install updates? (y/N): " install_updates
    if [[ "$install_updates" =~ ^[Yy]$ ]]; then
        sudo apt upgrade -y
        echo -e "${GREEN}System updated successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    core_software_menu
}

# LED Effects functions
install_led_effects() {
    show_header
    echo -e "${BLUE}INSTALL KLIPPER LED EFFECTS${NC}"
    echo "Installing Klipper LED Effects plugin..."
    echo ""
    
    if [ -d "${HOME}/klipper-led_effect" ]; then
        echo -e "${YELLOW}Klipper LED Effects is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        led_effects_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/julianschill/klipper-led_effect.git
    cd klipper-led_effect
    ./install-led_effect.sh
    
    echo -e "${GREEN}Klipper LED Effects installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    led_effects_menu
}

uninstall_led_effects() {
    show_header
    echo -e "${BLUE}UNINSTALL KLIPPER LED EFFECTS${NC}"
    echo ""
    
    if [ ! -d "${HOME}/klipper-led_effect" ]; then
        echo -e "${YELLOW}Klipper LED Effects is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        led_effects_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall LED Effects? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/klipper-led_effect"
        ./uninstall-led_effect.sh
        cd "${HOME}"
        rm -rf klipper-led_effect
        echo -e "${GREEN}Klipper LED Effects uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    led_effects_menu
}

check_led_effects_status() {
    show_header
    echo -e "${BLUE}KLIPPER LED EFFECTS STATUS${NC}"
    echo ""
    
    if [ -d "${HOME}/klipper-led_effect" ]; then
        echo -e "${GREEN}Status: Installed${NC}"
        echo "Location: ${HOME}/klipper-led_effect"
    else
        echo -e "${YELLOW}Status: Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    led_effects_menu
}

# Shake&Tune functions
install_shake_tune() {
    show_header
    echo -e "${BLUE}INSTALL SHAKE&TUNE${NC}"
    echo "Installing Shake&Tune for input shaping analysis..."
    echo ""
    
    if [ -d "${HOME}/klippain_shaketune" ]; then
        echo -e "${YELLOW}Shake&Tune is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        input_shaping_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/Frix-x/klippain-shaketune.git klippain_shaketune
    cd klippain_shaketune
    ./install.sh
    
    echo -e "${GREEN}Shake&Tune installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    input_shaping_menu
}

uninstall_shake_tune() {
    show_header
    echo -e "${BLUE}UNINSTALL SHAKE&TUNE${NC}"
    echo ""
    
    if [ ! -d "${HOME}/klippain_shaketune" ]; then
        echo -e "${YELLOW}Shake&Tune is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        input_shaping_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall Shake&Tune? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/klippain_shaketune"
        ./install.sh -u
        cd "${HOME}"
        rm -rf klippain_shaketune
        echo -e "${GREEN}Shake&Tune uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    input_shaping_menu
}

check_shake_tune_status() {
    show_header
    echo -e "${BLUE}SHAKE&TUNE STATUS${NC}"
    echo ""
    
    if [ -d "${HOME}/klippain_shaketune" ]; then
        echo -e "${GREEN}Status: Installed${NC}"
        echo "Location: ${HOME}/klippain_shaketune"
    else
        echo -e "${YELLOW}Status: Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    input_shaping_menu
}

# TMC Autotune functions
install_tmc_autotune() {
    show_header
    echo -e "${BLUE}INSTALL TMC AUTOTUNE${NC}"
    echo "Installing TMC Autotune for automatic driver tuning..."
    echo ""
    
    if [ -d "${HOME}/klipper_tmc_autotune" ]; then
        echo -e "${YELLOW}TMC Autotune is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        hardware_tuning_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/andrewmcgr/klipper_tmc_autotune.git
    cd klipper_tmc_autotune
    ./install.sh
    
    echo -e "${GREEN}TMC Autotune installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    hardware_tuning_menu
}

uninstall_tmc_autotune() {
    show_header
    echo -e "${BLUE}UNINSTALL TMC AUTOTUNE${NC}"
    echo ""
    
    if [ ! -d "${HOME}/klipper_tmc_autotune" ]; then
        echo -e "${YELLOW}TMC Autotune is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        hardware_tuning_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall TMC Autotune? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/klipper_tmc_autotune"
        ./install.sh -u
        cd "${HOME}"
        rm -rf klipper_tmc_autotune
        echo -e "${GREEN}TMC Autotune uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    hardware_tuning_menu
}

check_tmc_autotune_status() {
    show_header
    echo -e "${BLUE}TMC AUTOTUNE STATUS${NC}"
    echo ""
    
    if [ -d "${HOME}/klipper_tmc_autotune" ]; then
        echo -e "${GREEN}Status: Installed${NC}"
        echo "Location: ${HOME}/klipper_tmc_autotune"
    else
        echo -e "${YELLOW}Status: Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    hardware_tuning_menu
}

# KlipperScreen functions
install_klipperscreen() {
    show_header
    echo -e "${BLUE}INSTALL KLIPPERSCREEN${NC}"
    echo "Installing KlipperScreen touchscreen interface..."
    echo ""
    
    if [ -d "${HOME}/KlipperScreen" ]; then
        echo -e "${YELLOW}KlipperScreen is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        touchscreen_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/KlipperScreen/KlipperScreen.git
    cd KlipperScreen
    ./scripts/KlipperScreen-install.sh
    
    echo -e "${GREEN}KlipperScreen installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    touchscreen_menu
}

uninstall_klipperscreen() {
    show_header
    echo -e "${BLUE}UNINSTALL KLIPPERSCREEN${NC}"
    echo ""
    
    if [ ! -d "${HOME}/KlipperScreen" ]; then
        echo -e "${YELLOW}KlipperScreen is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        touchscreen_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall KlipperScreen? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/KlipperScreen"
        ./scripts/KlipperScreen-install.sh -u
        cd "${HOME}"
        rm -rf KlipperScreen
        echo -e "${GREEN}KlipperScreen uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    touchscreen_menu
}

check_klipperscreen_status() {
    show_header
    echo -e "${BLUE}KLIPPERSCREEN STATUS${NC}"
    echo ""
    
    if [ -d "${HOME}/KlipperScreen" ]; then
        echo -e "${GREEN}Status: Installed${NC}"
        echo "Location: ${HOME}/KlipperScreen"
        echo ""
        echo "Service status:"
        systemctl status KlipperScreen --no-pager || echo "Service not found"
    else
        echo -e "${YELLOW}Status: Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    touchscreen_menu
}

# Probe system functions
install_beacon() {
    show_header
    echo -e "${BLUE}INSTALL BEACON${NC}"
    echo "Installing Beacon probe support..."
    echo ""
    
    if [ -d "${HOME}/beacon_klipper" ]; then
        echo -e "${YELLOW}Beacon is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/beacon3d/beacon_klipper.git
    cd beacon_klipper
    ./install.sh
    
    echo -e "${GREEN}Beacon installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

uninstall_beacon() {
    show_header
    echo -e "${BLUE}UNINSTALL BEACON${NC}"
    echo ""
    
    if [ ! -d "${HOME}/beacon_klipper" ]; then
        echo -e "${YELLOW}Beacon is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall Beacon? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/beacon_klipper"
        ./install.sh -u
        cd "${HOME}"
        rm -rf beacon_klipper
        echo -e "${GREEN}Beacon uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

install_cartographer() {
    show_header
    echo -e "${BLUE}INSTALL CARTOGRAPHER${NC}"
    echo "Installing Cartographer probe support..."
    echo ""
    
    if [ -d "${HOME}/cartographer-klipper" ]; then
        echo -e "${YELLOW}Cartographer is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/Cartographer3D/cartographer-klipper.git
    cd cartographer-klipper
    ./install.sh
    
    echo -e "${GREEN}Cartographer installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

uninstall_cartographer() {
    show_header
    echo -e "${BLUE}UNINSTALL CARTOGRAPHER${NC}"
    echo ""
    
    if [ ! -d "${HOME}/cartographer-klipper" ]; then
        echo -e "${YELLOW}Cartographer is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall Cartographer? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/cartographer-klipper"
        ./install.sh -u
        cd "${HOME}"
        rm -rf cartographer-klipper
        echo -e "${GREEN}Cartographer uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

install_eddy_ng() {
    show_header
    echo -e "${BLUE}INSTALL EDDY-NG${NC}"
    echo "Installing Eddy-NG probe support..."
    echo ""
    
    if [ -d "${HOME}/eddy-ng" ]; then
        echo -e "${YELLOW}Eddy-NG is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/bigtreetech/eddy.git eddy-ng
    cd eddy-ng
    ./install.sh
    
    echo -e "${GREEN}Eddy-NG installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

uninstall_eddy_ng() {
    show_header
    echo -e "${BLUE}UNINSTALL EDDY-NG${NC}"
    echo ""
    
    if [ ! -d "${HOME}/eddy-ng" ]; then
        echo -e "${YELLOW}Eddy-NG is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        probe_systems_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall Eddy-NG? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/eddy-ng"
        ./install.sh -u
        cd "${HOME}"
        rm -rf eddy-ng
        echo -e "${GREEN}Eddy-NG uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

check_probe_systems_status() {
    show_header
    echo -e "${BLUE}PROBE SYSTEMS STATUS${NC}"
    echo ""
    
    echo "Beacon:"
    if [ -d "${HOME}/beacon_klipper" ]; then
        echo -e "  ${GREEN}Installed${NC}"
    else
        echo -e "  ${YELLOW}Not installed${NC}"
    fi
    
    echo ""
    echo "Cartographer:"
    if [ -d "${HOME}/cartographer-klipper" ]; then
        echo -e "  ${GREEN}Installed${NC}"
    else
        echo -e "  ${YELLOW}Not installed${NC}"
    fi
    
    echo ""
    echo "Eddy-NG:"
    if [ -d "${HOME}/eddy-ng" ]; then
        echo -e "  ${GREEN}Installed${NC}"
    else
        echo -e "  ${YELLOW}Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    probe_systems_menu
}

# Auto Z Calibration functions
install_auto_z_calibration() {
    show_header
    echo -e "${BLUE}INSTALL AUTO Z CALIBRATION${NC}"
    echo "Installing automatic Z offset calibration..."
    echo ""
    
    if [ -d "${HOME}/klipper_z_calibration" ]; then
        echo -e "${YELLOW}Auto Z Calibration is already installed.${NC}"
        read -p "Press Enter to continue..." dummy
        calibration_tools_menu
        return
    fi
    
    cd "${HOME}"
    git clone https://github.com/protoloft/klipper_z_calibration.git
    cd klipper_z_calibration
    ./install.sh
    
    echo -e "${GREEN}Auto Z Calibration installed successfully!${NC}"
    read -p "Press Enter to continue..." dummy
    calibration_tools_menu
}

uninstall_auto_z_calibration() {
    show_header
    echo -e "${BLUE}UNINSTALL AUTO Z CALIBRATION${NC}"
    echo ""
    
    if [ ! -d "${HOME}/klipper_z_calibration" ]; then
        echo -e "${YELLOW}Auto Z Calibration is not installed.${NC}"
        read -p "Press Enter to continue..." dummy
        calibration_tools_menu
        return
    fi
    
    read -p "Are you sure you want to uninstall Auto Z Calibration? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cd "${HOME}/klipper_z_calibration"
        ./install.sh -u
        cd "${HOME}"
        rm -rf klipper_z_calibration
        echo -e "${GREEN}Auto Z Calibration uninstalled successfully!${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    calibration_tools_menu
}

check_auto_z_calibration_status() {
    show_header
    echo -e "${BLUE}AUTO Z CALIBRATION STATUS${NC}"
    echo ""
    
    if [ -d "${HOME}/klipper_z_calibration" ]; then
        echo -e "${GREEN}Status: Installed${NC}"
        echo "Location: ${HOME}/klipper_z_calibration"
    else
        echo -e "${YELLOW}Status: Not installed${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    calibration_tools_menu
}