#!/bin/bash

# Macro utility functions for KANT

# Install baseline macros
install_baseline_macros() {
    print_header
    echo -e "${YELLOW}Install Baseline Macros${NC}"
    echo ""
    
    ensure_directory "${MACROS_DIR}"
    
    echo "This will install the following macros:"
    echo ""
    echo "  • START_PRINT - Customizable start print macro"
    echo "  • END_PRINT - End print macro"
    echo "  • PAUSE - Pause print macro"
    echo "  • RESUME - Resume print macro"
    echo "  • CANCEL_PRINT - Cancel print macro"
    echo "  • LOAD_FILAMENT - Filament loading macro"
    echo "  • UNLOAD_FILAMENT - Filament unloading macro"
    echo ""
    
    if ! confirm "Proceed with installation?"; then
        return
    fi
    
    # Create macro files
    create_start_print_macro
    create_end_print_macro
    create_pause_resume_macros
    create_filament_macros
    
    # Update printer.cfg to include macros
    update_printer_cfg_for_macros
    
    print_success "Baseline macros installed successfully"
    echo ""
    print_info "Macros installed in: ${MACROS_DIR}"
    print_info "Make sure printer.cfg includes: [include macros/*.cfg]"
    
    pause
}

# Configure start print macro
configure_start_print_macro() {
    print_header
    echo -e "${YELLOW}Configure Start Print Macro${NC}"
    echo ""
    
    ensure_directory "${MACROS_DIR}"
    
    local start_macro="${MACROS_DIR}/start_print.cfg"
    
    if [ -f "$start_macro" ]; then
        backup_file "$start_macro"
    fi
    
    echo "Configure start print behavior:"
    echo ""
    
    local bed_temp=$(get_input "Default bed temperature (°C)" "60")
    local extruder_temp=$(get_input "Default extruder temperature (°C)" "200")
    local preheat_extruder=$(get_input "Preheat extruder during bed heating? (yes/no)" "yes")
    local home_before_start=$(get_input "Home all axes before start? (yes/no)" "yes")
    local bed_mesh=$(get_input "Load bed mesh? (yes/no)" "yes")
    local purge_line=$(get_input "Draw purge line? (yes/no)" "yes")
    
    create_start_print_macro "$bed_temp" "$extruder_temp" "$preheat_extruder" "$home_before_start" "$bed_mesh" "$purge_line"
    
    print_success "Start print macro configured"
    pause
}

# Configure end print macro
configure_end_print_macro() {
    print_header
    echo -e "${YELLOW}Configure End Print Macro${NC}"
    echo ""
    
    ensure_directory "${MACROS_DIR}"
    
    local end_macro="${MACROS_DIR}/end_print.cfg"
    
    if [ -f "$end_macro" ]; then
        backup_file "$end_macro"
    fi
    
    echo "Configure end print behavior:"
    echo ""
    
    local retract_distance=$(get_input "Retraction distance (mm)" "2")
    local z_lift=$(get_input "Z-axis lift after print (mm)" "10")
    local park_x=$(get_input "Park X position" "0")
    local park_y=$(get_input "Park Y position" "200")
    local disable_motors=$(get_input "Disable motors after print? (yes/no)" "no")
    
    create_end_print_macro "$retract_distance" "$z_lift" "$park_x" "$park_y" "$disable_motors"
    
    print_success "End print macro configured"
    pause
}

# Create start print macro file
create_start_print_macro() {
    local bed_temp="${1:-60}"
    local extruder_temp="${2:-200}"
    local preheat="${3:-yes}"
    local home="${4:-yes}"
    local mesh="${5:-yes}"
    local purge="${6:-yes}"
    
    local start_macro="${MACROS_DIR}/start_print.cfg"
    
    cat > "$start_macro" << EOF
# START_PRINT macro
# Usage: START_PRINT BED_TEMP=<temp> EXTRUDER_TEMP=<temp>

[gcode_macro START_PRINT]
gcode:
    {% set BED_TEMP = params.BED_TEMP|default(${bed_temp})|float %}
    {% set EXTRUDER_TEMP = params.EXTRUDER_TEMP|default(${extruder_temp})|float %}
    
    # Start bed heating
    M140 S{BED_TEMP}
    
EOF

    if [ "$preheat" = "yes" ]; then
        cat >> "$start_macro" << EOF
    # Preheat extruder
    M104 S150
    
EOF
    fi

    if [ "$home" = "yes" ]; then
        cat >> "$start_macro" << EOF
    # Home all axes
    G28
    
EOF
    fi

    cat >> "$start_macro" << EOF
    # Wait for bed to reach temperature
    M190 S{BED_TEMP}
    
EOF

    if [ "$mesh" = "yes" ]; then
        cat >> "$start_macro" << EOF
    # Load bed mesh (if available)
    BED_MESH_PROFILE LOAD=default
    
EOF
    fi

    cat >> "$start_macro" << EOF
    # Set and wait for extruder temperature
    M104 S{EXTRUDER_TEMP}
    M109 S{EXTRUDER_TEMP}
    
EOF

    if [ "$purge" = "yes" ]; then
        cat >> "$start_macro" << EOF
    # Prime line
    G1 Z2.0 F3000
    G1 X5 Y20 Z0.3 F5000.0
    G1 X5 Y200.0 Z0.3 F1500.0 E15
    G1 X5.3 Y200.0 Z0.3 F5000.0
    G1 X5.3 Y20 Z0.3 F1500.0 E30
    G1 Z2.0 F3000
    G92 E0
    
EOF
    fi

    cat >> "$start_macro" << EOF
    # Ready to print
    M117 Printing...
EOF

    print_success "Created start_print.cfg"
}

# Create end print macro file
create_end_print_macro() {
    local retract="${1:-2}"
    local z_lift="${2:-10}"
    local park_x="${3:-0}"
    local park_y="${4:-200}"
    local disable_motors="${5:-no}"
    
    local end_macro="${MACROS_DIR}/end_print.cfg"
    
    cat > "$end_macro" << EOF
# END_PRINT macro

[gcode_macro END_PRINT]
gcode:
    # Retract filament
    G91
    G1 E-${retract} F2700
    G1 E-${retract} Z0.2 F2400
    
    # Present print
    G1 Z${z_lift} F3000
    G90
    G1 X${park_x} Y${park_y} F3000
    
    # Turn off heaters
    M104 S0
    M140 S0
    
    # Turn off fan
    M106 S0
    
EOF

    if [ "$disable_motors" = "yes" ]; then
        cat >> "$end_macro" << EOF
    # Disable steppers
    M84
    
EOF
    fi

    cat >> "$end_macro" << EOF
    M117 Print complete!
EOF

    print_success "Created end_print.cfg"
}

# Create pause/resume/cancel macros
create_pause_resume_macros() {
    local macro_file="${MACROS_DIR}/pause_resume.cfg"
    
    cat > "$macro_file" << 'EOF'
# Pause, Resume, and Cancel macros

[gcode_macro PAUSE]
description: Pause the current print
rename_existing: PAUSE_BASE
gcode:
    SAVE_GCODE_STATE NAME=PAUSE_state
    PAUSE_BASE
    G91
    G1 E-2 F2700
    G1 Z10 F900
    G90
    G1 X10 Y10 F5000

[gcode_macro RESUME]
description: Resume the paused print
rename_existing: RESUME_BASE
gcode:
    G91
    G1 E2 F2700
    G90
    RESTORE_GCODE_STATE NAME=PAUSE_state MOVE=1
    RESUME_BASE

[gcode_macro CANCEL_PRINT]
description: Cancel the current print
rename_existing: CANCEL_PRINT_BASE
gcode:
    TURN_OFF_HEATERS
    CANCEL_PRINT_BASE
    G91
    G1 E-2 F2700
    G1 Z10 F900
    G90
    G1 X10 Y200 F5000
    M106 S0
    M84
EOF

    print_success "Created pause_resume.cfg"
}

# Create filament loading/unloading macros
create_filament_macros() {
    local macro_file="${MACROS_DIR}/filament.cfg"
    
    cat > "$macro_file" << 'EOF'
# Filament loading and unloading macros

[gcode_macro LOAD_FILAMENT]
description: Load filament into extruder
gcode:
    {% set EXTRUDER_TEMP = params.TEMP|default(200)|float %}
    
    M117 Heating extruder...
    M109 S{EXTRUDER_TEMP}
    
    M117 Loading filament...
    G91
    G1 E50 F300
    G1 E50 F150
    G90
    M117 Filament loaded

[gcode_macro UNLOAD_FILAMENT]
description: Unload filament from extruder
gcode:
    {% set EXTRUDER_TEMP = params.TEMP|default(200)|float %}
    
    M117 Heating extruder...
    M109 S{EXTRUDER_TEMP}
    
    M117 Unloading filament...
    G91
    G1 E10 F300
    G1 E-50 F300
    G1 E-50 F1000
    G90
    M117 Filament unloaded
EOF

    print_success "Created filament.cfg"
}

# Update printer.cfg to include macros
update_printer_cfg_for_macros() {
    local printer_cfg="${KLIPPER_CONFIG_DIR}/printer.cfg"
    
    if [ ! -f "$printer_cfg" ]; then
        return
    fi
    
    # Check if include already exists
    if ! grep -q "^\[include macros/\*\.cfg\]" "$printer_cfg" && ! grep -q "^\[include macros/.*\.cfg\]" "$printer_cfg"; then
        backup_file "$printer_cfg"
        
        # Add include at the beginning of the file (after MCU sections if they exist)
        if grep -q "^\[mcu" "$printer_cfg"; then
            # Add after last MCU section
            sed -i '/^\[mcu.*\]/,/^$/a\\n[include macros/*.cfg]\n' "$printer_cfg"
        else
            # Add at the beginning
            sed -i '1i\[include macros/*.cfg]\n' "$printer_cfg"
        fi
        
        print_success "Added macro includes to printer.cfg"
    fi
}
