#!/bin/bash

# KANT - Klipper Assistant for New Toolheads
# A utility to assist with klipper configuration and setup

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KLIPPER_CONFIG_DIR="${HOME}/printer_data/config"
MACROS_DIR="${KLIPPER_CONFIG_DIR}/macros"
BACKUP_DIR="${KLIPPER_CONFIG_DIR}/backups"

# Source utility functions
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/mcu_utils.sh"
source "${SCRIPT_DIR}/lib/stepper_utils.sh"
source "${SCRIPT_DIR}/lib/macro_utils.sh"

# Header function
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${GREEN}KANT${NC} - Klipper Assistant              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         A utility for Klipper configuration & setup       ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main menu function
show_main_menu() {
    print_header
    echo -e "${YELLOW}Main Menu:${NC}"
    echo ""
    echo "  1) Check and Insert MCU IDs"
    echo "  2) Check for CAN IDs"
    echo "  3) Edit/Configure Stepper Pins"
    echo "  4) Install Baseline Macros"
    echo "  5) Configure Start Print Macro"
    echo "  6) Configure End Print Macro"
    echo "  7) Backup Current Configuration"
    echo "  8) About KANT"
    echo "  9) Exit"
    echo ""
    echo -n -e "${GREEN}Enter your choice [1-9]: ${NC}"
}

# About function
show_about() {
    print_header
    echo -e "${CYAN}About KANT${NC}"
    echo ""
    echo "KANT is a utility designed to assist with Klipper 3D printer"
    echo "configuration and setup. It provides an interactive menu to:"
    echo ""
    echo "  • Check and manage MCU IDs"
    echo "  • Scan for CAN bus devices"
    echo "  • Configure stepper motor pins"
    echo "  • Install and customize macros"
    echo ""
    echo "Version: 1.0.0"
    echo "License: GPLv3"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Main loop
main() {
    # Create necessary directories
    mkdir -p "${KLIPPER_CONFIG_DIR}"
    mkdir -p "${MACROS_DIR}"
    mkdir -p "${BACKUP_DIR}"
    
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1)
                check_insert_mcu_ids
                ;;
            2)
                check_can_ids
                ;;
            3)
                configure_stepper_pins
                ;;
            4)
                install_baseline_macros
                ;;
            5)
                configure_start_print_macro
                ;;
            6)
                configure_end_print_macro
                ;;
            7)
                backup_configuration
                ;;
            8)
                show_about
                ;;
            9)
                echo ""
                echo -e "${GREEN}Thank you for using KANT!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
