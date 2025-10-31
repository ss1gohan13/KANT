#!/bin/bash
# Force Move Plugin
# Handles force_move configuration

add_force_move() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi

    cp "$printer_cfg" "${BACKUP_DIR}/printer.cfg.forcemove_${CURRENT_DATE}"
    local working_cfg="${BACKUP_DIR}/printer.cfg.forcemove_${CURRENT_DATE}"
    
    if grep -q '^\[force_move\]' "$working_cfg"; then
        if grep -q '^\[force_move\]' -A 2 "$working_cfg" | grep -q 'enable_force_move: true'; then
            echo -e "${GREEN}Force move already enabled in printer.cfg${NC}"
            rm "$working_cfg"
            return
        else
            sed -i '/^\[force_move\]/,/^$/s/enable_force_move:.*$/enable_force_move: true/' "$working_cfg"
            if ! grep -q 'enable_force_move: true' "$working_cfg"; then
                sed -i '/^\[force_move\]/a enable_force_move: true' "$working_cfg"
            fi
            echo -e "${GREEN}Updated existing force_move section${NC}"
        fi
    else
        sed -i '1i[force_move]\nenable_force_move: true\n' "$working_cfg"
        echo -e "${GREEN}Added force_move section to printer.cfg${NC}"
    fi
    mv "$working_cfg" "$printer_cfg"
}
