#!/bin/bash
# Eddy NG Plugin
# Handles configuration of Eddy NG features

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