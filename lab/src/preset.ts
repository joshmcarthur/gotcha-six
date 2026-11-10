/** Host-side C4001 speed/distance preset for rear awareness. */
export const GOTCHA_SIX_PRESET: string[] = [
  "sensorStop",
  "setRunApp 1",
  "setRange 0.6 25",
  "setMicroMotion 1",
  "setThrFactor 5",
  "setUartOutput 2 1 1 1",
  "saveConfig",
  "sensorStart",
];

export async function sendPreset(
  writeLine: (line: string) => Promise<void>,
  gapMs = 150,
): Promise<void> {
  for (const cmd of GOTCHA_SIX_PRESET) {
    await writeLine(cmd);
    await new Promise((r) => setTimeout(r, gapMs));
  }
}

export function encodeCommandLine(cmd: string): Uint8Array {
  const trimmed = cmd.replace(/\r?\n$/, "");
  return new TextEncoder().encode(`${trimmed}\r\n`);
}
