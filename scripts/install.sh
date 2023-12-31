#!/usr/bin/env bash

#
# Installation script for klipper-priority-fix for Klipper.
#
# Based loosely on the following files/projects:
# - https://github.com/gobackup/gobackup/blob/main/install
# - https://github.com/eliteSchwein/mooncord/blob/master/scripts/install.sh
#

# Enable error handling.
set -eo pipefail

# Enable script debugging.
# set -x

# Get the script path.
SCRIPT_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

# Define global variables.
KLIPPER_PRIORITY_FIX_ROOT_PATH="$(cd "${SCRIPT_PATH}/.." >/dev/null 2>&1; pwd -P)"
KLIPPER_PRIORITY_FIX_INSTALL_PATH="/usr/local/bin"
KLIPPER_PRIORITY_FIX_SERVICE_NAME="klipper-priority-fix"
KLIPPER_PRIORITY_FIX_SERVICE_VERSION="2"
PYTHON_ENV_PATH="${HOME}/klipper-priority-fix-env"

# Attempt to find the moonraker.asvc file, which is usually located under ~/printer_data/moonraker.asvc.
# Search for the file in the following locations:
# - ~/printer_data/moonraker.asvc
# - ~/.moonraker/moonraker.asvc
# - /home/*/**/printer_data/moonraker.asvc
set +o pipefail
MOONRAKER_ASVC="$(find ~/printer_data/moonraker.asvc ~/.moonraker/moonraker.asvc /home/*/**/printer_data/moonraker.asvc 2>/dev/null | head -n 1)"
set -o pipefail

# Load the utility functions.
source "${SCRIPT_PATH}/util.sh"

# Stop the service if it already exists.
stop_systemd_service "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"

# Setup the Python virtual environment,
# and install any required Python dependencies.
create_virtualenv "${PYTHON_ENV_PATH}" "${KLIPPER_PRIORITY_FIX_ROOT_PATH}/requirements.txt"

# Function for installing or updating the custom klipper-priority-fix binary.
function install_klipper-priority-fix_binary() {
    local source_path="${KLIPPER_PRIORITY_FIX_ROOT_PATH}/klipper-priority-fix.py"
    local target_path="${KLIPPER_PRIORITY_FIX_INSTALL_PATH}/klipper-priority-fix"

    # Check if this is a fresh install
    if test -e "${target_path}"; then
        echo "klipper-priority-fix binary already installed, checking for updates ..."
        local source_hash="$(shasum -a 256 "${source_path}" | awk '{print $1}')"
        local target_hash="$(shasum -a 256 "${target_path}" | awk '{print $1}')"
        if test "${source_hash}" = "${target_hash}"; then
            echo "klipper-priority-fix binary already up-to-date"
            return
        else
            echo "klipper-priority-fix binary is out-of-date, updating ..."
        fi
    else
        echo "klipper-priority-fix binary is not installed, installing ..."
    fi

    # Check if running as root
    if test $(id -u) -eq 0; then
        cp -f "${source_path}" "${target_path}"
        chmod +x "${target_path}"
    else
        # Check if sudo is available
        if ! command -v sudo &> /dev/null; then
            echo "This script must be run as root or with sudo."
            exit 1
        fi
        sudo cp -f "${source_path}" "${target_path}"
        sudo chmod +x "${target_path}"
    fi

    echo "klipper-priority-fix binary successfully installed"
}

# Function for installing or updating the custom systemd service for klipper-priority-fix.
function install_klipper-priority-fix_service() {
    local source_path="/tmp/${KLIPPER_PRIORITY_FIX_SERVICE_NAME}.service"
    local target_path="/etc/systemd/system/${KLIPPER_PRIORITY_FIX_SERVICE_NAME}.service"

    local user="$(id -un)"
    if test -z "${user}"; then
        echo "ERROR: Could not determine current user name" >&2
        exit 1
    fi

    local group="$(id -gn)"
    if test -z "${group}"; then
        echo "ERROR: Could not determine current group name" >&2
        exit 1
    fi

    # Echo a systemd service file to the temporary directory.
    rm -f "${source_path}" || true
    cat <<EOT >> "${source_path}"
# KLIPPER_PRIORITY_FIX_SERVICE_VERSION=${KLIPPER_PRIORITY_FIX_SERVICE_VERSION}
[Unit]
Description=Klipper Priority Manager
Requires=klipper.service
After=klipper.service

[Service]
Type=simple
User=$user
Group=$group
ExecStart=$PYTHONDIR/bin/python $KLIPPER_PRIORITY_FIX_INSTALL_PATH/klipper-priority-fix
WorkingDirectory=$KLIPPER_PRIORITY_FIX_ROOT_PATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT

    # Check if this is a fresh install
    if test -e "${target_path}"; then
        echo "klipper-priority-fix systemd service already installed, checking for updates ..."

        # Check the KLIPPER_PRIORITY_FIX_SERVICE_VERSION of the service file to determine if we need to update it
        local service_version="$(grep "^# KLIPPER_PRIORITY_FIX_SERVICE_VERSION=" "${target_path}" | awk -F= '{print $NF}')"
        if test "${service_version}" = "${KLIPPER_PRIORITY_FIX_SERVICE_VERSION}"; then
            echo "klipper-priority-fix systemd service already up-to-date"
            return
        else
            echo "Updating klipper-priority-fix systemd service from version ${service_version} to ${KLIPPER_PRIORITY_FIX_SERVICE_VERSION} ..."
        fi
    else
        echo "klipper-priority-fix systemd service is not installed, installing ..."
    fi

    # Check if running as root
    if test $(id -u) -eq 0; then
        cp -f "${source_path}" "${target_path}"
    else
        # Check if sudo is available
        if ! command -v sudo &> /dev/null; then
            echo "This script must be run as root or with sudo."
            exit 1
        fi
        sudo cp -f "${source_path}" "${target_path}"
    fi

    # Remove the temporary systemd service file.
    rm -f "${source_path}" || true

    # Reload systemd and its services.
    reload_systemd

    # Ensure that the klipper-priority-fix systemd service is always enabled.
    enable_systemd_service "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"
}

# Stop the klipper-priority-fix systemd service.
stop_systemd_service "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"

# Check if klipper service is running
if ! systemctl is-active --quiet klipper.service; then
    echo "Klipper service is not running. Please start the Klipper service and try again."
    exit 1
fi

# Ensure that the klipper-priority-fix binary is installed and up-to-date.
install_klipper-priority-fix_binary

# Ensure that the custom systemd service is installed and up-to-date.
install_klipper-priority-fix_service

# Start the klipper-priority-fix systemd service.
start_systemd_service "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"

# Update the moonraker.asvc file.
update_moonraker_asvc "${MOONRAKER_ASVC}" "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"

## FIXME: This is not working quite as well as it should, so should probably not be used right now!
# Verify that the klipper-priority-fix systemd service is running.
#verify_systemd_service_running "${KLIPPER_PRIORITY_FIX_SERVICE_NAME}"

echo "klipper-priority-fix installation complete"
exit 0
