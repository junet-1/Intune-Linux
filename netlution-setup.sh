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
REBOOT_PHASE_FLAG="$HOME/.config/netlution-ubuntu-reboot-phase"

# Wenn wir nach dem Reboot sind, springe zur zweiten Phase
if [[ -f "$REBOOT_PHASE_FLAG" ]]; then
    # Nach Reboot - führe restliche Setup-Schritte aus
    exec "$0" --post-reboot
fi

if [[ -f "$FIRST_LOGIN_FLAG" ]]; then
    # Setup bereits abgeschlossen - Autostart-Datei entfernen falls noch vorhanden
    rm -f "$HOME/.config/autostart/netlution-setup.desktop"
    exit 0
fi

# Permissions fix als erstes
fix_permissions

# Autostart-Mechanik sicherstellen (für den Fall eines Reboots)
ensure_autostart_after_reboot

# Warten bis Desktop vollständig geladen ist
sleep 8

# Sicherstellen dass Autostart nach Reboot funktioniert
ensure_autostart_after_reboot() {
    # Log-Verzeichnis erstellen
    mkdir -p "$HOME/.local/share"
    echo "$(date): Autostart wird eingerichtet" >> "$HOME/.local/share/netlution-setup.log"
    
    # Skript an dauerhaften Ort kopieren falls noch nicht dort
    SCRIPT_PATH="$HOME/.local/bin/netlution-setup.sh"
    mkdir -p "$(dirname "$SCRIPT_PATH")"
    
    # Nur kopieren wenn es sich nicht um denselben Pfad handelt
    if [[ "$0" != "$SCRIPT_PATH" ]]; then
        cp "$0" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo "$(date): Skript kopiert nach $SCRIPT_PATH" >> "$HOME/.local/share/netlution-setup.log"
    fi
    
    # Autostart-Desktop-Datei erstellen/aktualisieren
    AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    
    cat > "$AUTOSTART_DIR/netlution-setup.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Netlution Ubuntu Setup
Comment=Automatisches Setup für Netlution Ubuntu Arbeitsplatz
Exec=bash -c 'sleep 15 && "$SCRIPT_PATH" --post-reboot'
Icon=applications-system
Terminal=false
NoDisplay=true
Hidden=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Categories=System;Setup;
MimeType=
EOF
    
    chmod +x "$AUTOSTART_DIR/netlution-setup.desktop"
    echo "$(date): Autostart-Datei erstellt in $AUTOSTART_DIR" >> "$HOME/.local/share/netlution-setup.log"
    
    # Zusätzlich: Backup-Autostart über .bashrc (falls Desktop-Autostart nicht funktioniert)
    if ! grep -q "netlution-setup-post-reboot" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'EOF'

# Netlution Setup - Post-Reboot Check (läuft nur einmal)
if [[ -f "$HOME/.config/netlution-ubuntu-reboot-phase" && ! -f "$HOME/.config/netlution-ubuntu-sso-first-login" ]]; then
    # Nur in interaktiven Sessions und mit GUI
    if [[ $- == *i* && -n "$DISPLAY" ]]; then
        echo "Netlution Setup wird fortgesetzt..."
        # Kurze Verzögerung dann Setup starten
        (sleep 5 && "$HOME/.local/bin/netlution-setup.sh" --post-reboot 2>/dev/null &)
    fi
fi
EOF
        echo "$(date): Backup-Autostart über .bashrc hinzugefügt" >> "$HOME/.local/share/netlution-setup.log"
    fi
}

# Debug-Funktion für Troubleshooting
debug_setup() {
    echo "=== Netlution Setup Debug ==="
    echo "Aktueller Pfad: $0"
    echo "Aktuelle Zeit: $(date)"
    echo "User: $(whoami)"
    echo "Display: $DISPLAY"
    echo "Desktop Session: $XDG_CURRENT_DESKTOP"
    echo ""
    
    echo "=== Flag Status ==="
    echo "FIRST_LOGIN_FLAG ($FIRST_LOGIN_FLAG): $(test -f "$FIRST_LOGIN_FLAG" && echo "EXISTS" || echo "NOT FOUND")"
    echo "REBOOT_PHASE_FLAG ($REBOOT_PHASE_FLAG): $(test -f "$REBOOT_PHASE_FLAG" && echo "EXISTS" || echo "NOT FOUND")"
    echo ""
    
    echo "=== Autostart Status ==="
    AUTOSTART_FILE="$HOME/.config/autostart/netlution-setup.desktop"
    echo "Autostart-Datei: $(test -f "$AUTOSTART_FILE" && echo "EXISTS" || echo "NOT FOUND")"
    if [[ -f "$AUTOSTART_FILE" ]]; then
        echo "Autostart-Inhalt:"
        cat "$AUTOSTART_FILE" | sed 's/^/  /'
    fi
    echo ""
    
    SCRIPT_PATH="$HOME/.local/bin/netlution-setup.sh"
    echo "Skript-Kopie: $(test -f "$SCRIPT_PATH" && echo "EXISTS" || echo "NOT FOUND")"
    if [[ -f "$SCRIPT_PATH" ]]; then
        echo "Berechtigung: $(ls -la "$SCRIPT_PATH")"
    fi
    echo ""
    
    echo "=== Log-Datei ==="
    LOG_FILE="$HOME/.local/share/netlution-setup.log"
    if [[ -f "$LOG_FILE" ]]; then
        echo "Letzte 10 Log-Einträge:"
        tail -10 "$LOG_FILE" | sed 's/^/  /'
    else
        echo "Keine Log-Datei gefunden"
    fi
    echo ""
    
    echo "=== Befehle verfügbar ==="
    echo "zenity: $(command -v zenity || echo "NOT FOUND")"
    echo "notify-send: $(command -v notify-send || echo "NOT FOUND")"
    echo ""
    
    echo "=== Nächste Schritte ==="
    if [[ -f "$REBOOT_PHASE_FLAG" && ! -f "$FIRST_LOGIN_FLAG" ]]; then
        echo "Status: Setup wartet auf Post-Reboot Fortsetzung"
        echo "Führe aus: $0 --post-reboot"
    elif [[ -f "$FIRST_LOGIN_FLAG" ]]; then
        echo "Status: Setup bereits abgeschlossen"
    else
        echo "Status: Setup noch nicht gestartet"
        echo "Führe aus: $0"
    fi
}

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
            
            # Neustart nach Authentifizierung erforderlich
            if zenity --question \
                --title="🔄 System-Neustart erforderlich" \
                --width=500 \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span font='14' weight='bold' color='#e74c3c'>System-Neustart erforderlich</span>\n\nNach der Anmeldung muss das System einmal neu gestartet werden,\num die Authentifizierung vollständig zu aktivieren.\n\n<span color='#3498db'><b>Was passiert beim Neustart:</b></span>\n• Authentifizierungs-Token werden aktiviert\n• System-Richtlinien werden angewendet\n• Setup wird automatisch fortgesetzt\n\n<span color='#7f8c8d'><small>Das ist ein einmaliger Vorgang und dauert nur wenige Minuten.</small></span>" \
                --ok-label="Jetzt neu starten" \
                --cancel-label="Später neu starten"; then
                
                # Flag setzen für Post-Reboot Phase
                touch "$REBOOT_PHASE_FLAG"
                
                # Sicherstellen dass das Skript für den Neustart verfügbar ist
                ensure_autostart_after_reboot
                
                # Neustart-Benachrichtigung
                zenity --info \
                    --title="🔄 Neustart wird eingeleitet" \
                    --window-icon="$HOME/.local/share/netlution/logo.png" \
                    --text="<span color='#e67e22'>⚠️ <b>System wird neu gestartet...</b></span>\n\nSpeichere alle offenen Arbeiten!\n\nDas Setup wird nach dem Neustart automatisch fortgesetzt." \
                    --timeout=10 \
                    --ok-label="OK"
                
                # Kurze Verzögerung und dann Neustart
                sleep 3
                sudo reboot
            else
                # Benutzer möchte später neu starten
                touch "$REBOOT_PHASE_FLAG"
                ensure_autostart_after_reboot
                
                zenity --info \
                    --title="🔄 Neustart später" \
                    --window-icon="$HOME/.local/share/netlution/logo.png" \
                    --text="<span color='#f39c12'>⏱️ <b>Neustart verschoben</b></span>\n\nBitte starte das System manuell neu, um die\nAuthentifizierung vollständig zu aktivieren.\n\nDas Setup wird nach dem Neustart automatisch fortgesetzt." \
                    --ok-label="Verstanden"
                exit 0
            fi
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
        
        # Frage zuerst nach der bevorzugten Methode
        if zenity --question \
            --title="🔐 Passwort-Änderung" \
            --width=500 \
            --window-icon="$HOME/.local/share/netlution/logo.png" \
            --text="<span font='14' weight='bold' color='#1e3c72'>Wie möchtest du dein Passwort ändern?</span>\n\n<span color='#3498db'><b>Terminal (empfohlen):</b></span>\n• Schnell und direkt\n• Sichere Eingabe ohne Sichtbarkeit\n\n<span color='#3498db'><b>Systemeinstellungen:</b></span>\n• Grafische Benutzeroberfläche\n• Mehr Optionen verfügbar" \
            --ok-label="🖥️ Terminal verwenden" \
            --cancel-label="⚙️ Systemeinstellungen"; then
            
            # Terminal-basierte Passwort-Änderung (Benutzer-Wahl)
            zenity --info \
                --title="🔐 Terminal Passwort-Änderung" \
                --window-icon="$HOME/.local/share/netlution/logo.png" \
                --text="<span color='#27ae60'>✅ <b>Terminal wird geöffnet!</b></span>\n\n<span color='#e74c3c'><b>Anleitung:</b></span>\n1. Gib dein <b>aktuelles</b> Passwort ein\n2. Gib dein <b>neues</b> Passwort zweimal ein\n3. Drücke Enter wenn fertig\n\n<span color='#7f8c8d'><small>💡 Tipp: Die Passwort-Eingabe wird nicht angezeigt (ist normal!)</small></span>" \
                --ok-label="Terminal öffnen"
            
            gnome-terminal --title="Netlution Passwort ändern" -- bash -c "
            echo '🔐 Netlution Passwort-Änderung'
            echo '=================================='
            echo 'Gib dein aktuelles Passwort ein, dann dein neues Passwort (zweimal).'
            echo ''
            passwd
            echo ''
            echo '✅ Passwort-Änderung abgeschlossen!'
            echo 'Drücke Enter um das Terminal zu schließen...'
            read
            " &
        else
            # Systemeinstellungen mit besserer Anleitung
            if command -v gnome-control-center >/dev/null 2>&1; then
                gnome-control-center user-accounts >/dev/null 2>&1 &
                sleep 2
                zenity --info \
                    --title="⚙️ Systemeinstellungen" \
                    --window-icon="$HOME/.local/share/netlution/logo.png" \
                    --text="<span color='#27ae60'>✅ <b>Systemeinstellungen geöffnet!</b></span>\n\n<span color='#e74c3c'><b>So änderst du dein Passwort:</b></span>\n\n1. Klicke auf dein <b>Benutzerkonto</b> ($(whoami))\n2. Klicke auf <b>'Passwort'</b> oder <b>'Ändern'</b>\n3. Gib dein aktuelles und neues Passwort ein\n4. Bestätige mit <b>'Ändern'</b>\n\n<span color='#7f8c8d'><small>Falls du Probleme hast, schließe die Einstellungen und verwende stattdessen das Terminal.</small></span>" \
                    --ok-label="Verstanden"
            else
                # Fallback falls gnome-control-center nicht verfügbar
                zenity --warning \
                    --title="⚠️ Systemeinstellungen" \
                    --window-icon="$HOME/.local/share/netlution/logo.png" \
                    --text="Systemeinstellungen nicht verfügbar.\nVerwende stattdessen das Terminal zur Passwort-Änderung?" \
                    --ok-label="Terminal öffnen" \
                    --cancel-label="Später"
                
                if [[ $? -eq 0 ]]; then
                    gnome-terminal --title="Netlution Passwort ändern" -- bash -c "
                    echo '🔐 Netlution Passwort-Änderung'
                    echo '=================================='
                    echo 'Gib dein aktuelles Passwort ein, dann dein neues Passwort (zweimal).'
                    echo ''
                    passwd
                    echo ''
                    echo '✅ Passwort-Änderung abgeschlossen!'
                    echo 'Drücke Enter um das Terminal zu schließen...'
                    read
                    " &
                fi
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

show_post_reboot_welcome() {
    zenity --info \
        --title="🔄 Netlution Setup - Fortsetzung" \
        --width=600 \
        --height=300 \
        --window-icon="$HOME/.local/share/netlution/logo.png" \
        --text="<span font='16' weight='bold' color='#27ae60'>🔄 Willkommen zurück!</span>\n\n<span font='12' color='#1e3c72'><b>Netlution IT Solutions</b></span>\n\nDer Neustart war erfolgreich und deine Authentifizierung ist jetzt aktiv.\n\nWir setzen das Setup mit den verbleibenden Schritten fort:\n\n<span color='#3498db'>📱 Intune Geräteregistrierung</span>\n<span color='#3498db'>🔐 Passwort-Sicherheit</span>\n<span color='#3498db'>🖥️ Desktop-Konfiguration</span>\n\n<i>Das dauert nur noch wenige Minuten!</i>" \
        --ok-label="Setup fortsetzen"
}

# Hauptprogramm - Schritt für Schritt
main() {
    # Schritt 1: Begrüßung
    if ! show_welcome; then
        # User hat abgebrochen - Autostart-Datei entfernen
        rm -f "$HOME/.config/autostart/netlution-setup.desktop"
        exit 0
    fi
    
    # Edge-Policies konfigurieren (im Hintergrund)
    setup_edge_policies
    
    # Schritt 2: Microsoft Edge Setup (mit Neustart)
    setup_microsoft_edge
    
    # Wenn wir hier ankommen, wurde der Neustart übersprungen oder abgebrochen
    # Das sollte normalerweise nicht passieren, aber für Robustheit behandeln wir es
    rm -f "$HOME/.config/autostart/netlution-setup.desktop"
    exit 0
}

# Post-Reboot Hauptprogramm
main_post_reboot() {
    # Debug: Logging für Troubleshooting
    echo "$(date): Post-Reboot Setup gestartet" >> "$HOME/.local/share/netlution-setup.log"
    
    # Kurz warten bis Desktop vollständig geladen ist
    sleep 10
    
    # Prüfen ob zenity verfügbar ist
    if ! command -v zenity >/dev/null 2>&1; then
        echo "$(date): Zenity nicht verfügbar" >> "$HOME/.local/share/netlution-setup.log"
        notify-send "Netlution Setup" "Setup-Dialog nicht verfügbar nach Reboot. Starte manuell!" --icon=dialog-warning
        return 1
    fi
    
    # Prüfen ob Display verfügbar ist
    if [[ -z "$DISPLAY" ]]; then
        export DISPLAY=:0
        echo "$(date): DISPLAY auf :0 gesetzt" >> "$HOME/.local/share/netlution-setup.log"
    fi
    
    # Test-Benachrichtigung dass Post-Reboot läuft
    notify-send "Netlution Setup" "Setup wird nach Neustart fortgesetzt..." --icon=dialog-information
    
    # Begrüßung nach Neustart
    if ! show_post_reboot_welcome; then
        echo "$(date): Post-Reboot Welcome abgebrochen" >> "$HOME/.local/share/netlution-setup.log"
        return 1
    fi
    
    echo "$(date): Post-Reboot Welcome erfolgreich" >> "$HOME/.local/share/netlution-setup.log"
    
    # Verbleibende Setup-Schritte
    setup_intune_portal
    change_password
    create_desktop_shortcuts
    show_completion
    
    # Flags bereinigen - Setup vollständig abgeschlossen
    touch "$FIRST_LOGIN_FLAG"
    rm -f "$REBOOT_PHASE_FLAG"
    
    # Autostart-Datei entfernen (läuft nur einmal)
    rm -f "$HOME/.config/autostart/netlution-setup.desktop"
    
    echo "$(date): Post-Reboot Setup abgeschlossen" >> "$HOME/.local/share/netlution-setup.log"
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

# Prüfen ob wir nach einem Reboot sind
if [[ "$1" == "--post-reboot" ]]; then
    main_post_reboot
elif [[ "$1" == "--debug" ]]; then
    debug_setup
else
    main
fi
