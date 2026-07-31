import { useEffect, useState } from "react";
import type { AppConfig } from "../matrix/client";
import { useInboxStore } from "../store/inboxStore";
import { LoginScreen } from "./LoginScreen";
import { InboxList } from "./InboxList";
import { ThreadView } from "./ThreadView";
import { ProfilePanel } from "./ProfilePanel";
import { SettingsPanel } from "./SettingsPanel";

interface InboxAppProps {
  config: AppConfig;
}

export function InboxApp({ config }: InboxAppProps) {
  const loadConfig = useInboxStore((s) => s.loadConfig);
  const isAuthenticated = useInboxStore((s) => s.isAuthenticated);
  const restoreLogin = useInboxStore((s) => s.restoreLogin);
  const setSettingsOpen = useInboxStore((s) => s.setSettingsOpen);
  const isSyncing = useInboxStore((s) => s.isSyncing);
  const [bootstrapped, setBootstrapped] = useState(false);

  useEffect(() => {
    loadConfig(config);
    void restoreLogin().finally(() => setBootstrapped(true));
  }, [config, loadConfig, restoreLogin]);

  if (!bootstrapped || (isSyncing && !isAuthenticated)) {
    return (
      <div
        className="flex h-full items-center justify-center"
        style={{ background: "var(--mm-bg)", color: "var(--mm-text-muted)" }}
      >
        Loading…
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginScreen />;
  }

  return (
    <div className="flex h-full flex-col">
      <header
        className="flex shrink-0 items-center justify-between border-b px-4 py-2.5"
        style={{
          background: "var(--mm-panel)",
          borderColor: "var(--mm-panel-border)",
        }}
      >
        <span className="text-sm font-semibold tracking-tight">
          Message Matrix
        </span>
        <button
          type="button"
          onClick={() => setSettingsOpen(true)}
          className="rounded-lg px-3 py-1.5 text-sm hover:bg-white/5"
          style={{ color: "var(--mm-text-muted)" }}
          aria-label="Settings"
        >
          Settings
        </button>
      </header>

      <div className="flex min-h-0 flex-1">
        <InboxList />
        <ThreadView />
        <ProfilePanel />
      </div>

      <SettingsPanel />
    </div>
  );
}
