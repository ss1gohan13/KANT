#!/bin/bash
# Force script to exit if an error occurs
set -e

# Script Info
# Last Updated: 2025-10-31 11:01:58 UTC
# Author: ss1gohan13

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all required modules
source "${SCRIPT_DIR}/core/config.sh"
source "${SCRIPT_DIR}/core/utils.sh"
source "${SCRIPT_DIR}/modules/macro_installer.sh"
source "${SCRIPT_DIR}/modules/hardware_config.sh"
source "${SCRIPT_DIR}/modules/software_management.sh"
source "${SCRIPT_DIR}/modules/canbus.sh"
source "${SCRIPT_DIR}/modules/diagnostics.sh"
source "${SCRIPT_DIR}/modules/backups.sh"
source "${SCRIPT_DIR}/modules/calibration.sh"

# Source all plugin modules
source "${SCRIPT_DIR}/modules/plugins/klipper_network_status.sh"
source "${SCRIPT_DIR}/modules/plugins/gcode_shell.sh"
source "${SCRIPT_DIR}/modules/plugins/kamp.sh"
source "${SCRIPT_DIR}/modules/plugins/numpy_adxl.sh"
source "${SCRIPT_DIR}/modules/plugins/eddy_ng.sh"
source "${SCRIPT_DIR}/modules/plugins/firmware_retraction.sh"
source "${SCRIPT_DIR}/modules/plugins/force_move.sh"
source "${SCRIPT_DIR}/modules/plugins/max_extrude_cross_section.sh"
source "${SCRIPT_DIR}/modules/klipper_installer.sh"

# Source all menu modules
source "${SCRIPT_DIR}/menus/main_menu.sh"
source "${SCRIPT_DIR}/menus/hardware_menu.sh"
source "${SCRIPT_DIR}/menus/software_menu.sh"
source "${SCRIPT_DIR}/menus/diagnostics_menu.sh"
source "${SCRIPT_DIR}/menus/backup_menu.sh"
source "${SCRIPT_DIR}/menus/additional_features_menu.sh"
source "${SCRIPT_DIR}/menus/klipper_install_menu.sh"

# Parse command line arguments
while getopts "c:s:ulh" arg; do
    case $arg in
        c)
            KLIPPER_CONFIG="$OPTARG"
            ;;
        s)
            KLIPPER_SERVICE_NAME="$OPTARG"
            ;;
        u)
            UNINSTALL=1
            ;;
        l)
            MENU_MODE=0
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# MAIN EXECUTION
verify_ready

if [ $UNINSTALL ]; then
    check_klipper
    create_backup_dir
    stop_klipper
    get_user_macro_files
    restore_backup
    start_klipper
    echo -e "${GREEN}Uninstallation complete! Original configuration has been restored.${NC}"
elif [ $MENU_MODE -eq 1 ]; then
    # Interactive menu mode (default)
    show_main_menu
else
    # Linear installation flow
    check_klipper
    create_backup_dir
    stop_klipper
    get_user_macro_files
    backup_existing_macros
    install_macros
    check_and_update_printer_cfg
    install_web_interface_config
    add_force_move
    start_klipper
    echo -e "${GREEN}Installation complete! Please check your printer's web interface to verify the changes.${NC}"

    echo ""
    echo "Would you like to install A Better Print_Start Macro?"
    echo "Note: This will also install KAMP, which needs to be configured per KAMP documentation."
    echo "More information can be found at: https://github.com/ss1gohan13/A-better-print_start-macro"
    read -p "Install Print_Start macro and KAMP? (y/N): " install_print_start
    
    if [[ "$install_print_start" =~ ^[Yy]$ ]]; then
        echo "Installing KAMP and A Better Print_Start Macro..."
        curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-better-print_start-macro/main/install_start_print.sh | bash
        add_max_extrude_cross_section_to_extruder
        add_firmware_retraction_to_printer_cfg
        echo ""
        echo -e "${GREEN}Print_Start macro and KAMP have been installed!${NC}"
        echo "Please visit https://github.com/ss1gohan13/A-better-print_start-macro for instructions on configuring your slicer settings."
        
        # Add numpy installation for ADXL resonance measurements
        echo ""
        echo "Would you like to install numpy for ADXL resonance measurements?"
        echo "This is recommended if you plan to use input shaping with an ADXL345 accelerometer."
        read -p "Install numpy? (y/N): " install_numpy
        
        if [[ "$install_numpy" =~ ^[Yy]$ ]]; then
            install_numpy_for_adxl
        fi
    fi

    echo ""
    echo "Would you like to install A Better End Print Macro?"
    echo "Note: This requires additional changes to your slicer settings."
    echo "More information can be found at: https://github.com/ss1gohan13/A-Better-End-Print-Macro"
    read -p "Install End Print macro? (y/N): " install_end_print
    
    if [[ "$install_end_print" =~ ^[Yy]$ ]]; then
        echo "Installing A Better End Print Macro..."
        cd ~
        curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-Better-End-Print-Macro/main/direct_install.sh | bash
        echo ""
        echo -e "${GREEN}End Print macro has been installed!${NC}"
        echo "Please visit https://github.com/ss1gohan13/A-Better-End-Print-Macro for instructions on configuring your slicer settings."
    fi
    
    echo ""
    echo -e "${CYAN}TIP: If you prefer the menu-driven interface, just run this script without the -l flag!${NC}"
fi
