#!/bin/bash

# Utility functions for KANT

# Print success message
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Print info message
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Pause and wait for user input
pause() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Confirm action
confirm() {
    local message="$1"
    echo -n -e "${YELLOW}$message [y/N]: ${NC}"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_name="${BACKUP_DIR}/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        print_success "Backed up to: $backup_name"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        echo -n -e "${GREEN}$prompt [$default]: ${NC}"
    else
        echo -n -e "${GREEN}$prompt: ${NC}"
    fi
    
    read -r input
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# Backup configuration
backup_configuration() {
    print_header
    echo -e "${YELLOW}Backup Configuration${NC}"
    echo ""
    
    if [ ! -d "${KLIPPER_CONFIG_DIR}" ]; then
        print_error "Klipper configuration directory not found"
        pause
        return
    fi
    
    local backup_name="config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    print_info "Creating backup of ${KLIPPER_CONFIG_DIR}..."
    
    cd "${KLIPPER_CONFIG_DIR}/.."
    tar -czf "${backup_path}" "config" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Backup created: ${backup_path}"
        
        # Get backup size
        local size=$(du -h "${backup_path}" | cut -f1)
        print_info "Backup size: ${size}"
    else
        print_error "Failed to create backup"
    fi
    
    pause
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}
