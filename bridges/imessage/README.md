# BlueBubbles + mautrix-imessage

iMessage is bridged through a **BlueBubbles server** running on macOS — not directly from Linux/Docker.

## Setup BlueBubbles (macOS)

1. Install [BlueBubbles Server](https://bluebubbles.app/install) on a Mac signed into iMessage.
2. Enable the REST API and set a server password.
3. Note the server URL (default `http://<mac-ip>:1234`).

If you don't have a physical Mac, see [BlueBubbles in Docker-OSX](https://docs.bluebubbles.app/server/advanced/macos-virtualization/running-bluebubbles-in-docker-osx/configuring-bluebubbles-as-a-service).

## Configure this stack

In `.env`:

```bash
BLUEBUBBLES_URL=http://192.168.1.50:1234   # or host.docker.internal if Mac is Docker host
BLUEBUBBLES_PASSWORD=your-bluebubbles-password
```

Re-run bridge init:

```bash
./scripts/init-bridge.sh imessage
docker compose --profile bridges up -d mautrix-imessage
```

## Verify

1. BlueBubbles web UI shows connected / messages syncing.
2. In Element, DM `@imessagebot:yourdomain` and run `login` if prompted.
3. Existing iMessage chats should appear as Matrix rooms (may take a few minutes on first sync).

Docs: [mautrix imessage BlueBubbles](https://github.com/mautrix/imessage/blob/master/imessage/bluebubbles/README.md)
