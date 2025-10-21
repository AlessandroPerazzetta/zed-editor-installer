# Zed Installer Script

This repository contains a small POSIX shell installer for the Zed editor.

Files
- `install.sh` — main installer script.
- `LICENSE` — license for the installer.

Overview
This installer downloads a release tarball published by Zed and extracts it to a destination directory on your machine. It supports installing the `stable` or `nightly` release channels (default: `stable`) and attempts to integrate with XDG-compatible Linux desktops by installing a `.desktop` file and setting the application icon.

Requirements
- A POSIX-compatible shell (`sh`).
- `curl` or `wget` available on PATH (the script uses whichever is present).
- `tar` (for extracting the downloaded tarball).
- `sudo` may be required if the chosen installation directory requires elevated privileges.
- Tested on macOS and Linux.

Supported platforms and architectures
The script detects platform and architecture using `uname` and maps to the binaries published by Zed:
- Platforms: `macos` (Darwin) and `linux` (Linux)
- Architectures normalized by the script: `aarch64`, `x86_64`

Usage
Run the installer directly from the repository or after downloading it:

- Basic (install stable into the default location):
  - Run `./install.sh`
  - Defaults: channel = `stable`, installation path = `$HOME/.local`

- Install a specific channel:
  - Run `./install.sh nightly`
  - This downloads the `nightly` release instead of `stable`.

- Specify an installation path:
  - Run `./install.sh stable /opt`
  - The script will install to `/opt/zed-stable` (and will attempt to create the directory with `sudo` if necessary).

Notes on behavior
- Temporary files: the script uses `$TMPDIR` if set and valid, otherwise `/tmp`.
- Download URL: it fetches the latest release for the chosen channel from `https://zed.dev/api/releases/<channel>/latest/`.
- Extraction: the tarball is extracted into `<installation_path>/zed-<channel>` while stripping the archive's top-level directory.
- Permissions: if the destination directory does not exist or is not writable, the script will try to create it or change ownership using `sudo`.
- Desktop integration (Linux only): if installing on Linux, the script will copy the `zed.desktop` file into your XDG data applications directory (defaults to `$HOME/.local/share/applications` if `XDG_DATA_HOME` is not set). It modifies the desktop file so the `Exec` and `Icon` point to the installed location.

After installation
- Add Zed to your shell `PATH`, for example:
  - Add `export PATH="$HOME/.local/zed-stable/bin:$PATH"` (or the path you used) to your shell profile.
- Launching:
  - The installed binary(s) will be under `<installation_path>/zed-<channel>/bin` and a helper `libexec/zed-editor` may be present.
  - On Linux, you should also see a desktop entry in your applications menu after running the installer.

Uninstall
To remove an installed channel:
- Delete the installation directory, e.g. `rm -rf $HOME/.local/zed-stable`
- Remove the desktop entry (Linux): remove `$XDG_DATA_HOME/applications/dev.zed.Zed.desktop` or `$HOME/.local/share/applications/dev.zed.Zed.desktop`
- Remove any icon cache entries as needed (desktop environments vary).

Troubleshooting
- "Could not find 'curl' or 'wget'": install one of these utilities and re-run the script.
- "Unsupported platform or architecture": your `uname -s` or `uname -m` returned a value the installer doesn't recognize; open an issue or install manually.
- Permission issues creating the destination directory: re-run with a path you own or allow the script to use `sudo` when prompted.
- Verify files: inspect `<installation_path>/zed-<channel>/bin` and run the `zed` binary directly.

Security notes
- The script downloads a tarball from `https://zed.dev`. As with any installer, review the script before running and ensure you trust the download source.
- The installer attempts to minimize the need for `sudo` but will use it when necessary to create or change ownership of the destination directory.

License
See the `LICENSE` file in this repository for license details.
