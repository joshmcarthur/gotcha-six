import type { DataHandler, RadarTransport } from "./types";

const NUS_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const NUS_RX = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // phone writes
const NUS_TX = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // device notifies

export class WebBluetoothTransport implements RadarTransport {
  readonly name = "ble";
  private device: BluetoothDevice | null = null;
  private rxChar: BluetoothRemoteGATTCharacteristic | null = null;
  private handler: DataHandler | null = null;

  onData(callback: DataHandler): void {
    this.handler = callback;
  }

  async connect(): Promise<void> {
    if (!navigator.bluetooth) {
      throw new Error("Web Bluetooth is not available in this browser");
    }
    this.device = await navigator.bluetooth.requestDevice({
      filters: [{ namePrefix: "Gotcha Six" }, { services: [NUS_SERVICE] }],
      optionalServices: [NUS_SERVICE],
    });
    const server = await this.device.gatt!.connect();
    const service = await server.getPrimaryService(NUS_SERVICE);
    const txChar = await service.getCharacteristic(NUS_TX);
    this.rxChar = await service.getCharacteristic(NUS_RX);
    await txChar.startNotifications();
    txChar.addEventListener("characteristicvaluechanged", this.onNotify);
  }

  async disconnect(): Promise<void> {
    if (this.device?.gatt?.connected) {
      this.device.gatt.disconnect();
    }
    this.device = null;
    this.rxChar = null;
  }

  async write(data: Uint8Array): Promise<void> {
    if (!this.rxChar) {
      throw new Error("BLE not connected");
    }
    // Chunk to ATT payload; 20 is safe default without MTU knowledge.
    const chunk = 20;
    for (let i = 0; i < data.length; i += chunk) {
      const slice = data.slice(i, i + chunk);
      await this.rxChar.writeValueWithoutResponse(slice);
    }
  }

  private onNotify = (ev: Event): void => {
    const target = ev.target as BluetoothRemoteGATTCharacteristic;
    const value = target.value;
    if (!value || !this.handler) {
      return;
    }
    this.handler(new Uint8Array(value.buffer.slice(value.byteOffset, value.byteOffset + value.byteLength)));
  };
}
