#!/usr/bin/env bash
# Ensure Docker CLI can reach a running daemon (OrbStack preferred on macOS).

ensure_docker() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  echo "==> Docker daemon is not reachable."

  if command -v orb >/dev/null 2>&1 || [[ -d /Applications/OrbStack.app ]]; then
    echo "    Starting OrbStack..."
    open -a OrbStack 2>/dev/null || orb start 2>/dev/null || true
    if command -v docker >/dev/null 2>&1; then
      docker context use orbstack >/dev/null 2>&1 || true
    fi
    for _ in $(seq 1 30); do
      if docker info >/dev/null 2>&1; then
        echo "    OrbStack is ready."
        return 0
      fi
      sleep 2
    done
  fi

  cat <<'EOF'
Could not connect to Docker.

On macOS, install and use OrbStack (recommended):
  brew install --cask orbstack
  open -a OrbStack
  docker context use orbstack

Using Colima instead:
  colima start
  docker context use colima

Then re-run this command.
EOF
  exit 1
}
