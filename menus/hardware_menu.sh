#!/bin/bash
# KANT Hardware Menu
# Hardware configuration menu interface

hardware_config_menu() {
    show_header
    echo -e "${BLUE}HARDWARE CONFIGURATION UTILITIES${NC}"
    echo "1) Check MCU IDs"
    echo "2) Check CAN bus devices"
    echo "3) Browse Official Klipper Configurations"
    echo "4) Enable Eddy NG tap start print function"
    echo "5) Configure firmware retraction"
    echo "6) Configure force_move"
    echo "7) Configure stepper drivers"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " hw_choice
    
    case $hw_choice in
        1) check_mcu_ids ;;
        2) check_can_bus ;;
        3) browse_official_configs ;;
        4) configure_eddy_ng_tap; hardware_config_menu ;;
        5) add_firmware_retraction_to_printer_cfg; hardware_config_menu ;;
        6) add_force_move; hardware_config_menu ;;
        7) configure_stepper_drivers; hardware_config_menu ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; hardware_config_menu ;;
    esac
}