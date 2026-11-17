// Gotcha Six wearable enclosure — layout B (side by side)
// C4001 mmWave + Seeed XIAO nRF52840 Sense + 500 mAh LiPo
//
// Read hardware/SPEC.md before you change this file.
//
// part: "shell" | "lid" | "carrier" | "clip" | "all" | "assembly" | "none"
//   all      : print plate, each part in its print orientation
//   assembly : parts in place with component models (view only)
//   none     : nothing; for scratch files that `include` this file
// fastener: "tapping" | "insert" — the two spine holes
//   tapping : 2.5 mm holes for M3 self-tapping screws
//   insert  : 4.0 mm holes for M3 heat-set inserts
//
// Worn orientation, viewed from the front (the radar side):
//   +Y is up (the clip hooks over the band there), USB-C is in the -Y wall.
//   Radar and XIAO are at -X, the cell is at +X, the spine is between them.
// Origin: outer front face at z = 0, centred on X and Y. The lid is at +Z.
// Units: millimetres.

part = "all";
fastener = "insert";
// Turn the radar bay 90 degrees if the wide beam axis needs it.
radar_rotated = false;
// Clip: space for the band, and arm length from the bend to the tip.
// The gap must not be less than the fabric thickness (PETG creeps under load).
clip_gap = 2.40;
clip_arm_len = 28.50;

/* [Hidden] */
$fn = 48;
eps = 0.01;

// --- Components (see SPEC.md section 2) ---
radar_pcb_w = 26.00;
radar_pcb_h = 30.00;
radar_z = 2.70;
// Estimate, not measured. The outer radar bay corners use this radius.
radar_corner_r = 1.50;
radar_w = radar_rotated ? radar_pcb_h : radar_pcb_w;
radar_h = radar_rotated ? radar_pcb_w : radar_pcb_h;

xiao_w = 18.05;
xiao_h = 21.05;
xiao_pcb_t = 1.00;
xiao_board_z = 3.00;
xiao_usb_z = 4.50;
xiao_fit = 0.30;
// Reset button. Estimates, not measured: centre from the board centre line
// (toward the spine), centre from the USB-end edge, top above the board bottom.
xiao_reset_x = 6.40;
xiao_reset_y = 1.50;
xiao_reset_z = 2.00;
xiao_can_y = 5.00; // the shield can starts here, from the USB-end edge

usb_shell_w = 8.94;
usb_shell_h = 3.26;
usb_shell_r = 1.30;
usb_clear = 0.25;
usb_past_edge = 0.20;
usb_plug_w = 12.50;
usb_plug_h = 7.00;

batt_x = 20.50;
batt_y = 27.50;
batt_z = 8.25;
batt_corner_r = 0.50;
batt_clear = 0.40; // cell to lid; never less
batt_side_fit = 0.30;
batt_lead_space = 2.00; // above the cell, for the leads

// --- Case ---
wall = 1.40;
window_t = 0.80; // radar window; see SPEC.md section 3
batt_front_t = 1.20; // front wall over the cell
corner_r = 5.00;
edge_chamfer = 1.00;
fit = 0.40; // total, radar and carrier in their bay
min_air_gap = 1.00; // antenna face to window

lid_t = 1.60;
lid_chamfer = 0.80;
ring_w = 0.80;
ring_z = 1.00;
ring_clear = 0.15;
detent = 0.25;

carrier_floor = 0.40;
carrier_clear = 0.10; // carrier top to lid

pad_w = 1.40;
pad_len = 5.00;
pad_y = 8.00;

web_t = 1.00; // spine side walls
boss_y = 10.00;
notch_w = 6.00;
notch_z = 3.50;

groove_z = 0.20;
groove_w = 0.60;
strip_w = 16.00;
strip_h = 24.00;

led_d = 2.00;
led_wall = 0.40;

// Reset pin hole in the lid, with a guide tube on the inside.
reset_d = 1.50;
reset_tube_wall = 0.60;
reset_tube_clear = 0.70; // tube end to the button

// Clip (see SPEC.md section 7). It prints on its side.
clip_w = 16.00;
clip_base_t = 2.00;
clip_arm_t0 = 2.20; // arm at the bend
clip_arm_t1 = 1.40; // arm at the tip
clip_flare = 1.50;
clip_flare_a = 30;
clip_lip = 0.60;
clip_rib = 0.40;
clip_edge = 0.40; // chamfer on the two bed-side edges, in 0.2 steps
clip_open = 2.00; // arm opening for the strain check
clip_max_strain = 0.015;
tether_d = 2.50;

// M3
m3_head_d = 6.00;
m3_clear = 3.40;
m3_tap_d = 2.50;
m3_tap_z = 6.00;
m3_insert_d = 4.00;
m3_insert_z = 6.00;

assert(fastener == "insert" || fastener == "tapping", "fastener must be \"insert\" or \"tapping\"");

function pilot_d() = fastener == "insert" ? m3_insert_d : m3_tap_d;
function pilot_z() = fastener == "insert" ? m3_insert_z : m3_tap_z;
spine_w = fastener == "insert" ? 6.40 : 5.00;

// --- Derived layout ---
inner_r = corner_r - wall;
// A part with corner radius rc fits a bay corner of radius r when its
// margin to both walls is at least (r - rc) * (1 - 1/sqrt(2)).
function corner_margin(rc, r = inner_r) = max(0, (r - rc) * (1 - 1 / sqrt(2)));

// The outer radar bay corners are not rounder than the board corners.
radar_bay_r = min(inner_r, radar_corner_r);
radar_margin = max(fit / 2, corner_margin(radar_corner_r, radar_bay_r));
// The cell must also clear the lid ring.
batt_margin = max(batt_side_fit, corner_margin(batt_corner_r), ring_w + ring_clear + 0.15);

inner_h = max(radar_h + 2 * radar_margin, batt_margin + batt_y + batt_lead_space);
inner_w = radar_margin + radar_w + fit / 2 + spine_w + batt_side_fit + batt_x + batt_margin;
outer_w = inner_w + 2 * wall;
outer_h = inner_h + 2 * wall;

x_left = -inner_w / 2;
radar_cx = x_left + radar_margin + radar_w / 2;
spine_x0 = radar_cx + radar_w / 2 + fit / 2;
spine_cx = spine_x0 + spine_w / 2;
batt_x0 = spine_x0 + spine_w;
cell_cx = batt_x0 + batt_side_fit + batt_x / 2;
cell_cy = -inner_h / 2 + batt_margin + batt_y / 2;

carrier_z = carrier_floor + xiao_usb_z + 0.10;
shell_z = max(
  window_t + min_air_gap + radar_z + carrier_z + carrier_clear,
  batt_front_t + batt_z + batt_clear
);
air_gap = shell_z - window_t - radar_z - carrier_z - carrier_clear;
z_radar = window_t + air_gap;
z_carrier = z_radar + radar_z;

assert(air_gap >= min_air_gap - eps, "air gap to the radar window is too small");
assert(shell_z - batt_front_t - batt_z >= batt_clear - eps, "the lid is too close to the cell");

// XIAO: parts toward the lid, board edge against the -Y wall.
xiao_cx = radar_cx;
xiao_y0 = -inner_h / 2;
z_xiao = z_carrier + carrier_floor;
usb_z_mid = z_xiao + xiao_pcb_t + usb_shell_h / 2;
usb_slot_w = usb_shell_w + usb_clear;
usb_slot_z0 = usb_z_mid - (usb_shell_h + usb_clear) / 2;
xiao_post_z = shell_z - (z_xiao + xiao_board_z) - 0.10;
reset_cx = xiao_cx + xiao_reset_x;
reset_cy = xiao_y0 + xiao_reset_y;
reset_tube_z = shell_z - (z_xiao + xiao_reset_z) - reset_tube_clear;

clip_base_y0 = -boss_y - 5;
// Strain at the arm root when the tip opens by clip_open (beam formula).
clip_strain = 3 * clip_open * clip_arm_t0 / (2 * clip_arm_len * clip_arm_len);
assert(clip_strain <= clip_max_strain, "the clip arm is too short or too thick");
// The longest screw that does not touch the bottom of the spine hole.
clip_screw_max = clip_base_t + lid_t + pilot_z();

module rounded_rect(size, r) {
  rr = max(0.05, min(r, size[0] / 2 - eps, size[1] / 2 - eps));
  hull()
    for (sx = [-1, 1], sy = [-1, 1])
      translate([sx * (size[0] / 2 - rr), sy * (size[1] / 2 - rr)])
        circle(r = rr);
}

// Extrusion with a chamfer on the z = 0 edge (the bed side).
module chamfered_slab(size, r, h, c) {
  hull() {
    linear_extrude(height = eps)
      rounded_rect([size[0] - 2 * c, size[1] - 2 * c], r - c);
    translate([0, 0, c])
      linear_extrude(height = h - c)
        rounded_rect(size, r);
  }
}

// The part of the inner profile between x0 and x1, from z0 to the top.
module bay(x0, x1, z0, r = inner_r) {
  intersection() {
    translate([0, 0, z0])
      linear_extrude(height = shell_z - z0 + eps)
        rounded_rect([inner_w, inner_h], r);
    translate([x0, -outer_h, 0])
      cube([x1 - x0, 2 * outer_h, shell_z + 1]);
  }
}

module boss_positions() {
  for (y = [-boss_y, boss_y])
    translate([spine_cx, y])
      children();
}

// USB-C slot and plug recess, in shell coordinates. The lid uses it also.
module usb_cuts() {
  // Slot, open to the lid: the wall over the connector would be a sliver.
  translate([xiao_cx, -outer_h / 2 + wall / 2, 0])
    hull() {
      for (sx = [-1, 1])
        translate([sx * (usb_slot_w / 2 - usb_shell_r), 0, usb_slot_z0 + usb_shell_r])
          rotate([90, 0, 0])
            cylinder(r = usb_shell_r, h = wall + 1, center = true);
      translate([0, 0, shell_z + lid_t])
        cube([usb_slot_w, wall + 1, eps], center = true);
    }
  // Recess for the plug body. It leaves window_t of wall at the slot.
  translate([xiao_cx - usb_plug_w / 2, -outer_h / 2 - 1, usb_z_mid - usb_plug_h / 2])
    cube([usb_plug_w, 1 + wall - window_t, usb_plug_h]);
}

module shell() {
  cell_top = cell_cy + batt_y / 2;
  difference() {
    chamfered_slab([outer_w, outer_h], corner_r, shell_z, edge_chamfer);

    bay(x_left - 1, spine_x0, window_t, radar_bay_r); // radar and XIAO
    bay(batt_x0, inner_w, batt_front_t); // cell

    // Wire channel in the spine, between the two webs. The bosses stay.
    difference() {
      bay(spine_x0 + web_t, batt_x0 - web_t, batt_front_t);
      translate([0, 0, batt_front_t - 1])
        linear_extrude(height = shell_z + 2)
          boss_positions()
            circle(d = spine_w);
    }
    // Wire notch across the spine, cell to XIAO.
    translate([spine_x0 - eps, -notch_w / 2, shell_z - notch_z])
      cube([spine_w + 2 * eps, notch_w, notch_z + eps]);

    boss_positions()
      translate([0, 0, shell_z - pilot_z()])
        cylinder(d = pilot_d(), h = pilot_z() + eps);

    usb_cuts();

    // Thin spot for the XIAO LED, from the inside of the -Y wall.
    translate([xiao_cx + usb_plug_w / 2 + led_d / 2 + 0.8, -inner_h / 2 + eps, usb_z_mid])
      rotate([90, 0, 0])
        cylinder(d = led_d, h = wall - led_wall + eps);

    // Front details, one layer deep. The front prints on the bed.
    translate([radar_cx, 0, -eps])
      linear_extrude(height = groove_z + eps)
        difference() {
          rounded_rect([radar_w - 2, radar_h - 2], 2.5);
          rounded_rect([radar_w - 2 - 2 * groove_w, radar_h - 2 - 2 * groove_w], 2.5 - groove_w);
        }
    translate([cell_cx, 0, -eps])
      linear_extrude(height = groove_z + eps)
        rounded_rect([strip_w, strip_h], 3);
  }

  // Radar seat: four pads under the board edges give the air gap.
  for (y = [-pad_y, pad_y]) {
    translate([x_left - eps, y - pad_len / 2, window_t - eps])
      cube([radar_margin + pad_w, pad_len, air_gap + eps]);
    translate([spine_x0 - fit / 2 - pad_w, y - pad_len / 2, window_t - eps])
      cube([fit / 2 + pad_w + eps, pad_len, air_gap + eps]);
  }

  // Stop ribs keep the cell out of the lead space.
  for (sx = [-1, 1])
    translate([cell_cx + sx * (batt_x / 2 - 3.0) - 3.0, cell_top + batt_side_fit, batt_front_t - eps])
      cube([6.0, 1.0, 3.0]);
}

// Local z = 0 is the inside face. The ring goes down into the shell.
module lid() {
  difference() {
    union() {
      translate([0, 0, lid_t])
        mirror([0, 0, 1])
          chamfered_slab([outer_w, outer_h], corner_r, lid_t, lid_chamfer);

      // Step ring inside the walls. It is a ring, not a plate.
      difference() {
        translate([0, 0, -ring_z])
          linear_extrude(height = ring_z + eps) {
            difference() {
              rounded_rect([inner_w - 2 * ring_clear, inner_h - 2 * ring_clear], inner_r - ring_clear);
              rounded_rect(
                [inner_w - 2 * (ring_clear + ring_w), inner_h - 2 * (ring_clear + ring_w)],
                inner_r - ring_clear - ring_w
              );
            }
          }
        // Gaps for the spine ends and for the USB-C connector.
        translate([spine_x0 - 0.3, -outer_h, -ring_z - 1])
          cube([spine_w + 0.6, 2 * outer_h, ring_z + 1 + eps]);
        translate([xiao_cx - usb_plug_w / 2, -outer_h / 2, -ring_z - 1])
          cube([usb_plug_w, wall + ring_w + 1, ring_z + 1 + eps]);
        // No ring over the cell: the ring arc comes inside the cell corners.
        translate([cell_cx, cell_cy, -ring_z - 1])
          linear_extrude(height = ring_z + 1 + eps)
            offset(delta = 0.25)
              rounded_rect([batt_x, batt_y], batt_corner_r);
      }

      // Detent bumps on the outer face of the ring at the short ends.
      for (sx = [-1, 1])
        translate([sx * (inner_w / 2 - ring_clear), 0, -ring_z / 2])
          scale([detent / 0.5, 3, 1])
            sphere(d = 1.0, $fn = 24);

      // Post holds the XIAO down on its shield can.
      translate([xiao_cx, xiao_y0 + xiao_h * 0.6, -xiao_post_z])
        cylinder(d = 3.5, h = xiao_post_z + eps);

      // Guide tube for the reset pin.
      translate([reset_cx, reset_cy, -reset_tube_z])
        cylinder(d = reset_d + 2 * reset_tube_wall, h = reset_tube_z + eps, $fn = 32);
    }

    // Reset pin hole, with a chamfer on the outside.
    translate([reset_cx, reset_cy, 0]) {
      translate([0, 0, -reset_tube_z - 1])
        cylinder(d = reset_d, h = reset_tube_z + lid_t + 2, $fn = 32);
      translate([0, 0, lid_t - 0.4])
        cylinder(d1 = reset_d, d2 = reset_d + 0.8, h = 0.4 + eps, $fn = 32);
    }

    boss_positions()
      translate([0, 0, -ring_z - 1])
        cylinder(d = m3_clear, h = lid_t + ring_z + 2);

    translate([0, 0, -shell_z])
      usb_cuts();

    // "UP" mark, one layer deep. The outside prints on the bed.
    translate([cell_cx, inner_h / 2 - 9, lid_t - groove_z]) {
      linear_extrude(height = groove_z + eps)
        text("UP", size = 5, halign = "center", valign = "top");
      translate([0, 1.5, 0])
        linear_extrude(height = groove_z + eps)
          polygon([[-3, 0], [3, 0], [0, 4]]);
    }
  }
}

// Sits on the back of the radar. Local z = 0 is the bottom of the floor,
// local origin is the centre of the radar bay.
module carrier() {
  cw = radar_w;
  ch = radar_h;
  pocket_w = xiao_w + xiao_fit;
  pocket_y1 = xiao_y0 + xiao_h + xiao_fit; // +Y end of the XIAO, shell coords
  side_x = pocket_w / 2;
  rebate = ring_clear + ring_w + 0.25 - radar_margin;
  top_z = carrier_z;

  difference() {
    linear_extrude(height = carrier_z)
      rounded_rect([cw, ch], radar_corner_r);

    // XIAO pocket, open to the lid and to the -Y wall.
    translate([-pocket_w / 2, -ch, carrier_floor])
      cube([pocket_w, ch + pocket_y1, carrier_z]);

    // Floor window under the battery pads of the XIAO.
    translate([-5, -ch / 2 + 5, -eps])
      cube([10, 10, carrier_floor + 2 * eps]);

    // Wire bay on the outer side, from the radar pads to the XIAO edge pads.
    translate([-cw, -ch / 2 + 6, -eps])
      cube([cw - side_x + eps, 10, carrier_z + 2 * eps]);

    // Wire notch toward the spine, in line with the spine notch.
    translate([side_x - eps, -notch_w / 2, top_z - notch_z + carrier_clear])
      cube([cw, notch_w, notch_z]);

    // Rebate for the lid ring along the three outer edges.
    if (rebate > 0)
      translate([0, 0, top_z - ring_z - 0.25])
        linear_extrude(height = ring_z + 1)
          difference() {
            square([cw + 2, ch + 2], center = true);
            // The kept area follows the ring arc at the outer corners.
            translate([rebate / 2 + 3, 0])
              rounded_rect([cw - rebate + 6, ch - 2 * rebate], inner_r - radar_margin - rebate);
          }
  }
}

// 2D profile: x is the worn Y, y is the distance from the lid outer face.
module clip_profile() {
  bt = clip_base_t;
  g = clip_gap;
  bend_r = (bt + g + clip_arm_t0) / 2;
  yc = outer_h / 2 - bend_r; // the bend is level with the top of the case
  y_tip = yc - clip_arm_len;
  y_lip = y_tip + clip_lip + 0.7;
  tab_y = yc + g / 2 + 1.5 + tether_d / 2;

  difference() {
    union() {
      difference() {
        union() {
          hull() {
            translate([clip_base_y0 + bt / 2, bt / 2])
              circle(d = bt);
            translate([yc - 1, 0])
              square([1, bt]);
          }
          // Bend and tether tab.
          hull() {
            translate([yc, bend_r])
              circle(r = bend_r);
            translate([tab_y, bend_r])
              circle(r = tether_d / 2 + 1.5);
          }
          // Arm, with a taper to the tip.
          polygon([
            [yc, bt + g],
            [yc, bt + g + clip_arm_t0],
            [y_tip, bt + g + clip_arm_t1],
            [y_tip, bt + g],
          ]);
          // Flared tip.
          hull() {
            translate([y_tip, bt + g + clip_arm_t1 / 2])
              circle(d = clip_arm_t1);
            translate([
              y_tip - clip_flare * cos(clip_flare_a),
              bt + g + clip_arm_t1 / 2 + clip_flare * sin(clip_flare_a),
            ])
              circle(d = clip_arm_t1);
          }
        }
        // Band slot. The inside of the bend is a full half circle.
        hull() {
          translate([yc, bt + g / 2])
            circle(d = g);
          translate([y_tip - 10, bt])
            square([1, g]);
        }
      }
      // Lip on the arm, 45 degree faces.
      polygon([
        [y_lip - clip_lip - 0.2, bt + g + eps],
        [y_lip - 0.2, bt + g - clip_lip],
        [y_lip + 0.2, bt + g - clip_lip],
        [y_lip + clip_lip + 0.2, bt + g + eps],
      ]);
      // Ribs on the base. The steep face is toward the bend, so the band
      // goes in easily and the unit does not move up.
      for (y = [-6.5:2.9:5.2])
        translate([y, bt - eps])
          polygon([[0, 0], [1.6, clip_rib + eps], [1.6, 0]]);
    }
    translate([tab_y, bend_r])
      circle(d = tether_d);
  }
}

// Print orientation: the profile is on the bed. Local x is the worn Y,
// local y is the distance from the lid, local z is across the width.
module clip() {
  step = 0.2;
  n = round(clip_edge / step);
  cs_h = (m3_head_d - m3_clear) / 2;

  difference() {
    union() {
      translate([0, 0, clip_edge - eps])
        linear_extrude(height = clip_w - 2 * clip_edge + 2 * eps, convexity = 10)
          clip_profile();
      for (i = [0:n - 1], end = [0, 1])
        translate([0, 0, end == 0 ? i * step : clip_w - (i + 1) * step])
          linear_extrude(height = step, convexity = 10)
            offset(delta = -(clip_edge - i * step))
              clip_profile();
    }
    for (y = [-boss_y, boss_y])
      translate([y, 0, clip_w / 2])
        rotate([-90, 0, 0]) {
          translate([0, 0, -eps])
            cylinder(d = m3_clear, h = clip_base_t + 2 * eps);
          // Countersink for the screw head.
          translate([0, 0, clip_base_t - cs_h])
            cylinder(d1 = m3_clear, d2 = m3_head_d, h = cs_h + eps);
          // The screw and the driver go through the arm.
          translate([0, 0, clip_base_t + clip_gap / 2])
            cylinder(d = m3_head_d + 0.5, h = 20);
        }
  }
}

module place_clip() {
  translate([spine_cx - clip_w / 2, 0, shell_z + lid_t])
    rotate([90, 0, 90])
      children();
}

module place_lid() {
  translate([0, 0, shell_z])
    children();
}

module place_carrier() {
  translate([radar_cx, 0, z_carrier])
    children();
}

// --- Component models, in shell coordinates (for checks and the assembly) ---
module radar_model() {
  translate([radar_cx, 0, z_radar])
    linear_extrude(height = radar_z)
      rounded_rect([radar_w, radar_h], radar_corner_r);
}

module xiao_model() {
  translate([xiao_cx - xiao_w / 2, xiao_y0, z_xiao])
    cube([xiao_w, xiao_h, xiao_pcb_t]);
  translate([xiao_cx - xiao_w / 2, xiao_y0 + xiao_can_y, z_xiao])
    cube([xiao_w, xiao_h - xiao_can_y, xiao_board_z]);
  translate([reset_cx - 1.0, reset_cy - 0.8, z_xiao])
    cube([2.0, 1.6, xiao_reset_z]);
  translate([xiao_cx - usb_shell_w / 2, xiao_y0 - usb_past_edge, z_xiao + xiao_pcb_t])
    cube([usb_shell_w, 7.3, usb_shell_h]);
}

module cell_model() {
  translate([cell_cx, cell_cy, batt_front_t])
    linear_extrude(height = batt_z)
      rounded_rect([batt_x, batt_y], batt_corner_r);
}

module assembly() {
  color("DimGray", 0.5) shell();
  color("Gray", 0.4) place_lid() lid();
  color("Orange") place_carrier() carrier();
  color("Tomato") place_clip() clip();
  color("Green") radar_model();
  color("Blue") xiao_model();
  color("Silver") cell_model();
}

module plate_all() {
  gap = 8;
  shell();
  translate([0, outer_h + gap, lid_t])
    rotate([180, 0, 0])
      lid();
  translate([outer_w / 2 + gap + radar_w / 2, 0, 0])
    carrier();
  translate([-outer_w / 2 - gap - outer_h / 2 - 6, 0, 0])
    clip();
}

if (part == "shell")
  shell();
else if (part == "lid")
  translate([0, 0, lid_t])
    rotate([180, 0, 0])
      lid();
else if (part == "carrier")
  carrier();
else if (part == "clip")
  clip();
else if (part == "all")
  plate_all();
else if (part == "assembly")
  assembly();
else
  assert(part == "none", "part must be shell|lid|carrier|clip|all|assembly|none");

echo(str("outer = ", outer_w, " x ", outer_h, " x ", shell_z + lid_t));
echo(str("shell_z = ", shell_z, "  air_gap = ", air_gap));
echo(str("radar_margin = ", radar_margin, "  batt_margin = ", batt_margin));
echo(str("spine x = ", spine_cx, "  screws y = +/-", boss_y, "  fastener = ", fastener));
echo(str("usb z = ", usb_z_mid, "  slot from z = ", usb_slot_z0));
echo(str("clip strain = ", clip_strain, "  clip screw, max length = ", clip_screw_max));
