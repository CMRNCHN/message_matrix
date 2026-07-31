import type { MatrixClient } from "matrix-js-sdk";
import { RoomEvent, type MatrixEvent, type Room } from "matrix-js-sdk";
import { classifyRoom, shouldShowInInbox } from "../matrix/classifier";

export function subscribeDesktopNotifications(
  client: MatrixClient,
  myUserId: string,
): () => void {
  if (typeof window === "undefined" || !("__TAURI__" in window)) {
    return () => {};
  }

  const handler = async (_event: MatrixEvent, room: Room | undefined) => {
    if (!room) return;
    const classified = classifyRoom(room, myUserId);
    if (!shouldShowInInbox(classified)) return;
    if (_event.getSender() === myUserId) return;
    if (_event.getType() !== "m.room.message") return;

    const body = (_event.getContent()?.body as string) ?? "New message";
    try {
      const { sendNotification } = await import("@tauri-apps/plugin-notification");
      await sendNotification({
        title: room.name ?? "Message Matrix",
        body: body.slice(0, 120),
      });
    } catch {
      // notifications optional
    }
  };

  client.on(RoomEvent.Timeline, handler);
  return () => client.removeListener(RoomEvent.Timeline, handler);
}
