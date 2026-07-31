export interface StoredSession {
  homeserverUrl: string;
  userId: string;
  accessToken: string;
  deviceId?: string;
}

const SESSION_KEY = "message-matrix-session";

export async function saveSession(session: StoredSession): Promise<void> {
  if (typeof window === "undefined") return;

  if ("__TAURI__" in window) {
    try {
      const { load } = await import("@tauri-apps/plugin-store");
      const store = await load("session.json", { autoSave: false });
      await store.set(SESSION_KEY, session);
      await store.save();
      return;
    } catch {
      // fall through to sessionStorage
    }
  }

  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export async function loadSession(): Promise<StoredSession | null> {
  if (typeof window === "undefined") return null;

  if ("__TAURI__" in window) {
    try {
      const { load } = await import("@tauri-apps/plugin-store");
      const store = await load("session.json", { autoSave: false });
      const value = (await store.get(SESSION_KEY)) as StoredSession | null;
      return value ?? null;
    } catch {
      // fall through
    }
  }

  const raw = sessionStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredSession;
  } catch {
    return null;
  }
}

export async function clearSession(): Promise<void> {
  if (typeof window === "undefined") return;

  if ("__TAURI__" in window) {
    try {
      const { load } = await import("@tauri-apps/plugin-store");
      const store = await load("session.json", { autoSave: false });
      await store.delete(SESSION_KEY);
      await store.save();
      return;
    } catch {
      // fall through
    }
  }

  sessionStorage.removeItem(SESSION_KEY);
}
