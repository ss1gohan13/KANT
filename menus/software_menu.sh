#!/bin/bash
# KANT Software Menu
# Software management menu interface

# Updated Software management menu with plugin support
software_management_menu() {
    show_header
    echo -e "${BLUE}SOFTWARE MANAGEMENT${NC}"
    echo "1) Core Software"
    echo "2) LED & Visual Effects"
    echo "3) Input Shaping & Analysis"
    echo "4) Driver & Hardware Tuning"
    echo "5) Touchscreen Interface"
    echo "6) Probe Systems"
    echo "7) Calibration Tools"
    echo "8) CANBUS"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " sw_choice
    
    case $sw_choice in
        1) core_software_menu ;;
        2) led_effects_menu ;;
        3) input_shaping_menu ;;
        4) hardware_tuning_menu ;;
        5) touchscreen_menu ;;
        6) probe_systems_menu ;;
        7) calibration_tools_menu ;;
        8) canbus_menu ;;  
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; software_management_menu ;;
    esac
}

# Core software menu (existing functionality)
core_software_menu() {
    show_header
    echo -e "${BLUE}CORE SOFTWARE MANAGEMENT${NC}"
    echo "1) Install Kiauh"
    echo "2) Update Klipper macros"
    echo "3) Check for system updates"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " core_choice
    
    case $core_choice in
        1) install_kiauh ;;
        2) update_macros ;;
        3) check_system_updates ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; core_software_menu ;;
    esac
}

# LED Effects menu
led_effects_menu() {
    show_header
    echo -e "${BLUE}LED & VISUAL EFFECTS${NC}"
    echo "1) Install Klipper LED Effects"
    echo "2) Uninstall Klipper LED Effects"
    echo "3) Check LED Effects status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " led_choice
    
    case $led_choice in
        1) install_led_effects ;;
        2) uninstall_led_effects ;;
        3) check_led_effects_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; led_effects_menu ;;
    esac
}

# Input Shaping menu
input_shaping_menu() {
    show_header
    echo -e "${BLUE}INPUT SHAPING & ANALYSIS${NC}"
    echo "1) Install Shake&Tune"
    echo "2) Uninstall Shake&Tune"
    echo "3) Check Shake&Tune status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " shake_choice
    
    case $shake_choice in
        1) install_shake_tune ;;
        2) uninstall_shake_tune ;;
        3) check_shake_tune_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; input_shaping_menu ;;
    esac
}

# Hardware Tuning menu
hardware_tuning_menu() {
    show_header
    echo -e "${BLUE}DRIVER & HARDWARE TUNING${NC}"
    echo "1) Install TMC Autotune"
    echo "2) Uninstall TMC Autotune"
    echo "3) Check TMC Autotune status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " tmc_choice
    
    case $tmc_choice in
        1) install_tmc_autotune ;;
        2) uninstall_tmc_autotune ;;
        3) check_tmc_autotune_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; hardware_tuning_menu ;;
    esac
}

# Touchscreen menu
touchscreen_menu() {
    show_header
    echo -e "${BLUE}TOUCHSCREEN INTERFACE${NC}"
    echo "1) Install KlipperScreen"
    echo "2) Uninstall KlipperScreen"
    echo "3) Check KlipperScreen status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " screen_choice
    
    case $screen_choice in
        1) install_klipperscreen ;;
        2) uninstall_klipperscreen ;;
        3) check_klipperscreen_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; touchscreen_menu ;;
    esac
}

# Probe Systems menu
probe_systems_menu() {
    show_header
    echo -e "${BLUE}PROBE SYSTEMS${NC}"
    echo "1) Install Beacon"
    echo "2) Uninstall Beacon"
    echo "3) Install Cartographer"
    echo "4) Uninstall Cartographer"
    echo "5) Install Eddy-NG"
    echo "6) Uninstall Eddy-NG"
    echo "7) Check all probe systems status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " probe_choice
    
    case $probe_choice in
        1) install_beacon ;;
        2) uninstall_beacon ;;
        3) install_cartographer ;;
        4) uninstall_cartographer ;;
        5) install_eddy_ng ;;
        6) uninstall_eddy_ng ;;
        7) check_probe_systems_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; probe_systems_menu ;;
    esac
}

# Calibration Tools menu
calibration_tools_menu() {
    show_header
    echo -e "${BLUE}CALIBRATION TOOLS${NC}"
    echo "1) Install Auto Z Calibration"
    echo "2) Uninstall Auto Z Calibration"
    echo "3) Check Auto Z Calibration status"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " cal_choice
    
    case $cal_choice in
        1) install_auto_z_calibration ;;
        2) uninstall_auto_z_calibration ;;
        3) check_auto_z_calibration_status ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; calibration_tools_menu ;;
    esac
}

# Communication & Networking submenu
canbus_menu() {
    show_header
    echo -e "${BLUE}COMMUNICATION & NETWORKING${NC}"
    echo "1) CANBUS Initial Setup (GUIDED)"
    echo "0) Back to software menu"
    echo ""
    read -p "Select an option: " comm_choice
    
    case $comm_choice in
        1) canbus_initial_setup ;;
        0) software_management_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; canbus_menu ;;
    esac
}