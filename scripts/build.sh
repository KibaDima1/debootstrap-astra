#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DIST_DIR="$ROOT_DIR/dist"
UPSTREAM_COMMIT=8457f34b4c30a09e7acfabf5ab153146cc3470ed
UPSTREAM_SHA256=6fb4622cd29f4357be070056536059c76045341faaa6499c247975cfa2e2c092
UPSTREAM_URL="https://salsa.debian.org/installer-team/debootstrap/-/archive/$UPSTREAM_COMMIT/debootstrap-$UPSTREAM_COMMIT.tar.gz"

mkdir -p "$DIST_DIR"
find "$DIST_DIR" -maxdepth 1 -type f -name '*.deb' -delete

if command -v dpkg-buildpackage >/dev/null 2>&1; then
    WORK_DIR=$(mktemp -d)
    trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM

    command -v curl >/dev/null 2>&1 || {
        echo "error: curl is required" >&2
        exit 1
    }

    curl -fsSL "$UPSTREAM_URL" -o "$WORK_DIR/upstream.tar.gz"
    if command -v sha256sum >/dev/null 2>&1; then
        actual_sha256=$(sha256sum "$WORK_DIR/upstream.tar.gz" | awk '{print $1}')
    else
        actual_sha256=$(shasum -a 256 "$WORK_DIR/upstream.tar.gz" | awk '{print $1}')
    fi
    if [ "$actual_sha256" != "$UPSTREAM_SHA256" ]; then
        echo "error: upstream archive checksum mismatch" >&2
        exit 1
    fi

    mkdir "$WORK_DIR/source"
    tar -xzf "$WORK_DIR/upstream.tar.gz" --strip-components=1 -C "$WORK_DIR/source"
    rm -rf "$WORK_DIR/source/debian"
    cp -a "$ROOT_DIR/debian" "$WORK_DIR/source/debian"
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
            apt-get install -y --no-install-recommends build-essential ca-certificates curl debhelper devscripts equivs
            mk-build-deps --install --remove --tool "apt-get -y --no-install-recommends" /src/debian/control
            /src/scripts/build.sh
        '
else
    echo "error: install dpkg-dev/debhelper or Docker" >&2
    exit 1
fi

echo "Built packages:"
find "$DIST_DIR" -maxdepth 1 -type f -name '*.deb' -print
