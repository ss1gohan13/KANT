#!/bin/bash
# KANT Diagnostics Menu
# Diagnostics menu interface

diagnostics_menu() {
    show_header
    echo -e "${BLUE}DIAGNOSTICS & TROUBLESHOOTING${NC}"
    echo "1) Check Klipper status"
    echo "2) View Klipper logs"
    echo "3) Verify configuration"
    echo "4) Run full system diagnostics"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " diag_choice
    
    case $diag_choice in
        1) check_klipper_status ;;
        2) view_klipper_logs ;;
        3) verify_configuration ;;
        4) run_full_diagnostics ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; diagnostics_menu ;;
    esac
}