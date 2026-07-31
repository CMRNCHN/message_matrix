import { useInboxStore } from "../store/inboxStore";
import { BRIDGE_DEFINITIONS } from "../bridges";
import { PlatformChip } from "./PlatformChip";
import { formatRelativeTime, truncate, avatarInitials } from "../utils/format";
import { PlatformBadge } from "./PlatformChip";
import { getBridge } from "../bridges";

export function InboxList() {
  const searchQuery = useInboxStore((s) => s.searchQuery);
  const setSearchQuery = useInboxStore((s) => s.setSearchQuery);
  const platformFilter = useInboxStore((s) => s.platformFilter);
  const setPlatformFilter = useInboxStore((s) => s.setPlatformFilter);
  const selectedRoomId = useInboxStore((s) => s.selectedRoomId);
  const selectRoom = useInboxStore((s) => s.selectRoom);
  const getFilteredConversations = useInboxStore((s) => s.getFilteredConversations);
  const platformCounts = useInboxStore((s) => s.platformCounts);
  const pinnedRoomIds = useInboxStore((s) => s.pinnedRoomIds);

  const conversations = getFilteredConversations();

  return (
    <aside
      className="flex h-full w-[300px] shrink-0 flex-col border-r"
      style={{
        background: "var(--mm-panel)",
        borderColor: "var(--mm-panel-border)",
      }}
    >
      <div
        className="border-b px-4 py-3"
        style={{ borderColor: "var(--mm-panel-border)" }}
      >
        <h2 className="text-sm font-semibold tracking-tight">All Messages</h2>
        <input
          type="search"
          placeholder="Search conversations…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="mt-2 w-full rounded-lg border px-3 py-2 text-sm outline-none focus:ring-1"
          style={{
            background: "var(--mm-bg)",
            borderColor: "var(--mm-panel-border)",
            color: "var(--mm-text)",
          }}
        />
      </div>

      <div
        className="flex gap-1.5 overflow-x-auto border-b px-3 py-2 mm-scroll"
        style={{ borderColor: "var(--mm-panel-border)" }}
      >
        <PlatformChip
          platform="all"
          active={platformFilter === "all"}
          onClick={() => setPlatformFilter("all")}
        />
        {BRIDGE_DEFINITIONS.filter((b) => !b.experimental).map((bridge) => (
          <PlatformChip
            key={bridge.id}
            platform={bridge.id}
            active={platformFilter === bridge.id}
            count={platformCounts[bridge.id]}
            onClick={() => setPlatformFilter(bridge.id)}
            compact
          />
        ))}
      </div>

      <div className="mm-scroll flex-1">
        {conversations.length === 0 ? (
          <p
            className="px-4 py-8 text-center text-sm"
            style={{ color: "var(--mm-text-muted)" }}
          >
            No conversations yet — connect a platform in Settings
          </p>
        ) : (
          conversations.map((conv) => {
            const bridge = getBridge(conv.platform);
            const isSelected = conv.roomId === selectedRoomId;
            const isPinned = pinnedRoomIds.has(conv.roomId);

            return (
              <button
                key={conv.roomId}
                type="button"
                onClick={() => selectRoom(conv.roomId)}
                className="flex w-full items-center gap-3 px-3 py-2.5 text-left transition-colors hover:bg-white/5"
                style={{
                  background: isSelected ? "rgba(99,102,241,0.12)" : undefined,
                  borderLeft: isSelected
                    ? `3px solid ${bridge?.accentColor ?? "var(--mm-accent)"}`
                    : "3px solid transparent",
                }}
              >
                <div
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-medium"
                  style={{
                    background: `${bridge?.accentColor ?? "#666"}33`,
                    color: bridge?.accentColor ?? "#aaa",
                  }}
                >
                  {avatarInitials(conv.name)}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="truncate text-sm font-medium">
                      {isPinned && "📌 "}
                      {conv.name}
                    </span>
                    <span
                      className="shrink-0 text-[11px]"
                      style={{ color: "var(--mm-text-muted)" }}
                    >
                      {formatRelativeTime(conv.lastTimestamp)}
                    </span>
                  </div>
                  <div className="mt-0.5 flex items-center gap-2">
                    <PlatformBadge platform={conv.platform} />
                    <span
                      className="truncate text-xs"
                      style={{ color: "var(--mm-text-muted)" }}
                    >
                      {truncate(conv.lastMessage)}
                    </span>
                  </div>
                </div>
                {conv.unreadCount > 0 && (
                  <span
                    className="flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full px-1 text-[10px] font-bold text-white"
                    style={{ background: "var(--mm-accent)" }}
                  >
                    {conv.unreadCount > 99 ? "99+" : conv.unreadCount}
                  </span>
                )}
              </button>
            );
          })
        )}
      </div>
    </aside>
  );
}
