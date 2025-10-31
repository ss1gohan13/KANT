#!/bin/bash
# Firmware Retraction Plugin
# Handles firmware retraction configuration

add_firmware_retraction_to_printer_cfg() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local working_cfg="${BACKUP_DIR}/printer.cfg.firmware_retraction_${CURRENT_DATE}"

    local firmware_retraction_block="[firmware_retraction]
retract_length: 0.6
#   The length of filament (in mm) to retract when G10 is activated,
#   and to unretract when G11 is activated (but see
#   unretract_extra_length below). The default is 0 mm.
retract_speed: 60
#   The speed of retraction, in mm/s. The default is 20 mm/s.
unretract_extra_length: 0
#   The length (in mm) of *additional* filament to add when
#   unretracting.
unretract_speed: 60
#   The speed of unretraction, in mm/s. The default is 10 mm/s.
"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        echo "You will need to manually add the firmware retraction block to your printer.cfg"
        return
    fi

    cp "$printer_cfg" "$working_cfg"
    echo "Created backup of printer.cfg at ${working_cfg}"

    if grep -q '^\[firmware_retraction\]' "$working_cfg"; then
        echo -e "${GREEN}Firmware retraction section already exists. Skipping addition.${NC}"
        rm "$working_cfg"
        return
    fi

    # Look for the SAVE_CONFIG comment marker instead of [save_config]
    local save_config_line=$(grep -n '#\*# <---------------------- SAVE_CONFIG ---------------------->' "$working_cfg" | cut -d: -f1 | head -n 1)
    
    if [ -n "$save_config_line" ]; then
        # Insert firmware retraction just before SAVE_CONFIG marker
        awk -v block="$firmware_retraction_block" -v line="$save_config_line" '
            NR==line {print block}
            {print}
        ' "$working_cfg" > "${working_cfg}.new"
        mv "${working_cfg}.new" "$printer_cfg"
        echo -e "${GREEN}Added firmware retraction above SAVE_CONFIG section in printer.cfg${NC}"
    else
        # No SAVE_CONFIG marker found, append to end
        echo "$firmware_retraction_block" >> "$working_cfg"
        mv "$working_cfg" "$printer_cfg"
        echo -e "${GREEN}Appended firmware retraction to end of printer.cfg${NC}"
    fi
}