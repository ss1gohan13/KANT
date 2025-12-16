#!/bin/bash
# KANT Klipper Installation Menu
# Menu interface for installing Klipper and core components

klipper_install_menu() {
    show_header
    echo -e "${BLUE}INSTALL KLIPPER & CORE COMPONENTS${NC}"
    echo ""
    echo -e "${CYAN}Firmware & API:${NC}"
    echo "  1) Install Klipper"
    echo "  2) Install Moonraker"
    echo ""
    echo -e "${CYAN}Webinterface:${NC}"
    echo "  3) Install Mainsail"
    echo "  4) Install Fluidd"
    echo ""
    echo -e "${CYAN}Client-Config:${NC}"
    echo "  5) Install Mainsail-Config"
    echo "  6) Install Fluidd-Config"
    echo ""
    echo "  0) Back to main menu"
    echo ""
    read -p "Select an option: " install_choice
    
    case $install_choice in
        1) install_klipper ;;
        2) install_moonraker ;;
        3) install_mainsail ;;
        4) install_fluidd ;;
        5) install_mainsail_config ;;
        6) install_fluidd_config ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; klipper_install_menu ;;
    esac
}
