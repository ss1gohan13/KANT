#!/bin/bash
# Force script to exit if an error occurs
set -e

# Script Info
# Last Updated: 2025-10-12 13:38:28 UTC
# Author: ss1gohan13

KLIPPER_CONFIG="${HOME}/printer_data/config"
KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME=klipper
BACKUP_DIR="${KLIPPER_CONFIG}/backup"
CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
VERSION="1.4.1"

# Default to menu mode - menu will show by default
MENU_MODE=1

REPO_URL="https://github.com/ss1gohan13/KANT"

# Function to check for updates (for Moonraker integration)
check_for_updates() {
    echo "Checking for KANT updates..."
    echo "Current version: $VERSION"
    echo "Repository: $REPO_URL"
}

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
usage() {
    echo "Usage: $0 [-c <config path>] [-s <klipper service name>] [-u] [-l]" 1>&2
    echo "  -c : Specify custom config path (default: ${KLIPPER_CONFIG})" 1>&2
    echo "  -s : Specify Klipper service name (default: klipper)" 1>&2
    echo "  -u : Uninstall" 1>&2
    echo "  -l : Run in linear mode (skip interactive menu)" 1>&2
    echo "  -h : Show this help message" 1>&2
    exit 1
}

while getopts "c:s:ulh" arg; do
    case $arg in
        c)
            KLIPPER_CONFIG="$OPTARG"
            ;;
        s)
            KLIPPER_SERVICE_NAME="$OPTARG"
            ;;
        u)
            UNINSTALL=1
            ;;
        l)
            MENU_MODE=0
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Utility to check Klipper config dir exists
check_klipper() {
    if [ ! -d "$KLIPPER_CONFIG" ]; then
        echo -e "${RED}[ERROR] Klipper config directory not found at \"$KLIPPER_CONFIG\". Please verify path or specify with -c.${NC}"
        exit -1
    fi
    echo -e "${GREEN}Klipper config directory found at $KLIPPER_CONFIG${NC}"
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Creating backup directory at $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Verify script is not run as root
verify_ready() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}[ERROR] This script must not run as root${NC}"
        exit -1
    fi
}

# Service management functions
start_klipper() {
    echo -n "Starting Klipper... "
    sudo systemctl start $KLIPPER_SERVICE_NAME
    echo -e "${GREEN}[OK]${NC}"
}

stop_klipper() {
    echo -n "Stopping Klipper... "
    sudo systemctl stop $KLIPPER_SERVICE_NAME
    echo -e "${GREEN}[OK]${NC}"
}

# Declare global array for backup files
declare -a BACKUP_FILES

# Modified to properly handle user input for macro files
get_user_macro_files() {
    echo "Looking for macro files in $KLIPPER_CONFIG..."
    echo "Found these potential macro files:"
    find "$KLIPPER_CONFIG" -maxdepth 1 -type f -name "*.cfg" | sort | while read -r file; do
        if [[ ! "$(basename "$file")" =~ (backup|[0-9]{8}_[0-9]{6})\.cfg$ ]]; then
            echo "  - $(basename "$file")"
        fi
    done

    echo ""
    read -p "Do you have a custom macro.cfg installed? (y/N): " has_custom_macro
    if [[ ! "$has_custom_macro" =~ ^[Yy]$ ]]; then
        echo "No custom macro.cfg detected. Will use default 'macros.cfg'."
        MACRO_FILES=("macros.cfg")
        echo "Will download new macros to: macros.cfg"
        return
    fi
    
    echo "Please enter the filenames of your macro files (space separated)."
    echo "Example: macros.cfg sv08_macros.cfg custom_macros.cfg"
    echo "Press Enter if you have no existing macro files."
    read -p "> " USER_MACRO_FILES
    
    MACRO_FILES=("macros.cfg")
    
    if [ -n "$USER_MACRO_FILES" ]; then
        echo "Will back up the following files: $USER_MACRO_FILES"
        read -ra USER_FILES <<< "$USER_MACRO_FILES"
        for file_name in "${USER_FILES[@]}"; do
            if [ -f "${KLIPPER_CONFIG}/${file_name}" ]; then
                echo "Will back up existing ${file_name}"
                BACKUP_FILES+=("$file_name")
            fi
        done
    else
        echo "No files specified. Will use default 'macros.cfg'."
    fi
    
    echo "Will download new macros to: macros.cfg"
}

# Modified to use both specified user files and default macros.cfg
backup_existing_macros() {
    local found_macro=0
    
    # First check if macros.cfg exists and back it up
    if [ -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
        echo "Creating backup of existing macros.cfg..."
        cp "${KLIPPER_CONFIG}/macros.cfg" "${BACKUP_DIR}/macros.cfg.backup_${CURRENT_DATE}"
        echo "Backup created at ${BACKUP_DIR}/macros.cfg.backup_${CURRENT_DATE}"
        found_macro=1
    fi
    
    # Also back up any additional files specified by the user
    if [ -n "${BACKUP_FILES}" ]; then
        for file_name in "${BACKUP_FILES[@]}"; do
            if [ -f "${KLIPPER_CONFIG}/${file_name}" ] && [ "$file_name" != "macros.cfg" ]; then
                echo "Creating backup of existing ${file_name}..."
                cp "${KLIPPER_CONFIG}/${file_name}" "${BACKUP_DIR}/${file_name}.backup_${CURRENT_DATE}"
                echo "Backup created at ${BACKUP_DIR}/${file_name}.backup_${CURRENT_DATE}"
                found_macro=1
            fi
        done
    fi

    if [ $found_macro -eq 1 ]; then
        echo "All specified macro configurations have been backed up."
    else
        echo "No existing macro files found to back up."
    fi
}

# Using the exact curl command that works - always to macros.cfg
install_macros() {
    echo "Downloading and installing new macros to macros.cfg..."
    # Always download to macros.cfg regardless of what the user entered
    curl -L https://raw.githubusercontent.com/ss1gohan13/KANT/main/printer_data/config/macros.cfg -o "${KLIPPER_CONFIG}/macros.cfg"
    # Verify download was successful
    if [ -s "${KLIPPER_CONFIG}/macros.cfg" ]; then
        echo -e "${GREEN}[OK]${NC} Macros file downloaded successfully"
        echo "First few lines of downloaded file:"
        head -n 3 "${KLIPPER_CONFIG}/macros.cfg"
        install_gcode_shell    # Install gcode_shell first
        install_klipper_network_status   # Now install klipper_network_status immediately after
        add_network_status_to_printer_cfg
    else
        echo -e "${RED}[ERROR] Failed to download macros file. Please check your internet connection.${NC}"
        exit 1
    fi
}

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

# Completely rewritten function to handle printer.cfg properly
check_and_update_printer_cfg() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    
    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        echo "You will need to manually add: [include macros.cfg] to your printer.cfg"
        return
    fi

    cp "$printer_cfg" "${BACKUP_DIR}/printer.cfg.backup_${CURRENT_DATE}"
    echo "Created backup of printer.cfg at ${BACKUP_DIR}/printer.cfg.backup_${CURRENT_DATE}"
    
    cp "$printer_cfg" "${BACKUP_DIR}/printer.cfg.working_${CURRENT_DATE}"
    local working_cfg="${BACKUP_DIR}/printer.cfg.working_${CURRENT_DATE}"
    
    echo "Processing printer.cfg file..."

    # Comment out the hardcoded Macro.cfg (existing behavior)
    sed -i 's/^\[include Macro\.cfg\]/# [include Macro.cfg]/' "$working_cfg"
    
    # NEW: Comment out user-specified macro files
    if [ -n "$USER_MACRO_FILES" ]; then
        read -ra USER_FILES <<< "$USER_MACRO_FILES"
        for file_name in "${USER_FILES[@]}"; do
            # Remove any path and get just the filename
            base_name=$(basename "$file_name")
            # Escape dots for sed regex
            escaped_name=$(echo "$base_name" | sed 's/\./\\./g')
            # Comment out this include line
            sed -i "s/^\[include ${escaped_name}\]/# [include ${base_name}]/" "$working_cfg"
            echo "Commented out [include ${base_name}]"
        done
    fi
    
    # Also comment out any files in BACKUP_FILES array
    if [ -n "${BACKUP_FILES}" ]; then
        for file_name in "${BACKUP_FILES[@]}"; do
            # Remove any path and get just the filename
            base_name=$(basename "$file_name")
            # Skip if it's macros.cfg since we want that to remain active
            if [ "$base_name" != "macros.cfg" ]; then
                # Escape dots for sed regex
                escaped_name=$(echo "$base_name" | sed 's/\./\\./g')
                # Comment out this include line
                sed -i "s/^\[include ${escaped_name}\]/# [include ${base_name}]/" "$working_cfg"
                echo "Commented out [include ${base_name}]"
            fi
        done
    fi
    
    # Check if macros.cfg include already exists (existing behavior)
    if grep -q '^\[include macros\.cfg\]' "$working_cfg"; then
        echo "Found existing [include macros.cfg]. No need to add another."
    else
        sed -i '1i[include macros.cfg]\n' "$working_cfg"
        echo "Added [include macros.cfg] to the top of printer.cfg"
    fi

    # Remove any commented duplicate macros.cfg lines (existing behavior)
    sed -i 's/^# \[include macros\.cfg\]//' "$working_cfg"

    mv "$working_cfg" "$printer_cfg"
    echo "Updated printer.cfg successfully"
}

# Modified to restore latest backup of specified macro files
restore_backup() {
    local latest_macros_backup=$(ls -t ${BACKUP_DIR}/macros.cfg.backup_* 2>/dev/null | head -n1)
    if [ -n "$latest_macros_backup" ]; then
        echo "Restoring from backup: $latest_macros_backup"
        cp "$latest_macros_backup" "${KLIPPER_CONFIG}/macros.cfg"
        echo -e "${GREEN}[OK]${NC}"
    else
        echo "No backup found for macros.cfg"
        if [ -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
            echo "Removing installed macros.cfg"
            rm "${KLIPPER_CONFIG}/macros.cfg"
        fi
    fi
    
    if [ -n "${BACKUP_FILES}" ]; then
        for file_name in "${BACKUP_FILES[@]}"; do
            if [ "$file_name" != "macros.cfg" ]; then
                local latest_backup=$(ls -t ${BACKUP_DIR}/${file_name}.backup_* 2>/dev/null | head -n1)
                if [ -n "$latest_backup" ]; then
                    echo "Restoring from backup: $latest_backup"
                    cp "$latest_backup" "${KLIPPER_CONFIG}/${file_name}"
                    echo -e "${GREEN}[OK]${NC}"
                fi
            fi
        done
    fi

    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    if [[ ! "$(basename "$printer_cfg")" =~ [0-9]{8}_[0-9]{6}\.cfg$ ]]; then
        local printer_backup=$(ls -t ${BACKUP_DIR}/printer.cfg.backup_* 2>/dev/null | head -n1)
        if [ -n "$printer_backup" ]; then
            echo "Restoring printer.cfg from backup: $printer_backup"
            cp "$printer_backup" "$printer_cfg"
            echo -e "${GREEN}[OK]${NC}"
        fi
    fi
}

# Function to install web interface configuration
install_web_interface_config() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        echo "You will need to manually add web interface configuration"
        return
    fi

    echo ""
    echo "What web interface are you using?"
    echo "1) Fluidd"
    echo "2) Mainsail"
    read -p "Select an option (1/2): " web_interface_choice
    
    local include_directive=""
    case $web_interface_choice in
        1)
            include_directive="[include fluidd.cfg]"
            echo "You selected Fluidd"
            ;;
        2)
            include_directive="[include mainsail.cfg]"
            echo "You selected Mainsail"
            ;;
        *)
            echo "Invalid selection. Skipping web interface configuration."
            return
            ;;
    esac
    
    local config_file=$(echo "$include_directive" | sed -n 's/\[include \(.*\)\]/\1/p')
    
    cp "$printer_cfg" "${BACKUP_DIR}/printer.cfg.webinterface_${CURRENT_DATE}"
    local working_cfg="${BACKUP_DIR}/printer.cfg.webinterface_${CURRENT_DATE}"

    echo "Processing printer.cfg for web interface configuration..."
    if grep -q "^\[include ${config_file}\]" "$working_cfg"; then
        echo "Found existing ${include_directive}. No need to add another."
    else
        if grep -q '^\[include macros\.cfg\]' "$working_cfg"; then
            sed -i "/\[include macros\.cfg\]/a\\${include_directive}" "$working_cfg"
            echo "Added ${include_directive} after [include macros.cfg]"
        else
            sed -i "1i${include_directive}\n" "$working_cfg"
            echo "Added ${include_directive} to the top of printer.cfg"
        fi
    fi

    sed -i "s/^# \[include ${config_file}\]//" "$working_cfg"
    mv "$working_cfg" "$printer_cfg"
    echo "Updated printer.cfg with web interface configuration"
}

add_max_extrude_cross_section_to_extruder() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local backup_cfg="${BACKUP_DIR}/printer.cfg.extruder_max_cross_section_${CURRENT_DATE}"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi

    cp "$printer_cfg" "$backup_cfg"
    echo "Created backup of printer.cfg at $backup_cfg"

    # Check if [extruder] section exists
    if ! grep -q '^\[extruder\]' "$printer_cfg"; then
        echo -e "${RED}[ERROR] No [extruder] section found in printer.cfg${NC}"
        return
    fi

    # Use awk to add or update the line
    awk '
    BEGIN { in_extruder=0; done=0 }
    /^\[extruder\]/ { print; in_extruder=1; next }
    /^\[/ { if (in_extruder && !done) { print "max_extrude_cross_section: 10"; done=1 } in_extruder=0 }
    in_extruder && /^max_extrude_cross_section:/ { if (!done) { print "max_extrude_cross_section: 10"; done=1 } next }
    { print }
    END { if (in_extruder && !done) print "max_extrude_cross_section: 10" }
    ' "$printer_cfg" > "${printer_cfg}.new" && mv "${printer_cfg}.new" "$printer_cfg"
    echo -e "${GREEN}max_extrude_cross_section: 10 added/updated in [extruder] section${NC}"
}

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

# Function to install KAMP
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

# Add firmware retraction to printer.cfg
add_firmware_retraction_to_printer_cfg() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local working_cfg="${BACKUP_DIR}/printer.cfg.firmware_retraction_${CURRENT_DATE}"

    local firmware_retraction_block="[firmware_retraction]
retract_length: 0.6
#   The length of filament (in mm) to retract when G10 is activated,
#   and to unretract when G11 is activated (but see
#   unretract_extra_length below). The default is 0 mm.
retract_speed: 60
#   The speed of retraction, in mm/s. The default is 20 mm/s.
unretract_extra_length: 0
#   The length (in mm) of *additional* filament to add when
#   unretracting.
unretract_speed: 60
#   The speed of unretraction, in mm/s. The default is 10 mm/s.
"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        echo "You will need to manually add the firmware retraction block to your printer.cfg"
        return
    fi

    cp "$printer_cfg" "$working_cfg"
    echo "Created backup of printer.cfg at ${working_cfg}"

    if grep -q '^\[firmware_retraction\]' "$working_cfg"; then
        echo -e "${GREEN}Firmware retraction section already exists. Skipping addition.${NC}"
        rm "$working_cfg"
        return
    fi

    # Look for the SAVE_CONFIG comment marker instead of [save_config]
    local save_config_line=$(grep -n '#\*# <---------------------- SAVE_CONFIG ---------------------->' "$working_cfg" | cut -d: -f1 | head -n 1)
    
    if [ -n "$save_config_line" ]; then
        # Insert firmware retraction just before SAVE_CONFIG marker
        awk -v block="$firmware_retraction_block" -v line="$save_config_line" '
            NR==line {print block}
            {print}
        ' "$working_cfg" > "${working_cfg}.new"
        mv "${working_cfg}.new" "$printer_cfg"
        echo -e "${GREEN}Added firmware retraction above SAVE_CONFIG section in printer.cfg${NC}"
    else
        # No SAVE_CONFIG marker found, append to end
        echo "$firmware_retraction_block" >> "$working_cfg"
        mv "$working_cfg" "$printer_cfg"
        echo -e "${GREEN}Appended firmware retraction to end of printer.cfg${NC}"
    fi
}

# Function to configure Eddy NG Tap in the start print macro and GANTRY_LEVELING macro
configure_eddy_ng_tap() {
    echo ""
    echo "Do you have Eddy NG installed?"
    echo "This will enable 'Tappy Tap' functionality, rapid bed mesh scanning, and enhanced gantry leveling."
    read -p "Enable Eddy NG features? (y/N): " enable_eddy_ng
    
    if [[ "$enable_eddy_ng" =~ ^[Yy]$ ]]; then
        echo "Enabling Eddy NG features in your configuration..."
        
        # Find the start print macro file
        local start_print_file="${KLIPPER_CONFIG}/print_start_macro.cfg"
        local macros_file="${KLIPPER_CONFIG}/macros.cfg"
        
        # --- Configure Start Print Macro ---
        if [ ! -f "$start_print_file" ]; then
            # Try to find the file that might contain the START_PRINT macro
            for potential_file in "${KLIPPER_CONFIG}"/*.cfg; do
                if grep -q "\[gcode_macro START_PRINT\]" "$potential_file"; then
                    start_print_file="$potential_file"
                    echo "Found START_PRINT macro in: $start_print_file"
                    break
                fi
            done
        fi
        
        if [ -f "$start_print_file" ]; then
            # Create a backup of the file
            cp "$start_print_file" "${BACKUP_DIR}/$(basename "$start_print_file").backup_${CURRENT_DATE}"
            
            # Uncomment the Eddy NG tapping lines
            sed -i 's/^#STATUS_CALIBRATING_Z/STATUS_CALIBRATING_Z/' "$start_print_file"
            sed -i 's/^#M117 Tappy Tap.../M117 Tappy Tap.../' "$start_print_file"
            sed -i 's/^#PROBE_EDDY_NG_TAP.*/PROBE_EDDY_NG_TAP/' "$start_print_file"
            
            # Uncomment the Method=rapid_scan for bed mesh
            sed -i 's/BED_MESH_CALIBRATE ADAPTIVE=1 #Method=rapid_scan/BED_MESH_CALIBRATE ADAPTIVE=1 Method=rapid_scan/' "$start_print_file"
            
            echo -e "${GREEN}Eddy NG tapping and rapid bed mesh scanning have been enabled in your start print macro.${NC}"
        else
            echo -e "${YELLOW}[WARNING] Could not find the START_PRINT macro file.${NC}"
            echo "You will need to manually uncomment the Eddy NG features in your start print macro."
        fi
        
        # --- Configure GANTRY_LEVELING Macro ---
        if [ -f "$macros_file" ]; then
            # Create a backup of the macros file
            cp "$macros_file" "${BACKUP_DIR}/macros.cfg.backup_eddy_${CURRENT_DATE}"
            
            # Uncomment retry_tolerance parameters for QGL and Z_TILT
            sed -i 's/QUAD_GANTRY_LEVEL horizontal_move_z=5 #retry_tolerance=1/QUAD_GANTRY_LEVEL horizontal_move_z=5 retry_tolerance=1/' "$macros_file"
            sed -i 's/Z_TILT_ADJUST horizontal_move_z=5 #RETRY_TOLERANCE=1/Z_TILT_ADJUST horizontal_move_z=5 RETRY_TOLERANCE=1/' "$macros_file"
            
            # Uncomment second pass fine adjustments
            sed -i 's/^#QUAD_GANTRY_LEVEL horizontal_move_z=2/QUAD_GANTRY_LEVEL horizontal_move_z=2/' "$macros_file"
            sed -i 's/^#Z_TILT_ADJUST horizontal_move_z=2/Z_TILT_ADJUST horizontal_move_z=2/' "$macros_file"
            
            # Also update G29 macro for rapid scanning
            sed -i 's/BED_MESH_CALIBRATE ADAPTIVE=1       # Method=rapid_scan/BED_MESH_CALIBRATE ADAPTIVE=1 Method=rapid_scan       #/' "$macros_file"
            
            echo -e "${GREEN}Eddy NG enhanced gantry leveling has been enabled in your GANTRY_LEVELING macro.${NC}"
            echo "Both QGL and Z_TILT configurations have been updated with retry_tolerance and fine adjustment passes."
        else
            echo -e "${YELLOW}[WARNING] Could not find macros.cfg file.${NC}"
            echo "You will need to manually uncomment the Eddy NG features in your gantry leveling macro."
        fi
        
        echo -e "${GREEN}All Eddy NG features have been enabled in your configuration.${NC}"
        
    else
        echo "Skipping Eddy NG features configuration."
    fi
}

# Function to add force_move section to printer.cfg
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

# New function to install Numpy for ADXL resonance measurements
install_numpy_for_adxl() {
    show_header
    echo -e "${BLUE}INSTALL NUMPY FOR ADXL RESONANCE MEASUREMENTS${NC}"
    
    echo "This will install numpy in the Klipper Python environment."
    echo "Numpy is required for processing ADXL345 accelerometer data for input shaping."
    echo "Reference: https://www.klipper3d.org/Measuring_Resonances.html"
    echo ""
    
    # Check if klippy-env exists
    if [ ! -d "${HOME}/klippy-env" ]; then
        echo -e "${RED}Error: Klipper Python environment not found at ~/klippy-env${NC}"
        echo "Please make sure Klipper is properly installed."
        return
    fi
    
    echo "Installing numpy (this may take a few minutes)..."
    ${HOME}/klippy-env/bin/pip install -v numpy
    
    # Verify installation
    if ${HOME}/klippy-env/bin/pip list | grep -q numpy; then
        echo -e "${GREEN}Numpy installed successfully!${NC}"
        echo "You can now use ADXL345-based resonance measurements with your printer."
        echo "For configuration instructions, see: https://www.klipper3d.org/Measuring_Resonances.html"
    else
        echo -e "${RED}Error: Failed to install numpy. Please try again or install manually.${NC}"
    fi
}

#############################################
# NEW FUNCTIONALITY: INTERACTIVE MENU SYSTEM
#############################################

show_header() {
    clear
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}    Klipper Assistant Navigation and Troubleshooting (KANT) v${VERSION}${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${YELLOW}Author: ss1gohan13${NC}"
    echo -e "${YELLOW}Last Updated: 2025-10-12${NC}"
    echo ""
}

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
            
            # # Then install KAMP (required by Print_Start Macro)
            # echo "Installing KAMP (required for A Better Print_Start Macro)..."
            # install_kamp
            
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

# Additional features menu
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
            # install_kamp
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
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; communication_networking_menu ;;
    esac
}

# CANBUS Initial Setup (GUIDED)
canbus_initial_setup() {
    show_header
    echo -e "${BLUE}CANBUS INITIAL SETUP (GUIDED)${NC}"
    echo ""
    echo "This guided setup will prepare your system for CAN Bus:"
    echo ""
    echo -e "${GREEN}AUTOMATED STEPS (Safe):${NC}"
    echo "✓ Check Linux kernel compatibility"
    echo "✓ Configure systemd-networkd service"
    echo "✓ Optimize boot performance"
    echo ""
    echo -e "${YELLOW}MANUAL STEPS (You Complete):${NC}"
    echo "• Network interface configuration"
    echo "• Hardware verification & wiring"
    echo "• MCU firmware flashing"
    echo ""
    echo -e "${RED}WARNING: This modifies system networking services.${NC}"
    echo ""
    read -p "Continue? (y/N): " continue_choice
    
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        communication_networking_menu
        return
    fi
    
    # Start automated setup
    canbus_automated_setup
}

# CANBUS Automated Setup Steps
canbus_automated_setup() {
    show_header
    echo -e "${BLUE}CANBUS SETUP - AUTOMATED STEPS${NC}"
    echo ""
    
    # Step 1: System Compatibility Check
    echo -e "${CYAN}STEP 1: SYSTEM COMPATIBILITY CHECK${NC}"
    echo "Checking Linux kernel compatibility..."
    echo "Running: uname -a"
    echo ""
    
    local system_info=$(uname -a)
    echo "$system_info"
    echo ""
    
    # Parse kernel version and architecture
    local kernel_version=$(echo "$system_info" | awk '{print $3}' | cut -d'-' -f1)
    local architecture=$(echo "$system_info" | awk '{print $NF}')
    
    echo "✓ Kernel Version: $kernel_version"
    echo "✓ Architecture: $architecture"
    echo ""
    
    # Check compatibility
    if [[ "$kernel_version" =~ ^6\.1\. ]] && [[ "$architecture" == "aarch64" ]]; then
        echo -e "${RED}⚠️  COMPATIBILITY WARNING:${NC}"
        echo "Your system has kernel 6.1.x with aarch64 architecture."
        echo "It's recommended to reflash with the latest Raspberry Pi OS."
        echo ""
        read -p "Continue anyway? (y/N): " warning_continue
        if [[ ! "$warning_continue" =~ ^[Yy]$ ]]; then
            canbus_setup_complete "aborted"
            return
        fi
    else
        echo -e "${GREEN}Status: Your system is compatible with CAN bus setup!${NC}"
    fi
    
    echo ""
    sleep 2
    
    # Step 2: Network Services Configuration
    echo -e "${CYAN}STEP 2: NETWORK SERVICES CONFIGURATION${NC}"
    echo "Configuring systemd-networkd service..."
    echo ""
    
    # Enable systemd-networkd
    echo "• Enabling systemd-networkd..."
    if sudo systemctl enable systemd-networkd >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Done${NC}"
    else
        echo -e "  ${RED}✗ Failed${NC}"
        canbus_setup_complete "failed"
        return
    fi
    
    # Unmask if needed and start systemd-networkd
    echo "• Starting systemd-networkd..."
    if ! sudo systemctl start systemd-networkd >/dev/null 2>&1; then
        echo "  Attempting to unmask service..."
        sudo systemctl unmask systemd-networkd >/dev/null 2>&1
        if sudo systemctl start systemd-networkd >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Done${NC}"
        else
            echo -e "  ${RED}✗ Failed${NC}"
            canbus_setup_complete "failed"
            return
        fi
    else
        echo -e "  ${GREEN}✓ Done${NC}"
    fi
    
    # Disable wait-online service
    echo "• Disabling systemd-networkd-wait-online..."
    if sudo systemctl disable systemd-networkd-wait-online.service >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Done${NC}"
    else
        echo -e "  ${YELLOW}⚠ May already be disabled${NC}"
    fi
    
    echo ""
    
    # Verify service status
    echo "Verifying service status..."
    local service_status=$(systemctl is-active systemd-networkd 2>/dev/null)
    if [[ "$service_status" == "active" ]]; then
        echo -e "systemd-networkd.service: ${GREEN}loaded active running ✓${NC}"
    else
        echo -e "systemd-networkd.service: ${RED}not running ✗${NC}"
        canbus_setup_complete "failed"
        return
    fi
    
    echo ""
    echo -e "${GREEN}All network services configured successfully!${NC}"
    echo ""
    sleep 2
    
    # Setup complete - show next steps
    canbus_setup_complete "success"
}

# CANBUS Setup Complete Screen
canbus_setup_complete() {
    local status="$1"
    
    show_header
    
    if [[ "$status" == "success" ]]; then
        echo -e "${GREEN}AUTOMATED SETUP COMPLETE${NC}"
        echo ""
        echo -e "${GREEN}✓ System compatibility verified${NC}"
        echo -e "${GREEN}✓ Network services configured${NC}"
        echo -e "${GREEN}✓ Boot optimization applied${NC}"
        echo ""
        echo -e "${CYAN}NEXT STEPS (Manual Configuration Required):${NC}"
        echo ""
        echo -e "${YELLOW}1. NETWORK INTERFACE SETUP${NC}"
        echo "   • Configure CAN network interface"
        echo "   • Set appropriate bitrate for your hardware"
        echo ""
        echo -e "${YELLOW}2. HARDWARE VERIFICATION${NC}"
        echo "   • Check 120Ω termination resistors"
        echo "   • Verify all CAN wiring connections"
        echo "   • Ensure proper power to MCUs"
        echo ""
        echo -e "${YELLOW}3. MCU CONFIGURATION${NC}"
        echo "   • Identify CAN adapter IDs"
        echo "   • Flash MCU firmware with CAN settings"
        echo ""
        echo -e "${BLUE}📖 Complete Guide: https://canbus.esoterical.online/${NC}"
        echo ""
        echo "Would you like to:"
        echo "1) Open advanced/troubleshooting options"
        echo "2) View complete manual steps guide"
        echo "3) Return to communication menu"
        echo ""
        read -p "Choice (1-3): " complete_choice
        
        case $complete_choice in
            1) canbus_advanced_options ;;
            2) canbus_manual_guide ;;
            3) communication_networking_menu ;;
            *) communication_networking_menu ;;
        esac
        
    elif [[ "$status" == "failed" ]]; then
        echo -e "${RED}SETUP FAILED${NC}"
        echo ""
        echo "The automated setup encountered an error."
        echo "Please check the error messages above and try again."
        echo ""
        read -p "Press Enter to return to menu..." dummy
        communication_networking_menu
        
    elif [[ "$status" == "aborted" ]]; then
        echo -e "${YELLOW}SETUP ABORTED${NC}"
        echo ""
        echo "Setup was cancelled due to compatibility concerns."
        echo "Consider updating your system before proceeding."
        echo ""
        read -p "Press Enter to return to menu..." dummy
        communication_networking_menu
    fi
}

# CANBUS Advanced Options
canbus_advanced_options() {
    while true; do
        show_header
        echo -e "${BLUE}ADVANCED CANBUS OPTIONS${NC}"
        echo ""
        echo "1) Configure CAN TX Queue Length (Bug Fix)"
        echo "   • Creates udev rule for CAN interface optimization"
        echo "   • Use if experiencing CAN communication issues"
        echo ""
        echo "2) View System Status"
        echo "   • Check current network service status"
        echo "   • Verify CAN interface configuration"
        echo ""
        echo "3) Reset Network Services"
        echo "   • Restore original network service state"
        echo "   • Use if experiencing network issues"
        echo ""
        echo "0) Back to main CAN setup"
        echo ""
        read -p "Choice (0-3): " advanced_choice
        
        case $advanced_choice in
            1) canbus_configure_txqueue ;;
            2) canbus_view_status ;;
            3) canbus_reset_services ;;
            0) canbus_setup_complete "success" ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Configure CAN TX Queue Length
canbus_configure_txqueue() {
    show_header
    echo -e "${BLUE}CONFIGURE CAN TX QUEUE LENGTH${NC}"
    echo ""
    echo "This creates a udev rule to optimize CAN interface performance."
    echo -e "${YELLOW}WARNING: This modifies system hardware configuration.${NC}"
    echo ""
    read -p "Continue? (y/N): " txqueue_choice
    
    if [[ "$txqueue_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Creating udev rule..."
        
        if echo -e 'SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"' | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null; then
            echo -e "${GREEN}✓ udev rule created successfully${NC}"
            echo ""
            echo "Verifying rule content:"
            cat /etc/udev/rules.d/10-can.rules
            echo ""
            echo -e "${CYAN}Rule will take effect after next reboot or udev reload.${NC}"
        else
            echo -e "${RED}✗ Failed to create udev rule${NC}"
        fi
    else
        echo "Operation cancelled."
    fi
    
    echo ""
    read -p "Press Enter to continue..." dummy
    canbus_advanced_options
}

# View System Status
canbus_view_status() {
    show_header
    echo -e "${BLUE}CANBUS SYSTEM STATUS${NC}"
    echo ""
    
    echo -e "${CYAN}Network Services Status:${NC}"
    systemctl status systemd-networkd --no-pager -l
    echo ""
    
    echo -e "${CYAN}Network Interfaces:${NC}"
    ip link show | grep -E "(can|eth|wlan)"
    echo ""
    
    echo -e "${CYAN}CAN Network Configuration:${NC}"
    if [ -f /etc/systemd/network/25-can.network ]; then
        echo "Found: /etc/systemd/network/25-can.network"
        cat /etc/systemd/network/25-can.network
    else
        echo "No CAN network configuration found (this is expected after automated setup)"
    fi
    echo ""
    
    echo -e "${CYAN}udev CAN Rules:${NC}"
    if [ -f /etc/udev/rules.d/10-can.rules ]; then
        echo "Found: /etc/udev/rules.d/10-can.rules"
        cat /etc/udev/rules.d/10-can.rules
    else
        echo "No CAN udev rules found"
    fi
    
    echo ""
    read -p "Press Enter to continue..." dummy
    canbus_advanced_options
}

# Reset Network Services
canbus_reset_services() {
    show_header
    echo -e "${BLUE}RESET NETWORK SERVICES${NC}"
    echo ""
    echo -e "${RED}This will disable systemd-networkd and re-enable wait-online service.${NC}"
    echo "Use this if you're experiencing network connectivity issues."
    echo ""
    read -p "Continue? (y/N): " reset_choice
    
    if [[ "$reset_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Resetting network services..."
        
        sudo systemctl disable systemd-networkd
        sudo systemctl stop systemd-networkd
        sudo systemctl enable systemd-networkd-wait-online.service
        
        echo -e "${GREEN}Network services reset to default state.${NC}"
        echo "You may need to reboot for full effect."
    else
        echo "Operation cancelled."
    fi
    
    echo ""
    read -p "Press Enter to continue..." dummy
    canbus_advanced_options
}

# Manual Guide Display
canbus_manual_guide() {
    show_header
    echo -e "${BLUE}CANBUS MANUAL CONFIGURATION STEPS${NC}"
    echo ""
    echo -e "${CYAN}The following steps must be completed manually:${NC}"
    echo ""
    echo -e "${YELLOW}STEP 1: Create CAN Network Interface${NC}"
    echo "Run this command to create the CAN network configuration:"
    echo ""
    echo -e "${GREEN}echo -e \"[Match]\\nName=can*\\n\\n[CAN]\\nBitRate=1M\\n\\n[Link]\\nRequiredForOnline=no\" | sudo tee /etc/systemd/network/25-can.network > /dev/null${NC}"
    echo ""
    echo "Then verify with:"
    echo -e "${GREEN}cat /etc/systemd/network/25-can.network${NC}"
    echo ""
    echo -e "${YELLOW}STEP 2: Reboot System${NC}"
    echo "Reboot your system to apply network changes:"
    echo -e "${GREEN}sudo reboot${NC}"
    echo ""
    echo -e "${YELLOW}STEP 3: Hardware Verification${NC}"
    echo "• Verify 120Ω termination resistors are installed"
    echo "• Check all CAN H/L wiring connections"
    echo "• Ensure proper power supply to all MCUs"
    echo ""
    echo -e "${YELLOW}STEP 4: MCU Configuration${NC}"
    echo "• Identify your CAN adapter device ID"
    echo "• Flash MCU firmware with CAN communication enabled"
    echo "• Configure Klipper for CAN communication"
    echo ""
    echo -e "${BLUE}📖 Complete detailed guide: https://canbus.esoterical.online/${NC}"
    echo ""
    read -p "Press Enter to continue..." dummy
    canbus_setup_complete "success"
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

# Function to configure stepper drivers
configure_stepper_drivers() {
    echo -e "${CYAN}=== Stepper Driver Configuration ===${NC}"
    echo "This will help you configure your stepper drivers and TMC settings."
    echo ""
    
    while true; do
        echo -e "${BLUE}Select Stepper to Configure:${NC}"
        echo "1) X Stepper"
        echo "2) Y Stepper" 
        echo "3) Z Stepper"
        echo "4) E Stepper (Extruder)"
        echo "5) Return to hardware menu"
        echo ""
        read -p "Enter your choice (1-5): " stepper_choice
        
        case $stepper_choice in
            1) configure_axis_stepper "x" ;;
            2) configure_axis_stepper "y" ;;
            3) configure_axis_stepper "z" ;;
            4) configure_extruder_stepper ;;
            5) break ;;
            *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
        esac
        echo ""
    done
}

# Function to apply stepper configuration using AWK
apply_stepper_config() {
    local axis="$1"
    local working_cfg="$2"
    local printer_cfg="$3"
    shift 3
    local step_pin="$1" dir_pin="$2" enable_pin="$3" microsteps="$4" rotation_distance="$5"
    local endstop_pin="$6" position_endstop="$7" position_min="$8" position_max="$9"
    shift 9
    local homing_speed="$1" homing_retract_dist="$2" homing_positive_dir="$3"
    local uart_pin="$4" diag_pin="$5" uart_address="$6" run_current="$7" driver_sgthrs="$8"
    local stealthchop_threshold="$9" interpolate="${10}" sense_resistor="${11}"
    
    # Create the configuration blocks
    local stepper_config=""
    stepper_config+="[stepper_${axis}]\n"
    [ -n "$step_pin" ] && stepper_config+="step_pin: ${step_pin}\n"
    [ -n "$dir_pin" ] && stepper_config+="dir_pin: ${dir_pin}\n"
    [ -n "$enable_pin" ] && stepper_config+="enable_pin: ${enable_pin}\n"
    stepper_config+="microsteps: ${microsteps}\n"
    stepper_config+="rotation_distance: ${rotation_distance}\n"
    stepper_config+="endstop_pin: ${endstop_pin}\n"
    [ -n "$position_endstop" ] && stepper_config+="position_endstop: ${position_endstop}\n"
    stepper_config+="position_min: ${position_min}\n"
    [ -n "$position_max" ] && stepper_config+="position_max: ${position_max}\n"
    stepper_config+="homing_speed: ${homing_speed}\n"
    stepper_config+="homing_retract_dist: ${homing_retract_dist}\n"
    stepper_config+="homing_positive_dir: ${homing_positive_dir}\n\n"
    
    local tmc_config=""
    tmc_config+="[tmc2209 stepper_${axis}]\n"
    [ -n "$uart_pin" ] && tmc_config+="uart_pin: ${uart_pin}\n"
    [ -n "$diag_pin" ] && tmc_config+="diag_pin: ${diag_pin}\n"
    tmc_config+="uart_address: ${uart_address}\n"
    [ -n "$run_current" ] && tmc_config+="run_current: ${run_current}\n"
    [ -n "$driver_sgthrs" ] && tmc_config+="driver_sgthrs: ${driver_sgthrs}\n"
    tmc_config+="stealthchop_threshold: ${stealthchop_threshold}\n"
    tmc_config+="interpolate: ${interpolate}\n"
    tmc_config+="sense_resistor: ${sense_resistor}\n"
    
    # Use AWK to replace or add the configuration sections
    awk -v stepper_section="stepper_${axis}" \
        -v tmc_section="tmc2209 stepper_${axis}" \
        -v stepper_config="$stepper_config" \
        -v tmc_config="$tmc_config" '
    BEGIN { 
        in_stepper = 0
        in_tmc = 0
        stepper_replaced = 0
        tmc_replaced = 0
    }
    
    # Start of stepper section
    $0 ~ "^\\[" stepper_section "\\]" {
        print stepper_config
        stepper_replaced = 1
        in_stepper = 1
        next
    }
    
    # Start of TMC section  
    $0 ~ "^\\[" tmc_section "\\]" {
        print tmc_config
        tmc_replaced = 1
        in_tmc = 1
        next
    }
    
    # End of any section
    /^\[/ && (in_stepper || in_tmc) {
        in_stepper = 0
        in_tmc = 0
        print
        next
    }
    
    # Skip lines within sections being replaced
    in_stepper || in_tmc { next }
    
    # Print all other lines
    { print }
    
    END {
        # Add sections if they were not found and replaced
        if (!stepper_replaced) {
            print stepper_config
        }
        if (!tmc_replaced) {
            print tmc_config  
        }
    }
    ' "$working_cfg" > "${working_cfg}.new"
    
    mv "${working_cfg}.new" "$printer_cfg"
    echo "Configuration applied to printer.cfg"
}

# Enhanced function to properly calculate endstop position and position_min
configure_axis_stepper() {
    local axis="$1"
    local AXIS=$(echo "$axis" | tr '[:lower:]' '[:upper:]')
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local working_cfg="${BACKUP_DIR}/printer.cfg.stepper_${axis}_${CURRENT_DATE}"
    
    echo -e "${CYAN}=== Configuring ${AXIS} Stepper ===${NC}"
    
    # Create backup
    if [ ! -f "$printer_cfg" ]; then
        echo -e "${RED}[ERROR] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi
    
    cp "$printer_cfg" "$working_cfg"
    echo "Created backup at ${working_cfg}"
    
    # Collect basic stepper parameters
    echo -e "${YELLOW}Enter stepper parameters (press Enter to skip):${NC}"
    read -p "step_pin: " step_pin
    read -p "dir_pin: " dir_pin
    read -p "enable_pin: " enable_pin
    read -p "microsteps [16]: " microsteps
    microsteps=${microsteps:-16}
    read -p "rotation_distance [40]: " rotation_distance
    rotation_distance=${rotation_distance:-40}
    read -p "endstop_pin [tmc2209_stepper_${axis}:virtual_endstop]: " endstop_pin
    endstop_pin=${endstop_pin:-"tmc2209_stepper_${axis}:virtual_endstop"}
    
    # Enhanced position and endstop configuration
    echo ""
    echo -e "${CYAN}=== Endstop and Position Configuration ===${NC}"
    echo "We need to determine three key values:"
    echo "1. Where the endstop physically triggers"
    echo "2. Where you want coordinate 0 to be (position_endstop)"  
    echo "3. How far past 0 the axis can travel (position_min)"
    echo ""
    
    # Step 1: Determine endstop trigger location
    echo -e "${BLUE}Step 1: Physical Endstop Location${NC}"
    echo "Where does the endstop switch/sensor physically trigger?"
    echo "Examples:"
    echo "  - If endstop triggers when nozzle is 5mm from bed edge: enter 5"
    echo "  - If endstop triggers exactly at desired 0 position: enter 0"
    echo "  - If endstop triggers when nozzle is past desired 0: enter negative value"
    echo ""
    read -p "Endstop trigger distance from desired 0 position (mm): " endstop_trigger_distance
    endstop_trigger_distance=${endstop_trigger_distance:-0}
    
    # Step 2: Calculate position_endstop
    echo ""
    echo -e "${BLUE}Step 2: Position Endstop Calculation${NC}"
    echo "position_endstop defines where coordinate 0 will be after homing."
    echo "Based on your endstop trigger distance: ${endstop_trigger_distance}mm"
    
    local position_endstop
    if [ "$endstop_trigger_distance" = "0" ]; then
        position_endstop="0"
        echo "Endstop triggers at desired 0 position → position_endstop: 0"
    elif [ "$endstop_trigger_distance" -gt 0 ] 2>/dev/null; then
        position_endstop="-${endstop_trigger_distance}"
        echo "Endstop triggers ${endstop_trigger_distance}mm before 0 → position_endstop: -${endstop_trigger_distance}"
    else
        # Negative trigger distance means endstop is past 0
        positive_distance=$(echo "$endstop_trigger_distance" | sed 's/^-//')
        position_endstop="$positive_distance"
        echo "Endstop triggers ${positive_distance}mm past 0 → position_endstop: ${positive_distance}"
    fi
    
    # Step 3: Determine additional negative travel
    echo ""
    echo -e "${BLUE}Step 3: Additional Negative Travel${NC}"
    echo "After homing to position 0, can the axis travel further in the negative direction?"
    echo "This is the mechanical travel available beyond your 0 position."
    echo ""
    read -p "Additional negative travel available (mm) [0]: " additional_negative_travel
    additional_negative_travel=${additional_negative_travel:-0}
    
    # Calculate position_min
    local position_min
    if [ "$additional_negative_travel" = "0" ]; then
        position_min="0"
    else
        position_min="-${additional_negative_travel}"
    fi
    
    # Step 4: Position max (manual)
    echo ""
    echo -e "${BLUE}Step 4: Maximum Position${NC}"
    echo "For position_max, you need to physically jog the axis to its maximum travel."
    echo "Leave blank to configure this later manually."
    read -p "position_max (maximum travel coordinate): " position_max
    
    # Summary with visual representation
    echo ""
    echo -e "${CYAN}=== Configuration Summary ===${NC}"
    echo "Visual representation of ${AXIS} axis:"
    echo ""
    
    # Create a simple ASCII representation
    local endstop_pos="ENDSTOP"
    local zero_pos="0"
    local min_pos="MIN"
    local max_pos="MAX"
    
    echo "Axis Travel: [${min_pos}]----[${zero_pos}]----[${endstop_pos}]----[${max_pos}]"
    echo ""
    echo "Calculated values:"
    echo "  position_min: $position_min (furthest negative travel)"
    echo "  position_endstop: $position_endstop (where 0 coordinate will be)"
    echo "  position_max: ${position_max:-'(to be set manually)'}"
    echo "  endstop_trigger_distance: ${endstop_trigger_distance}mm"
    echo "  additional_negative_travel: ${additional_negative_travel}mm"
    echo ""
    
    # Validation
    echo -e "${YELLOW}Validation:${NC}"
    echo "• Endstop will trigger at: calculated position"
    echo "• After homing, 0 position will be at: position_endstop ($position_endstop)"
    echo "• Axis can travel from $position_min to ${position_max:-'MAX'}"
    echo ""
    
    read -p "Does this configuration look correct? (Y/n): " confirm_config
    if [[ "$confirm_config" =~ ^[Nn]$ ]]; then
        echo "Configuration cancelled. Please restart the configuration process."
        return
    fi
    
    # Homing parameters
    echo ""
    echo -e "${YELLOW}Homing parameters:${NC}"
    read -p "homing_speed [50]: " homing_speed
    homing_speed=${homing_speed:-50}
    read -p "homing_retract_dist [5]: " homing_retract_dist
    homing_retract_dist=${homing_retract_dist:-5}
    
    # Determine homing direction
    local homing_positive_dir="false"
    echo "Setting homing_positive_dir: false (standard for min endstop)"
    
    # TMC2209 parameters
    echo ""
    echo -e "${YELLOW}Enter TMC2209 parameters:${NC}"
    read -p "uart_pin: " uart_pin
    read -p "diag_pin: " diag_pin
    read -p "uart_address [0]: " uart_address
    uart_address=${uart_address:-0}
    read -p "run_current: " run_current
    read -p "driver_sgthrs: " driver_sgthrs
    read -p "stealthchop_threshold [999999]: " stealthchop_threshold
    stealthchop_threshold=${stealthchop_threshold:-999999}
    read -p "interpolate [true]: " interpolate
    interpolate=${interpolate:-true}
    read -p "sense_resistor [0.110]: " sense_resistor
    sense_resistor=${sense_resistor:-0.110}
    
    # Apply the configuration
    apply_stepper_config "$axis" "$working_cfg" "$printer_cfg" \
        "$step_pin" "$dir_pin" "$enable_pin" "$microsteps" "$rotation_distance" \
        "$endstop_pin" "$position_endstop" "$position_min" "$position_max" \
        "$homing_speed" "$homing_retract_dist" "$homing_positive_dir" \
        "$uart_pin" "$diag_pin" "$uart_address" "$run_current" "$driver_sgthrs" \
        "$stealthchop_threshold" "$interpolate" "$sense_resistor"
    
    echo -e "${GREEN}${AXIS} stepper configured successfully!${NC}"
    
    # Post-configuration instructions
    echo ""
    echo -e "${CYAN}=== Next Steps ===${NC}"
    if [ -z "$position_max" ]; then
        echo "1. Test homing: HOME_${AXIS} or G28 ${AXIS}"
        echo "2. Verify 0 position is where expected"
        echo "3. Manually jog to maximum travel and note coordinate"
        echo "4. Update position_max in printer.cfg"
    else
        echo "1. Test homing: HOME_${AXIS} or G28 ${AXIS}"
        echo "2. Verify 0 position is where expected"
        echo "3. Test travel limits: jog to position_min and position_max"
    fi
    echo "5. Test negative travel if configured"
}

# ENHANCED: Function to configure extruder stepper (includes all extruder settings)
configure_extruder_stepper() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local working_cfg="${BACKUP_DIR}/printer.cfg.extruder_${CURRENT_DATE}"
    
    echo -e "${CYAN}=== Configuring Extruder System ===${NC}"
    echo "This will configure your complete extruder system including:"
    echo "• Stepper motor settings"
    echo "• Temperature limits and safety settings"
    echo "• Pressure advance configuration"
    echo "• TMC driver settings"
    echo ""
    
    # Create backup
    if [ ! -f "$printer_cfg" ]; then
        echo -e "${RED}[ERROR] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi
    
    cp "$printer_cfg" "$working_cfg"
    echo "Created backup at ${working_cfg}"
    
    # Collect stepper parameters
    echo -e "${YELLOW}Enter extruder stepper parameters:${NC}"
    read -p "step_pin: " step_pin
    read -p "dir_pin: " dir_pin
    read -p "enable_pin: " enable_pin
    read -p "microsteps [16]: " microsteps
    microsteps=${microsteps:-16}
    read -p "rotation_distance [22.6789511]: " rotation_distance
    rotation_distance=${rotation_distance:-22.6789511}
    
    # Temperature settings
    echo ""
    echo -e "${YELLOW}Temperature and physical settings:${NC}"
    read -p "nozzle_diameter [0.4]: " nozzle_diameter
    nozzle_diameter=${nozzle_diameter:-0.4}
    read -p "filament_diameter [1.75]: " filament_diameter
    filament_diameter=${filament_diameter:-1.75}
    read -p "max_temp [300]: " max_temp
    max_temp=${max_temp:-300}
    read -p "min_temp [0]: " min_temp
    min_temp=${min_temp:-0}
    read -p "min_extrude_temp [170]: " min_extrude_temp
    min_extrude_temp=${min_extrude_temp:-170}
    
    # Safety limits (consolidated from removed add_extruder_settings function)
    echo ""
    echo -e "${YELLOW}Safety limits:${NC}"
    read -p "max_extrude_cross_section [10]: " max_cross_section
    max_cross_section=${max_cross_section:-10}
    read -p "max_extrude_only_distance [500]: " max_distance
    max_distance=${max_distance:-500}
    read -p "max_extrude_only_velocity [120]: " max_velocity
    max_velocity=${max_velocity:-120}
    
    # Pressure advance
    echo ""
    echo -e "${YELLOW}Pressure advance (leave blank to skip):${NC}"
    read -p "pressure_advance [0.0]: " pressure_advance
    pressure_advance=${pressure_advance:-0.0}
    read -p "pressure_advance_smooth_time [0.040]: " pa_smooth_time
    pa_smooth_time=${pa_smooth_time:-0.040}
    
    # TMC settings
    echo ""
    echo -e "${YELLOW}TMC2209 settings:${NC}"
    read -p "uart_pin: " uart_pin
    read -p "run_current [0.8]: " run_current
    run_current=${run_current:-0.8}
    read -p "stealthchop_threshold [999999]: " stealthchop_threshold
    stealthchop_threshold=${stealthchop_threshold:-999999}
    
    # Create extruder configuration block
    local extruder_config="[extruder]
step_pin: ${step_pin}
dir_pin: ${dir_pin}
enable_pin: ${enable_pin}
microsteps: ${microsteps}
rotation_distance: ${rotation_distance}
nozzle_diameter: ${nozzle_diameter}
filament_diameter: ${filament_diameter}
heater_pin: # CONFIGURE MANUALLY
sensor_type: # CONFIGURE MANUALLY  
sensor_pin: # CONFIGURE MANUALLY
#control: pid
#pid_Kp: # RUN PID TUNING
#pid_Ki: # RUN PID TUNING  
#pid_Kd: # RUN PID TUNING
min_temp: ${min_temp}
max_temp: ${max_temp}
min_extrude_temp: ${min_extrude_temp}
max_extrude_cross_section: ${max_cross_section}
max_extrude_only_distance: ${max_distance}
max_extrude_only_velocity: ${max_velocity}"

    if [ "$pressure_advance" != "0.0" ]; then
        extruder_config+="\npressure_advance: ${pressure_advance}"
        extruder_config+="\npressure_advance_smooth_time: ${pa_smooth_time}"
    fi
    
    local tmc_config="[tmc2209 extruder]
uart_pin: ${uart_pin}
run_current: ${run_current}
stealthchop_threshold: ${stealthchop_threshold}
interpolate: true
sense_resistor: 0.110"
    
    # Apply configurations using AWK (similar to axis steppers)
    awk -v extruder_config="$extruder_config" -v tmc_config="$tmc_config" '
    BEGIN { 
        in_extruder = 0
        in_tmc = 0
        extruder_replaced = 0
        tmc_replaced = 0
    }
    
    /^\[extruder\]/ {
        print extruder_config
        extruder_replaced = 1
        in_extruder = 1
        next
    }
    
    /^\[tmc2209 extruder\]/ {
        print tmc_config
        tmc_replaced = 1
        in_tmc = 1
        next
    }
    
    /^\[/ && (in_extruder || in_tmc) {
        in_extruder = 0
        in_tmc = 0
        print
        next
    }
    
    in_extruder || in_tmc { next }
    
    { print }
    
    END {
        if (!extruder_replaced) {
            print extruder_config
        }
        if (!tmc_replaced) {
            print tmc_config  
        }
    }
    ' "$working_cfg" > "${working_cfg}.new"
    
    mv "${working_cfg}.new" "$printer_cfg"
    
    echo -e "${GREEN}Extruder system configured successfully!${NC}"
    echo ""
    echo -e "${CYAN}=== Manual Configuration Required ===${NC}"
    echo "You still need to configure manually in printer.cfg:"
    echo "• heater_pin: (hotend heater pin)"
    echo "• sensor_type: (thermistor type)"
    echo "• sensor_pin: (thermistor pin)"
    echo ""
    echo -e "${CYAN}=== Next Steps ===${NC}"
    echo "1. Configure heater and sensor pins manually"
    echo "2. Run PID tuning from 'Additional Features' menu"
    echo "3. Run E-steps calibration from 'Additional Features' menu"
    echo "4. Test extrusion at different temperatures"
}

# Hardware configuration menu (reorganized - removed add_extruder_settings)
hardware_config_menu() {
    show_header
    echo -e "${BLUE}HARDWARE CONFIGURATION UTILITIES${NC}"
    echo "1) Check MCU IDs"
    echo "2) Check CAN bus devices"
    echo "3) Browse Official Klipper Configurations"
    echo "4) Enable Eddy NG tap start print function"
    echo "5) Configure firmware retraction"
    echo "6) Configure force_move"
    echo "7) Configure stepper drivers"
    echo "0) Back to main menu"
    echo ""
    read -p "Select an option: " hw_choice
    
    case $hw_choice in
        1) check_mcu_ids ;;
        2) check_can_bus ;;
        3) browse_official_configs ;;
        4) configure_eddy_ng_tap; hardware_config_menu ;;
        5) add_firmware_retraction_to_printer_cfg; hardware_config_menu ;;
        6) add_force_move; hardware_config_menu ;;
        7) configure_stepper_drivers; hardware_config_menu ;;
        0) show_main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; hardware_config_menu ;;
    esac
}

# ENHANCED: Function to check MCU IDs with more robust section detection
check_mcu_ids() {
    show_header
    echo -e "${BLUE}MCU ID CHECKER & UPDATER${NC}"
    echo "This will show MCU IDs of all connected devices and let you update your printer.cfg"
    echo ""
    
    # First check if ls command exists
    if ! command -v ls &> /dev/null; then
        echo -e "${RED}Error: ls command not found${NC}"
        read -p "Press Enter to continue..." dummy
        hardware_config_menu
        return
    fi
    
    # Array to store all found MCU IDs with descriptive labels
    declare -a all_mcus
    
    echo "Serial MCUs:"
    echo "------------"
    if [ -d "/dev/serial/by-id/" ]; then
        i=1
        while read -r line; do
            mcu_path=$(echo "$line" | awk '{print $NF}')
            mcu_id=$(echo "$line" | awk '{print $9}')
            if [ -n "$mcu_id" ] && [ "$mcu_id" != "." ] && [ "$mcu_id" != ".." ]; then
                echo "$i) $mcu_id → $mcu_path"
                all_mcus+=("SERIAL|$mcu_id|$mcu_path")
                i=$((i+1))
            fi
        done < <(ls -la /dev/serial/by-id/ 2>/dev/null | grep -v '^total' | grep -v '^d')
    else
        echo "No serial MCUs found"
    fi
    echo ""
    
    echo "USB MCUs:"
    echo "---------"
    if [ -d "/dev/serial/by-path/" ]; then
        while read -r line; do
            mcu_path=$(echo "$line" | awk '{print $NF}')
            mcu_id=$(echo "$line" | awk '{print $9}')
            if [ -n "$mcu_id" ] && [ "$mcu_id" != "." ] && [ "$mcu_id" != ".." ]; then
                echo "$i) $mcu_id → $mcu_path"
                all_mcus+=("USB|$mcu_id|$mcu_path")
                i=$((i+1))
            fi
        done < <(ls -la /dev/serial/by-path/ 2>/dev/null | grep -v '^total' | grep -v '^d')
    else
        echo "No USB MCU paths found"
    fi
    echo ""
    
    # CAN bus UUIDs if available
    if [ -f "${HOME}/klipper/scripts/canbus_query.py" ] && command -v ip &> /dev/null; then
        echo "CAN bus devices:"
        echo "--------------"
        can_interfaces=($(ip -d link show | grep -i can | cut -d: -f2 | awk '{print $1}' | tr -d ' '))
        
        if [ ${#can_interfaces[@]} -gt 0 ]; then
            for interface in "${can_interfaces[@]}"; do
                echo "Querying CAN interface: $interface"
                can_results=$("${HOME}/klippy-env/bin/python" "${HOME}/klipper/scripts/canbus_query.py" "$interface" 2>/dev/null || echo "Error querying $interface")
                if [[ "$can_results" != *"Error"* ]]; then
                    while read -r uuid; do
                        if [[ -n "$uuid" ]]; then
                            echo "$i) $uuid (CAN bus on $interface)"
                            all_mcus+=("CAN|$uuid|$interface")
                            i=$((i+1))
                        fi
                    done < <(echo "$can_results" | grep -o '[0-9a-f]\{32\}')
                else
                    echo "  No devices found on $interface"
                fi
            done
        else
            echo "  No CAN interfaces found"
        fi
        echo ""
    fi
    
    # Show currently configured MCUs in printer.cfg
    echo "Currently configured MCUs in printer.cfg:"
    echo "----------------------------------------"
    
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    declare -a configured_mcus
    
    if [ -f "$printer_cfg" ]; then
        while read -r mcu_line; do
            section=$(echo "$mcu_line" | tr -d '[:space:]')
            section=${section#\[}
            section=${section%\]}
            
            if [[ "$section" == mcu* ]]; then
                echo -e "${CYAN}Found MCU section: [$section]${NC}"
                configured_mcus+=("$section")
                
                serial_line=$(sed -n "/\[$section\]/,/^\[/p" "$printer_cfg" | grep -i "serial:" | head -n 1)
                canbus_line=$(sed -n "/\[$section\]/,/^\[/p" "$printer_cfg" | grep -i "canbus_uuid:" | head -n 1)
                
                echo -e "${CYAN}[$section]${NC}"
                if [ -n "$serial_line" ]; then
                    echo "  $serial_line"
                elif [ -n "$canbus_line" ]; then
                    echo "  $canbus_line"
                else
                    echo "  No serial/canbus configuration found"
                fi
                echo ""
            fi
        done < <(grep -i "^\s*\[mcu" "$printer_cfg")
        
        if [ ${#configured_mcus[@]} -eq 0 ]; then
            echo -e "${YELLOW}No MCU sections found using standard detection.${NC}"
        fi
    else
        echo -e "${RED}printer.cfg not found${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}OPTIONS:${NC}"
    echo "1) Update MCU configuration in printer.cfg"
    echo "2) Return to hardware menu"
    
    read -p "Select an option: " mcu_option
    
    case $mcu_option in
        1)
            if [ ${#all_mcus[@]} -eq 0 ]; then
                echo -e "${RED}No MCUs found to configure${NC}"
                read -p "Press Enter to continue..." dummy
                hardware_config_menu
                return
            fi
            
            if [ ! -f "$printer_cfg" ]; then
                echo -e "${RED}printer.cfg not found. Cannot update configuration.${NC}"
                read -p "Press Enter to continue..." dummy
                hardware_config_menu
                return
            fi
            
            local backup_file="${BACKUP_DIR}/printer.cfg.mcu_update_${CURRENT_DATE}"
            cp "$printer_cfg" "$backup_file"
            echo "Created backup at $backup_file"
            
            if [ ${#configured_mcus[@]} -gt 0 ]; then
                echo ""
                echo "Which MCU section would you like to update?"
                for i in "${!configured_mcus[@]}"; do
                    echo "$((i+1))) ${configured_mcus[$i]}"
                done
                echo "$((${#configured_mcus[@]}+1))) Create new MCU section"
                
                read -p "Select MCU number: " mcu_num
                
                if [[ ! "$mcu_num" =~ ^[0-9]+$ ]] || [ "$mcu_num" -lt 1 ] || [ "$mcu_num" -gt $((${#configured_mcus[@]}+1)) ]; then
                    echo -e "${RED}Invalid selection${NC}"
                    read -p "Press Enter to continue..." dummy
                    hardware_config_menu
                    return
                fi
                
                if [ "$mcu_num" -eq $((${#configured_mcus[@]}+1)) ]; then
                    echo "Select MCU type:"
                    echo "1) Main MCU [mcu]"
                    echo "2) Secondary MCU (e.g., [mcu z], [mcu extruder])"
                    read -p "Select type (1/2): " mcu_type
                    
                    if [ "$mcu_type" -eq 1 ]; then
                        selected_mcu="mcu"
                    elif [ "$mcu_type" -eq 2 ]; then
                        read -p "Enter name for secondary MCU (e.g., z, extruder): " secondary_name
                        selected_mcu="mcu $secondary_name"
                    else
                        echo -e "${RED}Invalid selection${NC}"
                        read -p "Press Enter to continue..." dummy
                        hardware_config_menu
                        return
                    fi
                    
                    sed -i "1i[$selected_mcu]\n" "$printer_cfg"
                    echo -e "${GREEN}Created new [$selected_mcu] section in printer.cfg${NC}"
                else
                    selected_mcu="${configured_mcus[$((mcu_num-1))]}"
                fi
            else
                echo "No MCU sections found. Creating a new one."
                echo "Select MCU type:"
                echo "1) Main MCU [mcu]"
                echo "2) Secondary MCU (e.g., [mcu z], [mcu extruder])"
                read -p "Select type (1/2): " mcu_type
                
                if [ "$mcu_type" -eq 1 ]; then
                    selected_mcu="mcu"
                elif [ "$mcu_type" -eq 2 ]; then
                    read -p "Enter name for secondary MCU (e.g., z, extruder): " secondary_name
                    selected_mcu="mcu $secondary_name"
                else
                    echo -e "${RED}Invalid selection${NC}"
                    read -p "Press Enter to continue..." dummy
                    hardware_config_menu
                    return
                fi
                
                sed -i "1i[$selected_mcu]\n" "$printer_cfg"
                echo -e "${GREEN}Created new [$selected_mcu] section in printer.cfg${NC}"
            fi
            
            echo ""
            echo "Which MCU ID would you like to use for [${selected_mcu}]?"
            for i in "${!all_mcus[@]}"; do
                IFS='|' read -r type id path <<< "${all_mcus[$i]}"
                if [ "$type" == "CAN" ]; then
                    echo "$((i+1))) $id (CAN bus on $path)"
                else
                    echo "$((i+1))) $id ($type)"
                fi
            done
            
            read -p "Select MCU ID number: " id_num
            
            if [[ ! "$id_num" =~ ^[0-9]+$ ]] || [ "$id_num" -lt 1 ] || [ "$id_num" -gt ${#all_mcus[@]} ]; then
                echo -e "${RED}Invalid selection${NC}"
                read -p "Press Enter to continue..." dummy
                hardware_config_menu
                return
            fi
            
            selected_mcu_info="${all_mcus[$((id_num-1))]}"
            IFS='|' read -r type id path <<< "$selected_mcu_info"
            
            local tmp_file="${BACKUP_DIR}/printer.cfg.tmp_${CURRENT_DATE}"
            
            if [ "$type" == "CAN" ]; then
                cat "$printer_cfg" > "$tmp_file"
                
                selected_mcu_escaped=$(echo "$selected_mcu" | sed 's/ /\\ /g')
                
                sed -i "/^\[$selected_mcu_escaped\]/,/^\[/ {/^\[$selected_mcu_escaped\]/b; /^\[/b; /^serial:/d; /^canbus_uuid:/d}" "$tmp_file" 2>/dev/null || true
                
                if [[ "$selected_mcu" == *" "* ]]; then
                    awk -v mcu="[$selected_mcu]" -v uuid="canbus_uuid: $id" '
                    $0 ~ mcu {print; print uuid; next}
                    {print}
                    ' "$tmp_file" > "${tmp_file}.new"
                    mv "${tmp_file}.new" "$tmp_file"
                else
                    sed -i "/^\[$selected_mcu\]/a canbus_uuid: $id" "$tmp_file"
                fi
                
                echo -e "${GREEN}Updated [$selected_mcu] with CAN bus UUID: $id${NC}"
            else
                cat "$printer_cfg" > "$tmp_file"
                
                selected_mcu_escaped=$(echo "$selected_mcu" | sed 's/ /\\ /g')
                
                sed -i "/^\[$selected_mcu_escaped\]/,/^\[/ {/^\[$selected_mcu_escaped\]/b; /^\[/b; /^serial:/d; /^canbus_uuid:/d}" "$tmp_file" 2>/dev/null || true
                
                if [[ "$selected_mcu" == *" "* ]]; then
                    awk -v mcu="[$selected_mcu]" -v serial="serial: /dev/serial/by-id/$id" '
                    $0 ~ mcu {print; print serial; next}
                    {print}
                    ' "$tmp_file" > "${tmp_file}.new"
                    mv "${tmp_file}.new" "$tmp_file"
                else
                    sed -i "/^\[$selected_mcu\]/a serial: /dev/serial/by-id/$id" "$tmp_file"
                fi
                
                echo -e "${GREEN}Updated [$selected_mcu] with serial: /dev/serial/by-id/$id${NC}"
            fi
            
            mv "$tmp_file" "$printer_cfg"
            echo -e "${GREEN}MCU configuration updated successfully!${NC}"
            echo "Backup of previous configuration saved at: $backup_file"
            
            read -p "Press Enter to continue..." dummy
            check_mcu_ids
            ;;
        2|*)
            hardware_config_menu
            ;;
    esac
}

# Function to check CAN bus devices
check_can_bus() {
    show_header
    echo -e "${BLUE}CAN BUS DEVICE CHECKER${NC}"
    echo "Checking for CAN interfaces and devices..."
    echo ""
    
    if ! command -v ip &> /dev/null; then
        echo -e "${RED}Error: ip command not found${NC}"
        read -p "Press Enter to continue..." dummy
        hardware_config_menu
        return
    fi
    
    can_interfaces=($(ip -d link show | grep -i can | cut -d: -f2 | awk '{print $1}' | tr -d ' '))
    
    if [ ${#can_interfaces[@]} -eq 0 ]; then
        echo -e "${YELLOW}No CAN interfaces found${NC}"
        read -p "Press Enter to continue..." dummy
        hardware_config_menu
        return
    fi
    
    for interface in "${can_interfaces[@]}"; do
        echo -e "${CYAN}Interface: $interface${NC}"
        echo "Status: $(ip link show $interface | grep -o 'state [A-Z]*' | cut -d' ' -f2)"
        
        if [ -f "${HOME}/klipper/scripts/canbus_query.py" ]; then
            echo "Devices found:"
            can_results=$("${HOME}/klippy-env/bin/python" "${HOME}/klipper/scripts/canbus_query.py" "$interface" 2>/dev/null || echo "Error querying $interface")
            if [[ "$can_results" != *"Error"* ]]; then
                while read -r uuid; do
                    if [[ -n "$uuid" ]]; then
                        echo "  - UUID: $uuid"
                    fi
                done < <(echo "$can_results" | grep -o '[0-9a-f]\{32\}')
            else
                echo "  No devices found or error querying interface"
            fi
        else
            echo "  Cannot query devices (canbus_query.py not found)"
        fi
        echo ""
    done
    
    read -p "Press Enter to continue..." dummy
    hardware_config_menu
}

# Function to browse and download official Klipper configurations
browse_official_configs() {
    show_header
    echo -e "${BLUE}OFFICIAL KLIPPER CONFIGURATIONS${NC}"
    echo "Browse and download official Klipper example configurations"
    echo "These are maintained by the Klipper project and updated regularly."
    echo ""
    
    echo "1) List available configurations"
    echo "2) Download configuration file"
    echo "0) Back to hardware menu"
    echo ""
    read -p "Select an option: " config_choice
    
    case $config_choice in
        1) list_official_configs ;;
        2) download_official_config ;;
        0) hardware_config_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 2; browse_official_configs ;;
    esac
}

# Function to list official configurations with pagination
list_official_configs() {
    show_header
    echo -e "${BLUE}AVAILABLE KLIPPER CONFIGURATIONS${NC}"
    echo "Fetching latest configurations from GitHub..."
    echo ""
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required but not installed${NC}"
        read -p "Press Enter to continue..." dummy
        browse_official_configs
        return
    fi
    
    # Fetch configurations from GitHub API
    local api_response
    local http_code
    local temp_file="/tmp/klipper_configs_$$"
    
    http_code=$(curl -s -w "%{http_code}" -o "$temp_file" \
        "https://api.github.com/repos/Klipper3d/klipper/contents/config?ref=master" 2>/dev/null)
    
    if [ -f "$temp_file" ]; then
        api_response=$(cat "$temp_file")
        rm -f "$temp_file"
    fi
    
    if [ "$http_code" != "200" ] || [ -z "$api_response" ]; then
        echo -e "${RED}Error: Could not fetch configurations from GitHub${NC}"
        echo "Please check your internet connection or try again later."
        echo ""
        echo -e "${CYAN}Browse manually at: https://github.com/Klipper3d/klipper/tree/master/config${NC}"
        read -p "Press Enter to continue..." dummy
        browse_official_configs
        return
    fi
    
    # Build array of config files
    local configs=()
    
    while IFS= read -r line; do
        if [[ "$line" == *'"name":'* && "$line" == *'.cfg"'* ]]; then
            filename=$(echo "$line" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [[ "$filename" == *.cfg ]]; then
                configs+=("$filename")
            fi
        fi
    done <<< "$api_response"
    
    # Fallback parsing if first method fails
    if [ ${#configs[@]} -eq 0 ]; then
        while IFS= read -r filename; do
            if [[ -n "$filename" && "$filename" == *.cfg ]]; then
                configs+=("$filename")
            fi
        done < <(echo "$api_response" | grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]*\.cfg"' | cut -d'"' -f4)
    fi
    
    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No .cfg files found.${NC}"
        read -p "Press Enter to continue..." dummy
        browse_official_configs
        return
    fi
    
    # Sort the configs array
    IFS=$'\n' configs=($(sort <<<"${configs[*]}"))
    unset IFS
    
    # Pagination variables
    local page_size=15
    local current_page=0
    local total_pages=$(( (${#configs[@]} + page_size - 1) / page_size ))
    
    while true; do
        show_header
        echo -e "${BLUE}AVAILABLE KLIPPER CONFIGURATIONS${NC}"
        echo "Found ${#configs[@]} configuration files"
        echo "Page $((current_page + 1)) of $total_pages"
        echo ""
        
        # Calculate range for current page
        local start_idx=$((current_page * page_size))
        local end_idx=$((start_idx + page_size - 1))
        if [ $end_idx -ge ${#configs[@]} ]; then
            end_idx=$((${#configs[@]} - 1))
        fi
        
        # Display current page
        for i in $(seq $start_idx $end_idx); do
            echo "$((i + 1))) ${configs[$i]}"
        done
        
        echo ""
        echo -e "${CYAN}Navigation:${NC}"
        if [ $current_page -gt 0 ]; then
            echo "p) Previous page"
        fi
        if [ $current_page -lt $((total_pages - 1)) ]; then
            echo "n) Next page"
        fi
        echo "s) Search for specific config"
        echo "0) Back to config menu"
        echo ""
        
        read -p "Select option: " nav_choice
        
        case $nav_choice in
            p|P)
                if [ $current_page -gt 0 ]; then
                    current_page=$((current_page - 1))
                else
                    echo -e "${YELLOW}Already at first page${NC}"
                    sleep 1
                fi
                ;;
            n|N)
                if [ $current_page -lt $((total_pages - 1)) ]; then
                    current_page=$((current_page + 1))
                else
                    echo -e "${YELLOW}Already at last page${NC}"
                    sleep 1
                fi
                ;;
            s|S)
                echo ""
                read -p "Enter search term (partial filename): " search_term
                if [ -n "$search_term" ]; then
                    echo ""
                    echo -e "${CYAN}Matching configurations:${NC}"
                    local found=0
                    for i in "${!configs[@]}"; do
                        if [[ "${configs[$i]}" == *"$search_term"* ]]; then
                            echo "$((i + 1))) ${configs[$i]}"
                            found=1
                        fi
                    done
                    if [ $found -eq 0 ]; then
                        echo "No configurations found matching '$search_term'"
                    fi
                    echo ""
                    read -p "Press Enter to continue..." dummy
                fi
                ;;
            0)
                browse_official_configs
                return
                ;;
            *)
                echo -e "${YELLOW}Invalid option. Use p/n for navigation, s for search, or 0 to exit.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Function to download official configuration
download_official_config() {
    show_header
    echo -e "${BLUE}DOWNLOAD KLIPPER CONFIGURATION${NC}"
    echo ""
    
    # Fetch the list first for numbered selection
    local api_response
    local http_code
    local temp_file="/tmp/klipper_configs_$$"
    
    echo "Fetching available configurations..."
    http_code=$(curl -s -w "%{http_code}" -o "$temp_file" \
        "https://api.github.com/repos/Klipper3d/klipper/contents/config?ref=master" 2>/dev/null)
    
    if [ -f "$temp_file" ]; then
        api_response=$(cat "$temp_file")
        rm -f "$temp_file"
    fi
    
    if [ "$http_code" != "200" ] || [ -z "$api_response" ]; then
        echo -e "${RED}Error: Could not fetch configurations from GitHub${NC}"
        read -p "Press Enter to continue..." dummy
        browse_official_configs
        return
    fi
    
    # Build array of config files using improved parsing
    local configs=()
    
    # Same parsing logic as list function
    while IFS= read -r line; do
        if [[ "$line" == *'"name":'* && "$line" == *'.cfg"'* ]]; then
            filename=$(echo "$line" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [[ "$filename" == *.cfg ]]; then
                configs+=("$filename")
            fi
        fi
    done <<< "$api_response"
    
    # Fallback parsing if first method fails
    if [ ${#configs[@]} -eq 0 ]; then
        while IFS= read -r filename; do
            if [[ -n "$filename" && "$filename" == *.cfg ]]; then
                configs+=("$filename")
            fi
        done < <(echo "$api_response" | grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]*\.cfg"' | cut -d'"' -f4)
    fi
    
    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No configurations available for download${NC}"
        read -p "Press Enter to continue..." dummy
        browse_official_configs
        return
    fi
    
    # Sort the configs array
    IFS=$'\n' configs=($(sort <<<"${configs[*]}"))
    unset IFS
    
    # Show numbered list
    echo "Available configurations:"
    echo ""
    for i in "${!configs[@]}"; do
        echo "$((i+1))) ${configs[$i]}"
    done
    echo "0) Cancel"
    echo ""
    
    read -p "Select configuration number (0-${#configs[@]}): " selection
    
    if [ "$selection" -eq 0 ] 2>/dev/null; then
        browse_official_configs
        return
    fi
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#configs[@]} ]; then
        echo -e "${RED}Invalid selection${NC}"
        read -p "Press Enter to continue..." dummy
        download_official_config
        return
    fi
    
    local source_filename="${configs[$((selection-1))]}"
    local target_file="${KLIPPER_CONFIG}/printer.cfg"
    
    echo ""
    echo "Selected: $source_filename"
    echo "This will be downloaded and renamed to printer.cfg"
    echo ""
    
    # Backup existing printer.cfg if it exists
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}Existing printer.cfg found - creating backup...${NC}"
        cp "$target_file" "${BACKUP_DIR}/printer.cfg.backup_${CURRENT_DATE}"
        echo "Backup created: ${BACKUP_DIR}/printer.cfg.backup_${CURRENT_DATE}"
        echo ""
    fi
    
    echo "Downloading $source_filename..."
    
    # Download the file directly as printer.cfg
    local download_url="https://raw.githubusercontent.com/Klipper3d/klipper/master/config/$source_filename"
    
    if curl -s -f "$download_url" -o "$target_file"; then
        echo -e "${GREEN}Successfully downloaded and saved as printer.cfg${NC}"
        echo ""
        echo -e "${CYAN}Download Summary:${NC}"
        echo "• Source: $source_filename (from Klipper repository)"
        echo "• Saved as: ${KLIPPER_CONFIG}/printer.cfg"
        if [ -f "${BACKUP_DIR}/printer.cfg.backup_${CURRENT_DATE}" ]; then
            echo "• Previous printer.cfg backed up to: backup/printer.cfg.backup_${CURRENT_DATE}"
        fi
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "1. Review the downloaded printer.cfg file"
        echo "2. Modify settings to match your specific hardware"
        echo "3. Add any additional includes you need"
        echo "4. Restart Klipper service to load the new configuration"
        echo ""
        
        read -p "Would you like to restart Klipper now? (y/N): " restart_choice
        if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
            echo "Restarting Klipper service..."
            sudo systemctl restart $KLIPPER_SERVICE_NAME
            echo -e "${GREEN}Klipper service restarted!${NC}"
        else
            echo -e "${YELLOW}Remember to restart Klipper when you're ready to use the new configuration.${NC}"
        fi
    else
        echo -e "${RED}Error: Could not download $source_filename${NC}"
        echo "Please check your internet connection and try again."
    fi
    
    read -p "Press Enter to continue..." dummy
    browse_official_configs
}

# Backup management menu
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

# Diagnostics menu
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

check_klipper_status() {
    show_header
    echo -e "${BLUE}KLIPPER STATUS${NC}"
    
    echo "Checking Klipper service status..."
    sudo systemctl status $KLIPPER_SERVICE_NAME
    
    echo ""
    read -p "Press Enter to continue..." dummy
    diagnostics_menu
}

view_klipper_logs() {
    show_header
    echo -e "${BLUE}KLIPPER LOGS${NC}"
    
    echo "Last 50 log entries from Klipper:"
    sudo journalctl -u $KLIPPER_SERVICE_NAME -n 50 --no-pager
    
    echo ""
    echo "1) View more log entries"
    echo "2) View only errors"
    echo "0) Back to diagnostics menu"
    
    read -p "Select an option: " log_choice
    
    case $log_choice in
        1)
            echo "Last 200 log entries from Klipper:"
            sudo journalctl -u $KLIPPER_SERVICE_NAME -n 200 --no-pager
            ;;
        2)
            echo "Errors from Klipper log:"
            sudo journalctl -u $KLIPPER_SERVICE_NAME -n 500 --no-pager | grep -i error
            ;;
        0)
            diagnostics_menu
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..." dummy
    diagnostics_menu
}

verify_configuration() {
    show_header
    echo -e "${BLUE}CONFIGURATION VERIFICATION${NC}"
    
    local errors=0
    
    # Check that macros.cfg exists
    if [ ! -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
        echo -e "${RED}[ERROR] macros.cfg not found${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}[OK] macros.cfg exists${NC}"
    fi
    
    # Check that printer.cfg includes macros.cfg
    if [ -f "${KLIPPER_CONFIG}/printer.cfg" ]; then
        if ! grep -q '^\[include macros\.cfg\]' "${KLIPPER_CONFIG}/printer.cfg"; then
            echo -e "${YELLOW}[WARNING] printer.cfg does not include macros.cfg${NC}"
            errors=$((errors+1))
        else
            echo -e "${GREEN}[OK] printer.cfg includes macros.cfg${NC}"
        fi
    else
        echo -e "${RED}[ERROR] printer.cfg not found${NC}"
        errors=$((errors+1))
    fi
    
    # Check Klipper service status
    if ! systemctl is-active --quiet $KLIPPER_SERVICE_NAME; then
        echo -e "${RED}[ERROR] Klipper service not running${NC}"
        errors=$((errors+1))
    else
        echo -e "${GREEN}[OK] Klipper service is running${NC}"
    fi
    
    echo ""
    echo "Checking for required includes..."
    
    # Check for mandatory includes
    if [ -f "${KLIPPER_CONFIG}/printer.cfg" ]; then
        for include in "macros.cfg"; do
            if grep -q "^\[include $include\]" "${KLIPPER_CONFIG}/printer.cfg"; then
                echo -e "${GREEN}[OK] Found include for $include${NC}"
            else
                echo -e "${YELLOW}[WARNING] Missing include for $include${NC}"
            fi
        done
    fi
    
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] All checks passed! Configuration appears to be working correctly.${NC}"
    else
        echo -e "${YELLOW}[WARNING] Found $errors potential issue(s) with your installation.${NC}"
    fi
    
    read -p "Press Enter to continue..." dummy
    diagnostics_menu
}

run_full_diagnostics() {
    show_header
    echo -e "${BLUE}FULL SYSTEM DIAGNOSTICS${NC}"
    
    echo "This will perform a comprehensive check of your system."
    echo "It may take a few moments to complete."
    echo ""
    read -p "Press Enter to start diagnostics..." dummy
    
    echo -e "\n${CYAN}SYSTEM INFORMATION${NC}"
    echo "----------------------"
    uname -a
    
    echo -e "\n${CYAN}DISK SPACE${NC}"
    echo "-----------"
    df -h /
    
    echo -e "\n${CYAN}MEMORY USAGE${NC}"
    echo "------------"
    free -h
    
    echo -e "\n${CYAN}KLIPPER SERVICE STATUS${NC}"
    echo "---------------------"
    systemctl status $KLIPPER_SERVICE_NAME --no-pager
    
    echo -e "\n${CYAN}CONFIGURATION FILES${NC}"
    echo "------------------"
    find "$KLIPPER_CONFIG" -maxdepth 1 -name "*.cfg" | sort
    
    echo -e "\n${CYAN}CONFIG INCLUDES${NC}"
    echo "---------------"
    if [ -f "${KLIPPER_CONFIG}/printer.cfg" ]; then
        grep "^\[include" "${KLIPPER_CONFIG}/printer.cfg"
    else
        echo "printer.cfg not found"
    fi
    
    echo -e "\n${CYAN}AVAILABLE MACROS${NC}"
    echo "----------------"
    if [ -f "${KLIPPER_CONFIG}/macros.cfg" ]; then
        grep -n "\[gcode_macro" "${KLIPPER_CONFIG}/macros.cfg" | cut -d[ -f2 | cut -d] -f1 | sort
    else
        echo "macros.cfg not found"
    fi
    
    echo -e "\n${CYAN}RECENT ERRORS${NC}"
    echo "-------------"
    sudo journalctl -u $KLIPPER_SERVICE_NAME -n 50 --no-pager | grep -i error
    
    echo -e "\n${GREEN}Diagnostics complete!${NC}"
    read -p "Press Enter to continue..." dummy
    diagnostics_menu
}

# PID Tuning Assistant
pid_tuning_assistant() {
    show_header
    echo -e "${BLUE}PID TUNING ASSISTANT${NC}"
    echo "This will help you tune your hotend PID values."
    echo ""
    
    read -p "Enter target temperature for PID tuning (default 200): " pid_temp
    pid_temp=${pid_temp:-200}
    
    echo -e "${YELLOW}Starting PID calibration at ${pid_temp}°C...${NC}"
    echo "This process will take several minutes. Please wait..."
    echo "The hotend will heat up and oscillate around the target temperature."
    echo ""
    echo "Run this command in your printer console:"
    echo -e "${CYAN}PID_CALIBRATE HEATER=extruder TARGET=${pid_temp}${NC}"
    echo ""
    echo "After completion, run:"
    echo -e "${CYAN}SAVE_CONFIG${NC}"
    
    read -p "Press Enter to continue..." dummy
    additional_features_menu
}

# E-Steps Calibration Helper
esteps_calibration_helper() {
    show_header
    echo -e "${BLUE}E-STEPS CALIBRATION HELPER${NC}"
    echo "This will help you calibrate your extruder steps per mm."
    echo ""
    
    echo -e "${CYAN}=== E-Steps Calibration Process ===${NC}"
    echo "1. Heat your hotend to printing temperature"
    echo "2. Mark filament 120mm from extruder entry"
    echo "3. Extrude exactly 100mm of filament"
    echo "4. Measure remaining distance to mark"
    echo "5. Calculate new e-steps value"
    echo ""
    
    echo "Commands to run in printer console:"
    echo -e "${CYAN}M104 S200${NC}  # Heat hotend"
    echo -e "${CYAN}M109 S200${NC}  # Wait for temperature"
    echo -e "${CYAN}G91${NC}       # Relative positioning"
    echo -e "${CYAN}G1 E100 F100${NC}  # Extrude 100mm slowly"
    echo ""
    
    read -p "Enter measured distance remaining to mark (mm): " remaining_distance
    if [[ "$remaining_distance" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        actual_extruded=$(echo "120 - $remaining_distance" | bc -l)
        read -p "Enter current e-steps value (from M503 command): " current_esteps
        
        if [[ "$current_esteps" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            new_esteps=$(echo "scale=2; $current_esteps * 100 / $actual_extruded" | bc -l)
            echo ""
            echo -e "${GREEN}=== Calibration Results ===${NC}"
            echo "Actual filament extruded: ${actual_extruded}mm"
            echo "Current e-steps: ${current_esteps}"
            echo "New e-steps: ${new_esteps}"
            echo ""
            echo "Commands to set new e-steps:"
            echo -e "${CYAN}M92 E${new_esteps}${NC}"
            echo -e "${CYAN}M500${NC}  # Save to EEPROM"
        fi
    fi
    
    read -p "Press Enter to continue..." dummy
    additional_features_menu
}

# MAIN EXECUTION
verify_ready

if [ $UNINSTALL ]; then
    check_klipper
    create_backup_dir
    stop_klipper
    get_user_macro_files
    restore_backup
    start_klipper
    echo -e "${GREEN}Uninstallation complete! Original configuration has been restored.${NC}"
elif [ $MENU_MODE -eq 1 ]; then
    # Interactive menu mode (default)
    show_main_menu
else
    # Linear installation flow
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
    echo -e "${GREEN}Installation complete! Please check your printer's web interface to verify the changes.${NC}"

    echo ""
    echo "Would you like to install A Better Print_Start Macro?"
    echo "Note: This will also install KAMP, which needs to be configured per KAMP documentation."
    echo "More information can be found at: https://github.com/ss1gohan13/A-better-print_start-macro"
    read -p "Install Print_Start macro and KAMP? (y/N): " install_print_start
    
    if [[ "$install_print_start" =~ ^[Yy]$ ]]; then
        echo "Installing KAMP and A Better Print_Start Macro..."
        # install_kamp
        curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-better-print_start-macro/main/install_start_print.sh | bash
        add_max_extrude_cross_section_to_extruder
        add_firmware_retraction_to_printer_cfg
        echo ""
        echo -e "${GREEN}Print_Start macro and KAMP have been installed!${NC}"
        echo "Please visit https://github.com/ss1gohan13/A-better-print_start-macro for instructions on configuring your slicer settings."
        
        # Add numpy installation for ADXL resonance measurements
        echo ""
        echo "Would you like to install numpy for ADXL resonance measurements?"
        echo "This is recommended if you plan to use input shaping with an ADXL345 accelerometer."
        read -p "Install numpy? (y/N): " install_numpy
        
        if [[ "$install_numpy" =~ ^[Yy]$ ]]; then
            install_numpy_for_adxl
        fi
    fi

    echo ""
    echo "Would you like to install A Better End Print Macro?"
    echo "Note: This requires additional changes to your slicer settings."
    echo "More information can be found at: https://github.com/ss1gohan13/A-Better-End-Print-Macro"
    read -p "Install End Print macro? (y/N): " install_end_print
    
    if [[ "$install_end_print" =~ ^[Yy]$ ]]; then
        echo "Installing A Better End Print Macro..."
        cd ~
        curl -sSL https://raw.githubusercontent.com/ss1gohan13/A-Better-End-Print-Macro/main/direct_install.sh | bash
        echo ""
        echo -e "${GREEN}End Print macro has been installed!${NC}"
        echo "Please visit https://github.com/ss1gohan13/A-Better-End-Print-Macro for instructions on configuring your slicer settings."
    fi
    
    echo ""
    echo -e "${CYAN}TIP: If you prefer the menu-driven interface, just run this script without the -l flag!${NC}"
fi
