/** Host-side C4001 preset: commands and encode live in gotcha-six-core (WASM). */
import {
  presetGapMs,
  radarPresetCommands,
  encodeCommandLine as wasmEncodeCommandLine,
} from "./wasm/gotcha_six_core.js";

/** Current preset command list from core. Requires WASM init first. */
export function gotchaSixPreset(): string[] {
  return radarPresetCommands();
}

export async function sendPreset(
  writeLine: (line: string) => Promise<void>,
  gapMs = presetGapMs(),
): Promise<void> {
  for (const cmd of radarPresetCommands()) {
    await writeLine(cmd);
    await new Promise((r) => setTimeout(r, gapMs));
  }
}

export function encodeCommandLine(cmd: string): Uint8Array {
  return wasmEncodeCommandLine(cmd);
}
