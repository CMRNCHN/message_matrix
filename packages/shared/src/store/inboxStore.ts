import { create } from "zustand";
import type { MatrixClient } from "matrix-js-sdk";
import type { PlatformId } from "../bridges";
import type { ConversationPreview, ThreadMessage, AppConfig } from "../matrix/client";
import {
  buildConversationPreview,
  buildThreadMessages,
  getMatrixClient,
  loginWithPassword,
  markRoomRead,
  restoreSession,
  sendTextMessage,
  startSync,
  onClientReady,
  subscribeRoomUpdates,
  countRoomsByPlatform,
} from "../matrix/client";
import { subscribeDesktopNotifications } from "../matrix/notifications";

import {
  saveSession,
  loadSession,
  clearSession,
} from "../storage/session";

export type PlatformFilter = "all" | PlatformId;

interface InboxState {
  config: AppConfig | null;
  client: MatrixClient | null;
  userId: string | null;
  isAuthenticated: boolean;
  isSyncing: boolean;
  syncError: string | null;
  conversations: ConversationPreview[];
  selectedRoomId: string | null;
  messages: ThreadMessage[];
  platformFilter: PlatformFilter;
  searchQuery: string;
  pinnedRoomIds: Set<string>;
  mutedRoomIds: Set<string>;
  settingsOpen: boolean;
  platformCounts: Partial<Record<PlatformId, number>>;

  loadConfig: (config: AppConfig) => void;
  login: (username: string, password: string) => Promise<void>;
  restoreLogin: () => Promise<boolean>;
  logout: () => void;
  refreshConversations: () => void;
  selectRoom: (roomId: string) => void;
  sendMessage: (body: string) => Promise<void>;
  setPlatformFilter: (filter: PlatformFilter) => void;
  setSearchQuery: (query: string) => void;
  togglePin: (roomId: string) => void;
  toggleMute: (roomId: string) => void;
  setSettingsOpen: (open: boolean) => void;
  getFilteredConversations: () => ConversationPreview[];
}

export const useInboxStore = create<InboxState>((set, get) => ({
  config: null,
  client: null,
  userId: null,
  isAuthenticated: false,
  isSyncing: false,
  syncError: null,
  conversations: [],
  selectedRoomId: null,
  messages: [],
  platformFilter: "all",
  searchQuery: "",
  pinnedRoomIds: new Set(),
  mutedRoomIds: new Set(),
  settingsOpen: false,
  platformCounts: {},

  loadConfig: (config) => set({ config }),

  login: async (username, password) => {
    const { config } = get();
    if (!config) throw new Error("Config not loaded");
    set({ isSyncing: true, syncError: null });
    try {
      const creds = await loginWithPassword(
        config.homeserverUrl,
        username,
        password,
      );
      const client = getMatrixClient()!;
      await saveSession({
        homeserverUrl: config.homeserverUrl,
        userId: creds.userId,
        accessToken: creds.accessToken,
        deviceId: creds.deviceId,
      });

      await startSync(client);

      onClientReady(client, () => get().refreshConversations());
      subscribeRoomUpdates(client, () => get().refreshConversations());
      subscribeDesktopNotifications(client, creds.userId);

      set({
        client,
        userId: creds.userId,
        isAuthenticated: true,
        isSyncing: false,
      });
      get().refreshConversations();
    } catch (err) {
      set({
        isSyncing: false,
        syncError: err instanceof Error ? err.message : "Login failed",
      });
      throw err;
    }
  },

  restoreLogin: async () => {
    const session = await loadSession();
    const { config } = get();
    if (!session || !config) return false;
    if (session.homeserverUrl !== config.homeserverUrl) return false;

    set({ isSyncing: true, syncError: null });
    try {
      const client = restoreSession(
        session.homeserverUrl,
        session.userId,
        session.accessToken,
        session.deviceId,
      );
      await startSync(client);
      onClientReady(client, () => get().refreshConversations());
      subscribeRoomUpdates(client, () => get().refreshConversations());
      subscribeDesktopNotifications(client, session.userId);
      set({
        client,
        userId: session.userId,
        isAuthenticated: true,
        isSyncing: false,
      });
      get().refreshConversations();
      return true;
    } catch {
      await clearSession();
      set({ isSyncing: false });
      return false;
    }
  },

  logout: () => {
    const { client } = get();
    client?.stopClient();
    void clearSession();
    set({
      client: null,
      userId: null,
      isAuthenticated: false,
      conversations: [],
      selectedRoomId: null,
      messages: [],
      platformCounts: {},
    });
  },

  refreshConversations: () => {
    const { client, userId } = get();
    if (!client || !userId) return;
    const conversations = client
      .getRooms()
      .map((room) => buildConversationPreview(room, userId))
      .filter((c): c is ConversationPreview => c !== null)
      .sort((a, b) => b.lastTimestamp - a.lastTimestamp);

    set({
      conversations,
      platformCounts: countRoomsByPlatform(client, userId),
    });

    const { selectedRoomId } = get();
    if (selectedRoomId) {
      const room = client.getRoom(selectedRoomId);
      if (room) {
        set({ messages: buildThreadMessages(room, userId) });
      }
    }
  },

  selectRoom: (roomId) => {
    const { client, userId } = get();
    if (!client || !userId) return;
    const room = client.getRoom(roomId);
    if (!room) return;
    set({
      selectedRoomId: roomId,
      messages: buildThreadMessages(room, userId),
    });
    void markRoomRead(client, roomId);
    get().refreshConversations();
  },

  sendMessage: async (body) => {
    const { client, selectedRoomId } = get();
    if (!client || !selectedRoomId || !body.trim()) return;
    await sendTextMessage(client, selectedRoomId, body.trim());
    get().refreshConversations();
  },

  setPlatformFilter: (filter) => set({ platformFilter: filter }),

  setSearchQuery: (query) => set({ searchQuery: query }),

  togglePin: (roomId) => {
    const pinned = new Set(get().pinnedRoomIds);
    if (pinned.has(roomId)) pinned.delete(roomId);
    else pinned.add(roomId);
    set({ pinnedRoomIds: pinned });
  },

  toggleMute: (roomId) => {
    const muted = new Set(get().mutedRoomIds);
    if (muted.has(roomId)) muted.delete(roomId);
    else muted.add(roomId);
    set({ mutedRoomIds: muted });
  },

  setSettingsOpen: (open) => set({ settingsOpen: open }),

  getFilteredConversations: () => {
    const { conversations, platformFilter, searchQuery, pinnedRoomIds } = get();
    let list = [...conversations];

    if (platformFilter !== "all") {
      list = list.filter((c) => c.platform === platformFilter);
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      list = list.filter(
        (c) =>
          c.name.toLowerCase().includes(q) ||
          c.lastMessage.toLowerCase().includes(q),
      );
    }

    list.sort((a, b) => {
      const aPin = pinnedRoomIds.has(a.roomId) ? 1 : 0;
      const bPin = pinnedRoomIds.has(b.roomId) ? 1 : 0;
      if (aPin !== bPin) return bPin - aPin;
      return b.lastTimestamp - a.lastTimestamp;
    });

    return list;
  },
}));
