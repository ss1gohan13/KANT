#!/bin/bash
# KANT Calibration Module
# Handles calibration helper functions

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