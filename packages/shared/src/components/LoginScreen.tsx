import { useState } from "react";
import { useInboxStore } from "../store/inboxStore";

export function LoginScreen() {
  const config = useInboxStore((s) => s.config);
  const login = useInboxStore((s) => s.login);
  const isSyncing = useInboxStore((s) => s.isSyncing);
  const syncError = useInboxStore((s) => s.syncError);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await login(username, password);
  };

  return (
    <div
      className="flex min-h-full items-center justify-center p-6"
      style={{ background: "var(--mm-bg)" }}
    >
      <div
        className="w-full max-w-md rounded-2xl border p-8"
        style={{
          background: "var(--mm-panel)",
          borderColor: "var(--mm-panel-border)",
        }}
      >
        <h1 className="text-xl font-semibold tracking-tight">Message Matrix</h1>
        <p
          className="mt-1 text-sm"
          style={{ color: "var(--mm-text-muted)" }}
        >
          All your messages in one place
        </p>

        <form onSubmit={(e) => void handleSubmit(e)} className="mt-8 space-y-4">
          <div>
            <label
              className="mb-1 block text-xs font-medium"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Homeserver
            </label>
            <input
              type="text"
              readOnly
              value={config?.homeserverUrl ?? ""}
              className="w-full rounded-lg border px-3 py-2 text-sm opacity-70"
              style={{
                background: "var(--mm-bg)",
                borderColor: "var(--mm-panel-border)",
                color: "var(--mm-text)",
              }}
            />
          </div>
          <div>
            <label
              className="mb-1 block text-xs font-medium"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Username
            </label>
            <input
              type="text"
              autoComplete="username"
              placeholder={`user:${config?.serverName ?? "domain"}`}
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              className="w-full rounded-lg border px-3 py-2 text-sm outline-none"
              style={{
                background: "var(--mm-bg)",
                borderColor: "var(--mm-panel-border)",
                color: "var(--mm-text)",
              }}
            />
          </div>
          <div>
            <label
              className="mb-1 block text-xs font-medium"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Password
            </label>
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full rounded-lg border px-3 py-2 text-sm outline-none"
              style={{
                background: "var(--mm-bg)",
                borderColor: "var(--mm-panel-border)",
                color: "var(--mm-text)",
              }}
            />
          </div>

          {syncError && (
            <p className="text-sm text-red-400">{syncError}</p>
          )}

          <button
            type="submit"
            disabled={isSyncing}
            className="w-full rounded-xl py-2.5 text-sm font-medium text-white disabled:opacity-50"
            style={{ background: "var(--mm-accent)" }}
          >
            {isSyncing ? "Connecting…" : "Sign in"}
          </button>
        </form>
      </div>
    </div>
  );
}
