# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-11

### Added
- Interactive menu-driven installer for Klipper configuration
- MCU ID detection and configuration
  - Automatic scanning of /dev/serial/by-id/
  - Multiple MCU support
  - Automatic printer.cfg updates
- CAN bus support
  - CAN interface detection
  - Integration with Klipper's canbus_query.py
  - CAN MCU configuration with UUID
- Stepper motor configuration
  - Support for X, Y, Z axes
  - Multi-Z setup support (dual, triple, quad)
  - Extruder configuration (single and dual)
  - Pin configuration (step, dir, enable, endstop)
  - Customizable parameters (rotation distance, microsteps, etc.)
- Baseline macro installation
  - START_PRINT macro with customizable parameters
  - END_PRINT macro with safe shutdown
  - PAUSE/RESUME/CANCEL macros
  - LOAD_FILAMENT/UNLOAD_FILAMENT macros
- Configuration backup system
  - Automatic backups before changes
  - Timestamped backup files
  - Compressed configuration archives
- Comprehensive documentation
  - Detailed README with usage instructions
  - Quick start guide
  - Example configurations
- Installation script for easy setup
- Color-coded terminal interface
- Error handling and validation
- User confirmation for destructive operations

### Security
- Non-destructive configuration updates
- Automatic backup creation
- User prompts for overwrite operations

[1.0.0]: https://github.com/ss1gohan13/KANT/releases/tag/v1.0.0
