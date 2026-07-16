#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DIST_DIR="$ROOT_DIR/dist"

mkdir -p "$DIST_DIR"
find "$DIST_DIR" -maxdepth 1 -type f -name '*.deb' -delete

if command -v dpkg-buildpackage >/dev/null 2>&1; then
    WORK_DIR=$(mktemp -d)
    trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM
    cp -a "$ROOT_DIR" "$WORK_DIR/source"
    cd "$WORK_DIR/source"
    dpkg-buildpackage --no-sign -b
    version=$(dpkg-parsechangelog -S Version)
    cp "$WORK_DIR/debootstrap_${version}_all.deb" "$DIST_DIR/"
elif command -v docker >/dev/null 2>&1; then
    docker run --rm --platform linux/amd64 \
        -e DEBIAN_FRONTEND=noninteractive \
        -v "$ROOT_DIR:/src" \
        debian:trixie-slim sh -ec '
            apt-get update
            apt-get install -y --no-install-recommends build-essential debhelper devscripts equivs
            cp -a /src /build
            cd /build
            mk-build-deps --install --remove --tool "apt-get -y --no-install-recommends" debian/control
            dpkg-buildpackage --no-sign -b
            cp /debootstrap_*_all.deb /src/dist/
        '
else
    echo "error: install dpkg-dev/debhelper or Docker" >&2
    exit 1
fi

echo "Built packages:"
find "$DIST_DIR" -maxdepth 1 -type f -name '*.deb' -print
