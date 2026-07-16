#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 DEB_DIRECTORY OUTPUT_DIRECTORY" >&2
    exit 2
fi

DEB_DIR=$1
OUTPUT_DIR=$2
POOL_DIR="$OUTPUT_DIR/pool/main/d/debootstrap"
PACKAGES_DIR="$OUTPUT_DIR/dists/stable/main/binary-amd64"

command -v apt-ftparchive >/dev/null 2>&1 || {
    echo "error: apt-ftparchive is required (package apt-utils)" >&2
    exit 1
}

mkdir -p "$POOL_DIR" "$PACKAGES_DIR"
find "$DEB_DIR" -maxdepth 1 -type f -name '*.deb' -exec cp {} "$POOL_DIR/" \;

(
    cd "$OUTPUT_DIR"
    apt-ftparchive packages pool > dists/stable/main/binary-amd64/Packages
    gzip -n -9 -c dists/stable/main/binary-amd64/Packages \
        > dists/stable/main/binary-amd64/Packages.gz
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin=debootstrap-astra \
        -o APT::FTPArchive::Release::Label=debootstrap-astra \
        -o APT::FTPArchive::Release::Suite=stable \
        -o APT::FTPArchive::Release::Codename=stable \
        -o APT::FTPArchive::Release::Architectures=amd64 \
        -o APT::FTPArchive::Release::Components=main \
        release dists/stable > dists/stable/Release
)
