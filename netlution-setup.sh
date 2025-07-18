#!/bin/bash

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

# Edge First Run Experience deaktivieren
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
        --title="🏢 Netlution Ubuntu Setup" \
        --width=600 \
        --height=400 \
        ${LOGO_PATH:+--window-icon="$LOGO_PATH"} \
        --text="<span font='16' weight='bold'>Willkommen bei deinem Netlution_Ubuntu Arbeitsplatz!</span>\n\n<span font='12' color='#1e3c72'><b>Netlution IT Solutions</b></span>\n\nDein System ist fast bereit. Wir führen dich jetzt durch die letzten Schritte:\n\n<span color='#27ae60'>✅ Microsoft 365 SharePoint Zugang</span>\n<span color='#27ae60'>✅ Intune Geräteregistrierung</span>\n<span color='#27ae60'>✅ Passwort-Sicherheit</span>\n<span color='#27ae60'>✅ Desktop-Konfiguration</span>\n\n<i>Das Setup dauert nur wenige Minuten!</i>\n\n<small>Bei Fragen: helpdesk@netlution.de</small>" \
        --ok-label="Setup starten"
}

setup_microsoft_edge() {
    if zenity --question \
        --title="🌐 Netlution SharePoint" \
        --width=500 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='14' weight='bold' color='#1e3c72'>Schritt 1: Netlution SharePoint Zugang</span>\n\nWir öffnen jetzt Microsoft Edge mit dem Netlution SharePoint Portal.\n\n<span color='#e74c3c'>📋 <b>Wichtig:</b></span>\nBitte melde dich mit deinen <b>Netlution Microsoft 365</b> Anmeldedaten an.\n\n<span color='#7f8c8d'><small>💡 Tipp: Du kannst Edge geöffnet lassen und nach der Anmeldung zu diesem Dialog zurückkehren.</small></span>" \
        --ok-label="Edge öffnen" \
        --cancel-label="Überspringen"; then
        
        # Microsoft Edge mit Netlution SharePoint starten
        if command -v microsoft-edge >/dev/null 2>&1; then
            microsoft-edge \
                --new-window \
                "https://netlution365.sharepoint.com/" >/dev/null 2>&1 &
            
            # Kurze Pause, dann Bestätigung
            sleep 3
            zenity --info \
                --title="🌐 Microsoft Edge" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span color='#27ae60'>✅ <b>Microsoft Edge wurde geöffnet!</b></span>\n\nBitte melde dich im Netlution SharePoint an.\nKomm danach zu diesem Dialog zurück und klicke 'Weiter'." \
                --ok-label="Weiter"
        else
            zenity --warning \
                --title="⚠️ Microsoft Edge" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="Microsoft Edge ist nicht installiert.\nBitte wende dich an das Netlution IT-Team.\n\n📧 helpdesk@netlution.de"
        fi
    fi
}

setup_intune_portal() {
    if zenity --question \
        --title="📱 Netlution Geräteverwaltung" \
        --width=500 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='14' weight='bold' color='#1e3c72'>Schritt 2: Geräteregistrierung</span>\n\nJetzt registrieren wir dein Netlution_Ubuntu Gerät im Intune Company Portal.\n\n<span color='#3498db'><b>Das ermöglicht:</b></span>\n• Zentrale Geräteverwaltung\n• Automatische App-Installation\n• Sicherheitsrichtlinien\n• Remote-Support durch Netlution IT\n\n<span color='#e74c3c'><small>Die Registrierung ist erforderlich für den Zugang zu Netlution Ressourcen.</small></span>" \
        --ok-label="Intune Portal öffnen" \
        --cancel-label="Später"; then
        
        if command -v intune-portal >/dev/null 2>&1; then
            intune-portal >/dev/null 2>&1 &
            sleep 2
            zenity --info \
                --title="📱 Intune Company Portal" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span color='#27ae60'>✅ <b>Intune Company Portal wurde gestartet!</b></span>\n\nFolge den Anweisungen im Portal zur Geräteregistrierung.\nDas kann einige Minuten dauern." \
                --ok-label="Weiter"
        elif command -v microsoft-edge >/dev/null 2>&1; then
            # Fallback: Browser mit Intune Web-Portal
            microsoft-edge "https://portal.manage.microsoft.com/" >/dev/null 2>&1 &
            zenity --info \
                --title="📱 Intune Web-Portal" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span color='#27ae60'>✅ <b>Intune Web-Portal wurde geöffnet!</b></span>\n\n<small>(Das Company Portal ist nicht installiert - verwende das Web-Portal)</small>\n\nRegistriere dein Gerät über das Web-Interface." \
                --ok-label="Weiter"
        else
            zenity --warning \
                --title="⚠️ Intune Portal" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="Intune Portal ist nicht verfügbar.\nBitte wende dich an das Netlution IT-Team.\n\n📧 helpdesk@netlution.de"
        fi
    fi
}

change_password() {
    if zenity --question \
        --title="🔐 Netlution Sicherheit" \
        --width=500 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='14' weight='bold' color='#1e3c72'>Schritt 3: Passwort-Sicherheit</span>\n\nWir empfehlen dir, das Standard-Passwort zu ändern.\n\n<span color='#e74c3c'><b>Ein sicheres Passwort sollte enthalten:</b></span>\n• Mindestens 8 Zeichen\n• Groß- und Kleinbuchstaben\n• Zahlen und Sonderzeichen\n\n<span color='#7f8c8d'><small>Du kannst diesen Schritt auch später über die Systemeinstellungen machen.</small></span>" \
        --ok-label="Passwort ändern" \
        --cancel-label="Später"; then
        
        # Versuche zuerst gnome-control-center
        if command -v gnome-control-center >/dev/null 2>&1; then
            gnome-control-center user-accounts >/dev/null 2>&1 &
            zenity --info \
                --title="🔐 Benutzerkonten" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span color='#27ae60'>✅ <b>Benutzerkonten-Einstellungen geöffnet!</b></span>\n\nKlicke auf dein Benutzerkonto und dann auf 'Passwort ändern'.\nKomm danach zu diesem Dialog zurück." \
                --ok-label="Weiter"
        else
            # Fallback: Terminal-basierte Passwort-Änderung
            if zenity --question \
                --title="🔐 Passwort ändern" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="Möchtest du dein Passwort jetzt über das Terminal ändern?\n\n<small>Das Terminal wird geöffnet und du kannst dein neues Passwort eingeben.</small>" \
                --ok-label="Ja" \
                --cancel-label="Später"; then
                
                gnome-terminal -- bash -c "echo 'Passwort für $(whoami) ändern:'; passwd; echo 'Drücke Enter um fortzufahren...'; read" &
            fi
        fi
    fi
}

create_desktop_shortcuts() {
    if zenity --question \
        --title="🖥️ Netlution Desktop" \
        --width=500 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='14' weight='bold' color='#1e3c72'>Schritt 4: Desktop-Konfiguration</span>\n\nMöchtest du hilfreiche Netlution Shortcuts auf deinem Desktop?\n\n<span color='#3498db'><b>Wir erstellen Verknüpfungen für:</b></span>\n• Netlution SharePoint Portal\n• Geräteverwaltung (Intune)\n\n<span color='#7f8c8d'><small>Du kannst diese später jederzeit anpassen oder löschen.</small></span>" \
        --ok-label="Shortcuts erstellen" \
        --cancel-label="Überspringen"; then
        
        DESKTOP_DIR="$HOME/Desktop"
        mkdir -p "$DESKTOP_DIR"
        
        # Netlution SharePoint Shortcut mit Corporate Branding
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
StartupWMClass=Microsoft-edge
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
            --window-icon="$HOME/.local/share/netlution/logo.png" \
            --text="<span color='#27ae60'>✅ <b>Desktop-Shortcuts wurden erstellt!</b></span>\n\nDu findest sie jetzt auf deinem Desktop.\nSie sind sofort einsatzbereit." \
            --ok-label="Weiter"
    fi
}

show_completion() {
    zenity --info \
        --title="🎉 Netlution Setup Abgeschlossen" \
        --width=600 \
        --height=350 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='16' weight='bold' color='#27ae60'>🎉 Dein Netlution_Ubuntu Arbeitsplatz ist bereit!</span>\n\n<span font='12' color='#1e3c72'><b>Setup erfolgreich abgeschlossen:</b></span>\n\n<span color='#27ae60'>✅ Microsoft 365 SharePoint Zugang eingerichtet</span>\n<span color='#27ae60'>✅ Intune Portal konfiguriert</span>\n<span color='#27ae60'>✅ Passwort-Sicherheit überprüft</span>\n<span color='#27ae60'>✅ Desktop-Shortcuts erstellt</span>\n\n<span font='12' weight='bold' color='#2c3e50'>Dein System ist jetzt einsatzbereit!</span>\n\n<span color='#7f8c8d'>Bei Fragen oder Problemen wende dich an:</span>\n<span color='#e74c3c'>📧 helpdesk@netlution.de</span>\n\n<span font='10' color='#95a5a6'>Powered by Netlution IT Solutions</span>" \
        --ok-label="Fertig"
    
    # Abschluss-Benachrichtigung mit Corporate Branding
    if [[ -f "$HOME/.local/share/netlution/logo.png" ]]; then
        notify-send \
            "Netlution Ubuntu Setup" \
            "🎉 Setup erfolgreich abgeschlossen!\n\nDein Netlution Arbeitsplatz ist einsatzbereit." \
            --icon="$HOME/.local/share/netlution/logo.png" \
            --app-name="Netlution IT" \
            --expire-time=5000
    else
        notify-send \
            "Netlution Ubuntu Setup" \
            "🎉 Setup erfolgreich abgeschlossen!\n\nDein Netlution Arbeitsplatz ist einsatzbereit." \
            --icon=dialog-information \
            --app-name="Netlution IT" \
            --expire-time=5000
    fi
}

# Hauptprogramm - Schritt für Schritt
main() {
    # Schritt 1: Begrüßung
    if ! show_welcome; then
        exit 0  # Benutzer hat abgebrochen
    fi
    
    # Edge-Policies konfigurieren (im Hintergrund)
    setup_edge_policies
    
    # Schritt 2: Microsoft Edge Setup
    setup_microsoft_edge
    
    # Schritt 3: Intune Portal Setup
    setup_intune_portal
    
    # Schritt 4: Passwort ändern
    change_password
    
    # Schritt 5: Desktop-Shortcuts
    create_desktop_shortcuts
    
    # Schritt 6: Abschluss
    show_completion
    
    # Flag setzen - Setup als abgeschlossen markieren
    mkdir -p "$(dirname "$FIRST_LOGIN_FLAG")"
    touch "$FIRST_LOGIN_FLAG"
    
    # Autostart-Datei entfernen (läuft nur einmal)
    rm -f "$HOME/.config/autostart/netlution-setup.desktop"
}

# Prüfen ob zenity verfügbar ist
if ! command -v zenity >/dev/null 2>&1; then
    notify-send "Netlution Setup" "Setup-Dialog nicht verfügbar. Wende dich an das IT-Team." --icon=dialog-warning
    exit 1
fi

# Logo-Pfad setzen (mit Fallback)
LOGO_PATH="$HOME/.local/share/netlution/logo.png"
if [[ ! -f "$LOGO_PATH" ]]; then
    LOGO_PATH=""
fi

# Setup starten
main
