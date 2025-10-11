#!/bin/bash

# Stepper configuration utility functions for KANT

# Configure stepper pins
configure_stepper_pins() {
    print_header
    echo -e "${YELLOW}Stepper Pin Configuration${NC}"
    echo ""
    
    local printer_cfg="${KLIPPER_CONFIG_DIR}/printer.cfg"
    
    if [ ! -f "$printer_cfg" ]; then
        print_error "printer.cfg not found"
        print_info "Please create a printer.cfg first or configure MCU IDs"
        pause
        return
    fi
    
    echo "Select stepper to configure:"
    echo ""
    echo "  1) X Stepper"
    echo "  2) Y Stepper"
    echo "  3) Z Stepper"
    echo "  4) Z1 Stepper (dual Z)"
    echo "  5) Z2 Stepper (triple Z)"
    echo "  6) Z3 Stepper (quad Z)"
    echo "  7) Extruder"
    echo "  8) Extruder1 (dual extruder)"
    echo "  9) Back to Main Menu"
    echo ""
    echo -n -e "${GREEN}Enter your choice [1-9]: ${NC}"
    read stepper_choice
    
    case $stepper_choice in
        1) configure_stepper "stepper_x" "X" ;;
        2) configure_stepper "stepper_y" "Y" ;;
        3) configure_stepper "stepper_z" "Z" ;;
        4) configure_stepper "stepper_z1" "Z1" ;;
        5) configure_stepper "stepper_z2" "Z2" ;;
        6) configure_stepper "stepper_z3" "Z3" ;;
        7) configure_stepper "extruder" "Extruder" ;;
        8) configure_stepper "extruder1" "Extruder1" ;;
        9) return ;;
        *) 
            print_error "Invalid choice"
            pause
            configure_stepper_pins
            ;;
    esac
}

# Configure individual stepper
configure_stepper() {
    local stepper_name="$1"
    local display_name="$2"
    local printer_cfg="${KLIPPER_CONFIG_DIR}/printer.cfg"
    
    echo ""
    echo -e "${CYAN}Configuring $display_name Stepper${NC}"
    echo ""
    
    # Backup config
    backup_file "$printer_cfg"
    
    # Get pin configuration
    local step_pin=$(get_input "Enter step_pin (e.g., 'PA0' or 'mcu:PA0')" "")
    if [ -z "$step_pin" ]; then
        print_warning "Configuration cancelled"
        pause
        return
    fi
    
    local dir_pin=$(get_input "Enter dir_pin (e.g., 'PA1' or '!PA1' for inverted)" "")
    local enable_pin=$(get_input "Enter enable_pin (e.g., '!PA2')" "")
    local endstop_pin=$(get_input "Enter endstop_pin (optional, e.g., 'PA3' or '^PA3')" "")
    
    # Stepper-specific parameters
    if [[ "$stepper_name" == "extruder"* ]]; then
        local rotation_distance=$(get_input "Enter rotation_distance (mm)" "33.5")
        local nozzle_diameter=$(get_input "Enter nozzle_diameter (mm)" "0.4")
        local filament_diameter=$(get_input "Enter filament_diameter (mm)" "1.75")
        local heater_pin=$(get_input "Enter heater_pin" "")
        local sensor_type=$(get_input "Enter sensor_type" "EPCOS 100K B57560G104F")
        local sensor_pin=$(get_input "Enter sensor_pin" "")
        local min_temp=$(get_input "Enter min_temp (°C)" "0")
        local max_temp=$(get_input "Enter max_temp (°C)" "300")
    else
        local microsteps=$(get_input "Enter microsteps" "16")
        local rotation_distance=$(get_input "Enter rotation_distance (mm)" "40")
        local position_min=$(get_input "Enter position_min (mm)" "0")
        local position_max=$(get_input "Enter position_max (mm)" "200")
    fi
    
    # Check if section exists
    if grep -q "^\[${stepper_name}\]" "$printer_cfg"; then
        if ! confirm "Section [$stepper_name] already exists. Overwrite?"; then
            pause
            return
        fi
        
        # Remove existing section
        sed -i "/^\[${stepper_name}\]/,/^$/d" "$printer_cfg"
    fi
    
    # Add new stepper section
    echo "" >> "$printer_cfg"
    echo "[${stepper_name}]" >> "$printer_cfg"
    echo "step_pin: $step_pin" >> "$printer_cfg"
    
    if [ -n "$dir_pin" ]; then
        echo "dir_pin: $dir_pin" >> "$printer_cfg"
    fi
    
    if [ -n "$enable_pin" ]; then
        echo "enable_pin: $enable_pin" >> "$printer_cfg"
    fi
    
    if [[ "$stepper_name" == "extruder"* ]]; then
        # Extruder configuration
        echo "rotation_distance: $rotation_distance" >> "$printer_cfg"
        echo "nozzle_diameter: $nozzle_diameter" >> "$printer_cfg"
        echo "filament_diameter: $filament_diameter" >> "$printer_cfg"
        
        if [ -n "$heater_pin" ]; then
            echo "heater_pin: $heater_pin" >> "$printer_cfg"
        fi
        
        if [ -n "$sensor_type" ]; then
            echo "sensor_type: $sensor_type" >> "$printer_cfg"
        fi
        
        if [ -n "$sensor_pin" ]; then
            echo "sensor_pin: $sensor_pin" >> "$printer_cfg"
        fi
        
        echo "min_temp: $min_temp" >> "$printer_cfg"
        echo "max_temp: $max_temp" >> "$printer_cfg"
    else
        # Regular stepper configuration
        echo "microsteps: $microsteps" >> "$printer_cfg"
        echo "rotation_distance: $rotation_distance" >> "$printer_cfg"
        
        if [ -n "$endstop_pin" ]; then
            echo "endstop_pin: $endstop_pin" >> "$printer_cfg"
            echo "position_min: $position_min" >> "$printer_cfg"
            echo "position_max: $position_max" >> "$printer_cfg"
        fi
    fi
    
    echo "" >> "$printer_cfg"
    
    print_success "Configured $display_name stepper"
    
    if confirm "Configure another stepper?"; then
        configure_stepper_pins
    else
        pause
    fi
}
