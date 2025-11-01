// OpenSCAD model of DIN-rail enclosure for MikroTik RB2011UiAS-2HnD-IN
// Orientation:
//  - X axis runs along the router length (left-right when facing the ports)
//  - Y axis runs vertically (top is +Y, bottom is -Y)
//  - Z axis runs from the back wall (DIN rail side) towards the removable front cover
// Back face lies in the XY plane at Z = 0 and only hosts the DIN-rail clamp.
// Front face (cover opening) is parallel to the back at Z = body_depth.
// Bottom face lies in the XZ plane at Y = 0 and contains the downward ports.
// Top face lies in the XZ plane at Y = body_height and exposes power/console/antennas.

// ==============================
// === Global configuration  ===
// ==============================
// PCB parameters (approximate values for RB2011UiAS-2HnD-IN)
// Board envelope measured from the MikroTik mechanical drawing (rev. B)
board_length_x = 206;             // along X axis, screw-center distance is slightly inset from the shell
board_height_y = 26;              // along Y axis (vertical clearance for populated components)
board_thickness_z = 1.6;          // along Z axis (FR-4 thickness)
board_bottom_clearance = 6;       // distance from interior bottom to PCB lower edge
board_top_clearance = 6;          // free space above PCB upper edge (air gap and tall parts)
board_back_offset = 68;           // board face sits ~15 mm behind the front openings (86 - 3.2 - 15)

// Enclosure shell (follows factory housing: 214 x 44 x 86 mm)
body_wall = 2.8;
body_length = 214;                 // along X
body_height = 44;                  // along Y (bottom to top exterior)
body_depth = 86;                   // along Z (back to front exterior)
front_lip = 2.2;                   // lip that retains the front cover (cover not modeled)

// Hardware
standoff_diameter = 6;
standoff_hole = 3;                        // for M3 screws

// DIN rail parameters (standard 35 mm top hat)
din_width = 35;
din_depth = 7;
din_flange = 15;
din_thickness = 1.5;
din_offset_from_bottom = 18;              // offset of rail center from bottom

// Connector layout approximations for the RB2011 bottom edge (ports facing down)
// Measurements derived from the factory faceplate: gaps are referenced to the front lip plane.
panel_left_margin = 2.5;
front_panel_clearance = 3.2;              // free space between front lip and connector faces
rj45_block_ports = 5;
rj45_width = 14.5;
rj45_spacing = 0.3;
rj45_height = 17.2;
rj45_offset_z = body_depth - front_panel_clearance - rj45_height;
rj45_block_width = rj45_block_ports * rj45_width + (rj45_block_ports - 1) * rj45_spacing;

sfp_width = 14.6;
sfp_height = 13.8;
sfp_to_rj45_gap = 2.8;
sfp_offset_x = panel_left_margin;
sfp_offset_z = rj45_offset_z + (rj45_height - sfp_height) / 2;

led_slot_length = 24.2;
led_slot_height = 4.5;
led_gap_between_blocks = 3.2;
led_slot_offset_z = rj45_offset_z + (rj45_height - led_slot_height) / 2;
led_slot_offset_x = panel_left_margin + sfp_width + sfp_to_rj45_gap +
                    rj45_block_width + led_gap_between_blocks;

second_rj45_offset_x = led_slot_offset_x + led_slot_length + led_gap_between_blocks;
first_rj45_offset_x = panel_left_margin + sfp_width + sfp_to_rj45_gap;

usb_width = 10.4;
usb_height = 7.8;
usb_gap = 4;
usb_offset_x = second_rj45_offset_x + rj45_block_width + usb_gap;
usb_offset_z = rj45_offset_z + (rj45_height - usb_height) / 2;

// Top openings (power, console RJ45 and dual SMA antenna connectors)
power_diameter = 12.2;
power_center_x = panel_left_margin + 22.8;
power_center_z = body_depth - front_panel_clearance - 9.6;

console_width = 16.4;
console_height = 14.2;
console_offset_x = power_center_x + 35.8;
console_offset_z = body_depth - front_panel_clearance - console_height;

antenna_diameter = 9;
antenna_spacing = 31.5;
antenna_center_z = body_depth - front_panel_clearance - 8.5;
antenna_center_x = body_length - panel_left_margin - 23;

// PCB standoff layout (hole pattern approximation)
standoff_positions = [
    [18,               6],
    [board_length_x - 18, 6],
    [18,               board_height_y - 6],
    [board_length_x - 18, board_height_y - 6]
];

// Guide rails to hold PCB edges along Z
guide_thickness = 3;
guide_depth = board_thickness_z + 12;
guide_height = board_height_y + 6;
guide_offset_from_bottom = body_wall + board_bottom_clearance - 1.5;

$fn = 64;

module enclosure_body() {
    difference() {
        // Outer shell
        cube([body_length, body_height, body_depth], center = false);

        // Inner cavity
        translate([body_wall, body_wall, body_wall])
            cube([body_length - 2 * body_wall,
                  body_height - 2 * body_wall,
                  body_depth - body_wall - front_lip], center = false);

        // Front opening for removable cover
        translate([body_wall, body_wall, body_depth - front_lip])
            cube([body_length - 2 * body_wall,
                  body_height - 2 * body_wall,
                  front_lip + 1], center = false);
    }
}

module din_rail_mount() {
    // Simplified DIN rail clamp located completely behind the back wall (Z <= 0)
    clamp_width = din_flange + 10;
    clamp_height = din_width + 12;
    base_thickness = 4;
    hook_depth = din_depth + base_thickness;
    translate([(body_length - clamp_width) / 2,
               din_offset_from_bottom - clamp_height / 2,
               -hook_depth])
        difference() {
            cube([clamp_width, clamp_height, hook_depth], center = false);
            translate([5,
                       (clamp_height - din_width) / 2 - 1,
                       hook_depth - (din_thickness + base_thickness)])
                cube([clamp_width - 10, din_width + 2, hook_depth], center = false);
        }
}

module bottom_cutouts() {
    // SFP opening (left-most when facing the front)
    translate([sfp_offset_x, -1, sfp_offset_z])
        cube([sfp_width, body_wall + 3, sfp_height], center = false);

    // Left bank of Gigabit Ethernet (Eth1-Eth5)
    for (i = [0 : rj45_block_ports - 1]) {
        translate([first_rj45_offset_x + i * (rj45_width + rj45_spacing), -1, rj45_offset_z])
            cube([rj45_width, body_wall + 3, rj45_height], center = false);
    }

    // Status LED light pipe window between Ethernet groups
    translate([led_slot_offset_x, -1, led_slot_offset_z])
        cube([led_slot_length, body_wall + 3, led_slot_height], center = false);

    // Right bank of Fast Ethernet (Eth6-Eth10)
    for (i = [0 : rj45_block_ports - 1]) {
        translate([second_rj45_offset_x + i * (rj45_width + rj45_spacing), -1, rj45_offset_z])
            cube([rj45_width, body_wall + 3, rj45_height], center = false);
    }

    // USB opening (on the far right)
    translate([usb_offset_x, -1, usb_offset_z])
        cube([usb_width, body_wall + 3, usb_height], center = false);
}

module top_cutouts() {
    top_cutout_depth = body_wall + 3;
    // Power barrel jack opening (circular)
    translate([power_center_x, body_height - top_cutout_depth / 2, power_center_z])
        rotate([90, 0, 0])
            cylinder(d = power_diameter, h = top_cutout_depth + 2, center = true);

    // Console RJ45 window (rectangular punch oriented downwards)
    translate([console_offset_x, body_height - top_cutout_depth, console_offset_z])
        cube([console_width, top_cutout_depth + 1, console_height], center = false);

    // Dual SMA antenna connectors
    for (sign = [-1, 1]) {
        translate([antenna_center_x + sign * antenna_spacing / 2,
                   body_height - top_cutout_depth / 2,
                   antenna_center_z])
            rotate([90, 0, 0])
                cylinder(d = antenna_diameter, h = top_cutout_depth + 2, center = true);
    }
}

module standoffs() {
    board_x_offset = (body_length - board_length_x) / 2;
    board_y_offset = body_wall + board_bottom_clearance;
    for (pos = standoff_positions) {
        translate([board_x_offset + pos[0],
                   board_y_offset + pos[1],
                   body_wall])
            difference() {
                cylinder(d = standoff_diameter, h = board_back_offset, center = false);
                translate([0, 0, -1])
                    cylinder(d = standoff_hole, h = board_back_offset + 2, center = false);
            }
    }
}

module guide_rails() {
    board_x_offset = (body_length - board_length_x) / 2;
    // Lower guide
    translate([board_x_offset,
               guide_offset_from_bottom,
               body_wall + board_back_offset - guide_thickness])
        cube([board_length_x, guide_thickness, guide_depth], center = false);
    // Upper guide
    translate([board_x_offset,
               guide_offset_from_bottom + board_height_y,
               body_wall + board_back_offset - guide_thickness])
        cube([board_length_x, guide_thickness, guide_depth], center = false);
}

module pcb_placeholder() {
    board_x_offset = (body_length - board_length_x) / 2;
    translate([board_x_offset,
               body_wall + board_bottom_clearance,
               body_wall + board_back_offset])
        color("seagreen", 0.3)
            cube([board_length_x, board_height_y, board_thickness_z], center = false);
}

module enclosure() {
    difference() {
        union() {
            enclosure_body();
            din_rail_mount();
            standoffs();
            guide_rails();
        }
        bottom_cutouts();
        top_cutouts();
    }
    pcb_placeholder();
}

enclosure();
