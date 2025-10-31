#!/bin/bash
# Gcode Shell Plugin
# Handles installation of gcode_shell

install_gcode_shell() {
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}git is not installed. Please install git and rerun the script.${NC}"
        return 1
    fi

    # Check if already installed
    if [ -d "${KLIPPER_CONFIG}/gcode_shell" ]; then
        echo "gcode_shell already installed."
        return 0
    fi

    echo "Installing gcode_shell..."
    git clone https://github.com/kyleisah/gcode_shell.git "${KLIPPER_CONFIG}/gcode_shell"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}gcode_shell installed successfully in ${KLIPPER_CONFIG}/gcode_shell${NC}"
    else
        echo -e "${RED}Failed to install gcode_shell!${NC}"
        return 1
    fi
}