#!/bin/bash
# KAMP Plugin
# Handles installation and configuration of KAMP

add_kamp_include_to_printer_cfg() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local backup_cfg="${BACKUP_DIR}/printer.cfg.kamp_${CURRENT_DATE}"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        echo "You will need to manually add: [include KAMP_Settings.cfg] to your printer.cfg"
        return
    fi

    cp "$printer_cfg" "$backup_cfg"
    echo "Created backup of printer.cfg at $backup_cfg"

    # Only add if not already present
    if grep -q '^\[include KAMP_Settings\.cfg\]' "$printer_cfg"; then
        echo "Found existing [include KAMP_Settings.cfg]. No need to add another."
    else
        # Insert after [include macros.cfg] if present, else at top
        if grep -q '^\[include macros\.cfg\]' "$printer_cfg"; then
            sed -i '/^\[include macros\.cfg\]/a\[include KAMP_Settings.cfg]' "$printer_cfg"
            echo "Added [include KAMP_Settings.cfg] after [include macros.cfg]"
        else
            sed -i '1i[include KAMP_Settings.cfg]\n' "$printer_cfg"
            echo "Added [include KAMP_Settings.cfg] to the top of printer.cfg"
        fi
    fi
}

install_kamp() {
    if [ -d "${KLIPPER_CONFIG}/KAMP" ]; then
        echo "KAMP is already installed."
        return
    fi

    echo "Installing KAMP..."
    cd
    git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
    ln -s ~/Klipper-Adaptive-Meshing-Purging/Configuration "${KLIPPER_CONFIG}/KAMP"
    cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg "${KLIPPER_CONFIG}/KAMP_Settings.cfg"
    echo -e "${GREEN}KAMP installation complete!${NC}"

    add_kamp_include_to_printer_cfg
    
    # Automatically add firmware retraction after KAMP installation
    echo "Adding firmware retraction configuration..."
    add_firmware_retraction_to_printer_cfg
}