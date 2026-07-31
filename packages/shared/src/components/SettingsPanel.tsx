import { BRIDGE_DEFINITIONS } from "../bridges";
import { useInboxStore } from "../store/inboxStore";

export function SettingsPanel() {
  const settingsOpen = useInboxStore((s) => s.settingsOpen);
  const setSettingsOpen = useInboxStore((s) => s.setSettingsOpen);
  const logout = useInboxStore((s) => s.logout);
  const config = useInboxStore((s) => s.config);
  const userId = useInboxStore((s) => s.userId);
  const platformCounts = useInboxStore((s) => s.platformCounts);

  if (!settingsOpen) return null;

  return (
    <>
      <button
        type="button"
        aria-label="Close settings"
        className="fixed inset-0 z-40 bg-black/50"
        onClick={() => setSettingsOpen(false)}
      />
      <aside
        className="fixed right-0 top-0 z-50 flex h-full w-[320px] flex-col border-l shadow-xl"
        style={{
          background: "var(--mm-panel)",
          borderColor: "var(--mm-panel-border)",
        }}
      >
        <header
          className="flex items-center justify-between border-b px-5 py-4"
          style={{ borderColor: "var(--mm-panel-border)" }}
        >
          <h2 className="font-semibold">Settings</h2>
          <button
            type="button"
            onClick={() => setSettingsOpen(false)}
            className="text-sm opacity-60 hover:opacity-100"
          >
            Close
          </button>
        </header>

        <div className="mm-scroll flex-1 px-5 py-4">
          <section>
            <h3
              className="mb-2 text-[11px] font-semibold uppercase tracking-wider"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Account
            </h3>
            <p className="break-all text-sm">{userId}</p>
            <p
              className="mt-1 text-xs"
              style={{ color: "var(--mm-text-muted)" }}
            >
              {config?.homeserverUrl}
            </p>
            <button
              type="button"
              onClick={() => {
                logout();
                setSettingsOpen(false);
              }}
              className="mt-3 rounded-lg border px-3 py-2 text-sm hover:bg-white/5"
              style={{ borderColor: "var(--mm-panel-border)" }}
            >
              Sign out
            </button>
          </section>

          <section className="mt-8">
            <h3
              className="mb-2 text-[11px] font-semibold uppercase tracking-wider"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Connections
            </h3>
            <p
              className="mb-3 text-xs"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Read-only status. Set up bridges with{" "}
              <code className="rounded bg-black/30 px-1">./connect</code> on the
              server.
            </p>
            <ul className="space-y-2">
              {BRIDGE_DEFINITIONS.filter((b) => !b.experimental).map((bridge) => {
                const count = platformCounts[bridge.id] ?? 0;
                const connected = count > 0;
                return (
                  <li
                    key={bridge.id}
                    className="flex items-center justify-between rounded-lg px-3 py-2 text-sm"
                    style={{ background: "var(--mm-bg)" }}
                  >
                    <span className="flex items-center gap-2">
                      <span
                        className="h-2 w-2 rounded-full"
                        style={{
                          background: connected ? bridge.accentColor : "#444",
                        }}
                      />
                      {bridge.label}
                    </span>
                    <span
                      className="text-xs"
                      style={{ color: "var(--mm-text-muted)" }}
                    >
                      {connected ? `${count} chats` : "—"}
                    </span>
                  </li>
                );
              })}
            </ul>
          </section>

          <section className="mt-8">
            <h3
              className="mb-2 text-[11px] font-semibold uppercase tracking-wider"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Advanced
            </h3>
            <a
              href={config?.homeserverUrl.replace("matrix.", "chat.") ?? "#"}
              target="_blank"
              rel="noreferrer"
              className="block rounded-lg px-3 py-2 text-sm hover:bg-white/5"
            >
              Open Element Web ↗
            </a>
          </section>
        </div>
      </aside>
    </>
  );
}
