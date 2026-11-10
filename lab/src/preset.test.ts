import { describe, expect, it } from "vitest";
import { GOTCHA_SIX_PRESET, encodeCommandLine } from "./preset";

describe("preset", () => {
  it("includes speed mode and range 25", () => {
    expect(GOTCHA_SIX_PRESET).toContain("setRunApp 1");
    expect(GOTCHA_SIX_PRESET).toContain("setRange 0.6 25");
    expect(GOTCHA_SIX_PRESET).toContain("setUartOutput 2 1 1 1");
  });

  it("encodes CRLF command lines", () => {
    const bytes = encodeCommandLine("sensorStop");
    expect(new TextDecoder().decode(bytes)).toBe("sensorStop\r\n");
  });
});
