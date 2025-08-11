#!/bin/bash

# Warten bis OEM-Setup vollständig abgeschlossen ist
while [ ! -f /var/lib/oem-config/run ]; do
  sleep 5
done

# Den neu erstellten User finden
REAL_USER=$(getent passwd | grep -E ":[0-9]{4,}:" | grep -v "^_" | grep -v "^systemd" | head -n1 | cut -d: -f1)

if [ -n "$REAL_USER" ]; then
  USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  
  # Netlution Files herunterladen
  wget -O "$USER_HOME/netlution-setup.sh" "https://raw.githubusercontent.com/junet-1/Intune-Linux/refs/heads/main/netlution-setup.sh"
  mkdir -p "$USER_HOME/.config/autostart"
  wget -O "$USER_HOME/.config/autostart/netlution-setup.desktop" "https://raw.githubusercontent.com/junet-1/Intune-Linux/refs/heads/main/netlution-setup.desktop"
  
  # Berechtigungen setzen
  chmod +x "$USER_HOME/netlution-setup.sh"
  chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/netlution-setup.sh" "$USER_HOME/.config/"
  
  # Setup abgeschlossen markieren
  touch /var/lib/netlution-setup-completed
  systemctl disable netlution-post-oem.service
fi