#!/bin/bash

# KANT Installation Script

set -e

echo "Installing KANT - Klipper Assistant for New Toolheads"
echo "======================================================"
echo ""

# Determine installation directory
INSTALL_DIR="${HOME}/KANT"

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo "KANT is already installed at $INSTALL_DIR"
    echo -n "Do you want to update it? [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Updating KANT..."
            cd "$INSTALL_DIR"
            git pull
            ;;
        *)
            echo "Installation cancelled."
            exit 0
            ;;
    esac
else
    # Clone repository
    echo "Cloning KANT repository..."
    git clone https://github.com/ss1gohan13/KANT.git "$INSTALL_DIR"
fi

# Make scripts executable
echo "Setting permissions..."
chmod +x "$INSTALL_DIR/kant.sh"

# Create symbolic link in user's bin directory
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

if [ -L "$BIN_DIR/kant" ]; then
    rm "$BIN_DIR/kant"
fi

ln -s "$INSTALL_DIR/kant.sh" "$BIN_DIR/kant"

echo ""
echo "✓ Installation complete!"
echo ""
echo "To run KANT, use one of the following methods:"
echo "  1. Run: kant (if ~/.local/bin is in your PATH)"
echo "  2. Run: $INSTALL_DIR/kant.sh"
echo ""

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Note: $BIN_DIR is not in your PATH"
    echo "Add it by running:"
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo ""
fi

echo "For help and documentation, see: $INSTALL_DIR/README.md"
