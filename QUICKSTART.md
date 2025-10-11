# KANT Quick Start Guide

## Installation

```bash
curl -s https://raw.githubusercontent.com/ss1gohan13/KANT/main/install.sh | bash
```

Or manually:

```bash
cd ~
git clone https://github.com/ss1gohan13/KANT.git
cd KANT
chmod +x kant.sh
./kant.sh
```

## First-Time Setup Workflow

### Recommended Setup Order

1. **Configure MCU** (Menu Option 1)
   - Automatically detects USB-connected MCUs
   - Adds configuration to printer.cfg
   - Creates backup before modifying

2. **Configure CAN Bus** (Menu Option 2) - *If applicable*
   - Scans for CAN interfaces
   - Queries for CAN devices
   - Configures CAN MCUs

3. **Configure Steppers** (Menu Option 3)
   - Set up X, Y, Z steppers
   - Configure extruder(s)
   - Define pins and parameters

4. **Install Macros** (Menu Option 4)
   - Installs all baseline macros
   - Adds include statement to printer.cfg

5. **Customize Start Print** (Menu Option 5)
   - Set default temperatures
   - Enable/disable bed mesh
   - Configure purge line

6. **Customize End Print** (Menu Option 6)
   - Set retraction distance
   - Configure Z-lift
   - Set park position

7. **Backup Configuration** (Menu Option 7)
   - Creates compressed backup
   - Saves to ~/printer_data/config/backups/

## Common Tasks

### Adding a New MCU

1. Connect MCU via USB
2. Run KANT (option 1)
3. Select device from list
4. Enter MCU name (e.g., "mcu", "toolhead")
5. Configuration is automatically added

### Setting Up CAN Bus

1. Ensure CAN interface is up:
   ```bash
   sudo ip link set can0 type can bitrate 500000
   sudo ip link set up can0
   ```
2. Run KANT (option 2)
3. Select CAN interface
4. Enter UUID from canbus_query
5. Configuration is automatically added

### Changing Stepper Pins

1. Run KANT (option 3)
2. Select stepper to configure
3. Enter new pin values
4. Old configuration is backed up
5. New configuration is added

### Updating Macros

Simply run options 4, 5, or 6 to regenerate macros with new settings. Old versions are backed up automatically.

## Configuration File Locations

- **Main Config**: `~/printer_data/config/printer.cfg`
- **Macros**: `~/printer_data/config/macros/*.cfg`
- **Backups**: `~/printer_data/config/backups/`

## Troubleshooting

### Permission Issues

If you can't access serial devices:
```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

### CAN Bus Not Found

```bash
# Load CAN modules
sudo modprobe can
sudo modprobe can_raw

# Bring up interface
sudo ip link set can0 type can bitrate 500000
sudo ip link set up can0
```

### Klipper Won't Start After Changes

1. Check Klipper log: `~/printer_data/logs/klippy.log`
2. Restore from backup if needed
3. Review printer.cfg for syntax errors

## Tips

- **Always backup** before making changes (KANT does this automatically)
- **Test incrementally** - configure one thing at a time
- **Use the examples** - see `examples/` directory for reference
- **Check syntax** - restart Klipper after each change
- **Save working configs** - make manual backups of known-good configurations

## Support

- GitHub Issues: https://github.com/ss1gohan13/KANT/issues
- Documentation: See README.md
- Examples: See examples/ directory
