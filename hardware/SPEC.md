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
| Corners | Round. Radius not known. The design must not depend on it: bay corners use a 1.0 radius | M (shape) |
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

M2. Values from the file (F): clearance hole 2.2; head 4.5 × 1.6; self-tapping pilot 1.7, depth 6.0; heat-set insert hole 3.2, depth 4.2. The `fastener` parameter selects `tapping` (current default) or `insert`.

## 6. Depth budget

| Stack | Sum |
| --- | --- |
| Radar half: air gap 1.0 + radar 2.7 + floor 0.4 + XIAO 4.5 | 8.6 |
| Battery half: cell 8.25 + clearance 0.4 | 8.65 |
| Case: window 0.8 + cavity 8.65 + lid 1.6 | 11.05 |
| Clip: base 1.6 + gap 2.4 + arm 2.2 | 6.2 |

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

Target: about 56 × 33 × 11 without the clip, about 17 with the clip, case mass about 10 g in PETG.

Parts:

| Part | Function | Print |
| --- | --- | --- |
| `shell` | Front, walls, spine with two screw bosses and a wire notch, radar pads | Front face down |
| `lid` | Flat 1.6 plate with a step ring inside the walls | Outside face down |
| `carrier` | Frame on the back of the radar with a 0.4 floor and the XIAO pocket | Floor down |
| `clip` | J-hook with a base strip along the spine | On its side |

- Two M2 × 8 countersunk screws go through the clip base and the lid into the spine bosses. The clip load goes into the spine.
- The radar has no screws. It sits on 1.0 pads, and the carrier and lid clamp it.
- The radar bay corners have a 1.0 radius, which fits any board corner radius.
- No battery shim. The bay is the size of the cell.

Selected touches:

- Pebble outline: corner radius 5 in the plan view, 1.0 chamfers on the front and back edges. A radius of 5 fits a board with corners of about 3 with no added width. The board corner radius is not known, so the file must check this fit with an `assert` on a `radar_corner_r` parameter, and add margin if the value is smaller.
- Lens outline: a 0.2 groove on the front that traces the radar window. A raised rim was rejected because the shell prints front face down.
- Reflective strip recess: 0.2 deep on the front of the battery half. Never over the radar.
- LED window: a 0.4 thin spot in the bottom wall next to the USB slot.
- Tether hole: 2.5, in a tab at the top of the clip. A case corner hole was rejected because it adds width. Risk: if the clip breaks off the case, the cord does not hold the case.
- Step joint: the lid ring goes 1.0 into the shell, with two detent bumps at the short ends.
- "UP" mark on the outside of the lid.

Parameters that must stay: `part`, `fastener`, `radar_rotated` (turns the radar bay 90° for the beam axis), clip gap.

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
- Check for overlap: `use <enclosure.scad>` in a scratch file, intersect two placed parts (or a part and a box that models a component), export a binary STL, and compute the volume. Zero volume means no overlap. `use` does not import variables, so repeat the constants in the scratch file.
- Do not commit STL or 3MF exports.

## 11. Open questions

- Radar board: corner radius (Josh is not sure of the value), board thickness, and which side is the wide beam axis.
- Mass of the radar, XIAO and cell (not weighed).
- XIAO: which face is toward the lid, and where the LEDs are in relation to the bottom wall.
- Wire routes between the radar pads, the XIAO and the cell.
- Clip gap for the real waistband and for a cap.

## 12. Later options

- A cap clip variant, and a concave back with a radius of about 100 for the cap (costs about 1.0 of depth).
- A power switch.
- A rear light in the battery half.

## 13. Reference products

- Garmin Running Dynamics Pod: clips to the centre back of a waistband; retailers list 37.6 × 23.2 × 19.2 and 12 g.
- Nathan StrobeLight clip light: listed at 30 g.
