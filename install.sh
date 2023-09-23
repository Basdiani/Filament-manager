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
    cp "${HOME}/filaments-klipper-extra/Filaments.cfg" "${HOME}/printer_data/config/"

    # Copy Variables.cfg to printer_data/config/
    echo "Copying Variables.cfg to printer_data/config/"
    cp "${HOME}/filaments-klipper-extra/Variables.cfg" "${HOME}/printer_data/config/"
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

# Function to check if [include Filaments.cfg] is present in ~/printer_data/config/printer.cfg and add it if not
check_include_line()
{
    local config_file="${HOME}/printer_data/config/printer.cfg"
    if grep -q -F '[include Filaments.cfg]' "$config_file"; then
        echo "[CONFIGURATION] The 'include Filaments.cfg' line was found in $config_file."
    else
        echo "[CONFIGURATION] The 'include Filaments.cfg' line was not found in $config_file. Adding it..."
        sed -i "1i[include Filaments.cfg]" "$config_file"
        echo "[CONFIGURATION] The 'include Filaments.cfg' line was added to the beginning of $config_file."
    fi
}

# Function to check and add update_manager configuration
check_update_manager()
{
    local config_file="${HOME}/printer_data/config/moonraker.conf"
    if grep -q -F '[update_manager client Filaments]' "$config_file"; then
        echo "[CONFIGURATION] The section '[update_manager client Filaments]' was found."
    else
        echo "[CONFIGURATION] The section '[update_manager client Filaments]' was not found. Adding it..."
        echo "" >> "$config_file"  # Add an empty line
        cat <<EOF >> "$config_file"
[update_manager client Filaments]
type: git_repo
path: ~/filaments-klipper-extra
primary_branch: mainline
origin: https://github.com/Basdiani/filaments-klipper-extra.git
install_script: install.sh
managed_services: klipper
EOF
        echo "[CONFIGURATION] The section '[update_manager client Filaments]' was added to $config_file with an empty line at the end."
    fi
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

# Enable script termination on errors
set -e

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
