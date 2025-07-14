#!/bin/bash

# Am Anfang deines netlution-setup.sh Scripts hinzufügen:

# Permission-Fix für .local Verzeichnisse
fix_permissions() {
    # Stelle sicher, dass alle benötigten Verzeichnisse existieren und korrekte Permissions haben
    mkdir -p "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config"
    
    # Permissions korrigieren falls nötig
    chmod 755 "$HOME" "$HOME/.local" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache" "$HOME/.config" 2>/dev/null || true
    
    # XDG Umgebungsvariablen setzen
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export XDG_STATE_HOME="$HOME/.local/state"
}

# Prüfe ob dies der erste Login ist
FIRST_LOGIN_FLAG="$HOME/.config/netlution-ubuntu-sso-first-login"

if [[ -f "$FIRST_LOGIN_FLAG" ]]; then
    exit 0
fi

# Permissions fix als erstes
fix_permissions

# Warten bis Desktop vollständig geladen ist
sleep 8

# Funktionen für die verschiedenen Setup-Schritte
show_welcome() {
    zenity --info \
        --title="🔧 Netlution_Ubuntu Setup" \
        --width=500 \
        --height=300 \
        --text="<b><big>Willkommen bei deinem Netlution_Ubuntu Arbeitsplatz!</big></b>\n\n🏢 <b>Netlution IT Solutions</b>\n\nDein System ist fast bereit. Wir führen dich jetzt durch die letzten Schritte:\n\n✅ Microsoft 365 Anmeldung\n✅ Intune Geräteregistrierung\n✅ Desktop-Setup\n\n<i>Das dauert nur wenige Minuten!</i>" \
        --ok-label="Setup starten"
}

setup_microsoft_edge() {
    if zenity --question \
        --title="🌐 Microsoft Edge Setup" \
        --width=450 \
        --text="<b>Schritt 1: Microsoft 365 Anmeldung</b>\n\nWir öffnen jetzt Microsoft Edge mit den wichtigsten Netlution Portalen:\n\n• Microsoft 365 Portal\n• Teams\n• SharePoint\n\nBitte melde dich mit deinen <b>Netlution Microsoft 365</b> Anmeldedaten an.\n\n<small>Tipp: Du kannst alle Tabs offen lassen und nach der Anmeldung zu diesem Dialog zurückkehren.</small>" \
        --ok-label="Edge öffnen" \
        --cancel-label="Überspringen"; then
        
        # Microsoft Edge mit Netlution URLs starten
        if command -v microsoft-edge >/dev/null 2>&1; then
            microsoft-edge \
                --new-window \
                "https://login.microsoftonline.com/" \
                "https://portal.office.com/" \
                "https://teams.microsoft.com/" \
                "https://netlution365.sharepoint.com/" >/dev/null 2>&1 &
            
            # Kurze Pause, dann Bestätigung
            sleep 3
            zenity --info \
                --title="🌐 Microsoft Edge" \
                --text="✅ <b>Microsoft Edge wurde geöffnet!</b>\n\nBitte melde dich in den geöffneten Tabs an.\nKomm danach zu diesem Dialog zurück und klicke 'Weiter'." \
                --ok-label="Weiter"
        else
            zenity --warning \
                --title="⚠️ Microsoft Edge" \
                --text="Microsoft Edge ist nicht installiert.\nBitte wende dich an das Netlution IT-Team."
        fi
    fi
}

setup_intune_portal() {
    if zenity --question \
        --title="📱 Intune Company Portal" \
        --width=450 \
        --text="<b>Schritt 2: Geräteregistrierung</b>\n\nJetzt registrieren wir dein Netlution_Ubuntu Gerät im Intune Company Portal.\n\nDas ermöglicht:\n• Zentrale Geräteverwaltung\n• Automatische App-Installation\n• Sicherheitsrichtlinien\n• Remote-Support\n\n<small>Die Registrierung ist erforderlich für den Zugang zu Netlution Ressourcen.</small>" \
        --ok-label="Intune Portal öffnen" \
        --cancel-label="Später"; then
        
        if command -v intune-portal >/dev/null 2>&1; then
            intune-portal >/dev/null 2>&1 &
            sleep 2
            zenity --info \
                --title="📱 Intune Company Portal" \
                --text="✅ <b>Intune Company Portal wurde gestartet!</b>\n\nFolge den Anweisungen im Portal zur Geräteregistrierung.\nDas kann einige Minuten dauern." \
                --ok-label="Weiter"
        elif command -v microsoft-edge >/dev/null 2>&1; then
            # Fallback: Browser mit Intune Web-Portal
            microsoft-edge "https://portal.manage.microsoft.com/" >/dev/null 2>&1 &
            zenity --info \
                --title="📱 Intune Web-Portal" \
                --text="✅ <b>Intune Web-Portal wurde geöffnet!</b>\n\n(Das Company Portal ist nicht installiert - verwende das Web-Portal)\n\nRegistriere dein Gerät über das Web-Interface." \
                --ok-label="Weiter"
        else
            zenity --warning \
                --title="⚠️ Intune Portal" \
                --text="Intune Portal ist nicht verfügbar.\nBitte wende dich an das Netlution IT-Team."
        fi
    fi
}

create_desktop_shortcuts() {
    if zenity --question \
        --title="🖥️ Desktop Setup" \
        --width=450 \
        --text="<b>Schritt 3: Desktop-Shortcuts erstellen</b>\n\nMöchtest du hilfreiche Shortcuts auf deinem Desktop?\n\nWir erstellen Verknüpfungen für:\n• Netlution Microsoft 365\n• Netlution Teams\n• Netlution SharePoint\n• Geräteverwaltung\n\n<small>Du kannst diese später jederzeit anpassen oder löschen.</small>" \
        --ok-label="Shortcuts erstellen" \
        --cancel-label="Überspringen"; then
        
        DESKTOP_DIR="$HOME/Desktop"
        mkdir -p "$DESKTOP_DIR"
        
        # Netlution Microsoft 365 Shortcut
        cat > "$DESKTOP_DIR/Netlution-Microsoft365.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution Microsoft 365
Comment=Dein Zugang zu Netlution Office 365 Portal
Exec=microsoft-edge https://portal.office.com/
Icon=microsoft-edge
Terminal=false
Categories=Network;Office;
EOF
        
        # Netlution Teams Shortcut
        cat > "$DESKTOP_DIR/Netlution-Teams.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution Teams
Comment=Microsoft Teams für Netlution
Exec=microsoft-edge https://teams.microsoft.com/
Icon=teams
Terminal=false
Categories=Network;Chat;
EOF
        
        # Netlution SharePoint Shortcut
        cat > "$DESKTOP_DIR/Netlution-SharePoint.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution SharePoint
Comment=Dein Zugang zu Netlution Dateien und Projekten
Exec=microsoft-edge https://netlution365.sharepoint.com/
Icon=folder-documents
Terminal=false
Categories=Network;FileManager;
EOF
        
        # Intune Verwaltung Shortcut
        if command -v intune-portal >/dev/null 2>&1; then
            cat > "$DESKTOP_DIR/Netlution-Geräteverwaltung.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution Geräteverwaltung
Comment=Intune Company Portal für dein Netlution_Ubuntu
Exec=intune-portal
Icon=intune-portal
Terminal=false
Categories=System;Settings;
EOF
        fi
        
        chmod +x "$DESKTOP_DIR"/*.desktop
        
        zenity --info \
            --title="🖥️ Desktop Setup" \
            --text="✅ <b>Desktop-Shortcuts wurden erstellt!</b>\n\nDu findest sie jetzt auf deinem Desktop.\nSie sind sofort einsatzbereit." \
            --ok-label="Weiter"
    fi
}

show_completion() {
    # Zusätzliche Optionen anbieten
    CHOICE=$(zenity --list \
        --title="🎉 Setup abgeschlossen!" \
        --width=500 \
        --height=400 \
        --text="<b><big>Dein Netlution_Ubuntu Arbeitsplatz ist bereit!</big></b>\n\n✅ Microsoft 365 URLs geöffnet\n✅ Intune Portal gestartet\n✅ Desktop-Shortcuts erstellt\n\n<b>Was möchtest du als nächstes tun?</b>" \
        --column="Aktion" \
        --ok-label="Auswählen" \
        --cancel-label="Fertig" \
        "Microsoft 365 Portal öffnen" \
        "Teams direkt starten" \
        "SharePoint öffnen" \
        "System-Einstellungen öffnen" \
        "Netlution IT-Team kontaktieren" \
        "Setup-Dialog schließen")
    
    case "$CHOICE" in
        "Microsoft 365 Portal öffnen")
            microsoft-edge "https://portal.office.com/" >/dev/null 2>&1 &
            ;;
        "Teams direkt starten")
            microsoft-edge "https://teams.microsoft.com/" >/dev/null 2>&1 &
            ;;
        "SharePoint öffnen")
            microsoft-edge "https://netlution365.sharepoint.com/" >/dev/null 2>&1 &
            ;;
        "System-Einstellungen öffnen")
            gnome-control-center >/dev/null 2>&1 &
            ;;
        "Netlution IT kontaktieren")
            zenity --info \
                --title="📞 Netlution IT-Team" \
                --text="<b>Kontakt zum Netlution IT-Team:</b>\n\n📧 E-Mail: helpdesk@netlution.de\n> Wir helfen dir gerne bei Fragen oder Problemen!</small>"
            ;;
    esac
    
    # Abschluss-Benachrichtigung
    notify-send \
        "Netlution_Ubuntu Setup" \
        "🎉 Setup erfolgreich abgeschlossen!\n\nDein Arbeitsplatz ist einsatzbereit." \
        --icon=dialog-information \
        --app-name="Netlution IT" \
        --expire-time=5000
}

# Hauptprogramm - Schritt für Schritt
main() {
    # Schritt 1: Begrüßung
    if ! show_welcome; then
        exit 0  # Benutzer hat abgebrochen
    fi
    
    # Schritt 2: Microsoft Edge Setup
    setup_microsoft_edge
    
    # Schritt 3: Intune Portal Setup
    setup_intune_portal
    
    # Schritt 4: Desktop-Shortcuts
    create_desktop_shortcuts
    
    # Schritt 5: Abschluss mit Optionen
    show_completion
    
    # Flag setzen - Setup als abgeschlossen markieren
    mkdir -p "$(dirname "$FIRST_LOGIN_FLAG")"
    touch "$FIRST_LOGIN_FLAG"
}

# Prüfen ob zenity verfügbar ist
if ! command -v zenity >/dev/null 2>&1; then
    notify-send "Netlution Setup" "Setup-Dialog nicht verfügbar. Wende dich an das IT-Team." --icon=dialog-warning
    exit 1
fi

# Setup starten
main
