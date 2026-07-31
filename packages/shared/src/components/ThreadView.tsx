import { useState, useRef, useEffect } from "react";
import { useInboxStore } from "../store/inboxStore";
import { PlatformBadge } from "./PlatformChip";
import { getBridge } from "../bridges";

export function ThreadView() {
  const selectedRoomId = useInboxStore((s) => s.selectedRoomId);
  const conversations = useInboxStore((s) => s.conversations);
  const messages = useInboxStore((s) => s.messages);
  const sendMessage = useInboxStore((s) => s.sendMessage);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const conversation = conversations.find((c) => c.roomId === selectedRoomId);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, selectedRoomId]);

  if (!selectedRoomId || !conversation) {
    return (
      <main
        className="flex flex-1 items-center justify-center"
        style={{ background: "var(--mm-bg)" }}
      >
        <p className="text-sm" style={{ color: "var(--mm-text-muted)" }}>
          Select a conversation
        </p>
      </main>
    );
  }

  const bridge = getBridge(conversation.platform);

  const handleSend = async () => {
    if (!draft.trim() || sending) return;
    setSending(true);
    try {
      await sendMessage(draft);
      setDraft("");
    } finally {
      setSending(false);
    }
  };

  return (
    <main
      className="flex min-w-0 flex-1 flex-col"
      style={{ background: "var(--mm-bg)" }}
    >
      <header
        className="flex items-center justify-between border-b px-5 py-3"
        style={{ borderColor: "var(--mm-panel-border)" }}
      >
        <div>
          <h1 className="text-base font-semibold">{conversation.name}</h1>
          <div className="mt-0.5 flex items-center gap-2">
            <PlatformBadge platform={conversation.platform} />
            <span
              className="text-xs"
              style={{ color: "var(--mm-text-muted)" }}
            >
              via {bridge?.label ?? "Matrix"}
            </span>
          </div>
        </div>
      </header>

      <div className="mm-scroll flex-1 space-y-3 px-5 py-4">
        {messages.map((msg) => (
          <div
            key={msg.eventId}
            className={`flex ${msg.isMine ? "justify-end" : "justify-start"}`}
          >
            <div
              className="max-w-[75%] rounded-2xl px-4 py-2 text-sm"
              style={{
                background: msg.isMine
                  ? "var(--mm-bubble-out)"
                  : "var(--mm-bubble-in)",
                borderLeft: msg.isMine
                  ? undefined
                  : `3px solid ${bridge?.accentColor ?? "#444"}`,
              }}
            >
              {!msg.isMine && (
                <div
                  className="mb-1 text-[11px] font-medium"
                  style={{ color: bridge?.accentColor ?? "#888" }}
                >
                  {msg.senderName}
                </div>
              )}
              <p className="whitespace-pre-wrap break-words">{msg.body}</p>
              <time
                className="mt-1 block text-[10px] opacity-50"
                dateTime={new Date(msg.timestamp).toISOString()}
              >
                {new Date(msg.timestamp).toLocaleTimeString(undefined, {
                  hour: "numeric",
                  minute: "2-digit",
                })}
              </time>
            </div>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <footer
        className="border-t px-4 py-3"
        style={{ borderColor: "var(--mm-panel-border)" }}
      >
        <div className="flex gap-2">
          <input
            type="text"
            placeholder="Message…"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                void handleSend();
              }
            }}
            className="flex-1 rounded-xl border px-4 py-2.5 text-sm outline-none focus:ring-1"
            style={{
              background: "var(--mm-panel)",
              borderColor: "var(--mm-panel-border)",
              color: "var(--mm-text)",
            }}
          />
          <button
            type="button"
            onClick={() => void handleSend()}
            disabled={sending || !draft.trim()}
            className="rounded-xl px-5 py-2.5 text-sm font-medium text-white transition-opacity disabled:opacity-40"
            style={{ background: "var(--mm-accent)" }}
          >
            Send
          </button>
        </div>
      </footer>
    </main>
  );
}
