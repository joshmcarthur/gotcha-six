import { DistanceChart } from "./chart";
import { encodeCommandLine, sendPreset } from "./preset";
import { SessionRecorder, type TimedLine, downloadBlob, parseRecording } from "./session";
import { simulateApproach } from "./simulator";
import { WebBluetoothTransport } from "./transports/bluetooth";
import { WebSerialTransport } from "./transports/serial";
import type { RadarTransport } from "./transports/types";
import init, { WasmRadarEngine } from "./wasm/gotcha_six_core.js";

interface EngineOutput {
  kind: string;
  raw: string;
  motion: string;
  closingSpeedMS?: number | null;
  closing_speed_m_s?: number | null;
  detected?: boolean | null;
  count?: number | null;
  id?: number | null;
  distanceM?: number | null;
  distance_m?: number | null;
  speedMS?: number | null;
  speed_m_s?: number | null;
  energy?: number | null;
  accelMS2?: number[] | null;
  accel_m_s2?: number[] | null;
  gyroRadS?: number[] | null;
  gyro_rad_s?: number[] | null;
}

function num(v: number | null | undefined): number | null {
  return typeof v === "number" ? v : null;
}

function requireEl<T extends HTMLElement>(id: string): T {
  const node = document.getElementById(id);
  if (!node) {
    throw new Error(`missing element #${id}`);
  }
  return node as T;
}

const el = {
  status: requireEl("conn-status"),
  log: requireEl("log"),
  distance: requireEl("v-distance"),
  speed: requireEl("v-speed"),
  energy: requireEl("v-energy"),
  motion: requireEl("v-motion"),
  closing: requireEl("v-closing"),
  accel: requireEl("v-accel"),
  gyro: requireEl("v-gyro"),
  cmd: requireEl<HTMLInputElement>("cmd-input"),
  btnUsb: requireEl<HTMLButtonElement>("btn-usb"),
  btnBle: requireEl<HTMLButtonElement>("btn-ble"),
  btnDisconnect: requireEl<HTMLButtonElement>("btn-disconnect"),
  btnSend: requireEl<HTMLButtonElement>("btn-send"),
  btnPreset: requireEl<HTMLButtonElement>("btn-preset"),
  btnRecord: requireEl<HTMLButtonElement>("btn-record"),
  btnStopRecord: requireEl<HTMLButtonElement>("btn-stop-record"),
  btnExportTxt: requireEl<HTMLButtonElement>("btn-export-txt"),
  btnExportCsv: requireEl<HTMLButtonElement>("btn-export-csv"),
  btnSim: requireEl<HTMLButtonElement>("btn-sim"),
  btnReplay: requireEl<HTMLButtonElement>("btn-replay"),
  btnImport: requireEl<HTMLButtonElement>("btn-import"),
  fileImport: requireEl<HTMLInputElement>("file-import"),
  chart: requireEl<HTMLCanvasElement>("chart"),
};

let transport: RadarTransport | null = null;
let engine: WasmRadarEngine | null = null;
const recorder = new SessionRecorder();
const chart = new DistanceChart(el.chart);
let lastReplay: TimedLine[] = [];
const encoder = new TextEncoder();

function setConnected(connected: boolean, label: string): void {
  el.status.textContent = label;
  el.status.classList.toggle("live", connected);
  el.btnDisconnect.disabled = !connected;
  el.btnSend.disabled = !connected;
  el.btnPreset.disabled = !connected;
  el.btnUsb.disabled = connected;
  el.btnBle.disabled = connected;
}

const LOG_MAX_LINES = 500;
let logScrollPending = false;

function appendLog(kind: string, raw: string): void {
  const ts = new Date().toISOString().slice(11, 23);
  const line = document.createElement("div");
  line.innerHTML = `<span class="ts">${ts}</span> <span class="kind-${kind}">[${kind}]</span> ${escapeHtml(raw)}`;
  el.log.appendChild(line);
  while (el.log.childElementCount > LOG_MAX_LINES) {
    el.log.firstElementChild?.remove();
  }
  // A scroll after each line forces a layout each time. Scroll once per frame.
  if (!logScrollPending) {
    logScrollPending = true;
    requestAnimationFrame(() => {
      logScrollPending = false;
      el.log.scrollTop = el.log.scrollHeight;
    });
  }
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function handleOutputs(outputs: EngineOutput[], t: number): void {
  for (const o of outputs) {
    const distance = num(o.distance_m ?? o.distanceM);
    const speed = num(o.speed_m_s ?? o.speedMS);
    const closing = num(o.closing_speed_m_s ?? o.closingSpeedMS);
    const accel = o.accel_m_s2 ?? o.accelMS2 ?? null;
    const gyro = o.gyro_rad_s ?? o.gyroRadS ?? null;

    appendLog(o.kind, o.raw);
    recorder.recordSample({
      raw: o.raw,
      kind: o.kind,
      distance_m: distance,
      speed_m_s: speed,
      energy: o.energy ?? null,
      motion: o.motion,
    });

    if (o.kind === "target") {
      el.distance.textContent = distance == null ? "—" : `${distance.toFixed(3)} m`;
      el.speed.textContent = speed == null ? "—" : `${speed.toFixed(3)} m/s`;
      el.energy.textContent = o.energy == null ? "—" : String(o.energy);
      el.motion.textContent = o.motion;
      el.closing.textContent = closing == null ? "—" : closing.toFixed(3);
      if (distance != null) {
        chart.push(t, distance);
      }
    } else if (o.kind === "presence") {
      el.motion.textContent = o.detected ? "present" : "absent";
    } else if (o.kind === "imu" && accel && gyro) {
      el.accel.textContent = accel.map((v) => v.toFixed(2)).join(", ");
      el.gyro.textContent = gyro.map((v) => v.toFixed(3)).join(", ");
    }
  }
}

function onData(data: Uint8Array): void {
  if (!engine) {
    return;
  }
  const raw = engine.pushBytes(data) as EngineOutput[];
  handleOutputs(raw, performance.now());
}

/** Send timed lines through a fresh engine. The chart shows the full duration. */
function replay(lines: TimedLine[]): void {
  const first = lines[0];
  const last = lines[lines.length - 1];
  if (!engine || !first || !last) {
    return;
  }
  engine.reset();
  chart.clear();
  chart.setWindow(last.t - first.t);
  for (const { t, line } of lines) {
    handleOutputs(engine.pushBytes(encoder.encode(`${line}\n`)) as EngineOutput[], t);
  }
}

async function connectWith(factory: () => RadarTransport): Promise<void> {
  if (transport) {
    await transport.disconnect();
  }
  const t = factory();
  t.onData(onData);
  await t.connect();
  chart.clear();
  chart.setWindow(0);
  transport = t;
  setConnected(true, `Connected (${t.name})`);
}

async function disconnect(): Promise<void> {
  if (transport) {
    await transport.disconnect();
    transport = null;
  }
  setConnected(false, "Disconnected");
}

async function writeCommand(cmd: string): Promise<void> {
  if (!transport) {
    return;
  }
  await transport.write(encodeCommandLine(cmd));
}

el.btnUsb.addEventListener("click", () => {
  void connectWith(() => new WebSerialTransport()).catch((e: Error) => {
    setConnected(false, e.message);
  });
});

el.btnBle.addEventListener("click", () => {
  void connectWith(() => new WebBluetoothTransport()).catch((e: Error) => {
    setConnected(false, e.message);
  });
});

el.btnDisconnect.addEventListener("click", () => {
  void disconnect();
});

el.btnSend.addEventListener("click", () => {
  void writeCommand(el.cmd.value);
});

el.cmd.addEventListener("keydown", (ev) => {
  if (ev.key === "Enter") {
    void writeCommand(el.cmd.value);
  }
});

el.btnPreset.addEventListener("click", () => {
  void sendPreset(writeCommand).catch((e: Error) => appendLog("unknown", e.message));
});

el.btnRecord.addEventListener("click", () => {
  recorder.start();
  el.btnRecord.disabled = true;
  el.btnStopRecord.disabled = false;
});

el.btnStopRecord.addEventListener("click", () => {
  recorder.stop();
  lastReplay = recorder.timedLines();
  el.btnRecord.disabled = false;
  el.btnStopRecord.disabled = true;
  el.btnExportTxt.disabled = !recorder.hasData;
  el.btnExportCsv.disabled = !recorder.hasData;
  el.btnReplay.disabled = lastReplay.length === 0;
});

el.btnExportTxt.addEventListener("click", () => {
  downloadBlob(`gotcha-six-${Date.now()}.txt`, recorder.toText(), "text/plain");
});

el.btnExportCsv.addEventListener("click", () => {
  downloadBlob(`gotcha-six-${Date.now()}.csv`, recorder.toCsv(), "text/csv");
});

el.btnSim.addEventListener("click", () => {
  replay(simulateApproach());
});

el.btnReplay.addEventListener("click", () => {
  replay(lastReplay);
});

el.btnImport.addEventListener("click", () => {
  el.fileImport.click();
});

el.fileImport.addEventListener("change", () => {
  const file = el.fileImport.files?.[0];
  // Clear the input so the same file can be imported again.
  el.fileImport.value = "";
  if (!file) {
    return;
  }
  void file
    .text()
    .then((text) => {
      const lines = parseRecording(text);
      if (lines.length === 0) {
        appendLog("unknown", `${file.name}: no lines found`);
        return;
      }
      lastReplay = lines;
      el.btnReplay.disabled = false;
      replay(lines);
    })
    .catch((e: Error) => appendLog("unknown", e.message));
});

async function boot(): Promise<void> {
  await init();
  engine = new WasmRadarEngine();
  setConnected(false, "Disconnected");
}

void boot();
