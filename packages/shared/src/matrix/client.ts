import type { MatrixClient } from "matrix-js-sdk";
import {
  createClient,
  ClientEvent,
  RoomEvent,
  EventType,
  MsgType,
  type MatrixEvent,
  type Room,
} from "matrix-js-sdk";
import { classifyRoom, shouldShowInInbox } from "./classifier";
import type { PlatformId } from "../bridges";

export interface AppConfig {
  homeserverUrl: string;
  serverName: string;
}

export interface ConversationPreview {
  roomId: string;
  name: string;
  platform: PlatformId;
  lastMessage: string;
  lastTimestamp: number;
  unreadCount: number;
  avatarUrl?: string;
  isDirect: boolean;
}

export interface ThreadMessage {
  eventId: string;
  roomId: string;
  senderId: string;
  senderName: string;
  body: string;
  timestamp: number;
  isMine: boolean;
  msgType: string;
}

let client: MatrixClient | null = null;

export function getMatrixClient(): MatrixClient | null {
  return client;
}

export function createMatrixClient(baseUrl: string): MatrixClient {
  client = createClient({ baseUrl });
  return client;
}

export async function loginWithPassword(
  baseUrl: string,
  username: string,
  password: string,
): Promise<{ userId: string; accessToken: string; deviceId: string }> {
  const temp = createClient({ baseUrl });
  const response = await temp.login("m.login.password", {
    type: "m.login.password",
    identifier: {
      type: "m.id.user",
      user: username.includes("@") ? username.replace(/^@/, "").split(":")[0] : username,
    },
    password,
  });
  client = createClient({
    baseUrl,
    accessToken: response.access_token,
    userId: response.user_id,
    deviceId: response.device_id,
  });
  return {
    userId: response.user_id,
    accessToken: response.access_token,
    deviceId: response.device_id ?? "",
  };
}

export function restoreSession(
  baseUrl: string,
  userId: string,
  accessToken: string,
  deviceId?: string,
): MatrixClient {
  client = createClient({
    baseUrl,
    accessToken,
    userId,
    deviceId,
  });
  return client;
}

export async function startSync(c: MatrixClient): Promise<void> {
  await c.startClient({ initialSyncLimit: 30 });
}

export function getRoomDisplayName(room: Room, myUserId: string): string {
  const name = room.name;
  if (name) return name;
  const members = room.getJoinedMembers().filter((m) => m.userId !== myUserId);
  if (members.length === 1) {
    return members[0]!.name || members[0]!.userId;
  }
  return "Unknown";
}

function eventBody(event: MatrixEvent): string {
  const msgtype = event.getContent()?.msgtype as string | undefined;
  if (msgtype === MsgType.Image) return "Photo";
  if (msgtype === MsgType.File) return "File";
  if (msgtype === MsgType.Audio) return "Audio";
  if (msgtype === MsgType.Video) return "Video";
  return (event.getContent()?.body as string) ?? "";
}

export function buildConversationPreview(
  room: Room,
  myUserId: string,
): ConversationPreview | null {
  const classified = classifyRoom(room, myUserId);
  if (!shouldShowInInbox(classified)) return null;

  const timeline = room.getLiveTimeline().getEvents();
  const messageEvents = timeline.filter(
    (e) => e.getType() === EventType.RoomMessage,
  );
  const lastEvent = messageEvents[messageEvents.length - 1];
  const members = room.getJoinedMembers().filter((m) => m.userId !== myUserId);

  return {
    roomId: room.roomId,
    name: getRoomDisplayName(room, myUserId),
    platform: classified.platform,
    lastMessage: lastEvent ? eventBody(lastEvent) : "No messages yet",
    lastTimestamp: lastEvent?.getTs() ?? room.getLastActiveTimestamp() ?? 0,
    unreadCount: room.getUnreadNotificationCount() ?? 0,
    avatarUrl: room.getMxcAvatarUrl() ?? undefined,
    isDirect: members.length === 1,
  };
}

export function buildThreadMessages(
  room: Room,
  myUserId: string,
): ThreadMessage[] {
  const timeline = room.getLiveTimeline().getEvents();
  return timeline
    .filter((e) => e.getType() === EventType.RoomMessage)
    .map((event) => ({
      eventId: event.getId()!,
      roomId: room.roomId,
      senderId: event.getSender()!,
      senderName: room.getMember(event.getSender()!)?.name ?? event.getSender()!,
      body: eventBody(event),
      timestamp: event.getTs(),
      isMine: event.getSender() === myUserId,
      msgType: (event.getContent()?.msgtype as string) ?? MsgType.Text,
    }));
}

export async function sendTextMessage(
  c: MatrixClient,
  roomId: string,
  body: string,
): Promise<void> {
  await c.sendEvent(roomId, EventType.RoomMessage, {
    msgtype: MsgType.Text,
    body,
  });
}

export async function markRoomRead(c: MatrixClient, roomId: string): Promise<void> {
  const room = c.getRoom(roomId);
  if (!room) return;
  try {
    await c.sendReadReceipt(room.getLiveTimeline().getEvents().slice(-1)[0]!);
  } catch {
    // ignore read receipt failures
  }
}

export function onClientReady(
  c: MatrixClient,
  callback: () => void,
): () => void {
  const handler = (state: string) => {
    if (state === "PREPARED" || state === "SYNCING") {
      callback();
    }
  };
  c.on(ClientEvent.Sync, handler);
  return () => c.removeListener(ClientEvent.Sync, handler);
}

export function subscribeRoomUpdates(
  c: MatrixClient,
  callback: () => void,
): () => void {
  const onTimeline = (_event: MatrixEvent, room: Room | undefined) => {
    if (room) callback();
  };
  c.on(RoomEvent.Timeline, onTimeline);
  return () => c.removeListener(RoomEvent.Timeline, onTimeline);
}

export function countRoomsByPlatform(
  c: MatrixClient,
  myUserId: string,
): Record<PlatformId, number> {
  const counts = {} as Record<PlatformId, number>;
  for (const room of c.getRooms()) {
    const preview = buildConversationPreview(room, myUserId);
    if (!preview) continue;
    counts[preview.platform] = (counts[preview.platform] ?? 0) + 1;
  }
  return counts;
}
