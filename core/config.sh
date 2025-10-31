#!/bin/bash
# KANT Core Configuration
# Contains all configuration variables and constants

# Script Info
VERSION="1.5.0"
REPO_URL="https://github.com/ss1gohan13/KANT"

# Default paths
KLIPPER_CONFIG="${HOME}/printer_data/config"
KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME=klipper
BACKUP_DIR="${KLIPPER_CONFIG}/backup"
CURRENT_DATE=$(date +%Y%m%d_%H%M%S)

# Default to menu mode - menu will show by default
MENU_MODE=1

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Declare global array for backup files
declare -a BACKUP_FILES

# Declare global array for macro files
declare -a MACRO_FILES
