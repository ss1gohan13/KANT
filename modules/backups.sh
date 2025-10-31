#!/bin/bash
# KANT Backups Module
# Handles backup management functions

list_backups() {
    show_header
    echo -e "${BLUE}ALL BACKUPS${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No backup directory found${NC}"
        read -p "Press Enter to continue..." dummy
        manage_backups
        return
    fi
    
    backup_files=($(find "$BACKUP_DIR" -name "*.backup_*" -type f | sort -r))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No backup files found${NC}"
    else
        echo "Found ${#backup_files[@]} backup files:"
        echo ""
        for backup in "${backup_files[@]}"; do
            filename=$(basename "$backup")
            filesize=$(du -h "$backup" | cut -f1)
            echo "  $filename ($filesize)"
        done
    fi
    
    read -p "Press Enter to continue..." dummy
    manage_backups
}

restore_from_backup() {
    show_header
    echo -e "${BLUE}RESTORE FROM BACKUP${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No backup directory found${NC}"
        read -p "Press Enter to continue..." dummy
        manage_backups
        return
    fi
    
    backup_files=($(find "$BACKUP_DIR" -name "*.backup_*" -type f | sort -r))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No backup files found${NC}"
        read -p "Press Enter to continue..." dummy
        manage_backups
        return
    fi
    
    echo "Select a backup to restore:"
    echo ""
    for i in "${!backup_files[@]}"; do
        filename=$(basename "${backup_files[$i]}")
        echo "$((i+1))) $filename"
    done
    echo "0) Cancel"
    
    read -p "Select backup number: " backup_num
    
    if [ "$backup_num" -eq 0 ]; then
        manage_backups
        return
    fi
    
    if [[ ! "$backup_num" =~ ^[0-9]+$ ]] || [ "$backup_num" -lt 1 ] || [ "$backup_num" -gt ${#backup_files[@]} ]; then
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..." dummy
        restore_from_backup
        return
    fi
    
    selected_backup="${backup_files[$((backup_num-1))]}"
    filename=$(basename "$selected_backup")
    
    # Determine target file based on backup name
    if [[ "$filename" == printer.cfg.backup_* ]]; then
        target_file="${KLIPPER_CONFIG}/printer.cfg"
    elif [[ "$filename" == macros.cfg.backup_* ]]; then
        target_file="${KLIPPER_CONFIG}/macros.cfg"
    else
        # Extract original filename from backup name
        original_name=$(echo "$filename" | sed 's/\.backup_[0-9]*_[0-9]*$//')
        target_file="${KLIPPER_CONFIG}/$original_name"
    fi
    
    echo ""
    echo "This will restore:"
    echo "  From: $filename"
    echo "  To: $(basename "$target_file")"
    echo ""
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cp "$selected_backup" "$target_file"
        echo -e "${GREEN}Backup restored successfully!${NC}"
        echo "Restarting Klipper..."
        sudo systemctl restart $KLIPPER_SERVICE_NAME
    else
        echo "Restore cancelled."
    fi
    
    read -p "Press Enter to continue..." dummy
    manage_backups
}

clean_old_backups() {
    show_header
    echo -e "${BLUE}CLEAN OLD BACKUPS${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No backup directory found${NC}"
        read -p "Press Enter to continue..." dummy
        manage_backups
        return
    fi
    
    echo "How many days of backups would you like to keep?"
    echo "Backups older than this will be deleted."
    read -p "Days to keep (default: 7): " days_to_keep
    
    # Default to 7 days if no input
    days_to_keep=${days_to_keep:-7}
    
    if [[ ! "$days_to_keep" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid number${NC}"
        read -p "Press Enter to continue..." dummy
        clean_old_backups
        return
    fi
    
    old_backups=($(find "$BACKUP_DIR" -name "*.backup_*" -type f -mtime +$days_to_keep))
    
    if [ ${#old_backups[@]} -eq 0 ]; then
        echo -e "${GREEN}No old backups found to clean${NC}"
    else
        echo "Found ${#old_backups[@]} backup(s) older than $days_to_keep days:"
        echo ""
        for backup in "${old_backups[@]}"; do
            echo "  $(basename "$backup")"
        done
        echo ""
        read -p "Delete these backups? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for backup in "${old_backups[@]}"; do
                rm "$backup"
            done
            echo -e "${GREEN}Old backups cleaned successfully!${NC}"
        else
            echo "Cleanup cancelled."
        fi
    fi
    
    read -p "Press Enter to continue..." dummy
    manage_backups
}