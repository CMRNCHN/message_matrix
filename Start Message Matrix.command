#!/bin/bash
# Double-click in Finder to start Message Matrix and open the inbox.
cd "$(dirname "$0")" || exit 1
./start
echo
echo "Press Return to close this window..."
read -r _
