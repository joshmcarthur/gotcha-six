import type { TimedLine } from "./session";

/** Synthetic approaching `$DFDMD` lines plus some IMU lines, `stepMs` apart. */
export function simulateApproach(steps = 20, stepMs = 100): TimedLine[] {
  const lines: TimedLine[] = [];
  for (let i = 0; i < steps; i++) {
    const t = i * stepMs;
    const dist = 25 - i * (20 / steps);
    const speed = 0.5 + i * 0.05;
    const energy = 1000 + i * 50;
    lines.push({ t, line: `$DFDMD,1,1,${dist.toFixed(3)},${speed.toFixed(3)},${energy}, , *` });
    if (i % 3 === 0) {
      lines.push({ t, line: "$GSIMU,0.0,0.1,9.8,0.01,0.0,-0.01*" });
    }
  }
  lines.push({ t: steps * stepMs, line: "$DFDMD,0, , , , , , *" });
  return lines;
}
