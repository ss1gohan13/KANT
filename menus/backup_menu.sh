#!/bin/bash
# KANT Backup Menu
# Backup management menu interface

manage_backups() {
    show_header
    echo -e "${BLUE}BACKUP MANAGEMENT${NC}"
    echo "1) List all backups"
    echo "2) Restore from backup"
    echo "3) Clean old backups"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " backup_choice
    
    case $backup_choice in
        1) list_backups ;;
        2) restore_from_backup ;;
        3) clean_old_backups ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; manage_backups ;;
    esac
}