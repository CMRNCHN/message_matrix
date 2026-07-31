import type { Room } from "matrix-js-sdk";
import {
  BOT_LOCALPARTS,
  detectPlatformFromLocalpart,
  type PlatformId,
} from "../bridges";

export interface ClassifiedRoom {
  roomId: string;
  platform: PlatformId;
  isBridged: boolean;
  isHidden: boolean;
  hideReason?: string;
}

function parseLocalpart(mxid: string): string | null {
  const match = /^@([^:]+):/.exec(mxid);
  return match?.[1] ?? null;
}

export function classifyRoom(room: Room, myUserId: string): ClassifiedRoom {
  const roomId = room.roomId;
  const members = room.getJoinedMembers();
  const others = members.filter((m) => m.userId !== myUserId);

  if (others.length === 0) {
    return {
      roomId,
      platform: "matrix",
      isBridged: false,
      isHidden: true,
      hideReason: "empty",
    };
  }

  const name = (room.name ?? "").toLowerCase();
  const isManagementRoom =
    name.includes("bridge") &&
    (name.includes("management") || name.includes("status"));

  if (isManagementRoom) {
    return {
      roomId,
      platform: "matrix",
      isBridged: false,
      isHidden: true,
      hideReason: "management",
    };
  }

  if (others.length === 1) {
    const localpart = parseLocalpart(others[0]!.userId);
    if (localpart && BOT_LOCALPARTS.has(localpart)) {
      return {
        roomId,
        platform: detectPlatformFromLocalpart(localpart) ?? "matrix",
        isBridged: false,
        isHidden: true,
        hideReason: "bridge_bot",
      };
    }
  }

  let detected: PlatformId | null = null;
  for (const member of others) {
    const localpart = parseLocalpart(member.userId);
    if (!localpart) continue;
    if (BOT_LOCALPARTS.has(localpart)) continue;
    const platform = detectPlatformFromLocalpart(localpart);
    if (platform) {
      detected = platform;
      break;
    }
  }

  if (!detected) {
    const timeline = room.getLiveTimeline().getEvents();
    if (timeline.length === 0) {
      return {
        roomId,
        platform: "matrix",
        isBridged: false,
        isHidden: true,
        hideReason: "no_messages",
      };
    }
    return {
      roomId,
      platform: "matrix",
      isBridged: false,
      isHidden: false,
    };
  }

  return {
    roomId,
    platform: detected,
    isBridged: true,
    isHidden: false,
  };
}

export function shouldShowInInbox(classified: ClassifiedRoom): boolean {
  return !classified.isHidden;
}
