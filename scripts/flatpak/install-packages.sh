#!/bin/bash

set -e

SCRIPTDIR=$(dirname "${BASH_SOURCE[0]}")

function retry_command {
  # Package servers tend to be unreliable at times..
  # Retry a bunch of times.
  local RETRIES=10

  for i in $(seq 1 "$RETRIES"); do
    "$@" && break
    if [ "$i" == "$RETRIES" ]; then
      echo "Command \"$@\" failed after ${RETRIES} retries."
      exit 1
    fi
  done
}

ARCH=x86_64
KDE_BRANCH=6.6
BRANCH=23.08
FLAT_MANAGER_CLIENT_DIR="$HOME/.local/bin"

# Build packages. Mostly needed for flat-manager-client.
declare -a BUILD_PACKAGES=(
  "flatpak"
  "flatpak-builder"
  "appstream-util"
  "python3-aiohttp"
  "python3-tenacity"
  "python3-gi"
  "gobject-introspection"
  "libappstream-glib8"
  "libappstream-glib-dev"
  "libappstream-dev"
  "gir1.2-ostree-1.0"
)

# Flatpak runtimes and SDKs.
declare -a FLATPAK_PACKAGES=(
  "org.kde.Platform/${ARCH}/${KDE_BRANCH}"
  "org.kde.Sdk/${ARCH}/${KDE_BRANCH}"
  "org.freedesktop.Sdk.Extension.llvm17/${ARCH}/${BRANCH}"
  "org.freedesktop.appstream-glib/${ARCH}/stable"
)

retry_command sudo apt-get -qq update

# Install packages needed for building
echo "Will install the following packages for building - ${BUILD_PACKAGES[*]}"
retry_command sudo apt-get -y install "${BUILD_PACKAGES[@]}"

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install packages needed for building
echo "Will install the following packages for building - ${FLATPAK_PACKAGES[*]}"
retry_command sudo flatpak -y install "${FLATPAK_PACKAGES[@]}"

echo "Downloading flat-manager-client"
mkdir -p "$FLAT_MANAGER_CLIENT_DIR"
pushd "$FLAT_MANAGER_CLIENT_DIR"
aria2c -Z "https://raw.githubusercontent.com/flatpak/flat-manager/9401efbdc0d6bd489507d8401c567ba219d735d5/flat-manager-client"
chmod +x flat-manager-client
echo "$FLAT_MANAGER_CLIENT_DIR" >> $GITHUB_PATH
popd
