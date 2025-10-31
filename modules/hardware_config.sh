#!/bin/bash
# KANT Hardware Configuration Module
# Handles hardware configuration utilities

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