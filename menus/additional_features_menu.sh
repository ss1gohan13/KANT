#!/bin/bash
# KANT Additional Features Menu
# Additional features menu interface

additional_features_menu() {
    show_header
    echo -e "${BLUE}ADDITIONAL FEATURES & EXTENSIONS${NC}"
    echo "1) Install Print Start Macro"
    echo "2) Install End Print Macro"
    echo "3) Install KAMP"
    echo "4) Enable Eddy NG tap start print function"
    echo "5) Install Numpy for ADXL Resonance Measurements"
    echo "6) Install Crowsnest (webcam streaming)"
    echo "7) Install Moonraker-Timelapse"
    echo "8) PID Tuning Assistant"
    echo "9) E-Steps Calibration Helper"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " feature_choice
    
    case $feature_choice in
        1)
            echo "Installing A Better Print_Start Macro..."
            curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-better-print_start-macro/main/install_start_print.sh | bash

            add_max_extrude_cross_section_to_extruder
            add_firmware_retraction_to_printer_cfg

            add_max_extrude_cross_section_to_extruder
            
            echo -e "${GREEN}Print_Start macro installed successfully!${NC}"
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        2)
            echo "Installing A Better End Print Macro..."
            curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-Better-End-Print-Macro/main/direct_install.sh | bash
            echo -e "${GREEN}End Print macro installed successfully!${NC}"
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        3)
            install_kamp
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        4)
            check_klipper
            create_backup_dir
            stop_klipper
            configure_eddy_ng_tap
            start_klipper
            echo -e "${GREEN}Eddy NG tap start print function enabled successfully!${NC}"
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        5)
            install_numpy_for_adxl
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        6)
            echo "Installing Crowsnest..."
            cd ~
            git clone https://github.com/mainsail-crew/crowsnest.git
            cd crowsnest
            sudo bash ./tools/install.sh
            echo -e "${GREEN}Crowsnest installation complete!${NC}"
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        7)
            echo "Installing Moonraker-Timelapse..."
            cd ~
            git clone https://github.com/mainsail-crew/moonraker-timelapse.git
            cd moonraker-timelapse
            bash ./install.sh
            echo -e "${GREEN}Moonraker-Timelapse installation complete!${NC}"
            read -p "Press Enter to continue..." dummy
            additional_features_menu
            ;;
        8) pid_tuning_assistant ;;
        9) esteps_calibration_helper ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; additional_features_menu ;;
    esac
}