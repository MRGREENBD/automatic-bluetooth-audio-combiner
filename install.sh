#!/usr/bin/env bash
# Automatic Bluetooth audio combiner for Linux Mint 22.x / PipeWire.
# Installs a per-user systemd service that combines every connected
# Bluetooth A2DP output into one virtual sink named "both_bluetooth".

set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this installer as your normal desktop user, not with sudo." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer expects Linux Mint / Ubuntu with apt-get." >&2
  exit 1
fi

echo "[1/4] Installing required audio tools..."
sudo apt-get update
sudo apt-get install -y pipewire-pulse wireplumber pavucontrol

if ! command -v pactl >/dev/null 2>&1; then
  echo "pactl was not found after installing pipewire-pulse." >&2
  exit 1
fi

echo "[2/4] Installing automatic Bluetooth audio watcher..."
install -d "${HOME}/.local/bin" "${HOME}/.config/systemd/user"

cat > "${HOME}/.local/bin/auto-bluetooth-combine.sh" <<'WATCHER'
#!/usr/bin/env bash
set -u

COMBINE="both_bluetooth"
LAST="__initial__"

get_bt_sinks() {
  pactl list short sinks 2>/dev/null |
    awk '$2 ~ /^bluez_output\./ {print $2}' |
    sort |
    paste -sd, -
}

reconcile() {
  local current module count id

  current="$(get_bt_sinks)"
  [[ "$current" == "$LAST" ]] && return
  LAST="$current"

  module="$(
    pactl list short modules 2>/dev/null |
      awk '$2 == "module-combine-sink" && /sink_name=both_bluetooth/ {print $1; exit}'
  )"

  if [[ -n "$module" ]]; then
    pactl unload-module "$module" >/dev/null 2>&1 || true
  fi

  if [[ -z "$current" ]]; then
    echo "No Bluetooth audio outputs connected."
    return
  fi

  count="$(awk -F, '{print NF}' <<< "$current")"

  if (( count >= 2 )); then
    if pactl load-module module-combine-sink \
      sink_name="$COMBINE" slaves="$current" >/dev/null; then
      pactl set-default-sink "$COMBINE" >/dev/null 2>&1 || true

      # Move currently playing streams into the combined output.
      while read -r id; do
        [[ -n "$id" ]] &&
          pactl move-sink-input "$id" "$COMBINE" >/dev/null 2>&1 || true
      done < <(pactl list short sink-inputs 2>/dev/null | awk '{print $1}')

      echo "Combined $count Bluetooth audio outputs: $current"
    else
      echo "Could not create the combined output. Check Bluetooth profiles and PipeWire."
    fi
  else
    pactl set-default-sink "$current" >/dev/null 2>&1 || true
    echo "One Bluetooth audio output connected: $current"
  fi
}

# Wait briefly for the user's audio session to become ready.
for _ in {1..30}; do
  pactl info >/dev/null 2>&1 && break
  sleep 1
done

reconcile

# Reconcile whenever a Bluetooth sink is added, changed, or removed.
while IFS= read -r event; do
  case "$event" in
    *"on sink"*)
      sleep 2
      reconcile
      ;;
  esac
done < <(pactl subscribe)
WATCHER

chmod 0755 "${HOME}/.local/bin/auto-bluetooth-combine.sh"

echo "[3/4] Installing and enabling the user service..."
cat > "${HOME}/.config/systemd/user/auto-bluetooth-combine.service" <<'UNIT'
[Unit]
Description=Automatically combine connected Bluetooth audio outputs
After=pipewire.service pipewire-pulse.service wireplumber.service
Wants=pipewire.service pipewire-pulse.service wireplumber.service

[Service]
Type=simple
ExecStart=%h/.local/bin/auto-bluetooth-combine.sh
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
UNIT

systemctl --user daemon-reload
systemctl --user enable --now auto-bluetooth-combine.service

echo "[4/4] Installation complete."
echo
echo "Connect at least two Bluetooth audio devices (A2DP)."
echo "Check status:  systemctl --user status auto-bluetooth-combine.service"
echo "Check outputs: pactl list short sinks"
echo "Open mixer:    pavucontrol"
echo
echo "Note: this combines all detected Bluetooth audio outputs. Bluetooth latency"
echo "can differ between devices, and some devices may not support simultaneous playback."
