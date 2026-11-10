/** Synthetic approaching `$DFDMD` stream plus optional IMU. */
export function* simulateApproach(steps = 20): Generator<Uint8Array> {
  const enc = new TextEncoder();
  for (let i = 0; i < steps; i++) {
    const dist = 25 - i * (20 / steps);
    const speed = 0.5 + i * 0.05;
    const energy = 1000 + i * 50;
    yield enc.encode(`$DFDMD,1,1,${dist.toFixed(3)},${speed.toFixed(3)},${energy}, , *\r\n`);
    if (i % 3 === 0) {
      yield enc.encode("$GSIMU,0.0,0.1,9.8,0.01,0.0,-0.01*\r\n");
    }
  }
  yield enc.encode("$DFDMD,0, , , , , , *\r\n");
}
