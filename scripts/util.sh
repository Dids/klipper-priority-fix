#!/usr/bin/env bash

# Ensure that this script is never ran as root.
if test $(id -u) -eq 0; then
  echo "ERROR: This script should not be run as root" >&2
  exit 1
fi

# Ensure that this script can only be sourced and not ran directly.
if test "${BASH_SOURCE[0]}" = "${0}"; then
  echo "ERROR: This script should be sourced, not ran directly" >&2
  exit 1
fi

# Ensure that we always have a valid user home directory available.
if test -z "${HOME}"; then
  HOME="$(getent passwd $(whoami) | cut -d: -f6)"
fi
if test -z "${HOME}"; then
  echo "ERROR: Could not determine user home directory (is HOME environment variable set?)" >&2
  exit 1
fi

function is_version_lte() {
  [  "${1}" = "`echo -e "${1}\n${2}" | sort -V | head -n1`" ]
}

function version() {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

# Function for reloading the systemd daemon and its services.
function reload_systemd() {
  echo "Reloading systemd daemon ..."
  if test $(id -u) -eq 0; then
    systemctl daemon-reload
  else
    sudo systemctl daemon-reload
  fi
}

# Function that checks if a systemd service file exists,
# based on the service name as the first argument.
function systemd_service_exists() {
  ## TODO: We might want to use systemctl instead of checking the file system directly, in case paths change in the future?
  if test -e "/etc/systemd/system/${1}.service"; then
    return 0
  else
    return 1
  fi
}

# Function for enabling a systemd service,
# based on the service name as the first argument.
function enable_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Enabling systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl enable "${1}"
  else
    sudo systemctl enable "${1}"
  fi
}

# Function for disabling a systemd service,
# based on the service name as the first argument.
function disable_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Disabling systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl disable "${1}"
  else
    sudo systemctl disable "${1}"
  fi
}

# Function for starting a systemd service,
# based on the service name as the first argument.
function start_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Starting systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl start "${1}"
  else
    sudo systemctl start "${1}"
  fi
}

# Function for stopping a systemd service,
# based on the service name as the first argument.
function stop_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Stopping systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl stop "${1}"
  else
    sudo systemctl stop "${1}"
  fi
}

# Function for restarting a systemd service,
# based on the service name as the first argument.
function restart_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Restarting systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl restart "${1}"
  else
    sudo systemctl restart "${1}"
  fi
}

# Function for checking if a systemd service is enabled 
# and running, with a timeout based second retry check,
# based on the service name as the first argument.
verify_systemd_service_running() {
  echo "Verifying that ${1} systemd service is running ..."

  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  # Check if the service is enabled.
  if ! systemctl is-enabled "${1}" >/dev/null 2>&1; then
    echo "ERROR: systemd service ${1} is not enabled" >&2
    return 1
  fi

  # Check if the service is running, and if not
  # wait for 5 seconds and check again.
  if ! systemctl is-active "${1}" >/dev/null 2>&1; then
    echo "WARNING: systemd service ${1} is not running, waiting 5 seconds and checking again ..." >&2
    sleep 5
    if ! systemctl is-active "${1}" >/dev/null 2>&1; then
      echo "ERROR: systemd service ${1} is not running" >&2
      return 1
    fi
  fi
}