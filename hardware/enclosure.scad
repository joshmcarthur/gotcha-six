// Gotcha Six wearable enclosure
// C4001 mmWave + Seeed XIAO nRF52840 Sense + 500 mAh LiPo
//
// part: "shell" | "back" | "shim" | "xiao_shim" | "all"
// fastener: "insert" | "tapping" — four lid M2 holes only
//   insert  : 3.2 mm holes for M2 heat-set inserts
//   tapping : 1.7 mm holes for M2 self-tapping screws
// Radar bosses are always printed M2 taps.
//
// Battery is the 500 mAh cell, same orientation as the XIAO:
// long axis along Y, USB-end of the cell at +Y (USB-C wall).
//
// Units: millimetres. Origin at the outer front face, centred on X/Y.

part = "back";
fastener = "tapping";

/* [Hidden] */
$fn = 48;

// --- Components ---
radar_w = 26.00;
radar_h = 30.00;
radar_z = 2.70;
radar_hole_span = 22.00;
radar_hole_inset = 2.00;

xiao_w = 18.05;
xiao_h = 21.05;
xiao_board_z = 3.00;
xiao_bay_z = 4.50;
xiao_fit = 0.30;
xiao_lip_in = 1.20;
xiao_lip_t = 1.20;

// 500 mAh: 27.5 along Y (with XIAO), 20.5 along X, 8.25 thick
batt_x = 20.50;
batt_y = 27.50;
batt_z = 8.25;

// --- Shell sizing ---
wall = 2.40;
window_t = 1.60;
corner_r = 6.00;
edge_r = 1.20;
fit = 0.40;
batt_clear = 0.40;

wire_notch_w = 14.00;
wire_notch_h = 2.50;
wire_notch_d = 1.20;

usb_shell_w = 8.94;
usb_shell_h = 3.26;
usb_shell_r = 1.30;
usb_clear = 0.25;
usb_slot_w = usb_shell_w + usb_clear;
usb_slot_h = usb_shell_h + usb_clear;
usb_slot_r = usb_shell_r + usb_clear / 2;

clip_t = 2.80;
clip_gap = 2.40;
clip_lip = 1.60;

// M2
m2_clear = 2.20;
m2_head_d = 4.50;
m2_head_h = 1.60;
m2_insert_d = 3.20;
m2_insert_z = 4.20;
m2_tap_d = 1.70;
m2_tap_z = 6.00;
boss_od = 7.20;
boss_stack_gap = 1.00; // air between electronics well and each cylinder

radar_boss_od = 4.40;
radar_tap_d = 1.70;

// Electronics well (radar / XIAO / cell). Cylinders sit outside this.
inner_w = max(radar_w + fit, batt_x + batt_clear);
inner_h = max(radar_h + fit, batt_y + batt_clear);
function boss_x() = inner_w / 2 + boss_stack_gap + boss_od / 2;
function boss_y() = inner_h / 2 - 1.00;
function boss_xs() = [-boss_x(), boss_x()];
function boss_ys() = [-boss_y(), boss_y()];
outer_w = 2 * (boss_x() + boss_od / 2 + 0.50);
outer_h = 2 * (max(inner_h / 2 + wall, boss_y() + boss_od / 2 + 0.50));
clip_w = 2 * boss_x() - boss_od - 1.60;

cavity_z = radar_z + xiao_bay_z + batt_z + batt_clear;
shell_z = window_t + cavity_z;
lid_t = 2.40;

assert(fastener == "insert" || fastener == "tapping", "fastener must be \"insert\" or \"tapping\"");

function m2_pilot_d() = fastener == "insert" ? m2_insert_d : m2_tap_d;
function m2_pilot_z() = fastener == "insert" ? m2_insert_z : m2_tap_z;
function inner_r() = max(0.1, corner_r - wall);
function nest_r(clear) = max(0.1, inner_r() - clear);

function radar_hole_x() = radar_hole_span / 2;
function radar_hole_y() = -(radar_h / 2 - radar_hole_inset);

module rounded_rect(size, r) {
  w = size[0];
  h = size[1];
  rr = min(r, w / 2, h / 2);
  hull() {
    for (sx = [-1, 1], sy = [-1, 1])
      translate([sx * (w / 2 - rr), sy * (h / 2 - rr)])
        circle(r = rr);
  }
}

module rounded_box(size, r) {
  linear_extrude(height = size[2])
    rounded_rect([size[0], size[1]], r);
}

module filleted_box(size, r) {
  rr = min(r, size[0] / 2 - 0.2, size[1] / 2 - 0.2, size[2] / 2 - 0.2);
  translate([0, 0, size[2] / 2])
    minkowski() {
      cube([size[0] - 2 * rr, size[1] - 2 * rr, size[2] - 2 * rr], center = true);
      sphere(r = rr, $fn = 24);
    }
}

module corner_boss_solids() {
  for (x = boss_xs(), y = boss_ys())
    translate([x, y, window_t])
      cylinder(d = boss_od, h = cavity_z + 0.01);
}

module radar_boss_solids() {
  for (sx = [-1, 1])
    translate([sx * radar_hole_x(), radar_hole_y(), window_t]) {
      cylinder(d = radar_boss_od + 2.0, h = 1.00);
      cylinder(d = radar_boss_od, h = radar_z);
    }
}

module shell() {
  difference() {
    filleted_box([outer_w, outer_h, shell_z], edge_r);

    // Hollow the tub but keep corner and radar bosses
    difference() {
      translate([0, 0, window_t])
        linear_extrude(height = cavity_z + 0.02)
          rounded_rect([inner_w, inner_h], inner_r());
      corner_boss_solids();
      radar_boss_solids();
    }

    translate([
      0,
      -inner_h / 2 + wire_notch_h / 2 - 0.01,
      window_t + radar_z / 2
    ])
      cube([wire_notch_w, wire_notch_h + wall, wire_notch_d + radar_z], center = true);

    // USB on the edge opposite the radar header, wires, and C4001 screws
    usb_z_mid = window_t + radar_z + xiao_bay_z / 2;
    translate([0, outer_h / 2 - wall / 2, usb_z_mid])
      rotate([90, 0, 0])
        linear_extrude(height = wall + 0.4, center = true)
          rounded_rect([usb_slot_w, usb_slot_h], usb_slot_r);

    for (x = boss_xs(), y = boss_ys()) {
      translate([x, y, shell_z - m2_pilot_z() + 0.01])
        cylinder(d = m2_pilot_d(), h = m2_pilot_z() + 0.02);
      if (fastener == "insert")
        translate([x, y, shell_z - 0.49])
          cylinder(d1 = m2_insert_d, d2 = m2_insert_d + 1.0, h = 0.50);
    }

    for (sx = [-1, 1])
      translate([sx * radar_hole_x(), radar_hole_y(), window_t - 0.2])
        cylinder(d = radar_tap_d, h = radar_z + 2.0);
  }
}

module clothing_clip() {
  // Open J-hook: arm parallel to the lid, entry at the header end (-Y).
  // The tip lip hangs toward the lid but leaves a slot so fabric can slide on.
  z0 = 0;
  r = 0.60;
  entry = 1.20;
  spine_y = inner_h / 2 - 4.0;
  arm_bottom = -inner_h / 2 + 3.0;
  arm_len = spine_y - arm_bottom;
  module clip_bar(x, y, z, sx, sy, sz) {
    rr = min(r, sx / 2, sy / 2, sz / 2);
    hull()
      for (dx = [-1, 1], dy = [-1, 1], dz = [-1, 1])
        translate([
          x + dx * (sx / 2 - rr),
          y + dy * (sy / 2 - rr),
          z + dz * (sz / 2 - rr)
        ])
          sphere(r = rr, $fn = 16);
  }
  hull() {
    clip_bar(0, spine_y, z0 + clip_t / 2, clip_w, 10.0, clip_t);
    clip_bar(0, spine_y, z0 + clip_gap + clip_t / 2, clip_w, 8.0, clip_t);
  }
  clip_bar(0, (spine_y + arm_bottom) / 2, z0 + clip_gap + clip_t / 2, clip_w, arm_len, clip_t);
  clip_bar(
    0,
    arm_bottom + clip_lip / 2,
    z0 + entry + (clip_gap - entry) / 2,
    clip_w,
    clip_lip,
    clip_gap - entry
  );
}

module back() {
  difference() {
    union() {
      filleted_box([outer_w, outer_h, lid_t], edge_r);

      // Locate ring into the shell mouth
      translate([0, 0, -1.00])
        linear_extrude(height = 1.00)
          rounded_rect([inner_w - 0.40, inner_h - 0.40], max(0.1, corner_r - wall - 0.2));

      translate([0, 0, lid_t])
        clothing_clip();
    }

    // M2 through the lid only — corners sit outside the J-hook
    for (x = boss_xs(), y = boss_ys()) {
      translate([x, y, -1.20])
        cylinder(d = m2_clear, h = lid_t + 1.40);
      translate([x, y, lid_t - m2_head_h])
        cylinder(d = m2_head_d, h = m2_head_h + 0.2);
      translate([x, y, -1.20])
        cylinder(d = boss_od + 0.50, h = 1.15);
    }
  }
}

module shim() {
  // Cradle in the radar-sized well. Battery USB-end sits at +Y.
  ow = inner_w - 0.50;
  oh = inner_h - 0.50;
  pocket_w = batt_x + 0.30;
  pocket_h = batt_y + 0.30;
  pocket_cy = oh / 2 - pocket_h / 2;

  difference() {
    linear_extrude(height = batt_z)
      rounded_rect([ow, oh], 1.2);

    translate([0, pocket_cy, -0.01])
      linear_extrude(height = batt_z + 0.02)
        rounded_rect([pocket_w, pocket_h], 0.8);

    translate([0, oh / 2, batt_z / 2])
      cube([pocket_w, 4.0, batt_z + 0.1], center = true);

    for (x = boss_xs(), y = boss_ys())
      translate([x, y, -0.01])
        cylinder(d = boss_od + 0.60, h = batt_z + 0.02);
  }
}

module xiao_shim() {
  clear = 0.20;
  ow = inner_w - 2 * clear;
  oh = inner_h - 2 * clear;
  pocket_w = xiao_w + xiao_fit;
  pocket_h = xiao_h + xiao_fit;
  pocket_cy = oh / 2 - pocket_h / 2;
  board_z = xiao_bay_z - xiao_lip_t;

  difference() {
    linear_extrude(height = xiao_bay_z)
      rounded_rect([ow, oh], nest_r(clear));

    // Board cavity; USB edge (+Y) stays open so the XIAO slides in under the lip
    translate([0, pocket_cy, -0.01])
      linear_extrude(height = board_z + 0.01)
        rounded_rect([pocket_w, pocket_h], 0.6);

    // Lip on the header/screw side (-Y) and both sides
    translate([0, pocket_cy + xiao_lip_in / 2, board_z - 0.01])
      linear_extrude(height = xiao_bay_z - board_z + 0.02)
        rounded_rect([pocket_w - 2 * xiao_lip_in, pocket_h - xiao_lip_in], 0.5);

    translate([0, oh / 2, xiao_bay_z / 2])
      cube([usb_slot_w + 0.6, 3.0, xiao_bay_z + 0.1], center = true);

    // M2 through-holes on the C4001 pattern (header edge, opposite USB)
    for (sx = [-1, 1]) {
      translate([sx * radar_hole_x(), radar_hole_y(), -0.01])
        cylinder(d = m2_clear, h = xiao_bay_z + 0.02);
      translate([sx * radar_hole_x(), radar_hole_y(), xiao_bay_z - 0.80])
        cylinder(d = 3.60, h = 0.90);
    }
  }
}

module plate_all() {
  gap = 14;
  row_top_y = outer_h / 2 + gap;
  row_bot_y = -(outer_h / 2 + gap + 24);

  translate([-(outer_w / 2 + gap / 2), row_top_y, 0])
    shell();
  translate([outer_w / 2 + gap / 2, row_top_y, lid_t])
    rotate([180, 0, 0])
      back();

  translate([-(inner_w / 2 + gap + 6), row_bot_y, 0])
    shim();
  translate([inner_w / 2 + gap + 6, row_bot_y, 0])
    xiao_shim();
}

if (part == "shell")
  shell();
else if (part == "back")
  rotate([180, 0, 0])
    back();
else if (part == "shim")
  shim();
else if (part == "xiao_shim")
  xiao_shim();
else if (part == "all")
  plate_all();
else
  assert(false, "part must be shell|back|shim|xiao_shim|all");

echo(str("fastener=", fastener, " pilot_d=", m2_pilot_d(), " pilot_z=", m2_pilot_z()));
echo(str("outer_w=", outer_w));
echo(str("outer_h=", outer_h));
echo(str("shell_z=", shell_z));
echo(str("wall=", wall, " corner_r=", corner_r, " edge_r=", edge_r));
echo(str("usb_slot=", usb_slot_w, "x", usb_slot_h, " r=", usb_slot_r));
echo(str("radar_bosses x=±", radar_hole_x(), " y=", radar_hole_y()));
echo(str("lid_bosses x=±", boss_x(), " y=±", boss_y()));
echo(str("clip_w=", clip_w));
echo(str("xiao_shim_pocket=", xiao_w + xiao_fit, "x", xiao_h + xiao_fit, "x", xiao_bay_z));
echo(str("xiao_shim_lip=", xiao_lip_in, "x", xiao_lip_t));
echo(str("batt=", batt_x, "x", batt_y, "x", batt_z));
