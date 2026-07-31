import { useInboxStore } from "../store/inboxStore";
import { getBridge } from "../bridges";
import { avatarInitials } from "../utils/format";

export function ProfilePanel() {
  const selectedRoomId = useInboxStore((s) => s.selectedRoomId);
  const conversations = useInboxStore((s) => s.conversations);
  const togglePin = useInboxStore((s) => s.togglePin);
  const toggleMute = useInboxStore((s) => s.toggleMute);
  const pinnedRoomIds = useInboxStore((s) => s.pinnedRoomIds);
  const mutedRoomIds = useInboxStore((s) => s.mutedRoomIds);
  const client = useInboxStore((s) => s.client);
  const userId = useInboxStore((s) => s.userId);

  const conversation = conversations.find((c) => c.roomId === selectedRoomId);

  if (!conversation) {
    return (
      <aside
        className="hidden w-[280px] shrink-0 border-l lg:flex lg:items-center lg:justify-center"
        style={{
          background: "var(--mm-panel)",
          borderColor: "var(--mm-panel-border)",
        }}
      >
        <p className="text-xs" style={{ color: "var(--mm-text-muted)" }}>
          Profile & actions
        </p>
      </aside>
    );
  }

  const bridge = getBridge(conversation.platform);
  const isPinned = pinnedRoomIds.has(conversation.roomId);
  const isMuted = mutedRoomIds.has(conversation.roomId);

  const room = client?.getRoom(conversation.roomId);
  const otherMember = room
    ?.getJoinedMembers()
    .find((m) => m.userId !== userId);

  return (
    <aside
      className="hidden w-[280px] shrink-0 flex-col border-l lg:flex"
      style={{
        background: "var(--mm-panel)",
        borderColor: "var(--mm-panel-border)",
      }}
    >
      <div className="border-b px-5 py-6 text-center" style={{ borderColor: "var(--mm-panel-border)" }}>
        <div
          className="mx-auto flex h-16 w-16 items-center justify-center rounded-full text-xl font-semibold"
          style={{
            background: `${bridge?.accentColor ?? "#666"}33`,
            color: bridge?.accentColor ?? "#aaa",
          }}
        >
          {avatarInitials(conversation.name)}
        </div>
        <h2 className="mt-3 text-base font-semibold">{conversation.name}</h2>
        <p className="mt-1 text-xs" style={{ color: "var(--mm-text-muted)" }}>
          via {bridge?.label ?? "Matrix"}{" "}
          <span style={{ color: bridge?.accentColor }}>●</span> connected
        </p>
      </div>

      <div className="flex-1 px-4 py-4">
        <h3
          className="mb-2 text-[11px] font-semibold uppercase tracking-wider"
          style={{ color: "var(--mm-text-muted)" }}
        >
          Actions
        </h3>
        <div className="space-y-1">
          <ActionButton
            label={isMuted ? "Unmute" : "Mute conversation"}
            onClick={() => toggleMute(conversation.roomId)}
          />
          <ActionButton
            label={isPinned ? "Unpin" : "Pin conversation"}
            onClick={() => togglePin(conversation.roomId)}
          />
          <ActionButton label="Search in conversation" disabled />
          <ActionButton label="Open in native app" disabled />
        </div>

        {otherMember && (
          <>
            <h3
              className="mb-2 mt-6 text-[11px] font-semibold uppercase tracking-wider"
              style={{ color: "var(--mm-text-muted)" }}
            >
              Contact
            </h3>
            <dl className="space-y-2 text-sm">
              <div>
                <dt style={{ color: "var(--mm-text-muted)" }}>Matrix ID</dt>
                <dd className="break-all text-xs">{otherMember.userId}</dd>
              </div>
              {otherMember.name && (
                <div>
                  <dt style={{ color: "var(--mm-text-muted)" }}>Display name</dt>
                  <dd>{otherMember.name}</dd>
                </div>
              )}
            </dl>
          </>
        )}
      </div>
    </aside>
  );
}

function ActionButton({
  label,
  onClick,
  disabled,
}: {
  label: string;
  onClick?: () => void;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="w-full rounded-lg px-3 py-2 text-left text-sm transition-colors hover:bg-white/5 disabled:cursor-not-allowed disabled:opacity-40"
      style={{ color: "var(--mm-text)" }}
    >
      {label}
    </button>
  );
}
