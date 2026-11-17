# Enclosure specification

Read this before any work on `hardware/enclosure.scad`. Units are millimetres.

Each value has a source:

- **M** — measured by Josh on the real part (2026-11-12).
- **F** — taken from `hardware/enclosure.scad` as it was on 2026-11-12. Not measured again.
- **D** — from a vendor document or a published guide.
- **A** — an assumption. The first print must confirm it.

## 1. Purpose and wear

A rear-facing radar unit for a runner. It clips to the back of a cap or to the centre back of the waistband of running shorts.

Consequences:

- The radar window faces away from the body.
- The clip hooks over the top edge of a band. The body of the unit hangs below the hook.
- The clip arm is against skin on shorts. It must be wide, thin and round, with no screw heads.
- Sweat and rain come from above. No opening at the top.
- Low mass and small depth are the primary goals. Bounce load is mass multiplied by distance from the fabric.

## 2. Components

### C4001 radar (DFRobot SEN0609)

| Property | Value | Source |
| --- | --- | --- |
| Width | 25.94 | M |
| Height | 29.96 | M |
| Depth, total | 2.7 | M |
| Corners | Round. Radius about 1.5 (estimate by Josh, 2026-11-13, after the first print: the board did not go into bay corners of radius 3.6) | A |
| Faces | One flat face with the antenna patches. All parts and the header pads on the other face | M |
| Board thickness | about 1.0 | A |
| Mounting holes | Two, 22.0 apart, 2.0 from the header edge | F |
| Beam | about 100° × 40°. Wide axis must be horizontal when worn | D (README) |
| Which board side is the wide axis | Not known | open |
| Supply | 3.3 V, about 90 mA | D (README) |

### Seeed XIAO nRF52840 Sense

| Property | Value | Source |
| --- | --- | --- |
| Width | 18.05 | M |
| Length, without USB-C | 21.05 | M |
| USB-C past the board edge | 0.2 | M |
| Depth, without USB-C | 3.0 | M |
| Depth, with USB-C | 4.5 | M |
| USB-C metal shell | 8.94 × 3.26, corner radius 1.3 | F |
| BLE antenna | At the end opposite the USB-C | D |
| Battery pads | On the bottom face | D |

### Battery

| Cell | Length | Width | Depth | Status |
| --- | --- | --- | --- | --- |
| A, 500 mAh | 27.5 | 20.5 | 8.25 | Selected |
| B, 800 mAh | 40.0 | 17.8 | 9.8 | Not used. Too long for the radar footprint and deeper |

All battery values are M.

### Reference: the existing commercial case

Inner 26.87 × 30.8. Outer 34.04 × 38.07 × 15.22. All M.

## 3. Hard constraints

1. **Do not compress the cell.** Keep 0.4 clearance between the cell and the lid. No lid feature may enter the cell volume.
2. **Radar window.** For 24 GHz in plastic, a wall of 1/8 wavelength in the material or less (below about 0.9) or a half wavelength (about 3.6) is good. A quarter wavelength (about 1.8) gives the most reflection. Use 0.8. Keep an air gap between the antenna face and the window; 1.0 is the minimum used here (the guides prefer 6.2, which the depth goal does not permit). (D)
3. **No metal and no carbon in front of the radar.** No reflective tape, no screws, no carbon-filled or carbon-black-heavy filament over the window. (D)
4. **USB-C plug access.** The receptacle face is 0.2 past the board edge. A plug body is larger than the metal shell, so a slot through a thick wall stops the plug. Leave a recess of about 12.5 × 7 around the slot with 0.8 of wall, or keep the wall at the slot to 0.8.
5. **USB-C not at the top.** Bottom or side only.
6. **BLE antenna.** Do not put the cell or the radar ground plane on both faces of the XIAO antenna end.
7. **Insulate the XIAO from the back of the radar.** A printed floor of 0.4 or tape.
8. **Wide beam axis horizontal** in the worn orientation.

## 4. Print constraints

- Material: PETG is the baseline. PETG creeps under a constant load, so the clip must not be under load when it is on the fabric, and inside corners of the clip must be round.
- The shell prints front face down. The front must be flat: recesses of one layer (0.2) are acceptable; raised features on the front are not.
- Use chamfers, not fillets, on edges that touch the bed.
- The lid prints flat with no supports. This is the reason for a separate clip.
- The clip prints on its side, so the layers follow the hook profile.
- Fit clearances that the current file uses: 0.4 around the radar, 0.3 around the XIAO, 0.4 above the cell. (F)

## 5. Fasteners

M3. Values from the file (F): clearance hole 3.4; countersunk head 6.0 (the clip countersink uses 6.0 at 90°); self-tapping pilot 2.5, depth 6.0; heat-set insert hole 4.0, depth 6.0. The insert hole accepts brass heat-set inserts from 3 to 5.7 long. The `fastener` parameter selects `insert` (current default) or `tapping`.

## 6. Depth budget

| Stack | Sum |
| --- | --- |
| Battery half: front 1.2 + cell 8.25 + clearance 0.4 | 9.85 |
| Radar half: window 0.8 + air gap 1.25 + radar 2.7 + carrier 5.0 + clearance 0.1 | 9.85 |
| Carrier: floor 0.4 + XIAO 4.5 + 0.1 | 5.0 |
| Case: shell 9.85 + lid 1.6 | 11.45 |
| Clip: base 2.0 + gap 2.4 + arm 2.2 | 6.6 |

The battery half sets the shell depth. The front over the cell is 1.2 to protect the cell. The radar half gets the difference as air gap. The file computes these values and has an `assert` for the air gap and for the cell clearance.

Radar plus XIAO (7.2) and the cell (8.25) are almost equal in depth. This is why they sit side by side.

## 7. Selected design (2026-11-12)

Layout B, side by side. Viewed from the front, clip at the top:

```
 ┌──────────────────┬──┬──────────────┐
 │  radar (front)   │sp│              │
 │  carrier + XIAO  │in│   battery    │
 │  (behind radar)  │e │              │
 └───────USB────────┴──┴──────────────┘
```

As built in the file (2026-11-17): 57.5 × 33.4 × 11.45 without the clip (56.1 wide with `fastener = "tapping"`). Shell, lid and carrier are 9.4 cm³, about 12 g in PETG. With `radar_rotated = true` the width is 61.5.

Parts:

| Part | Function | Print |
| --- | --- | --- |
| `shell` | Front, walls, spine with two screw bosses and a wire notch, radar pads | Front face down |
| `lid` | Flat 1.6 plate with a step ring inside the walls and a post that holds the XIAO down | Outside face down |
| `carrier` | Frame on the back of the radar with a 0.4 floor and the XIAO pocket | Floor down |
| `clip` | J-hook with a base strip along the spine | On its side |

- Two M3 countersunk screws go through the clip base and the lid into the spine bosses. The clip load goes into the spine. The file prints the maximum screw length: 9.6 with `insert` and with `tapping`. Use M3 × 8.
- The radar has no screws. It sits on 1.0 pads, and the carrier and lid clamp it.
- The two outer radar bay corners have the radius `radar_corner_r` (1.5), not the case inner radius (3.6). The radar margin stays 0.2 and the outline does not change. The wall at these two corners is 0.53 at its thinnest point, and 0.33 in the one layer from z = 0.8 to 1.0 (front chamfer).
- No battery shim. The bay is the size of the cell. Two stop ribs keep the cell out of the lead space at the top.
- The XIAO has its parts toward the lid and its board on the carrier floor. Its board edge is against the bottom wall, so the wall takes the pull of the plug and the pocket end takes the push. (A: this orientation is a design choice, not a measurement.)
- The USB-C slot is a U notch that is open to the lid, because the wall over the connector would be 0.2 high.
- The lid ring has gaps at the spine ends, at the USB-C connector, and over the cell. The ring arc comes inside the cell corners, so a full ring would press on the cell.
- The carrier has a rebate for the lid ring on its three outer edges.
- The carrier floor sits on the tallest parts on the back of the radar. (A: those parts can take a light load.)

Selected touches:

- Pebble outline: corner radius 5 in the plan view, 1.0 chamfers on the front and back edges. The radar bay does not follow this radius at its outer corners (see above), so the board corner radius adds no width. The cell bay corners and the lid ring keep the case inner radius.
- Lens outline: a 0.2 groove on the front that traces the radar window. A raised rim was rejected because the shell prints front face down.
- Reflective strip recess: 0.2 deep on the front of the battery half. Never over the radar.
- LED window: a 0.4 thin spot in the bottom wall next to the USB slot.
- Tether hole: 2.5, in a tab at the top of the clip. A case corner hole was rejected because it adds width. Risk: if the clip breaks off the case, the cord does not hold the case.
- Step joint: the lid ring goes 1.0 into the shell, with two detent bumps at the short ends.
- "UP" mark on the outside of the lid.
- Reset pin hole in the lid, 1.5 diameter, above the XIAO reset button. It accepts a paper clip or a SIM pin. A guide tube (2.7 outside, 2.0 long) on the inside aims the pin and stops 0.7 above the button. The hole is 1.25 from the clip base, so it stays open with the clip on (0.55 with `fastener = "tapping"`).

Clip, as built in the file (2026-11-17): 16 wide, 6.6 deep, 2.1 cm³, about 2.6 g in PETG. The top of the bend is level with the top of the case. The tether tab is 3.4 above the case. The tip is 0.4 below the case.

- Base 2.0 with five sawtooth ribs, 0.4 high. The steep face is toward the bend: the band goes in easily, and the unit does not move up.
- Bend: the inside is a full half circle with radius `clip_gap` / 2.
- Arm: 2.2 at the bend, 1.4 at the tip, length `clip_arm_len` (28.5). The tip is flared 30° for 1.5. A 0.6 lip with 45° faces is 1.3 from the tip. The gap at the lip is 1.8.
- Two 6.5 holes in the arm, in line with the screws. The screw head (6.0) and the driver go through them, because the gap is smaller than the screw length. The screw heads are in countersinks in the base, not on the skin side. 0.7 of base stays below each countersink. The ribs are between the two countersinks.
- The two bed-side edges have a 0.4 chamfer made of 0.2 steps, one step for each layer.
- The file has an `assert`: the strain at the arm root for a 2.0 opening must be 1.5% or less. The value is 0.81%. (A: the 1.5% limit for PETG is not from a datasheet.)

Clip rules (D: snap-fit guides and published clip designs, 2026-11-13):

- The layers must follow the hook profile. A clip that bends across the layers splits at the root.
- No sharp inside corner at the root.
- Root strain is about `3 × opening × thickness / (2 × length²)`. A longer or thinner arm decreases it.
- The gap must be at least the fabric thickness. The lip and the ribs hold the unit; a squeeze does not, because PETG creeps.
- Lead-in 25° to 35°. A catch face of 45° to 70° can be removed again.
- For a cap, use the same clip on the adjuster strap with a different `clip_gap`.

Risks: the 5.0 hole near the bend is in the area of highest strain. The arm has no stop against too much opening.

Parameters that must stay: `part`, `fastener`, `radar_rotated` (turns the radar bay 90° for the beam axis), `radar_corner_r`, `clip_gap`, `clip_arm_len`.

Corner fit rule: a part with corner radius `rc` fits a bay corner of radius `r` when its margin to both walls is at least `(r - rc) × (1 - 1/√2)`. The file uses this for the radar (with `r` = `radar_bay_r`) and the cell. With a bay radius of 1.5 and a margin of 0.2, a board corner radius down to 0.8 fits.

## 8. Rejected

- **Layout A, one stack** (about 31 × 35 × 19). About twice the bounce load at equal mass, and the cell covers the BLE antenna.
- **Clip as part of the lid.** The lid then needs supports, and the hook layers are in the weak direction.
- **Four lid bosses outside the well.** They added 17.4 to the width.
- **Radar screws into front bosses.** The bosses were in the board space, and screws near the window are metal in front of the antenna.

## 9. Findings from the stacked design (review of 2026-11-12)

Do not repeat these.

- The lid "locate ring" was a solid plate 1.0 deep with 0.4 clearance: it went 0.6 into the cell.
- A well corner radius of `corner_r - wall` (3.6) with shim corners of 1.0 to 1.2 gave an overlap at each corner.
- Radar bosses 4.4 in diameter and as high as the radar layer were in the board space.
- A 9.2 × 3.5 USB slot through a 2.4 wall stops the plug.
- A 1.6 window with the radar in contact is close to the worst thickness.
- Shell plus lid was 22.4 cm³, about 28 g in PETG, for about 17 g of contents (the contents mass is an estimate, not weighed).

## 10. How to check a change

OpenSCAD is at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`. It is not on the PATH.

- Render each part with `-o part.stl -D 'part="shell"'` and look for errors.
- Look at the fit with `-D 'part="assembly"'`.
- Check for overlap with a scratch file outside the repository:

  ```
  include </full/path/hardware/enclosure.scad>
  part = "none";
  intersection() { place_lid() lid(); cell_model(); }
  ```

  Export a binary STL. An empty result means no overlap. The file has `place_lid()`, `place_carrier()`, `radar_model()`, `xiao_model()` and `cell_model()` for this.
- Check each pair: shell, lid and carrier with each other and with each component model. Check `place_clip() clip();` with the lid and with the shell.
- Two results are not zero and are correct: shell with lid is 0.15 mm³ (the detent bumps press 0.1 into the wall), and shell with `xiao_model()` is 0.06 mm³ (the model has square USB corners; the slot corners are round).
- Shell with `radar_model()` gives a few facets with zero volume: the radar touches the top of the pads at z = 2.05. This is correct.
- Do not commit STL or 3MF exports.

## 11. Open questions

- Radar board: corner radius (1.5 is an estimate), board thickness, and which side is the wide beam axis.
- Mass of the radar, XIAO and cell (not weighed).
- XIAO: which face is toward the lid, and where the LEDs are in relation to the bottom wall.
- XIAO reset button: the position is an estimate (6.4 from the board centre line toward the spine, 1.5 from the USB-end edge, top 2.0 above the board bottom). Measure it and correct `xiao_reset_x`, `xiao_reset_y` and `xiao_reset_z`.
- Wire routes between the radar pads, the XIAO and the cell.
- Clip gap for the real waistband and for a cap.

## 12. Later options

- A spring-steel or TPU insert for the clip, if the PETG arm loses grip.
- A cap clip variant, and a concave back with a radius of about 100 for the cap (costs about 1.0 of depth).
- A power switch.
- A rear light in the battery half.

## 13. Reference products

- Garmin Running Dynamics Pod: clips to the centre back of a waistband; retailers list 37.6 × 23.2 × 19.2 and 12 g.
- Nathan StrobeLight clip light: listed at 30 g.
