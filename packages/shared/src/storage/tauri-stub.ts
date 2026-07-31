/** Web build stub — real plugin used in Tauri desktop only */
export async function load(
  _path: string,
  _options?: { autoSave?: boolean },
): Promise<{
  set: (_key: string, _value: unknown) => Promise<void>;
  get: <T>(_key: string) => Promise<T | null>;
  delete: (_key: string) => Promise<void>;
  save: () => Promise<void>;
}> {
  throw new Error("Tauri plugin not available");
}

export async function sendNotification(_opts: {
  title: string;
  body: string;
}): Promise<void> {
  // no-op on web
}
