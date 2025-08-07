#!/bin/bash

fix_permissions() {
    mkdir -p "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config"
    chmod 755 "$HOME" "$HOME/.local" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config" 2>/dev/null || true
    
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
}

setup_edge_policies() {
    if [[ -d /etc/opt/microsoft/msedge ]] || command -v microsoft-edge >/dev/null 2>&1; then
        sudo mkdir -p /etc/opt/microsoft/msedge/policies/managed 2>/dev/null || true
        if [[ -w /etc/opt/microsoft/msedge/policies/managed ]] || sudo test -w /etc/opt/microsoft/msedge/policies/managed 2>/dev/null; then
            sudo cat > /etc/opt/microsoft/msedge/policies/managed/netlution-policies.json << 'EOF' 2>/dev/null || true
{
  "HideFirstRunExperience": true,
  "DefaultBrowserSettingEnabled": false,
  "BrowserSignin": 1,
  "SyncDisabled": false,
  "ShowHomeButton": true,
  "HomepageLocation": "https://netlution365.sharepoint.com/",
  "NewTabPageLocation": "https://netlution365.sharepoint.com/"
}
EOF
        fi
    fi
}

setup_wallpaper() {
    local wallpaper_url="https://netintuneautomation.blob.core.windows.net/\$web/wallpaper.jpg"
    local wallpaper_dir="$HOME/.local/share/backgrounds"
    local wallpaper_file="$wallpaper_dir/netlution-wallpaper.jpg"
    
    mkdir -p "$wallpaper_dir"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "$wallpaper_url" -O "$wallpaper_file" 2>/dev/null || {
            return 1
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s "$wallpaper_url" -o "$wallpaper_file" 2>/dev/null || {
            return 1
        }
    else
        return 1
    fi
    
    if [[ ! -f "$wallpaper_file" ]] || [[ ! -s "$wallpaper_file" ]]; then
        return 1
    fi
    
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_file" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_file" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-options 'stretched' 2>/dev/null || true
        return 0
    else
        return 1
    fi
}

show_quick_notification() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Netlution Setup" "Konfiguration abgeschlossen! Tutorial wird geöffnet..." --icon=info
    fi
}

show_tutorial() {
    zenity --info \
        --title="Willkommen bei deinem Netlution Arbeitsplatz!" \
        --width=700 \
        --height=500 \
        --text="<span font='18' weight='bold' color='#1e3c72'>Willkommen bei deinem neuen n_Arbeitsplatz!</span>

<span font='14' weight='bold' color='#27ae60'>Automatische Konfiguration abgeschlossen:</span>

🌐 <b>Microsoft Edge</b> - Konfiguriert für Netlution SharePoint
🖼️ <b>Desktop Wallpaper</b> - Netlution Hintergrund gesetzt
⚙️ <b>System-Einstellungen</b> - Optimiert für deine Arbeit

<span font='14' weight='bold' color='#e74c3c'>📋 Nächste Schritte (manuell):</span>

<span color='#2c3e50'><b>1. Microsoft 365 Anmeldung:</b></span>
   • Öffne https://netlution365.sharepoint.com/
   • Melde dich mit deinen Netlution-Anmeldedaten an
   
<span color='#2c3e50'><b>2. Starte neu:</b></span>
   • Starte kurz neu um die Entra Registrierung abzuschließen.

<span color='#2c3e50'><b>3. Passwort ändern (empfohlen):</b></span>
   • Terminal öffnen und <b>passwd</b> eingeben
   • Oder über Systemeinstellungen → Benutzer

<span color='#2c3e50'><b>4. Gerät registrieren:</b></span>
   • Intune Portal öffnen
   • Den Anweisungen zur Geräteregistrierung folgen

<span font='12' color='#7f8c8d'>Bei Fragen: helpdesk@netlution.de</span>

<span font='10' color='#95a5a6'>Dein System ist jetzt einsatzbereit! 🎉</span>" \
        --ok-label="Tutorial schließen"
}

SETUP_FLAG="$HOME/.config/netlution-ubuntu-setup-done"

if [[ "$1" == "--reset" ]]; then
    rm -f "$SETUP_FLAG"
    rm -f "$HOME/.config/autostart/netlution-setup.desktop"
    exit 0
elif [[ "$1" == "--help" ]]; then
    exit 0
fi

if [[ -f "$SETUP_FLAG" ]]; then
    if [[ "$1" == "--show-tutorial" ]]; then
        show_tutorial
    fi
    exit 0
fi

if ! command -v zenity >/dev/null 2>&1; then
    NOGUI=true
fi

fix_permissions
setup_edge_policies
setup_wallpaper

rm -f "$HOME/.config/autostart/netlution-setup.desktop"
touch "$SETUP_FLAG"

if [[ "$NOGUI" != "true" ]]; then
    sleep 2
    show_quick_notification
    sleep 3
    show_tutorial
fi
