#!/usr/bin/sh

# Start where the desktop entry does (Path=/opt/resolve/)
cd /opt/resolve || exit
exec "/opt/resolve/DaVinci Control Panels Setup/DaVinci Control Panels Setup" "$@"
