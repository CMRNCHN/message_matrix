import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { InboxApp, type AppConfig } from "@message-matrix/shared";
import "@message-matrix/shared/styles/index.css";

const DEFAULT_CONFIG: AppConfig = {
  homeserverUrl: import.meta.env.VITE_HOMESERVER_URL ?? "https://matrix.example.com",
  serverName: import.meta.env.VITE_SERVER_NAME ?? "example.com",
};

async function loadConfig(): Promise<AppConfig> {
  try {
    const res = await fetch("/config.json");
    if (res.ok) return (await res.json()) as AppConfig;
  } catch {
    // desktop may bundle config at build time
  }
  return DEFAULT_CONFIG;
}

function App() {
  const [config, setConfig] = useState<AppConfig | null>(null);

  useEffect(() => {
    void loadConfig().then(setConfig);
  }, []);

  if (!config) {
    return (
      <div
        style={{
          display: "flex",
          height: "100vh",
          alignItems: "center",
          justifyContent: "center",
          background: "#0d0d0f",
          color: "#8b8b90",
          fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
        }}
      >
        Loading…
      </div>
    );
  }

  return <InboxApp config={config} />;
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
