import init, { WasmRadarEngine } from "./wasm/gotcha_six_core.js";
import { DistanceChart } from "./chart";
import { encodeCommandLine, sendPreset } from "./preset";
import { downloadBlob, SessionRecorder } from "./session";
import { simulateApproach } from "./simulator";
import { WebBluetoothTransport } from "./transports/bluetooth";
import { WebSerialTransport } from "./transports/serial";
import type { RadarTransport } from "./transports/types";

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

const el = {
  status: document.getElementById("conn-status")!,
  log: document.getElementById("log")!,
  distance: document.getElementById("v-distance")!,
  speed: document.getElementById("v-speed")!,
  energy: document.getElementById("v-energy")!,
  motion: document.getElementById("v-motion")!,
  closing: document.getElementById("v-closing")!,
  accel: document.getElementById("v-accel")!,
  gyro: document.getElementById("v-gyro")!,
  cmd: document.getElementById("cmd-input") as HTMLInputElement,
  btnUsb: document.getElementById("btn-usb") as HTMLButtonElement,
  btnBle: document.getElementById("btn-ble") as HTMLButtonElement,
  btnDisconnect: document.getElementById("btn-disconnect") as HTMLButtonElement,
  btnSend: document.getElementById("btn-send") as HTMLButtonElement,
  btnPreset: document.getElementById("btn-preset") as HTMLButtonElement,
  btnRecord: document.getElementById("btn-record") as HTMLButtonElement,
  btnStopRecord: document.getElementById("btn-stop-record") as HTMLButtonElement,
  btnExportTxt: document.getElementById("btn-export-txt") as HTMLButtonElement,
  btnExportCsv: document.getElementById("btn-export-csv") as HTMLButtonElement,
  btnSim: document.getElementById("btn-sim") as HTMLButtonElement,
  btnReplay: document.getElementById("btn-replay") as HTMLButtonElement,
  chart: document.getElementById("chart") as HTMLCanvasElement,
};

let transport: RadarTransport | null = null;
let engine: WasmRadarEngine | null = null;
const recorder = new SessionRecorder();
const chart = new DistanceChart(el.chart);
let lastRawReplay: Uint8Array | null = null;

function setConnected(connected: boolean, label: string): void {
  el.status.textContent = label;
  el.status.classList.toggle("live", connected);
  el.btnDisconnect.disabled = !connected;
  el.btnSend.disabled = !connected;
  el.btnPreset.disabled = !connected;
  el.btnUsb.disabled = connected;
  el.btnBle.disabled = connected;
}

function appendLog(kind: string, raw: string): void {
  const ts = new Date().toISOString().slice(11, 23);
  const line = document.createElement("div");
  line.innerHTML = `<span class="ts">${ts}</span> <span class="kind-${kind}">[${kind}]</span> ${escapeHtml(raw)}`;
  el.log.appendChild(line);
  el.log.scrollTop = el.log.scrollHeight;
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function handleOutputs(outputs: EngineOutput[]): void {
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
        chart.push(performance.now(), distance);
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
  recorder.recordBytes(data);
  if (!engine) {
    return;
  }
  const raw = engine.pushBytes(data) as EngineOutput[];
  handleOutputs(raw);
}

async function connectWith(factory: () => RadarTransport): Promise<void> {
  if (transport) {
    await transport.disconnect();
  }
  const t = factory();
  t.onData(onData);
  await t.connect();
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
  lastRawReplay = recorder.rawReplayBytes();
  el.btnRecord.disabled = false;
  el.btnStopRecord.disabled = true;
  el.btnExportTxt.disabled = !recorder.hasData;
  el.btnExportCsv.disabled = !recorder.hasData;
  el.btnReplay.disabled = !lastRawReplay || lastRawReplay.length === 0;
});

el.btnExportTxt.addEventListener("click", () => {
  downloadBlob(`gotcha-six-${Date.now()}.txt`, recorder.toText(), "text/plain");
});

el.btnExportCsv.addEventListener("click", () => {
  downloadBlob(`gotcha-six-${Date.now()}.csv`, recorder.toCsv(), "text/csv");
});

el.btnSim.addEventListener("click", () => {
  if (!engine) {
    return;
  }
  engine.reset();
  chart.clear();
  for (const chunk of simulateApproach()) {
    handleOutputs(engine.pushBytes(chunk) as EngineOutput[]);
  }
});

el.btnReplay.addEventListener("click", () => {
  if (!engine || !lastRawReplay) {
    return;
  }
  engine.reset();
  chart.clear();
  handleOutputs(engine.pushBytes(lastRawReplay) as EngineOutput[]);
});

async function boot(): Promise<void> {
  await init();
  engine = new WasmRadarEngine();
  setConnected(false, "Disconnected");
}

void boot();
