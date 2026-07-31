declare module "@tauri-apps/plugin-store" {
  export function load(
    path: string,
    options?: { autoSave?: boolean },
  ): Promise<TauriStore>;
  interface TauriStore {
    set(key: string, value: unknown): Promise<void>;
    get(key: string): Promise<unknown>;
    delete(key: string): Promise<void>;
    save(): Promise<void>;
  }
}

declare module "@tauri-apps/plugin-notification" {
  export function sendNotification(options: {
    title: string;
    body: string;
  }): Promise<void>;
}
