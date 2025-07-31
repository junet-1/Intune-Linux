#!/bin/bash

# Netlution Ubuntu Setup - Vereinfachte Tutorial-Version
# Macht die wichtigsten Einstellungen automatisch und zeigt ein einfaches Tutorial

# Permission-Fix für .local Verzeichnisse
fix_permissions() {
    mkdir -p "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config"
    chmod 755 "$HOME" "$HOME/.local" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config" 2>/dev/null || true
    
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
}

# Edge Policies automatisch setzen
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

# Desktop Shortcuts automatisch erstellen
create_desktop_shortcuts() {
    DESKTOP_DIR="$HOME/Desktop"
    mkdir -p "$DESKTOP_DIR"
    
    # Netlution SharePoint Shortcut
    cat > "$DESKTOP_DIR/Netlution-SharePoint.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution SharePoint
Comment=Zugang zu Netlution Dateien und Projekten
Exec=microsoft-edge https://netlution365.sharepoint.com/
Icon=folder-documents
Terminal=false
Categories=Network;FileManager;
EOF
    
    # Intune Portal Shortcut (falls verfügbar)
    if command -v intune-portal >/dev/null 2>&1; then
        cat > "$DESKTOP_DIR/Netlution-Geraeteverwaltung.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution Geräteverwaltung
Comment=Intune Company Portal
Exec=intune-portal
Icon=intune-portal
Terminal=false
Categories=System;Settings;
EOF
    fi
    
    chmod +x "$DESKTOP_DIR"/*.desktop 2>/dev/null || true
}

# Einfaches Tutorial-Fenster
show_tutorial() {
    zenity --info \
        --title="🏢 Willkommen bei deinem Netlution Arbeitsplatz!" \
        --width=700 \
        --height=500 \
        --text="<span font='18' weight='bold' color='#1e3c72'>Willkommen bei deinem neuen Netlution Arbeitsplatz!</span>

<span font='14' weight='bold' color='#27ae60'>✅ Automatische Konfiguration abgeschlossen:</span>

🌐 <b>Microsoft Edge</b> - Konfiguriert für Netlution SharePoint
🖥️ <b>Desktop Shortcuts</b> - Schnellzugriff auf wichtige Tools
⚙️ <b>System-Einstellungen</b> - Optimiert für deine Arbeit

<span font='14' weight='bold' color='#e74c3c'>📋 Nächste Schritte (manuell):</span>

<span color='#2c3e50'><b>1. Microsoft 365 Anmeldung:</b></span>
   • Öffne den <b>Netlution SharePoint</b> Shortcut
   • Melde dich mit deinen Netlution-Anmeldedaten an

<span color='#2c3e50'><b>2. Gerät neustarten:</b></span>
   • Starte kurz neu um eine saubere Inetragion zu haben</b> Shortcut

<span color='#2c3e50'><b>3. Passwort ändern:</b></span>
   • Terminal öffnen und <b>passwd</b> eingeben
   • Oder über Systemeinstellungen → Benutzer

<span color='#2c3e50'><b>4. Gerät registrieren:</b></span>
   • Intune Portal öffnen
   • Den Anweisungen zur Geräteregistrierung folgen

<span font='12' color='#7f8c8d'>Bei Fragen: helpdesk@netlution.de</span>

<span font='10' color='#95a5a6'>Dein System ist jetzt einsatzbereit! 🎉</span>" \
        --ok-label="Tutorial schließen"
}

# Quick-Start Benachrichtigung
show_quick_notification() {
    notify-send \
        "Netlution Setup" \
        "🎉 Willkommen bei deinem n_Arbeitsplatz!\n\nSetup abgeschlossen!" \
        --icon=dialog-information \
        --app-name="Netlution IT" \
        --expire-time=3000
}

# Flag für einmalige Ausführung
SETUP_FLAG="$HOME/.config/netlution-ubuntu-setup-done"

# Prüfen ob Setup bereits ausgeführt wurde
if [[ -f "$SETUP_FLAG" ]]; then
    # Setup bereits ausgeführt - nur Tutorial zeigen falls gewünscht
    if [[ "$1" == "--show-tutorial" ]] || [[ "$1" == "--help" ]]; then
        show_tutorial
    else
        echo "Netlution Setup bereits abgeschlossen."
        echo "Verwende --show-tutorial um das Tutorial erneut anzuzeigen."
    fi
    exit 0
fi

# Prüfen ob zenity verfügbar ist
if ! command -v zenity >/dev/null 2>&1; then
    echo "Warnung: zenity nicht verfügbar - Setup läuft ohne GUI"
    NOGUI=true
fi

# Automatische Konfiguration durchführen
echo "🔧 Netlution Ubuntu Setup wird ausgeführt..."

# 1. Permissions korrigieren
echo "   • Berechtigungen korrigieren..."
fix_permissions

# 2. Edge Policies setzen
echo "   • Microsoft Edge konfigurieren..."
setup_edge_policies

# 3. Desktop Shortcuts erstellen
echo "   • Desktop Shortcuts erstellen..."
create_desktop_shortcuts

# 4. Autostart-Datei entfernen (falls vorhanden)
rm -f "$HOME/.config/autostart/netlution-setup.desktop"

# 5. Setup als abgeschlossen markieren
touch "$SETUP_FLAG"

echo "✅ Automatische Konfiguration abgeschlossen!"

# Tutorial anzeigen (falls GUI verfügbar)
if [[ "$NOGUI" != "true" ]]; then
    # Kurz warten bis alles bereit ist
    sleep 2
    
    # Benachrichtigung senden
    show_quick_notification
    
    # Kurze Pause dann Tutorial
    sleep 3
    show_tutorial
else
    # Fallback für Non-GUI Umgebungen
    echo ""
    echo "🏢 Willkommen bei deinem Netlution Arbeitsplatz!"
    echo "================================================"
    echo ""
    echo "✅ Automatische Konfiguration abgeschlossen:"
    echo "   • Microsoft Edge konfiguriert"
    echo "   • Desktop Shortcuts erstellt"
    echo "   • System-Einstellungen optimiert"
    echo ""
    echo "📋 Nächste Schritte:"
    echo "   1. Microsoft Edge öffnen → https://netlution365.sharepoint.com/"
    echo "   2. Mit Netlution-Anmeldedaten anmelden"
    echo "   3. Passwort ändern: passwd"
    echo "   4. Gerät registrieren (Intune Portal)"
    echo ""
    echo "Bei Fragen: helpdesk@netlution.de"
    echo ""
    echo "Dein System ist jetzt einsatzbereit! 🎉"
fi

echo ""
echo "Netlution Setup abgeschlossen. Verwende '$0 --show-tutorial' um das Tutorial erneut anzuzeigen."
