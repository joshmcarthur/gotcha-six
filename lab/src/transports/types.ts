export type DataHandler = (data: Uint8Array) => void;

export interface RadarTransport {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  write(data: Uint8Array): Promise<void>;
  onData(callback: DataHandler): void;
  readonly name: string;
}
