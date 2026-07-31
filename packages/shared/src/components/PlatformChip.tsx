import { getBridge, type PlatformId } from "../bridges";

interface PlatformChipProps {
  platform: PlatformId | "all";
  active?: boolean;
  count?: number;
  onClick?: () => void;
  compact?: boolean;
}

export function PlatformChip({
  platform,
  active,
  count,
  onClick,
  compact,
}: PlatformChipProps) {
  const bridge = platform === "all" ? null : getBridge(platform);
  const label =
    platform === "all" ? "All" : compact ? bridge?.shortLabel : bridge?.label;
  const color = platform === "all" ? "var(--mm-accent)" : bridge?.accentColor;

  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex shrink-0 items-center gap-1 rounded-full border px-2.5 py-1 text-xs font-medium transition-colors"
      style={{
        borderColor: active ? color : "var(--mm-panel-border)",
        background: active ? `${color}22` : "transparent",
        color: active ? "var(--mm-text)" : "var(--mm-text-muted)",
      }}
    >
      {platform !== "all" && (
        <span
          className="h-1.5 w-1.5 rounded-full"
          style={{ background: color }}
        />
      )}
      {label}
      {count !== undefined && count > 0 && (
        <span className="text-[10px] opacity-70">({count})</span>
      )}
    </button>
  );
}

interface PlatformBadgeProps {
  platform: PlatformId;
}

export function PlatformBadge({ platform }: PlatformBadgeProps) {
  const bridge = getBridge(platform);
  if (!bridge || platform === "matrix") return null;

  return (
    <span
      className="rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide"
      style={{
        background: `${bridge.accentColor}22`,
        color: bridge.accentColor,
      }}
    >
      {bridge.shortLabel}
    </span>
  );
}
