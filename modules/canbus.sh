#!/bin/bash
# KANT CAN Bus Module
# Handles CAN bus configuration and setup

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
        canbus_menu
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
            3) canbus_menu ;;
            *) canbus_menu ;;
        esac
        
    elif [[ "$status" == "failed" ]]; then
        echo -e "${RED}SETUP FAILED${NC}"
        echo ""
        echo "The automated setup encountered an error."
        echo "Please check the error messages above and try again."
        echo ""
        read -p "Press Enter to return to menu..." dummy
        canbus_menu
        
    elif [[ "$status" == "aborted" ]]; then
        echo -e "${YELLOW}SETUP ABORTED${NC}"
        echo ""
        echo "Setup was cancelled due to compatibility concerns."
        echo "Consider updating your system before proceeding."
        echo ""
        read -p "Press Enter to return to menu..." dummy
        canbus_menu
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