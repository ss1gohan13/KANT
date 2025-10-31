#!/bin/bash
# Klipper Network Status Plugin
# Handles installation and configuration of klipper_network_status

install_klipper_network_status() {
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}git is not installed. Please install git and rerun the script.${NC}"
        return 1
    fi

    # Check if config dir exists and is writable
    if [ ! -d "${KLIPPER_CONFIG}" ] || [ ! -w "${KLIPPER_CONFIG}" ]; then
        echo -e "${RED}Config directory ${KLIPPER_CONFIG} does not exist or is not writable!${NC}"
        return 1
    fi

    # Check if already installed
    if [ -d "${KLIPPER_CONFIG}/klipper_network_status" ]; then
        echo "klipper_network_status already installed."
        return 0
    fi

    echo "Installing klipper_network_status..."
    git clone https://github.com/goopypanther/klipper_network_status.git "${KLIPPER_CONFIG}/klipper_network_status"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}klipper_network_status installed successfully in ${KLIPPER_CONFIG}/klipper_network_status${NC}"
    else
        echo -e "${RED}Failed to install klipper_network_status!${NC}"
        if [ ! -w "${KLIPPER_CONFIG}" ]; then
            echo -e "${RED}Cannot write to ${KLIPPER_CONFIG}. Check permissions!${NC}"
        fi
        return 1
    fi
}

add_network_status_to_printer_cfg() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local backup_cfg="${BACKUP_DIR}/printer.cfg.network_status_${CURRENT_DATE}"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi

    cp "$printer_cfg" "$backup_cfg"
    echo "Created backup of printer.cfg at $backup_cfg"

    # Only add if not already present
    if grep -q '^\[network_status\]' "$printer_cfg"; then
        echo "Found existing [network_status] block. No need to add another."
    else
        # Insert at the very top
        sed -i '1i[network_status]\n' "$printer_cfg"
        echo "Added [network_status] to the top of printer.cfg"
    fi
}