/** Bridge registry — ported from scripts/lib/bridges.sh */

export type PlatformId =
  | "signal"
  | "telegram"
  | "whatsapp"
  | "imessage"
  | "gvoice"
  | "gmessages"
  | "discord"
  | "slack"
  | "meta"
  | "snapchat"
  | "matrix";

export interface BridgeDefinition {
  id: PlatformId;
  label: string;
  shortLabel: string;
  botLocalpart: string;
  puppetPrefix: string;
  accentColor: string;
  experimental?: boolean;
}

export const BRIDGE_DEFINITIONS: BridgeDefinition[] = [
  {
    id: "signal",
    label: "Signal",
    shortLabel: "Signal",
    botLocalpart: "signalbot",
    puppetPrefix: "signal_",
    accentColor: "#3a76f0",
  },
  {
    id: "telegram",
    label: "Telegram",
    shortLabel: "TG",
    botLocalpart: "telegrambot",
    puppetPrefix: "telegram_",
    accentColor: "#2aabee",
  },
  {
    id: "whatsapp",
    label: "WhatsApp",
    shortLabel: "WA",
    botLocalpart: "whatsappbot",
    puppetPrefix: "whatsapp_",
    accentColor: "#25d366",
  },
  {
    id: "imessage",
    label: "iMessage",
    shortLabel: "iMsg",
    botLocalpart: "imessagebot",
    puppetPrefix: "imessage_",
    accentColor: "#34c759",
  },
  {
    id: "gvoice",
    label: "Google Voice",
    shortLabel: "GV",
    botLocalpart: "gvoicebot",
    puppetPrefix: "gvoice_",
    accentColor: "#4285f4",
  },
  {
    id: "gmessages",
    label: "Google Messages",
    shortLabel: "GM",
    botLocalpart: "gmessagesbot",
    puppetPrefix: "gmessages_",
    accentColor: "#1a73e8",
  },
  {
    id: "discord",
    label: "Discord",
    shortLabel: "DC",
    botLocalpart: "discordbot",
    puppetPrefix: "discord_",
    accentColor: "#5865f2",
  },
  {
    id: "slack",
    label: "Slack",
    shortLabel: "SL",
    botLocalpart: "slackbot",
    puppetPrefix: "slack_",
    accentColor: "#e01e5a",
  },
  {
    id: "meta",
    label: "Meta",
    shortLabel: "Meta",
    botLocalpart: "metabot",
    puppetPrefix: "meta_",
    accentColor: "#0084ff",
  },
  {
    id: "snapchat",
    label: "Snapchat",
    shortLabel: "SC",
    botLocalpart: "snapchatbot",
    puppetPrefix: "snapchat_",
    accentColor: "#fffc00",
    experimental: true,
  },
];

export const BRIDGE_IDS = BRIDGE_DEFINITIONS.map((b) => b.id).filter(
  (id) => id !== "matrix",
) as Exclude<PlatformId, "matrix">[];

export const BOT_LOCALPARTS = new Set(
  BRIDGE_DEFINITIONS.map((b) => b.botLocalpart),
);

export function getBridge(id: PlatformId): BridgeDefinition | undefined {
  if (id === "matrix") {
    return {
      id: "matrix",
      label: "Matrix",
      shortLabel: "MX",
      botLocalpart: "",
      puppetPrefix: "",
      accentColor: "#888888",
    };
  }
  return BRIDGE_DEFINITIONS.find((b) => b.id === id);
}

export function detectPlatformFromLocalpart(
  localpart: string,
): PlatformId | null {
  for (const bridge of BRIDGE_DEFINITIONS) {
    if (localpart.startsWith(bridge.puppetPrefix)) {
      return bridge.id;
    }
  }
  return null;
}

export function isBridgeBotLocalpart(localpart: string): boolean {
  return BOT_LOCALPARTS.has(localpart);
}
