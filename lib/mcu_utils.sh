#!/bin/bash

# MCU utility functions for KANT

# Check and insert MCU IDs
check_insert_mcu_ids() {
    print_header
    echo -e "${YELLOW}MCU ID Management${NC}"
    echo ""
    
    print_info "Scanning for connected MCU devices..."
    echo ""
    
    # Check for serial devices
    if ls /dev/serial/by-id/* >/dev/null 2>&1; then
        echo -e "${GREEN}Found serial devices:${NC}"
        echo ""
        local count=1
        declare -a devices
        
        for device in /dev/serial/by-id/*; do
            echo "  $count) $(basename "$device")"
            devices[$count]="$device"
            ((count++))
        done
        
        echo ""
        echo -n -e "${GREEN}Select MCU to configure (1-$((count-1)), or 0 to skip): ${NC}"
        read mcu_choice
        
        if [ "$mcu_choice" -gt 0 ] && [ "$mcu_choice" -lt "$count" ]; then
            configure_mcu_in_config "${devices[$mcu_choice]}"
        fi
    else
        print_warning "No serial devices found in /dev/serial/by-id/"
        echo ""
        print_info "Make sure your MCU is connected via USB"
    fi
    
    pause
}

# Configure MCU in printer.cfg
configure_mcu_in_config() {
    local device_path="$1"
    local device_id=$(basename "$device_path")
    
    echo ""
    print_info "Selected device: $device_id"
    
    local mcu_name=$(get_input "Enter MCU name (e.g., 'mcu', 'mcu_toolhead')" "mcu")
    
    # Check if printer.cfg exists
    local printer_cfg="${KLIPPER_CONFIG_DIR}/printer.cfg"
    
    if [ ! -f "$printer_cfg" ]; then
        if confirm "printer.cfg not found. Create new one?"; then
            create_basic_printer_cfg "$printer_cfg"
        else
            return
        fi
    fi
    
    # Backup existing config
    backup_file "$printer_cfg"
    
    # Check if MCU section already exists
    if grep -q "^\[mcu ${mcu_name}\]" "$printer_cfg" || grep -q "^\[mcu\]" "$printer_cfg" && [ "$mcu_name" = "mcu" ]; then
        if confirm "MCU section [$mcu_name] already exists. Update it?"; then
            # Update existing MCU section
            if [ "$mcu_name" = "mcu" ]; then
                sed -i "/^\[mcu\]/,/^\[/ s|^serial:.*|serial: $device_path|" "$printer_cfg"
            else
                sed -i "/^\[mcu ${mcu_name}\]/,/^\[/ s|^serial:.*|serial: $device_path|" "$printer_cfg"
            fi
            print_success "Updated MCU configuration for [$mcu_name]"
        fi
    else
        # Add new MCU section
        if [ "$mcu_name" = "mcu" ]; then
            echo "" >> "$printer_cfg"
            echo "[mcu]" >> "$printer_cfg"
        else
            echo "" >> "$printer_cfg"
            echo "[mcu ${mcu_name}]" >> "$printer_cfg"
        fi
        echo "serial: $device_path" >> "$printer_cfg"
        echo "" >> "$printer_cfg"
        
        print_success "Added MCU configuration for [$mcu_name]"
    fi
    
    echo ""
    print_info "MCU ID: $device_id"
    print_info "Path: $device_path"
}

# Create a basic printer.cfg
create_basic_printer_cfg() {
    local cfg_path="$1"
    
    cat > "$cfg_path" << 'EOF'
# This file contains common pin mappings for 3D printers.
# To use this config, during "make menuconfig" select the appropriate
# micro-controller and configure for your specific hardware.

# See docs/Config_Reference.md for a description of parameters.

EOF
    
    print_success "Created basic printer.cfg"
}

# Check for CAN IDs
check_can_ids() {
    print_header
    echo -e "${YELLOW}CAN Bus ID Scanner${NC}"
    echo ""
    
    # Check if ip command is available
    if ! command_exists ip; then
        print_error "Required tool 'ip' not found"
        print_info "Install with: sudo apt-get install iproute2"
        pause
        return
    fi
    
    # Check for CAN interfaces
    print_info "Checking for CAN interfaces..."
    echo ""
    
    local can_interfaces=$(ip link show | grep -o 'can[0-9]*' | sort -u)
    
    if [ -z "$can_interfaces" ]; then
        print_warning "No CAN interfaces found"
        echo ""
        print_info "To set up CAN bus interface, you need to:"
        echo "  1. Load the CAN kernel modules"
        echo "  2. Configure your CAN interface (typically can0)"
        echo "  3. Set the appropriate bitrate"
        echo ""
        print_info "Example commands:"
        echo "  sudo modprobe can"
        echo "  sudo modprobe can_raw"
        echo "  sudo ip link set can0 type can bitrate 500000"
        echo "  sudo ip link set up can0"
        pause
        return
    fi
    
    echo -e "${GREEN}Found CAN interfaces:${NC}"
    for iface in $can_interfaces; do
        echo "  • $iface"
        
        # Check interface status
        local status=$(ip link show "$iface" | grep -o 'state [A-Z]*' | awk '{print $2}')
        if [ "$status" = "UP" ]; then
            print_success "$iface is UP"
        else
            print_warning "$iface is DOWN"
        fi
    done
    
    echo ""
    echo -n -e "${GREEN}Select interface to query (or press Enter to skip): ${NC}"
    read selected_iface
    
    if [ -n "$selected_iface" ]; then
        query_can_interface "$selected_iface"
    fi
    
    pause
}

# Query CAN interface for devices
query_can_interface() {
    local iface="$1"
    
    echo ""
    print_info "Querying $iface for devices..."
    echo ""
    
    # Check if Klipper's canbus_query is available
    if [ -f "${HOME}/klipper/scripts/canbus_query.py" ]; then
        print_info "Using Klipper's canbus_query.py..."
        python3 "${HOME}/klipper/scripts/canbus_query.py" "$iface" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo ""
            if confirm "Would you like to add a CAN MCU to your configuration?"; then
                add_can_mcu_to_config
            fi
        else
            print_error "Failed to query CAN bus"
            print_info "Make sure Klipper is installed and the CAN interface is up"
        fi
    else
        print_warning "Klipper's canbus_query.py not found"
        print_info "You can manually query CAN devices with:"
        echo "  ~/klipper/scripts/canbus_query.py $iface"
        echo ""
        
        # Offer to add CAN MCU manually
        if confirm "Would you like to manually add a CAN MCU to your configuration?"; then
            add_can_mcu_to_config
        fi
    fi
}

# Add CAN MCU to configuration
add_can_mcu_to_config() {
    echo ""
    local mcu_name=$(get_input "Enter MCU name (e.g., 'mcu_can', 'toolhead')" "mcu_can")
    local can_uuid=$(get_input "Enter CAN UUID (from canbus_query)" "")
    
    if [ -z "$can_uuid" ]; then
        print_error "CAN UUID is required"
        return
    fi
    
    local can_interface=$(get_input "Enter CAN interface" "can0")
    
    local printer_cfg="${KLIPPER_CONFIG_DIR}/printer.cfg"
    
    if [ ! -f "$printer_cfg" ]; then
        print_error "printer.cfg not found"
        return
    fi
    
    # Backup existing config
    backup_file "$printer_cfg"
    
    # Add CAN MCU section
    if [ "$mcu_name" = "mcu" ]; then
        echo "" >> "$printer_cfg"
        echo "[mcu]" >> "$printer_cfg"
    else
        echo "" >> "$printer_cfg"
        echo "[mcu ${mcu_name}]" >> "$printer_cfg"
    fi
    echo "canbus_uuid: $can_uuid" >> "$printer_cfg"
    echo "canbus_interface: $can_interface" >> "$printer_cfg"
    echo "" >> "$printer_cfg"
    
    print_success "Added CAN MCU configuration for [$mcu_name]"
    print_info "UUID: $can_uuid"
    print_info "Interface: $can_interface"
}
