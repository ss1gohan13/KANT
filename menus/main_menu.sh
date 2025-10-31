#!/bin/bash
# KANT Main Menu
# Main menu interface

show_main_menu() {
    show_header
    echo -e "${BLUE}MAIN MENU${NC}"
    echo "1) Install Klipper Macros"
    echo "2) Hardware Configuration Utilities"
    echo "3) Additional Features & Extensions"
    echo "4) Backup Management"
    echo "5) Diagnostics & Troubleshooting"
    echo "6) Software Management"
    echo "7) Uninstall"
    echo "0) Exit"
    echo ""
    read -p "Select an option: " menu_choice
    
    case $menu_choice in
        1) install_core_macros_menu ;;
        2) hardware_config_menu ;;
        3) additional_features_menu ;;
        4) manage_backups ;;
        5) diagnostics_menu ;;
        6) software_management_menu ;;
        7) uninstall_menu ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; show_main_menu ;;
    esac
}

# Revised menu structure for macros installation
install_core_macros_menu() {
    show_header
    echo -e "${BLUE}INSTALL KLIPPER MACROS${NC}"
    echo "Select which macros to install:"
    echo ""
    echo "1) Install standard Klipper macros"
    echo "2) Install A Better Print_Start Macro"
    echo "3) Install A Better End Print Macro"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " install_choice
    
    case $install_choice in
        1) 
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
            echo -e "${GREEN}Standard Klipper macros installed successfully!${NC}"
            read -p "Press Enter to continue..." dummy
            show_main_menu
            ;;
        2)
            check_klipper
            create_backup_dir
            stop_klipper
            # First install base macros if not already installed
            if [ ! -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
                get_user_macro_files
                backup_existing_macros
                install_macros
                check_and_update_printer_cfg
            fi
            
            # Install Print_Start Macro
            echo "Installing A Better Print_Start Macro..."
            curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-better-print_start-macro/main/install_start_print.sh | bash

            add_max_extrude_cross_section_to_extruder
            add_firmware_retraction_to_printer_cfg

            add_max_extrude_cross_section_to_extruder
            
            start_klipper
            echo -e "${GREEN}A Better Print_Start Macro installed successfully!${NC}"
            echo -e "${YELLOW}Remember to update your slicer's start G-code as per the documentation${NC}"
            echo -e "${YELLOW}Visit https://github.com/ss1gohan13/A-better-print_start-macro for details${NC}"
            read -p "Press Enter to continue..." dummy
            show_main_menu
            ;;
        3)
            check_klipper
            create_backup_dir
            stop_klipper
            # First install base macros if not already installed
            if [ ! -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
                get_user_macro_files
                backup_existing_macros
                install_macros
                check_and_update_printer_cfg
            fi
            
            # Install End Print Macro
            echo "Installing A Better End Print Macro..."
            curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-Better-End-Print-Macro/main/direct_install.sh | bash
            
            start_klipper
            echo -e "${GREEN}A Better End Print Macro installed successfully!${NC}"
            echo -e "${YELLOW}Remember to update your slicer's end G-code as per the documentation${NC}"
            echo -e "${YELLOW}Visit https://github.com/ss1gohan13/A-Better-End-Print-Macro for details${NC}"
            read -p "Press Enter to continue..." dummy
            show_main_menu
            ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; install_core_macros_menu ;;
    esac
}

# Uninstall menu
uninstall_menu() {
    show_header
    echo -e "${RED}UNINSTALL KLIPPER MACROS${NC}"
    
    echo "This will remove the Klipper macros and restore your previous configuration."
    echo "Are you sure you want to uninstall?"
    
    read -p "Type 'YES' to confirm: " confirm
    
    if [ "$confirm" = "YES" ]; then
        check_klipper
        create_backup_dir
        stop_klipper
        get_user_macro_files
        restore_backup
        start_klipper
        
        echo -e "${GREEN}Uninstallation complete! Original configuration has been restored.${NC}"
    else
        echo "Uninstallation cancelled."
    fi
    
    read -p "Press Enter to continue..." dummy
    show_main_menu
}
