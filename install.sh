#!/usr/bin/env sh
set -eu

# Get arguments, if any (e.g., "stable" or "nightly")
channel="${1:-stable}"
# Get destination directory from arguments or default to ~/.local
installation_path="${2:-$HOME/.local}"
# Clean installation_path if contain a trailing slash
installation_path="${installation_path%/}"

platform="$(uname -s)"
arch="$(uname -m)"

# Download file from URL to destination using curl or wget
download() {
    url="$1"
    dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$dest" "$url"
    else
        echo "Could not find 'curl' or 'wget' in your path"
        exit 1
    fi
}

# Integration with an XDG-compatible desktop environment, need to install the .desktop file
xdg_install() {
    if [ -n "${XDG_DATA_HOME:-}" ]; then
        data_home="$XDG_DATA_HOME"
    else
        data_home="$HOME/.local/share"
    fi

    cp "$installation_path/zed-${channel}/share/applications/zed.desktop" "$data_home/applications/dev.zed.Zed.desktop"
    sed -i "s|Icon=zed|Icon=$installation_path/zed-${channel}/share/icons/hicolor/512x512/apps/zed.png|g" "$data_home/applications/dev.zed.Zed.desktop"
    sed -i "s|Exec=zed|Exec=$installation_path/zed-${channel}/libexec/zed-editor|g" "$data_home/applications/dev.zed.Zed.desktop"

}

# Main installation logic
main() {
    # Use TMPDIR if available (for environments with non-standard temp directories)
    if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR}" ]; then
        echo "Using TMPDIR: $TMPDIR"    
        temp="$(mktemp -d "$TMPDIR/zed-installer.XXXXXX")"
        echo "Created temp dir: $temp"
    else
        echo "Using /tmp for temporary files"
        temp="$(mktemp -d "/tmp/zed-installer.XXXXXX")"
        echo "Created temp dir: $temp"
    fi

    if [ "$platform" = "Darwin" ]; then
        platform="macos"
    elif [ "$platform" = "Linux" ]; then
        platform="linux"
    else
        echo "Unsupported platform $platform"
        exit 1
    fi

    case "$platform-$arch" in
        macos-arm64* | linux-arm64* | linux-armhf | linux-aarch64)
            arch="aarch64"
            ;;
        macos-x86* | linux-x86* | linux-i686*)
            arch="x86_64"
            ;;
        *)
            echo "Unsupported platform or architecture"
            exit 1
            ;;
    esac

    echo "Installing Zed ($channel) for $platform-$arch to $installation_path/zed-${channel}"


    # https://zed.dev/api/releases/$channel/latest/zed-linux-$arch.tar.gz
    tarball="zed-${platform}-${arch}.tar.gz"
    url="https://zed.dev/api/releases/${channel}/latest/${tarball}"

    echo "Downloading Zed from $url"
    download "$url" "$temp/$tarball"

    # Check if $installation_path/zed-${channel} exists, if not try to create it, if fails try to create with sudo and grant permissions for the user
    if [ ! -d "$installation_path/zed-${channel}" ]; then
        echo "$installation_path/zed-${channel} does not exist. Creating it."
        mkdir -p "$installation_path/zed-${channel}" || {
            echo "Failed to create $installation_path/zed-${channel}. Trying with sudo."
            sudo mkdir -p "$installation_path/zed-${channel}" || {
                echo "Failed to create $installation_path/zed-${channel} even with sudo. Exiting."
                exit 1
            }
            sudo chown "$(whoami)":"$(whoami)" "$installation_path/zed-${channel}"
        }
    else
        echo "$installation_path/zed-${channel} already exists."
        # Check if we have write permissions
        if [ ! -w "$installation_path/zed-${channel}" ]; then
            echo "No write permissions for $installation_path/zed-${channel}. Trying to change ownership with sudo."
            sudo chown -R "$(whoami)":"$(whoami)" "$installation_path/zed-${channel}" || {
                echo "Failed to change ownership of $installation_path/zed-${channel}. Exiting."
                exit 1
            }
        fi
    fi

    echo "Installing Zed to $installation_path/zed-${channel}"
    
    # tar -xzf "$temp/$tarball" -C "$installation_path/zed-${channel}"
    # Extract tarball to installation_path/zed-${channel} getting rid of the top-level directory
    tar -xzf "$temp/$tarball" -C "$installation_path/zed-${channel}" --strip-components=1

    echo "Zed has been installed to $dest/zed-${channel}"
    echo "To run Zed from your terminal, add $installation_path/zed-${channel}/bin to your PATH"
    echo "For example, you can add the following line to your shell profile:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'

    # Install .desktop file and icons for desktop integration
    if [ "$platform" = "linux" ]; then
        xdg_install
    fi
}

main