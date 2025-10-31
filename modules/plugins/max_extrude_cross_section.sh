#!/bin/bash
# Max Extrude Cross Section Plugin
# Handles max_extrude_cross_section configuration

add_max_extrude_cross_section_to_extruder() {
    local printer_cfg="${KLIPPER_CONFIG}/printer.cfg"
    local backup_cfg="${BACKUP_DIR}/printer.cfg.extruder_max_cross_section_${CURRENT_DATE}"

    if [ ! -f "$printer_cfg" ]; then
        echo -e "${YELLOW}[WARNING] printer.cfg not found at ${printer_cfg}${NC}"
        return
    fi

    cp "$printer_cfg" "$backup_cfg"
    echo "Created backup of printer.cfg at $backup_cfg"

    # Check if [extruder] section exists
    if ! grep -q '^\[extruder\]' "$printer_cfg"; then
        echo -e "${RED}[ERROR] No [extruder] section found in printer.cfg${NC}"
        return
    fi

    # Use awk to add or update the line
    awk '
    BEGIN { in_extruder=0; done=0 }
    /^\[extruder\]/ { print; in_extruder=1; next }
    /^\[/ { if (in_extruder && !done) { print "max_extrude_cross_section: 10"; done=1 } in_extruder=0 }
    in_extruder && /^max_extrude_cross_section:/ { if (!done) { print "max_extrude_cross_section: 10"; done=1 } next }
    { print }
    END { if (in_extruder && !done) print "max_extrude_cross_section: 10" }
    ' "$printer_cfg" > "${printer_cfg}.new" && mv "${printer_cfg}.new" "$printer_cfg"
    echo -e "${GREEN}max_extrude_cross_section: 10 added/updated in [extruder] section${NC}"
}