#!/bin/bash
# Numpy ADXL Plugin
# Handles installation of numpy for ADXL345 resonance measurements

install_numpy_for_adxl() {
    show_header
    echo -e "${BLUE}INSTALL NUMPY FOR ADXL RESONANCE MEASUREMENTS${NC}"
    echo ""
    echo "This will install numpy and dependencies in the Klipper Python environment."
    echo "Numpy is required for processing ADXL345 accelerometer data for input shaping."
    echo "Reference: https://www.klipper3d.org/Measuring_Resonances.html"
    echo ""
    
    # Check if klippy-env exists
    if [ ! -d "${HOME}/klippy-env" ]; then
        echo -e "${RED}Error: Klipper Python environment not found at ~/klippy-env${NC}"
        echo "Please make sure Klipper is properly installed."
        return 1
    fi
    
    echo -e "${CYAN}Step 1: Updating package lists...${NC}"
    if sudo apt update; then
        echo -e "${GREEN}✓ Package lists updated${NC}"
    else
        echo -e "${RED}✗ Failed to update package lists${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Step 2: Installing system dependencies...${NC}"
    echo "Installing: python3-numpy python3-matplotlib libatlas-base-dev libopenblas-dev"
    
    if sudo apt install -y python3-numpy python3-matplotlib libatlas-base-dev libopenblas-dev; then
        echo -e "${GREEN}✓ System dependencies installed${NC}"
    else
        echo -e "${RED}✗ Failed to install system dependencies${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Step 3: Installing numpy in Klipper environment...${NC}"
    echo "This may take several minutes. Please wait..."
    
    if ${HOME}/klippy-env/bin/pip install -v "numpy<1.26"; then
        echo -e "${GREEN}✓ Numpy installed in klippy-env${NC}"
    else
        echo -e "${RED}✗ Failed to install numpy in klippy-env${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Step 4: Verifying installation...${NC}"
    
    # Verify numpy installation
    if ${HOME}/klippy-env/bin/pip list | grep -q numpy; then
        local numpy_version=$(${HOME}/klippy-env/bin/pip list | grep numpy | awk '{print $2}')
        echo -e "${GREEN}✓ Numpy ${numpy_version} verified in klippy-env${NC}"
    else
        echo -e "${RED}✗ Numpy not found in klippy-env${NC}"
        return 1
    fi
    
    # Verify matplotlib installation
    if ${HOME}/klippy-env/bin/pip list | grep -q matplotlib; then
        local matplotlib_version=$(${HOME}/klippy-env/bin/pip list | grep matplotlib | awk '{print $2}')
        echo -e "${GREEN}✓ Matplotlib ${matplotlib_version} verified${NC}"
    else
        echo -e "${YELLOW}⚠ Matplotlib not found (may need manual installation)${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}=== Installation Complete ===${NC}"
    echo "You can now use ADXL345-based resonance measurements with your printer."
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Connect your ADXL345 accelerometer to your printer"
    echo "2. Configure the accelerometer in your printer.cfg"
    echo "3. Run resonance testing commands"
    echo ""
    echo "For configuration instructions, see:"
    echo "https://www.klipper3d.org/Measuring_Resonances.html"
}

uninstall_numpy_for_adxl() {
    show_header
    echo -e "${BLUE}UNINSTALL NUMPY FOR ADXL${NC}"
    echo ""
    echo -e "${YELLOW}WARNING: This will remove numpy from the Klipper environment.${NC}"
    echo "This may affect other Klipper features that depend on numpy."
    echo ""
    
    read -p "Are you sure you want to uninstall numpy? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        return 0
    fi
    
    echo ""
    echo -e "${CYAN}Uninstalling numpy from Klipper environment...${NC}"
    
    if ${HOME}/klippy-env/bin/pip uninstall -y numpy; then
        echo -e "${GREEN}✓ Numpy removed from klippy-env${NC}"
    else
        echo -e "${RED}✗ Failed to remove numpy${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Note: System packages (python3-numpy, libatlas-base-dev, etc.) were NOT removed.${NC}"
    echo "If you want to remove system packages, run:"
    echo "sudo apt remove python3-numpy python3-matplotlib libatlas-base-dev libopenblas-dev"
    echo ""
    echo -e "${GREEN}Numpy uninstallation complete.${NC}"
}

check_numpy_status() {
    show_header
    echo -e "${BLUE}NUMPY STATUS${NC}"
    echo ""
    
    echo -e "${CYAN}Checking klippy-env numpy installation...${NC}"
    if ${HOME}/klippy-env/bin/pip list | grep -q numpy; then
        local numpy_version=$(${HOME}/klippy-env/bin/pip list | grep numpy | awk '{print $2}')
        echo -e "${GREEN}✓ Numpy ${numpy_version} is installed in klippy-env${NC}"
    else
        echo -e "${YELLOW}✗ Numpy is NOT installed in klippy-env${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Checking system numpy installation...${NC}"
    if dpkg -l | grep -q python3-numpy; then
        local system_version=$(dpkg -l | grep python3-numpy | awk '{print $3}')
        echo -e "${GREEN}✓ System python3-numpy ${system_version} is installed${NC}"
    else
        echo -e "${YELLOW}✗ System python3-numpy is NOT installed${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Checking system dependencies...${NC}"
    
    if dpkg -l | grep -q libatlas-base-dev; then
        echo -e "${GREEN}✓ libatlas-base-dev is installed${NC}"
    else
        echo -e "${YELLOW}✗ libatlas-base-dev is NOT installed${NC}"
    fi
    
    if dpkg -l | grep -q libopenblas-dev; then
        echo -e "${GREEN}✓ libopenblas-dev is installed${NC}"
    else
        echo -e "${YELLOW}✗ libopenblas-dev is NOT installed${NC}"
    fi
    
    if dpkg -l | grep -q python3-matplotlib; then
        echo -e "${GREEN}✓ python3-matplotlib is installed${NC}"
    else
        echo -e "${YELLOW}✗ python3-matplotlib is NOT installed${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..." dummy
}