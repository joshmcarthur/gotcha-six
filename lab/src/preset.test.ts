import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { beforeAll, describe, expect, it } from "vitest";
import { encodeCommandLine, gotchaSixPreset } from "./preset";
import init from "./wasm/gotcha_six_core.js";

describe("preset", () => {
  beforeAll(async () => {
    const wasmPath = join(dirname(fileURLToPath(import.meta.url)), "wasm/gotcha_six_core_bg.wasm");
    await init({ module_or_path: readFileSync(wasmPath) });
  });

  it("includes speed mode and range 25", () => {
    const preset = gotchaSixPreset();
    expect(preset).toContain("setRunApp 1");
    expect(preset).toContain("setRange 0.6 25");
    expect(preset).toContain("setUartOutput 2 1 1 1");
  });

  it("encodes CRLF command lines", () => {
    const bytes = encodeCommandLine("sensorStop");
    expect(new TextDecoder().decode(bytes)).toBe("sensorStop\r\n");
  });
});
