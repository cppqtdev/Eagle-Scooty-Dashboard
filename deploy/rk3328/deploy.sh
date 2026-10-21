#!/bin/sh
# Copies the build to the board and (re)starts it as a service.
#   BOARD   ssh target (default root@10.42.0.132)
set -e
here=$(cd "$(dirname "$0")" && pwd)
BOARD=${BOARD:-root@10.42.0.132}
ssh "$BOARD" 'mkdir -p /opt/eagle/bin /etc/eagle'
scp "$here/../../build-rk3328/EagleTheme" "$BOARD:/opt/eagle/bin/EagleTheme"
scp "$here/eagle-dashboard.service" "$BOARD:/etc/systemd/system/eagle-dashboard.service"
# The connector map: copied once, then the board's own (edit it for the harness fitted).
ssh "$BOARD" 'test -e /etc/eagle/harness.json' || scp "$here/harness.json" "$BOARD:/etc/eagle/harness.json"
# The CAN interface the dashboard reads; 500 kbit/s as on the scooter.
ssh "$BOARD" 'ip link set can0 down 2>/dev/null; ip link set can0 type can bitrate 500000 && ip link set can0 up || echo "no can0 on this board: the service will fall back to the simulator"'
ssh "$BOARD" 'systemctl daemon-reload && systemctl enable eagle-dashboard.service && systemctl restart eagle-dashboard.service'
echo "Deployed to $BOARD"
