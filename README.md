# Automatic Bluetooth Audio Combiner (Linux Mint)

A per-user PipeWire/PulseAudio-compatible service that automatically combines
all connected Bluetooth audio outputs into one virtual output named
`both_bluetooth`.

## Supported setup

- Linux Mint 22.x (Cinnamon or other desktop editions)
- PipeWire with `pipewire-pulse` and WirePlumber
- Bluetooth devices that expose an audio playback output (normally A2DP)

## Install

Run `install.sh` as your normal desktop user:

```bash
chmod +x install.sh
./install.sh
```

After publishing this repository on GitHub, users can install with this
one-line command (replace `OWNER/REPO` with the actual GitHub path):

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install.sh | bash
```

Do not run the installer with `sudo`; it uses sudo only for apt package
installation and installs the service in the current user's home directory.

## Check

```bash
systemctl --user status auto-bluetooth-combine.service
pactl list short sinks
```

When two or more Bluetooth audio outputs are connected, `both_bluetooth`
should appear and become the default output.

## Uninstall

```bash
systemctl --user disable --now auto-bluetooth-combine.service
rm -f ~/.config/systemd/user/auto-bluetooth-combine.service
rm -f ~/.local/bin/auto-bluetooth-combine.sh
systemctl --user daemon-reload
systemctl --user reset-failed
```

## Notes

- Devices must be connected and recognized as Bluetooth audio outputs; pairing
  alone is not enough.
- The service combines every detected Bluetooth audio output, not just a
  selected pair.
- Bluetooth devices can have different audio delays; perfectly synchronized
  playback is not guaranteed.
- This is a community utility, not an official Linux Mint feature.
