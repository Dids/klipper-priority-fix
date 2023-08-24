#!/usr/bin/env bash

#
# Uninstallation script for klipper-priority-fix for Klipper.
#

# Enable error handling
set -eo pipefail

# Enable script debugging
# set -x

# Get the script path.
SCRIPT_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

# Load the utility functions.
source "${SCRIPT_PATH}/util.sh"

# Stop the klipper-priority-fix systemd service.
echo "Stopping klipper-priority-fix systemd service ..."
stop_systemd_service

# Disable the klipper-priority-fix systemd service.
echo "Disabling klipper-priority-fix systemd service ..."
disable_systemd_service

# Remove the klipper-priority-fix systemd service.
echo "Removing klipper-priority-fix systemd service ..."
if test $(id -u) -eq 0; then
  rm -f /etc/systemd/system/klipper-priority-fix.service
else
  sudo rm -f /etc/systemd/system/klipper-priority-fix.service
fi

# Reload the systemd daemon.
reload_systemd

# Remove the klipper-priority-fix binary.
if test $(id -u) -eq 0; then
  rm -f /usr/local/bin/klipper-priority-fix
else
  sudo rm -f /usr/local/bin/klipper-priority-fix
fi

# Remove the klipper-priority-fix Python virtual environment.
echo "Removing klipper-priority-fix Python virtual environment ..."
rm -fr ~/klipper-priority-fix-env

# Remove the klipper-priority-fix source code.
# echo "Removing klipper-priority-fix source code ..."
# rm -fr ~/klipper-priority-fix

echo "Successfully uninstalled klipper-priority-fix"
