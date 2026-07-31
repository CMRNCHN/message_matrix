# Future & experimental bridges

Production bridges are wired into `docker-compose.yml` and have wizards under `./connect`.

| Platform | Status | How to add |
|----------|--------|------------|
| WhatsApp | Production | `./connect whatsapp` |
| Discord | Production | `./connect discord` |
| Slack | Production | `./connect slack` |
| Google Messages | Production | `./connect gmessages` |
| Meta | Production | `./connect meta` |
| **Snapchat** | Experimental | `./connect snapchat` (explains limitations) |

## Snapchat

Community WIP: [lalomorales22/snapchat-bridge](https://github.com/lalomorales22/snapchat-bridge)

No official API — requires reverse-engineered endpoints. The wizard blocks full setup until a production image is available.

## Plugin wizard pattern

To add a new connection:

1. Register in `scripts/lib/bridges.sh` (`BRIDGE_IDS`, ports, bot name)
2. Add Docker service to `docker-compose.yml`
3. Create `scripts/wizards/<id>.sh` (see `signal.sh` as minimal example)
4. Optional: `bridges/<id>/README.md`

The wizard calls `wizard_finish_bridge` from `_common.sh` which handles init, Synapse registration, and container start.
