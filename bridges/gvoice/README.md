# mautrix-gvoice (Google Voice)

Bridges Google Voice SMS/MMS into Matrix.

## Requirements

- Google Voice account
- For **consumer (non-Workspace) accounts**, the bridge may need **Electron** running headless for authentication — see [mautrix-gvoice setup](https://docs.mau.fi/bridges/go/gvoice/index.html)

## Configure

```bash
./scripts/init-bridge.sh gvoice
docker compose --profile bridges --profile gvoice up -d mautrix-gvoice
```

In Element, message `@gvoicebot:yourdomain` and follow `login` instructions.

## Limitations (as of 2026)

- Call/voicemail notifications are supported; merging calls into the same room as SMS is still evolving upstream.
- Workspace Google accounts have a simpler auth path than consumer Gmail-linked Voice.
