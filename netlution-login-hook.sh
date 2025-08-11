#!/bin/bash
# Nur beim ersten grafischen Login und wenn Setup noch nicht gemacht wurde
if [ -n "$DISPLAY" ] && [ "$USER" != "root" ] && [ ! -f "$HOME/.netlution-setup-done" ]; then
  # Netlution Files herunterladen
  wget -O "$HOME/netlution-setup.sh" "https://raw.githubusercontent.com/DEIN-REPO/BRANCH/netlution-setup.sh" 2>/dev/null
  if [ $? -eq 0 ]; then
    mkdir -p "$HOME/.config/autostart"
    wget -O "$HOME/.config/autostart/netlution-setup.desktop" "https://raw.githubusercontent.com/junet-1/Intune-Linux/refs/heads/main/netlution-setup.desktop" 2>/dev/null
    chmod +x "$HOME/netlution-setup.sh"
    touch "$HOME/.netlution-setup-done"
    # Netlution Setup sofort starten
    "$HOME/netlution-setup.sh" &
  fi

fi
