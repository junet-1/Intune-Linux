#!/bin/bash
HOST=$(cat /target/etc/hostname)
KEY=$(cat /target/setup/${HOST}-User.password)

# GNOME-Session-Variablen setzen
export DISPLAY=:0
export XAUTHORITY=/run/user/999/.Xauthority
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/999/bus

zenity --info \
  --title="Wichtiger Hinweis" \
  --width=450 \
  --height=200 \
  --text="Hi,\n\nDein vorläufiges LUKS-Verschlüsselungskennwort ist:\n\n<b>${KEY}</b>\n\nSobald du auf „Neustart“ klickst, gibt es keine Möglichkeit mehr, dieses einzusehen."
