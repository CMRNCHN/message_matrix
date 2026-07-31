import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { InboxApp, type AppConfig } from "@message-matrix/shared";
import "@message-matrix/shared/styles/index.css";

const DEFAULT_CONFIG: AppConfig = {
  homeserverUrl: "https://matrix.example.com",
  serverName: "example.com",
};

function App() {
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/config.json")
      .then((r) => {
        if (!r.ok) throw new Error("config.json not found");
        return r.json();
      })
      .then((data: AppConfig) => setConfig(data))
      .catch(() => {
        setConfig(DEFAULT_CONFIG);
        setError("Using default config — deploy config.json for production");
      });
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
        }}
      >
        Loading…
      </div>
    );
  }

  return (
    <>
      {error && (
        <div
          style={{
            position: "fixed",
            bottom: 8,
            left: 8,
            right: 8,
            zIndex: 100,
            padding: "8px 12px",
            background: "#1e1e22",
            borderRadius: 8,
            fontSize: 12,
            color: "#8b8b90",
          }}
        >
          {error}
        </div>
      )}
      <InboxApp config={config} />
    </>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
