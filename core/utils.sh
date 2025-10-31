#!/bin/bash
# KANT Core Utilities
# Common utility functions

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

# Function to check for updates (for Moonraker integration)
check_for_updates() {
    echo "Checking for KANT updates..."
    echo "Current version: $VERSION"
    echo "Repository: $REPO_URL"
}

# Show header function
show_header() {
    clear
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${CYAN}    Klipper Assistant Navigation and Troubleshooting (KANT) v${VERSION}${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${YELLOW}Author: ss1gohan13${NC}"
    echo -e "${YELLOW}Last Updated: 2025-10-12${NC}"
    echo ""
}

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