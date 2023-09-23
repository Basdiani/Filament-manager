#!/bin/bash
KLIPPER_PATH="${HOME}/klipper"
SYSTEMDDIR="/etc/systemd/system"

# Function to check if Klipper is installed
check_klipper()
{
    if [ "$EUID" -eq 0 ]; then
        echo "[PRE-CHECK] This script should not be run as root!"
        exit -1
    fi

    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper.service')" ]; then
        printf "[PRE-CHECK] Klipper service found! Proceeding...\n\n"
        
    elif [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper-1.service')" ]; then
        printf "[PRE-CHECK] Klipper service found! Proceeding...\n\n"

    elif [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper-2.service')" ]; then
        printf "[PRE-CHECK] Klipper service found! Proceeding...\n\n"
        
    else
        echo "[ERROR] Klipper service not found. Please install Klipper first!"
        exit -1
    fi
}

# Function to link extensions with Klipper and copy configuration files
link_extension()
{
    echo "Linking [filaments] extension with Klipper..."
    ln -sf "${SRCDIR}/filaments.py" "${KLIPPER_PATH}/klippy/extras/filaments.py"
    
    # Copy Filament.cfg to printer_data/config/
    echo "Copying Filament.cfg to printer_data/config/"
    cp "${HOME}/filament-manager/Filaments.cfg" "${HOME}/printer_data/config/"

     # Copy Filament.cfg to printer_data/config/
    echo "Copying Filament.cfg to printer_1_data/config/"
    cp "${HOME}/filament-manager/Filaments.cfg" "${HOME}/printer_1_data/config/"

         # Copy Filament.cfg to printer_data/config/
    echo "Copying Filament.cfg to printer_2_data/config/"
    cp "${HOME}/filament-manager/Filaments.cfg" "${HOME}/printer_2_data/config/"

    # Copy Variables.cfg to printer_data/config/
    echo "Copying Variables.cfg to printer_data/config/"
    cp "${HOME}/filament-manager/Variables.cfg" "${HOME}/printer_data/config/"

    # Copy Variables.cfg to printer_data/config/
    echo "Copying Variables.cfg to printer_1_data/config/"
    cp "${HOME}/filament-manager/Variables.cfg" "${HOME}/printer_data/config/"

    # Copy Variables.cfg to printer_data/config/
    echo "Copying Variables.cfg to printer_2_data/config/"
    cp "${HOME}/filament-manager/Variables.cfg" "${HOME}/printer_data/config/"
}

# Function to restart Klipper
restart_klipper()
{
    echo "[AFTER INSTALLATION] Restarting Klipper..."
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper.service')" ]; then
        sudo systemctl restart klipper
    elif [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper-1.service')" ]; then
        sudo systemctl restart klipper-1
    elif [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F 'klipper-2.service')" ]; then
        sudo systemctl restart klipper-2
    else
        echo "[ERROR] Klipper service not found. Please install Klipper first!"
        exit -1
    fi
}

# Function for readiness
ready()
{
    echo "[READY] You are ready."
}

#!/bin/bash

# Funktion zum Hinzufügen von [include Filaments.cfg] in die printer.cfg-Dateien
add_include_line() {
    local start_directory="$1"

    # Suche nach allen printer.cfg-Dateien im Startverzeichnis und seinen Unterordnern
    find "$start_directory" -name "printer.cfg" -print | while read -r config_file; do
        if grep -q -F '[include Filaments.cfg]' "$config_file"; then
            echo "[CONFIGURATION] Die Zeile 'include Filaments.cfg' wurde in $config_file gefunden."
        else
            echo "[CONFIGURATION] Die Zeile 'include Filaments.cfg' wurde in $config_file nicht gefunden. Füge sie hinzu..."
            sed -i "1i[include Filaments.cfg]" "$config_file"
            echo "[CONFIGURATION] Die Zeile 'include Filaments.cfg' wurde am Anfang von $config_file hinzugefügt."
        fi
    done
}

# Verwenden Sie die Funktion mit einem Startverzeichnis (zum Beispiel das Heimatverzeichnis des Benutzers)
add_include_line "$HOME"

# Funktion zur Überprüfung und Hinzufügung der update_manager-Konfiguration in allen moonraker.conf-Dateien
check_update_manager()
{
    local config_files=($(find "${HOME}" -type f -name "moonraker.conf"))

    for config_file in "${config_files[@]}"; do
        if grep -q -F '[update_manager client Filaments]' "$config_file"; then
            echo "[CONFIGURATION] The section '[update_manager client Filaments]' was found in $config_file."
        else
            echo "[CONFIGURATION] The section '[update_manager client Filaments]' was not found in $config_file. Adding it..."
            echo "" >> "$config_file"  # Add an empty line
            cat <<EOF >> "$config_file"
[update_manager client Filaments]
type: git_repo
path: ~/filament-manager
origin: https://github.com/basdiani/filament-manager.git
install_script: install.sh
managed_services: klipper
EOF
            echo "[CONFIGURATION] The section '[update_manager client Filaments]' was added to $config_file with an empty line at the end."
        fi
    done
}


# Function to create a configuration backup
create_config_backup()
{
    local config_file="${HOME}/printer_data/config/printer.cfg"
    local backup_file="${HOME}/printer_data/config/Printerbackup.cfg"

    if [ -f "$config_file" ]; then
        echo "[BACKUP] Creating a backup of printer.cfg as Printerbackup.cfg..."
        cp "$config_file" "$backup_file"
        echo "[BACKUP] Backup created at $backup_file."
    else
        echo "[BACKUP] printer.cfg not found. No backup was created."
    fi
}

# Helper function to check if the script is run as root
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script should not be run as root."
        exit -1
    fi
}


# Determine SRCDIR from the path of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"

# Process command-line arguments
while getopts "k:" arg; do
    case $arg in
        k) KLIPPER_PATH=$OPTARG;;
    esac
done

# Execute the steps
verify_ready
create_config_backup
check_include_line
check_update_manager
link_extension
restart_klipper
ready
