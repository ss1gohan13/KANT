# KANT - Klipper Assistant for New Toolheads

A comprehensive utility to assist with Klipper 3D printer configuration and setup. KANT provides an interactive menu-driven interface to help you configure your printer quickly and correctly.

## Features

- 🔧 **MCU ID Management** - Automatically detect and configure MCU serial IDs
- 🚌 **CAN Bus Support** - Scan for and configure CAN bus devices
- ⚙️ **Stepper Configuration** - Easy configuration of stepper motor pins for all axes
- 📝 **Baseline Macros** - Install essential print macros with customizable parameters
- 🎯 **Start/End Print Macros** - Customizable start and end print sequences
- 💾 **Configuration Backup** - Automatic backup of configuration files

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ss1gohan13/KANT.git
cd KANT
./installer.sh
```
## Usage

### Main Menu

When you run KANT, you'll see an interactive menu with the following options:

1. **Check and Insert MCU IDs** - Scan for connected MCU devices and add them to your configuration
2. **Check for CAN IDs** - Scan CAN bus interfaces and configure CAN-connected MCUs
3. **Edit/Configure Stepper Pins** - Configure stepper motor pins for X, Y, Z, and extruders
4. **Install Baseline Macros** - Install a complete set of essential macros
5. **Configure Start Print Macro** - Customize your start print sequence
6. **Configure End Print Macro** - Customize your end print sequence
7. **Backup Current Configuration** - Create a timestamped backup of your configuration
8. **About KANT** - Information about the utility
9. **Exit** - Exit the program

### MCU Configuration

The MCU configuration feature will:
- Automatically detect MCU devices in `/dev/serial/by-id/`
- Allow you to select which MCU to configure
- Add or update MCU sections in your `printer.cfg`
- Support multiple MCUs with custom names

### CAN Bus Configuration

For CAN bus setups, KANT will:
- Detect available CAN interfaces (can0, can1, etc.)
- Check interface status
- Use Klipper's `canbus_query.py` if available
- Help you add CAN MCU configuration with UUIDs

### Stepper Configuration

Configure steppers for:
- X, Y, Z axes (including multi-Z setups)
- Extruders (single or dual extruder)
- Custom pin assignments
- Rotation distance, microsteps, and endstop configuration

### Baseline Macros

KANT includes the following macros:

- **START_PRINT** - Comprehensive start sequence with bed leveling and purge line
- **END_PRINT** - Safe end sequence with part presentation
- **PAUSE** - Pause print with filament retraction
- **RESUME** - Resume print and restore state
- **CANCEL_PRINT** - Cancel print and cleanup
- **LOAD_FILAMENT** - Automated filament loading
- **UNLOAD_FILAMENT** - Automated filament unloading

All macros are customizable through the configuration interface.

## File Structure

```
KANT/
├── installer.sh         # Main installer and menu script
├── README.md
└── LICENSE
```

## Configuration Files

KANT works with your Klipper configuration directory (typically `~/printer_data/config/`):

- **printer.cfg** - Main configuration file (updated by KANT)
- **macros.cfg** - Main configuration containing macros
- **backups/** - Automatic backups of configuration changes

## Requirements

- Klipper 3D printer firmware installed
- Bash shell (Linux/Unix environment)
- Basic command-line tools: `grep`, `sed`, `tar`
- Optional: `iproute2` package for CAN bus support

## Safety Features

- **Automatic Backups** - KANT creates timestamped backups before making changes
- **Confirmation Prompts** - Important changes require user confirmation
- **Non-destructive** - Existing configurations are backed up before modification

## Examples

### Configuring a Serial MCU

1. Connect your MCU via USB
2. Run KANT and select option 1 (Check and Insert MCU IDs)
3. Select your device from the list
4. Enter a name for the MCU (default: "mcu")
5. KANT will add the configuration to printer.cfg

### Installing Macros

1. Run KANT and select option 4 (Install Baseline Macros)
2. Confirm installation
3. Macros will be installed in `~/printer_data/config/macros/`
4. Your printer.cfg will be updated to include them

### Configuring Start Print

1. Select option 5 (Configure Start Print Macro)
2. Set your preferences:
   - Default bed temperature
   - Default extruder temperature
   - Enable/disable bed mesh
   - Enable/disable purge line
3. The macro will be customized to your settings

## Troubleshooting

### No MCU devices found

- Ensure your MCU is connected via USB
- Check that you have permissions to access `/dev/serial/by-id/`
- Try running with `sudo` if needed

### CAN interface not found

- Verify CAN kernel modules are loaded: `lsmod | grep can`
- Check if interface is up: `ip link show can0`
- Install required tools: `sudo apt-get install iproute2`

### Macro not working

- Verify the include statement in printer.cfg: `[include macros/*.cfg]`
- Check for syntax errors: `RESTART` in Klipper console
- Review macro file in `~/printer_data/config/macros.cfg`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Note**: KANT modifies your Klipper configuration files. While it creates automatic backups, always ensure you have additional backups of your working configuration before making changes.
