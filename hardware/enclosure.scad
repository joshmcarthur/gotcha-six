// Gotcha Six wearable enclosure
// C4001 mmWave + Seeed XIAO nRF52840 Sense + LiPo (A or B)
//
// part: "shell" | "back" | "clip" | "shim" | "xiao_shim" | "all"
// battery: "A" (500 mAh) | "B" (800 mAh) — affects battery shim only
//
// Units: millimetres. Origin at the outer front face, centred on X/Y.

part = "all";
battery = "A";
band_width = 25;

/* [Hidden] */
$fn = 48;

// --- Components ---
radar_w = 26.00;
radar_h = 30.00;
radar_z = 2.70;

xiao_w = 18.05;
xiao_h = 21.05;
xiao_bay_z = 4.50;
xiao_fit = 0.30;

batt_a_l = 27.50;
batt_a_z = 8.25;

batt_b_short = 17.80;

// --- Shell sizing ---
wall = 1.60;
window_t = 1.20;
corner_r = 2.00;
fit = 0.40;

batt_bay_l = 40.00;
batt_bay_w = 20.50;
batt_bay_z = 9.80;
batt_clear = 0.40;

wire_notch_w = 14.00;
wire_notch_h = 2.50;
wire_notch_d = 1.20;

// USB-C receptacle shell is 8.94 x 3.26 mm, ~1.3 mm corner radii.
// Cutout adds 0.25 mm print clearance on each axis.
usb_shell_w = 8.94;
usb_shell_h = 3.26;
usb_shell_r = 1.30;
usb_clear = 0.25;
usb_slot_w = usb_shell_w + usb_clear;
usb_slot_h = usb_shell_h + usb_clear;
usb_slot_r = usb_shell_r + usb_clear / 2;

snap_w = 4.00;
snap_d = 1.20;
snap_h = 1.40;

band_slot_t = 2.20;
band_bridge = 2.00;
clip_rail_w = 12.00;
clip_rail_t = 2.00;
clip_rail_h = 3.00;
clip_gap = 2.20;
clip_jaw = 8.00;
clip_thick = 2.00;

inner_w = max(radar_w + fit, batt_bay_l + batt_clear);
inner_h = max(radar_h + fit, band_width + 2 * band_bridge);
outer_w = inner_w + 2 * wall;
outer_h = inner_h + 2 * wall;

cavity_z = radar_z + xiao_bay_z + batt_bay_z + batt_clear;
shell_z = window_t + cavity_z;
back_plate_t = 2.00;

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

function tunnel_outer_h() = band_width + 2 * band_bridge;

module shell() {
  difference() {
    rounded_box([outer_w, outer_h, shell_z], corner_r);

    // Main cavity above the window
    translate([0, 0, window_t])
      linear_extrude(height = cavity_z + 0.02)
        rounded_rect([inner_w, inner_h], max(0.1, corner_r - wall));

    // Wire notch on bottom edge (radar header edge)
    translate([
      0,
      -inner_h / 2 + wire_notch_h / 2 - 0.01,
      window_t + radar_z / 2
    ])
      cube([wire_notch_w, wire_notch_h + wall, wire_notch_d + radar_z], center = true);

    // USB-C stadium cutout on bottom wall through the XIAO bay
    usb_z_mid = window_t + radar_z + xiao_bay_z / 2;
    translate([0, -outer_h / 2 + wall / 2, usb_z_mid])
      rotate([90, 0, 0])
        linear_extrude(height = wall + 0.2, center = true)
          rounded_rect([usb_slot_w, usb_slot_h], usb_slot_r);

    // Snap seats on the open end
    for (sx = [-1, 1])
      translate([
        sx * (inner_w / 2 - snap_d / 2 - 0.2),
        0,
        shell_z - snap_h / 2
      ])
        cube([snap_d + 0.2, snap_w, snap_h + 0.2], center = true);
  }

  // Radar retaining lip
  lip_t = 0.80;
  lip_in = 1.00;
  difference() {
    translate([0, 0, window_t + radar_z - lip_t])
      linear_extrude(height = lip_t)
        rounded_rect([radar_w + fit + 2 * lip_in, radar_h + fit + 2 * lip_in], 1.2);
    translate([0, 0, window_t + radar_z - lip_t - 0.01])
      linear_extrude(height = lip_t + 0.02)
        rounded_rect([radar_w + fit, radar_h + fit], 0.8);
    translate([0, -radar_h / 2, window_t + radar_z - lip_t / 2])
      cube([wire_notch_w + 2, 6, lip_t + 0.2], center = true);
  }
}

module back() {
  // Body-face features point +Z. Shell inserts point -Z.
  difference() {
    union() {
      rounded_box([outer_w, outer_h, back_plate_t], corner_r);

      translate([0, 0, -1.00])
        linear_extrude(height = 1.00)
          rounded_rect([inner_w - 0.30, inner_h - 0.30], max(0.1, corner_r - wall - 0.15));

      for (sx = [-1, 1])
        translate([
          sx * (inner_w / 2 - snap_d / 2 - 0.35),
          0,
          -1.00 - snap_h / 2
        ])
          cube([snap_d, snap_w - 0.30, snap_h], center = true);

      // Clip rail
      translate([0, 1.5, back_plate_t + clip_rail_h / 2])
        cube([clip_rail_w, clip_rail_t, clip_rail_h], center = true);
      translate([0, 1.5, back_plate_t + 0.70 / 2])
        cube([clip_rail_w + 2.40, clip_rail_t + 1.60, 0.70], center = true);

      // Band tunnel housings
      for (sx = [-1, 1])
        translate([
          sx * (outer_w / 2 - (band_bridge + 0.8) / 2),
          0,
          back_plate_t + (band_slot_t + band_bridge) / 2
        ])
          cube([band_bridge + 0.8, tunnel_outer_h(), band_slot_t + band_bridge], center = true);
    }

    for (sx = [-1, 1])
      translate([
        sx * (outer_w / 2 - (band_bridge + 0.8) / 2),
        0,
        back_plate_t + band_bridge / 2 + band_slot_t / 2
      ])
        cube([band_bridge + 1.2, band_width + 0.4, band_slot_t], center = true);
  }
}

module clip() {
  body_l = 18.00;
  body_w = clip_rail_w + 4.00;
  body_t = clip_thick;

  difference() {
    union() {
      translate([0, 0, body_t / 2])
        cube([body_w, body_l, body_t], center = true);

      translate([0, -body_l / 2 - clip_jaw / 2 + 1, body_t / 2])
        cube([body_w - 2, clip_jaw, body_t], center = true);

      translate([0, -body_l / 2 - clip_jaw + 1.2, body_t / 2 + (clip_gap + 1.0) / 2])
        cube([body_w - 2, 2.40, clip_gap + 1.0], center = true);
    }

    translate([0, 1.0, body_t - 0.01])
      cube([clip_rail_w + 0.35, clip_rail_t + 0.35, body_t + 0.2], center = true);
    translate([0, 1.0, 0.70 / 2 - 0.01])
      cube([clip_rail_w + 2.75, clip_rail_t + 1.95, 0.70 + 0.2], center = true);

    translate([0, -body_l / 2 - clip_jaw / 2 + 2.2, body_t + clip_gap / 2])
      cube([body_w, clip_jaw - 2, clip_gap], center = true);
  }
}

module shim_a() {
  end_block = batt_bay_l - batt_a_l; // 12.5
  pad_z = batt_bay_z - batt_a_z;     // 1.55
  translate([(batt_bay_l - end_block) / 2, 0, batt_bay_z / 2])
    cube([end_block - 0.2, batt_bay_w - 0.2, batt_bay_z - 0.2], center = true);
  translate([-end_block / 2, 0, pad_z / 2])
    cube([batt_a_l - 0.2, batt_bay_w - 0.2, pad_z], center = true);
}

module shim_b() {
  bar = batt_bay_w - batt_b_short; // 2.7
  translate([0, (batt_bay_w - bar) / 2, batt_bay_z / 2])
    cube([batt_bay_l - 0.2, bar - 0.2, batt_bay_z - 0.2], center = true);
}

module shim() {
  if (battery == "A")
    shim_a();
  else if (battery == "B")
    shim_b();
  else
    assert(false, "battery must be \"A\" or \"B\"");
}

module xiao_shim() {
  // Frame fills the radar footprint; pocket holds the smaller XIAO.
  // USB edge is toward -Y to match the shell cutout.
  ow = radar_w + fit - 0.20;
  oh = radar_h + fit - 0.20;
  pocket_w = xiao_w + xiao_fit;
  pocket_h = xiao_h + xiao_fit;

  difference() {
    linear_extrude(height = xiao_bay_z)
      rounded_rect([ow, oh], 1.0);

    translate([0, -oh / 2 + pocket_h / 2, -0.01])
      linear_extrude(height = xiao_bay_z + 0.02)
        rounded_rect([pocket_w, pocket_h], 0.6);

    // Open the USB edge through the frame
    translate([0, -oh / 2, xiao_bay_z / 2])
      cube([usb_slot_w + 0.6, 3.0, xiao_bay_z + 0.1], center = true);
  }
}

module plate_all() {
  // Two rows with a fixed gap so parts do not share volume in the preview.
  gap = 12;
  row_top_y = outer_h / 2 + gap;
  row_bot_y = -(outer_h / 2 + gap + 22);

  translate([-(outer_w / 2 + gap / 2), row_top_y, 0])
    shell();
  translate([outer_w / 2 + gap / 2, row_top_y, back_plate_t])
    rotate([180, 0, 0])
      back();

  translate([-(batt_bay_l / 2 + gap + 12), row_bot_y, 0])
    clip();
  translate([0, row_bot_y, 0])
    shim();
  translate([batt_bay_l / 2 + gap + 10, row_bot_y, 0])
    xiao_shim();
}

if (part == "shell")
  shell();
else if (part == "back")
  rotate([180, 0, 0])
    back();
else if (part == "clip")
  clip();
else if (part == "shim")
  shim();
else if (part == "xiao_shim")
  xiao_shim();
else if (part == "all")
  plate_all();
else
  assert(false, "part must be shell|back|clip|shim|xiao_shim|all");

echo(str("outer_w=", outer_w));
echo(str("outer_h=", outer_h));
echo(str("shell_z=", shell_z));
echo(str("inner_w=", inner_w));
echo(str("inner_h=", inner_h));
echo(str("cavity_z=", cavity_z));
echo(str("batt_bay=", batt_bay_l, "x", batt_bay_w, "x", batt_bay_z));
echo(str("usb_slot=", usb_slot_w, "x", usb_slot_h, " r=", usb_slot_r));
echo(str("xiao_shim_outer=", radar_w + fit - 0.20, "x", radar_h + fit - 0.20));
echo(str("xiao_shim_pocket=", xiao_w + xiao_fit, "x", xiao_h + xiao_fit, "x", xiao_bay_z));
echo(str("shim_A_end=", batt_bay_l - batt_a_l, " pad_z=", batt_bay_z - batt_a_z));
echo(str("shim_B_bar=", batt_bay_w - batt_b_short));
