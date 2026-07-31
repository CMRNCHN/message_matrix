#!/bin/sh
# Render inbox config.json from environment at container start
set -e
CONFIG="/usr/share/nginx/html/config.json"
cat > "$CONFIG" <<EOF
{
  "homeserverUrl": "${INBOX_HOMESERVER_URL:-https://matrix.example.com}",
  "serverName": "${INBOX_SERVER_NAME:-example.com}"
}
EOF
exec nginx -g 'daemon off;'
