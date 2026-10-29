# Automatic Bluetooth Audio Combiner

A small Linux Mint / PipeWire utility that automatically combines all connected Bluetooth audio outputs into a single virtual sink named `both_bluetooth`.

This is useful when you have multiple Bluetooth speakers or headphones connected and want them to behave like one audio output instead of switching between devices manually.

## What this project does

The tool:

- detects active Bluetooth audio sinks exposed by PipeWire
- creates a combined virtual sink named `both_bluetooth`
- sets the combined sink as the default audio output when two or more Bluetooth outputs are connected
- keeps watching for sink changes and updates the combined output automatically
- unloads the old combined module before recreating it when the device list changes

## Supported setup

- Linux Mint 22.x
- PipeWire with `pipewire-pulse`
- WirePlumber
- Bluetooth devices using audio playback profiles such as A2DP

## Requirements

The installer expects a normal desktop user session, not root.

Install the required packages automatically with:

```bash
chmod +x install.sh
./install.sh
```

You may also install it directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/MRGREENBD/automatic-bluetooth-audio-combiner/main/install.sh | bash
```

Important:

- Do not run the installer with `sudo`
- The script installs system packages using `sudo`, but the service itself is installed for the current user only
- The service is created under `~/.config/systemd/user/`

## How it works

The script does two main things:

1. It installs the required audio tools for PipeWire and PulseAudio compatibility
2. It installs a per-user systemd service that watches for Bluetooth audio devices

The watcher script:

- runs `pactl list short sinks`
- filters Bluetooth sinks using the `bluez_output.*` naming pattern
- combines them when at least two are detected
- creates the `both_bluetooth` sink using `module-combine-sink`
- moves active sink-input streams to the combined output
- listens to PipeWire events and re-runs the logic when device states change

## Check status

After installation, verify the service and outputs:

```bash
systemctl --user status auto-bluetooth-combine.service
pactl list short sinks
```

If two or more Bluetooth audio devices are connected, a sink named `both_bluetooth` should appear.

You can also open the mixer for manual checks:

```bash
pavucontrol
```

## Uninstall

```bash
systemctl --user disable --now auto-bluetooth-combine.service
rm -f ~/.config/systemd/user/auto-bluetooth-combine.service
rm -f ~/.local/bin/auto-bluetooth-combine.sh
systemctl --user daemon-reload
systemctl --user reset-failed
```

## Notes

- A Bluetooth device must be connected and visible as an audio output; pairing alone is not always enough
- This utility combines all detected Bluetooth outputs, not just one selected device
- Different Bluetooth devices may have different audio latency, so exact synchronization is not guaranteed
- This project is a community utility and is not an official Linux Mint feature

## Troubleshooting

If the combined sink does not appear:

```bash
pactl info
pactl list short sinks
systemctl --user status auto-bluetooth-combine.service
journalctl --user -u auto-bluetooth-combine.service -f
```

Also check that PipeWire is running correctly and that your Bluetooth devices are connected with the A2DP audio profile.
