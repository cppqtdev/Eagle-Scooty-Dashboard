#!/bin/sh
# Cross-compiles the dashboard for the RK3328 board with the Yocto (Poky) SDK.
#   SDK_ENV   the SDK's environment script (default: Poky 4.0 aarch64)
#   QMAKE     the SDK's qmake (default: the one on PATH after sourcing)
set -e
here=$(cd "$(dirname "$0")" && pwd)
root="$here/../.."
SDK_ENV=${SDK_ENV:-/opt/poky/4.0.27/environment-setup-armv8a-poky-linux}
. "$SDK_ENV"
QMAKE=${QMAKE:-qmake}
mkdir -p "$root/build-rk3328"
cd "$root/build-rk3328"
"$QMAKE" "$root/EagleTheme.pro" CONFIG+=release
make -j"$(nproc)"
echo "Built $(pwd)/EagleTheme"
