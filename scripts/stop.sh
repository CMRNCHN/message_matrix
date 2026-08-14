#!/usr/bin/env bash
# Stop Message Matrix containers (leaves OrbStack running).
# Usage: ./stop

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.orbstack/bin:${PATH}"

# shellcheck disable=SC1091
source scripts/lib/docker.sh

ensure_docker

echo "==> Stopping Message Matrix"
# Include bridge profile so enabled bridge containers are stopped too.
docker compose --profile bridges stop
echo "Done. Start again with: ./start"
