#!/bin/bash
# KANT Plugins Module
# Handles installation of plugin extensions

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