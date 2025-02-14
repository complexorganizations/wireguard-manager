#!/bin/bash

# WireGuard-Manager Installation Script
# Purpose: This script automates the installation of WireGuard-Manager, a comprehensive tool for managing WireGuard VPN configurations.
# Author: ComplexOrganizations
# Repository: https://github.com/complexorganizations/wireguard-manager

# Usage Instructions:
# 1. System Requirements: Ensure you have 'curl' installed on your system. This script is compatible with most Linux distributions.
# 2. Downloading the Script:
#    - Use the following command to download the script:
#      curl https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh --create-dirs -o /usr/local/bin/wireguard-manager.sh
# 3. Making the Script Executable:
#    - Grant execution permissions to the script:
#      chmod +x /usr/local/bin/wireguard-manager.sh
# 4. Running the Script:
#    - Execute the script with root privileges:
#      bash /usr/local/bin/wireguard-manager.sh
# 5. Follow the on-screen instructions to complete the installation of WireGuard-Manager.

# Advanced Usage:
# - The script supports various command-line arguments for custom installations. Refer to the repository's readme.md for more details.
# - For automated deployments, environment variables can be set before running this script.

# Troubleshooting:
# - If you encounter issues, ensure your system is up-to-date and retry the installation.
# - For specific errors, refer to the 'Troubleshooting' section in the repository's documentation.

# Contributing:
# - Contributions to the script are welcome. Please follow the contributing guidelines in the repository.

# Contact Information:
# - For support, feature requests, or bug reports, please open an issue on the GitHub repository.

# License: MIT License

# Note: This script is provided 'as is', without warranty of any kind. The user is responsible for understanding the operations and risks involved.

# Define a function to check if the script is being run with root privileges
function check_root() {
  # Compare the user ID of the current user to 0, which is the ID for root
  if [ "$(id -u)" -ne 0 ]; then
    # If the user ID is not 0 (i.e., not root), print an error message
    echo "Error: This script must be run as root."
    # Exit the script with a status code of 1, indicating an error
    exit 1 # Exit the script with an error code.
  fi
}

# Call the check_root function to verify that the script is executed with root privileges
check_root

# Define a function to gather and store system-related information
function system_information() {
  # Check if the /etc/os-release file exists, which contains information about the OS
  if [ -f /etc/os-release ]; then
    # If the /etc/os-release file is present, source it to load system details into environment variables
    # shellcheck source=/dev/null  # Instructs shellcheck to ignore warnings about sourcing files
    source /etc/os-release
    # Set the CURRENT_DISTRO variable to the system's distribution ID (e.g., 'ubuntu', 'debian')
    CURRENT_DISTRO=${ID}
    # Set the CURRENT_DISTRO_VERSION variable to the system's version ID (e.g., '20.04' for Ubuntu 20.04)
    CURRENT_DISTRO_VERSION=${VERSION_ID}
    # Extract the major version of the system by splitting the version string at the dot (.) and keeping the first field
    # For example, for '20.04', it will set CURRENT_DISTRO_MAJOR_VERSION to '20'
    CURRENT_DISTRO_MAJOR_VERSION=$(echo "${CURRENT_DISTRO_VERSION}" | cut --delimiter="." --fields=1)
  fi
}

# Call the system_information function to gather the system details
system_information

# Function to install either resolvconf or openresolv, depending on the distribution.
function install_resolvconf_or_openresolv() {
  # Check if resolvconf is already installed on the system.
  if [ ! -x "$(command -v resolvconf)" ]; then
    # If resolvconf is not installed, install it for Ubuntu, Debian, Raspbian, Pop, Kali, Linux Mint, and Neon distributions.
    if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
      apt-get install resolvconf -y
    # For CentOS, RHEL, AlmaLinux, and Rocky distributions, install openresolv.
    elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
      # If the distribution is CentOS 7, enable the copr repository before installing openresolv.
      if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
        yum copr enable macieks/openresolv -y
      fi
      yum install openresolv -y
    # For Fedora and Oracle Linux distributions, install openresolv.
    elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
      yum install openresolv -y
    # For Arch, Arch ARM, and Manjaro distributions, install resolvconf.
    elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
      pacman -Su --noconfirm --needed resolvconf
    # For Alpine Linux, install resolvconf.
    elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
      apk add resolvconf
    # For FreeBSD, install resolvconf.
    elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
      pkg install resolvconf
    fi
  fi
}

# Invoke the function to install either resolvconf or openresolv, depending on the distribution.
install_resolvconf_or_openresolv

# Define a function to check system requirements and install missing packages
function installing_system_requirements() {
  # Check if the current Linux distribution is one of the supported distributions
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
    # If the distribution is supported, check if the required packages are already installed
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v cron)" ] || [ ! -x "$(command -v awk)" ] || [ ! -x "$(command -v ps)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v qrencode)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v nft)" ] || [ ! -x "$(command -v ifup)" ] || [ ! -x "$(command -v chattr)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v systemd-detect-virt)" ]; }; then
      # If any of the required packages are missing, begin the installation process for the respective distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        # For Debian-based distributions, update package lists and install required packages
        apt-get update
        apt-get install curl coreutils jq iproute2 lsof cron gawk procps grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        # For Red Hat-based distributions, check for updates and install required packages
        yum check-update
        # For CentOS 7+, install EPEL and ELRepo repositories if needed
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" -ge 7 ]; then
          yum install epel-release elrepo-release -y
        fi
        # If CentOS 7, install the ELRepo plugin
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
          yum install yum-plugin-elrepo -y
        fi
        # Install necessary packages for Red Hat-based distributions
        yum install curl coreutils jq iproute lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables NetworkManager e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        # For Arch-based distributions, update the keyring and install required packages
        pacman -Sy --noconfirm archlinux-keyring
        pacman -Su --noconfirm --needed curl coreutils jq iproute2 lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        # For Alpine Linux, update package lists and install required packages
        apk update
        apk add curl coreutils jq iproute2 lsof cronie gawk procps grep sed zip unzip openssl nftables e2fsprogs gnupg
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        # For FreeBSD, update package lists and install required packages
        pkg update
        pkg install curl coreutils jq iproute2 lsof cronie gawk procps grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        # For Oracle Linux (OL), check for updates and install required packages
        yum check-update
        yum install curl coreutils jq iproute lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables NetworkManager e2fsprogs gnupg systemd -y
      fi
    fi
  else
    # If the current distribution is not supported, display an error and exit the script
    echo "Error: Your current distribution ${CURRENT_DISTRO} version ${CURRENT_DISTRO_VERSION} is not supported by this script. Please consider updating your distribution or using a supported one."
    exit 1 # Exit the script with an error code.
  fi
}

# Call the function to check system requirements and install necessary packages if needed
installing_system_requirements

# Checking For Virtualization
function virt_check() {
  # This code checks if the system is running in a supported virtualization.
  # It returns the name of the virtualization if it is supported, or "none" if
  # it is not supported. This code is used to check if the system is running in
  # a virtual machine, and if so, if it is running in a supported virtualization.
  # systemd-detect-virt is a utility that detects the type of virtualization
  # that the system is running on. It returns a string that indicates the name
  # of the virtualization, such as "kvm" or "vmware".
  CURRENT_SYSTEM_VIRTUALIZATION=$(systemd-detect-virt)
  # This case statement checks if the virtualization that the system is running
  # on is supported. If it is not supported, the script will print an error
  # message and exit.
  case ${CURRENT_SYSTEM_VIRTUALIZATION} in
  "amazon" | "docker" | "google" | "kvm" | "lxc" | "microsoft" | "none" | "qemu" | "vmware" | "xen") ;;
  *)
    echo "Error: the ${CURRENT_SYSTEM_VIRTUALIZATION} virtualization is currently not supported. Please stay tuned for future updates."
    exit 1 # Exit the script with an error code.
    ;;
  esac
}

# Call the virt_check function to check for supported virtualization.
virt_check

# The following function checks the kernel version.
function kernel_check() {
  CURRENT_KERNEL_VERSION=$(uname --kernel-release | cut --delimiter="." --fields=1-2)
  # Get the current kernel version and extract the major and minor version numbers.
  CURRENT_KERNEL_MAJOR_VERSION=$(echo "${CURRENT_KERNEL_VERSION}" | cut --delimiter="." --fields=1)
  # Extract the major version number from the current kernel version.
  CURRENT_KERNEL_MINOR_VERSION=$(echo "${CURRENT_KERNEL_VERSION}" | cut --delimiter="." --fields=2)
  # Extract the minor version number from the current kernel version.
  ALLOWED_KERNEL_VERSION="3.1"
  # Set the minimum allowed kernel version to 3.1.0.
  ALLOWED_KERNEL_MAJOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=1)
  # Extract the major version number from the allowed kernel version.
  ALLOWED_KERNEL_MINOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=2)
  # Extract the minor version number from the allowed kernel version.
  if [ "${CURRENT_KERNEL_MAJOR_VERSION}" -lt "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
    # If the current major version is less than the allowed major version, show an error message and exit.
    echo "Error: Your current kernel version ${CURRENT_KERNEL_VERSION} is not supported. Please update to version ${ALLOWED_KERNEL_VERSION} or later."
    exit 1 # Exit the script with an error code.
  fi
  if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
    # If the current major version is equal to the allowed major version, check the minor version.
    if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
      # If the current minor version is less than the allowed minor version, show an error message and exit.
      echo "Error: Your current kernel version ${CURRENT_KERNEL_VERSION} is not supported. Please update to version ${ALLOWED_KERNEL_VERSION} or later."
      exit 1 # Exit the script with an error code.
    fi
  fi
}

# Call the kernel_check function to verify the kernel version.
kernel_check

# The following function checks if the current init system is one of the allowed options.
function check_current_init_system() {
  # Get the current init system by checking the process name of PID 1.
  CURRENT_INIT_SYSTEM=$(ps -p 1 -o comm= | awk -F'/' '{print $NF}') # Extract only the command name without the full path.
  # Convert to lowercase to make the comparison case-insensitive.
  CURRENT_INIT_SYSTEM=$(echo "$CURRENT_INIT_SYSTEM" | tr '[:upper:]' '[:lower:]')
  # Log the detected init system (optional for debugging purposes).
  echo "Detected init system: ${CURRENT_INIT_SYSTEM}"
  # Define a list of allowed init systems (case-insensitive).
  ALLOWED_INIT_SYSTEMS=("systemd" "sysvinit" "init" "upstart" "bash" "sh")
  # Check if the current init system is in the list of allowed init systems
  if [[ ! "${ALLOWED_INIT_SYSTEMS[*]}" =~ ${CURRENT_INIT_SYSTEM} ]]; then
    # If the init system is not allowed, display an error message and exit with an error code.
    echo "Error: The '${CURRENT_INIT_SYSTEM}' initialization system is not supported. Please stay tuned for future updates."
    exit 1 # Exit the script with an error code.
  fi
}

# The check_current_init_system function is being called.
check_current_init_system

# The following function checks if there's enough disk space to proceed with the installation.
function check_disk_space() {
  # This function checks if there is more than 1 GB of free space on the drive.
  FREE_SPACE_ON_DRIVE_IN_MB=$(df -m / | tr --squeeze-repeats " " | tail -n1 | cut --delimiter=" " --fields=4)
  # This line calculates the available free space on the root partition in MB.
  if [ "${FREE_SPACE_ON_DRIVE_IN_MB}" -le 1024 ]; then
    # If the available free space is less than or equal to 1024 MB (1 GB), display an error message and exit.
    echo "Error: You need more than 1 GB of free space to install everything. Please free up some space and try again."
    exit 1 # Exit the script with an error code.
  fi
}

# Calls the check_disk_space function.
check_disk_space

# Global variables
# Assigns the path of the current script to a variable
CURRENT_FILE_PATH=$(realpath "${0}")
# Assigns the WireGuard website URL to a variable
WIREGUARD_WEBSITE_URL="https://www.wireguard.com"
# Assigns a path for WireGuard
WIREGUARD_PATH="/etc/wireguard"
# Assigns a path for WireGuard clients
WIREGUARD_CLIENT_PATH="${WIREGUARD_PATH}/clients"
# Assigns a public network interface name for WireGuard
WIREGUARD_PUB_NIC="wg0"
# Assigns a path for the WireGuard configuration file
WIREGUARD_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}.conf"
# Assigns a path for the WireGuard additional peer configuration file
WIREGUARD_ADD_PEER_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}-add-peer.conf"
# Assigns a path for system backups
SYSTEM_BACKUP_PATH="/var/backups"
# Assigns a path for the WireGuard configuration backup file
WIREGUARD_CONFIG_BACKUP="${SYSTEM_BACKUP_PATH}/wireguard-manager.zip"
# Assigns a path for the WireGuard backup password file
WIREGUARD_BACKUP_PASSWORD_PATH="${HOME}/.wireguard-manager"
# Assigns a path for the DNS resolver configuration file
RESOLV_CONFIG="/etc/resolv.conf"
# Assigns a path for the old DNS resolver configuration file
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"
# Assigns a path for Unbound DNS resolver
UNBOUND_ROOT="/etc/unbound"
# Assigns a path for the Unbound configuration file
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"
# Assigns a path for the Unbound root hints file
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"
# Assigns a path for the Unbound anchor file
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
if { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
  UNBOUND_ANCHOR="${UNBOUND_ROOT}/root.key"
fi
# Assigns a path for the Unbound configuration directory
UNBOUND_CONFIG_DIRECTORY="${UNBOUND_ROOT}/unbound.conf.d"
# Assigns a path for the Unbound hosts configuration file
UNBOUND_CONFIG_HOST="${UNBOUND_CONFIG_DIRECTORY}/hosts.conf"
case $(shuf --input-range=1-1 --head-count=1) in
1)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://raw.githubusercontent.com/Strong-Foundation/wireguard-manager/main/assets/named.cache"
  ;;
esac
case $(shuf --input-range=1-1 --head-count=1) in
1)
  UNBOUND_CONFIG_HOST_URL="https://raw.githubusercontent.com/Strong-Foundation/wireguard-manager/main/assets/hosts"
  ;;
esac
case $(shuf --input-range=1-1 --head-count=1) in
1)
  WIREGUARD_MANAGER_UPDATE="https://raw.githubusercontent.com/Strong-Foundation/wireguard-manager/main/wireguard-manager.sh"
  ;;
esac
# Check if the CURRENT_DISTRO variable matches any of the following distros:
# fedora, centos, rhel, almalinux, or rocky
if { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
  # If the condition is true, set the SYSTEM_CRON_NAME variable to "crond"
  SYSTEM_CRON_NAME="crond"
# If the CURRENT_DISTRO variable matches any of the following distros:
# arch, archarm, or manjaro
elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
  # If the condition is true, set the SYSTEM_CRON_NAME variable to "cronie"
  SYSTEM_CRON_NAME="cronie"
else
  # If none of the above conditions are met, set the SYSTEM_CRON_NAME variable to "cron"
  SYSTEM_CRON_NAME="cron"
fi

# This is a Bash function named "get_network_information" that retrieves network information.
function get_network_information() {
  # This variable will store the IPv4 address of the default network interface by querying the "ipengine" API using "curl" command and extracting it using "jq" command.
  DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.2 --silent 'https://checkip.amazonaws.com')"
  # If the IPv4 address is empty, try getting it from another API.
  if [ -z "${DEFAULT_INTERFACE_IPV4}" ]; then
    DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
  fi
  # This variable will store the IPv6 address of the default network interface by querying the "ipengine" API using "curl" command and extracting it using "jq" command.
  DEFAULT_INTERFACE_IPV6="$(curl --ipv6 --connect-timeout 5 --tlsv1.3 --silent 'https://ifconfig.co')"
  # If the IPv6 address is empty, try getting it from another API.
  if [ -z "${DEFAULT_INTERFACE_IPV6}" ]; then
    DEFAULT_INTERFACE_IPV6="$(curl --ipv6 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
  fi
}

# Usage Guide of the application
function usage_guide() {
  echo "Usage: ./$(basename "${0}") <command>"
  echo "  --install     Installs the WireGuard interface on your system"
  echo "  --start       Starts the WireGuard interface if it's not already running"
  echo "  --stop        Stops the WireGuard interface if it's currently running"
  echo "  --restart     Restarts the WireGuard interface"
  echo "  --list        Lists all the peers currently connected to the WireGuard interface"
  echo "  --add         Adds a new peer to the WireGuard interface"
  echo "  --remove      Removes a specified peer from the WireGuard interface"
  echo "  --reinstall   Reinstalls the WireGuard interface, keeping the current configuration"
  echo "  --uninstall   Uninstalls the WireGuard interface from your system"
  echo "  --update      Updates the WireGuard Manager to the latest version"
  echo "  --ddns        Updates the IP address of the WireGuard interface using Dynamic DNS"
  echo "  --backup      Creates a backup of your current WireGuard configuration"
  echo "  --restore     Restores the WireGuard configuration from a previous backup"
  echo "  --purge       Removes all peers from the WireGuard interface"
  echo "  --help        Displays this usage guide"
}

# Define a function that takes command line arguments as input
function usage() {
  # Check if there are any command line arguments left
  while [ $# -ne 0 ]; do
    # Use a switch-case statement to check the value of the first argument
    case ${1} in
    --install) # If it's "--install", set the variable HEADLESS_INSTALL to "true"
      shift
      HEADLESS_INSTALL=${HEADLESS_INSTALL=true}
      ;;
    --start) # If it's "--start", set the variable WIREGUARD_OPTIONS to 2
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=2}
      ;;
    --stop) # If it's "--stop", set the variable WIREGUARD_OPTIONS to 3
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=3}
      ;;
    --restart) # If it's "--restart", set the variable WIREGUARD_OPTIONS to 4
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=4}
      ;;
    --list) # If it's "--list", set the variable WIREGUARD_OPTIONS to 1
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=1}
      ;;
    --add) # If it's "--add", set the variable WIREGUARD_OPTIONS to 5
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=5}
      ;;
    --remove) # If it's "--remove", set the variable WIREGUARD_OPTIONS to 6
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=6}
      ;;
    --reinstall) # If it's "--reinstall", set the variable WIREGUARD_OPTIONS to 7
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=7}
      ;;
    --uninstall) # If it's "--uninstall", set the variable WIREGUARD_OPTIONS to 8
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=8}
      ;;
    --update) # If it's "--update", set the variable WIREGUARD_OPTIONS to 9
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=9}
      ;;
    --backup) # If it's "--backup", set the variable WIREGUARD_OPTIONS to 10
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=10}
      ;;
    --restore) # If it's "--restore", set the variable WIREGUARD_OPTIONS to 11
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=11}
      ;;
    --ddns) # If it's "--ddns", set the variable WIREGUARD_OPTIONS to 12
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=12}
      ;;
    --purge) # If it's "--purge", set the variable WIREGUARD_OPTIONS to 14
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=14}
      ;;
    --help) # If it's "--help", call the function usage_guide
      shift
      usage_guide
      ;;
    *) # If it's anything else, print an error message and call the function usage_guide, then exit
      echo "Invalid argument: ${1}"
      usage_guide
      exit
      ;;
    esac
  done
}

# Call the function usage with all the command line arguments
usage "$@"

# The function defines default values for configuration variables when installing WireGuard in headless mode.
# These variables include private subnet settings, server host settings, NAT choice, MTU choice, client allowed IP settings, automatic updates, automatic backup, DNS provider settings, content blocker settings, client name, and automatic config remover.
function headless_install() {
  # If headless installation is specified, set default values for configuration variables.
  if [ "${HEADLESS_INSTALL}" == true ]; then
    PRIVATE_SUBNET_V4_SETTINGS=${PRIVATE_SUBNET_V4_SETTINGS=1} # Default to 1 if not specified
    PRIVATE_SUBNET_V6_SETTINGS=${PRIVATE_SUBNET_V6_SETTINGS=1} # Default to 1 if not specified
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS=1}       # Default to 1 if not specified
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS=1}       # Default to 1 if not specified
    SERVER_PUB_NIC_SETTINGS=${SERVER_PUB_NIC_SETTINGS=1}       # Default to 1 if not specified
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS=1}             # Default to 1 if not specified
    NAT_CHOICE_SETTINGS=${NAT_CHOICE_SETTINGS=1}               # Default to 1 if not specified
    MTU_CHOICE_SETTINGS=${MTU_CHOICE_SETTINGS=1}               # Default to 1 if not specified
    SERVER_HOST_SETTINGS=${SERVER_HOST_SETTINGS=1}             # Default to 1 if not specified
    CLIENT_ALLOWED_IP_SETTINGS=${CLIENT_ALLOWED_IP_SETTINGS=1} # Default to 1 if not specified
    AUTOMATIC_UPDATES_SETTINGS=${AUTOMATIC_UPDATES_SETTINGS=1} # Default to 1 if not specified
    AUTOMATIC_BACKUP_SETTINGS=${AUTOMATIC_BACKUP_SETTINGS=1}   # Default to 1 if not specified
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS=1}           # Default to 1 if not specified
    CONTENT_BLOCKER_SETTINGS=${CONTENT_BLOCKER_SETTINGS=1}     # Default to 1 if not specified
    CLIENT_NAME=${CLIENT_NAME=$(openssl rand -hex 5)}          # Generate a random client name if not specified
    AUTOMATIC_CONFIG_REMOVER=${AUTOMATIC_CONFIG_REMOVER=1}     # Default to 1 if not specified
  fi
}

# Call the headless-install function to set default values for configuration variables in headless mode.
headless_install

# Set up the wireguard, if config it isn't already there.
if [ ! -f "${WIREGUARD_CONFIG}" ]; then

  # Define a function to set a custom IPv4 subnet
  function set_ipv4_subnet() {
    # Prompt the user for the desired IPv4 subnet
    echo "Please specify the IPv4 subnet you want to use for the WireGuard interface. This should be a private subnet that is not in use elsewhere on your network."
    echo "  1) 10.32.0.0/12 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Keep prompting the user until they enter a valid subnet choice
    until [[ "${PRIVATE_SUBNET_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V4_SETTINGS
    done
    # Based on the user's choice, set the private IPv4 subnet
    case ${PRIVATE_SUBNET_V4_SETTINGS} in
    1)
      PRIVATE_SUBNET_V4="10.32.0.0/12" # Set a default IPv4 subnet
      ;;
    2)
      read -rp "Custom IPv4 Subnet:" PRIVATE_SUBNET_V4 # Prompt user for custom subnet
      if [ -z "${PRIVATE_SUBNET_V4}" ]; then           # If the user did not enter a subnet, set default
        PRIVATE_SUBNET_V4="10.32.0.0/12"
      fi
      ;;
    esac
  }

  # Call the function to set the custom IPv4 subnet
  set_ipv4_subnet

  # Define a function to set a custom IPv6 subnet
  function set_ipv6_subnet() {
    # Ask the user which IPv6 subnet they want to use
    echo "Please specify the IPv6 subnet you want to use for the WireGuard interface. This should be a private subnet that is not in use elsewhere on your network."
    echo "  1) fd32:00:00::0/12 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Use a loop to ensure the user inputs a valid option
    until [[ "${PRIVATE_SUBNET_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Please choose the IPv6 subnet for your WireGuard interface [Option 1-2]: " -e -i 1 PRIVATE_SUBNET_V6_SETTINGS
    done
    # Use a case statement to set the IPv6 subnet based on the user's choice
    case ${PRIVATE_SUBNET_V6_SETTINGS} in
    1)
      # Use the recommended IPv6 subnet if the user chooses option 1
      PRIVATE_SUBNET_V6="fd32:00:00::0/12"
      ;;
    2)
      # Ask the user for a custom IPv6 subnet if they choose option 2
      read -rp "Please enter a custom IPv6 subnet for your WireGuard interface: " PRIVATE_SUBNET_V6
      # If the user does not input a subnet, use the recommended one
      if [ -z "${PRIVATE_SUBNET_V6}" ]; then
        PRIVATE_SUBNET_V6="fd32:00:00::0/12"
      fi
      ;;
    esac
  }

  # Call the set_ipv6_subnet function to set the custom IPv6 subnet
  set_ipv6_subnet

  # Define the private subnet mask for the IPv4 network used by the WireGuard interface
  PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv4
  # Define the IPv4 gateway for the WireGuard interface
  GATEWAY_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).1 # Get the gateway address of IPv4
  # Define the private subnet mask for the IPv6 network used by the WireGuard interface
  PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv6
  # Define the IPv6 gateway for the WireGuard interface
  GATEWAY_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-3)::1 # Get the gateway address of IPv6
  # Retrieve the networking configuration details
  get_network_information
  # Call a function to get the networking data

  # Define a function to retrieve the IPv4 address of the WireGuard interface
  function test_connectivity_v4() {
    # Prompt the user to choose the method for detecting the IPv4 address
    echo "How would you like to detect IPv4?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until the user provides a valid input
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS
    done
    # Choose the method for detecting the IPv4 address based on the user's input
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4} # Use the default IPv4 address
      ;;
    2)
      # Prompt the user to enter a custom IPv4 address
      read -rp "Custom IPv4:" SERVER_HOST_V4
      # If the user doesn't provide an input, use the default IPv4 address
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      fi
      ;;
    esac
  }

  # Call the function to retrieve the IPv4 address
  test_connectivity_v4

  # Define a function to retrieve the IPv6 address of the WireGuard interface
  function test_connectivity_v6() {
    # Prompt the user to choose the method for detecting the IPv6 address
    echo "How would you like to detect IPv6?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until the user provides a valid input
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS
    done
    # Choose the method for detecting the IPv6 address based on the user's input
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6} # Use the default IPv6 address
      ;;
    2)
      # Prompt the user to enter a custom IPv6 address
      read -rp "Custom IPv6:" SERVER_HOST_V6
      # If the user doesn't provide an input, use the default IPv6 address
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      fi
      ;;
    esac
  }

  # Call the function to retrieve the IPv6 address
  test_connectivity_v6

  # Define a function to identify the public Network Interface Card (NIC).
  function server_pub_nic() {
    # Prompt the user to select the method for identifying the NIC.
    echo "How would you like to identify the Network Interface Card (NIC)?"
    echo "  1) IP Route (Recommended)"
    echo "  2) Custom Input (Advanced)"
    # Loop until the user provides a valid input (either 1 or 2).
    until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "NIC Choice [1-2]:" -e -i 1 SERVER_PUB_NIC_SETTINGS
    done
    # Execute a case statement based on the user's choice.
    case ${SERVER_PUB_NIC_SETTINGS} in
    1)
      # Use the IP route command to automatically identify the NIC.
      SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      # If no NIC is found, exit the script with an error message.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        echo "Error: Unable to identify your server's public network interface."
        exit
      fi
      ;;
    2)
      # Prompt the user to manually input the NIC.
      read -rp "Custom NIC:" SERVER_PUB_NIC
      # Input validation loop to ensure the name is alphanumeric.
      while [[ ! "$SERVER_PUB_NIC" =~ ^[a-zA-Z0-9]+$ ]]; do
        echo "Error: The NIC name must be alphanumeric."
        read -rp "Custom NIC:" SERVER_PUB_NIC
      done
      # If the user doesn't provide an input, use the IP route command to identify the NIC.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      fi
      ;;
    esac
  }

  # Call the function to identify the public NIC.
  server_pub_nic

  # Define a function to configure the WireGuard server's listening port
  function set_port() {
    # Prompt the user to specify the port for the WireGuard server
    echo "What port do you want WireGuard server to listen to?"
    # Provide the user with options for setting the port
    echo "  1) 51820 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Continue prompting the user until a valid option (1 or 2) is selected
    until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user for their port choice, with 1 as the default option
      read -rp "Port Choice [1-2]:" -e -i 1 SERVER_PORT_SETTINGS
    done
    # Set the SERVER_PORT variable based on the user's choice
    case ${SERVER_PORT_SETTINGS} in
    1)
      SERVER_PORT="51820"
      # If the chosen port is already in use, display an error message and exit the script
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: Please use a different port because ${SERVER_PORT} is already in use."
        exit
      fi
      ;;
    2)
      # Continue prompting the user until a valid custom port number (between 1 and 65535) is entered
      until [[ "${SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]:" SERVER_PORT
      done
      # If no custom port is entered, set the SERVER_PORT variable to the default of 51820
      if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT="51820"
      fi
      # If the chosen port is already in use, display an error message and exit the script
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: The port ${SERVER_PORT} is already used by a different application, please use a different port."
        exit
      fi
      ;;
    esac
  }

  # Invoke the set_port function to configure the WireGuard server's listening port
  set_port

  # Define a function to set the NAT keepalive interval.
  function nat_keepalive() {
    # Prompt the user to specify the NAT keepalive interval.
    echo "What do you want your NAT keepalive interval to be?"
    # Provide the user with options for setting the interval.
    echo "  1) 25 seconds (Default)"
    echo "  2) Custom (Advanced)"
    # Continue prompting the user until a valid option (1 or 2) is selected.
    until [[ "${NAT_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user for their interval choice, with 1 as the default option.
      read -rp "Keepalive Choice [1-2]:" -e -i 1 NAT_CHOICE_SETTINGS
    done
    # Set the NAT_CHOICE variable based on the user's choice.
    case ${NAT_CHOICE_SETTINGS} in
    1)
      # If the user chose the default option, set the NAT_CHOICE to 25 seconds.
      NAT_CHOICE="25"
      ;;
    2)
      # If the user chose the custom option, prompt them to enter a custom interval.
      until [[ "${NAT_CHOICE}" =~ ^[0-9]+$ ]] && [ "${NAT_CHOICE}" -ge 1 ] && [ "${NAT_CHOICE}" -le 300 ]; do
        read -rp "Custom NAT [1-300]:" NAT_CHOICE
      done
      # If no custom interval is entered, set the NAT_CHOICE variable to the default of 25 seconds.
      if [ -z "${NAT_CHOICE}" ]; then
        NAT_CHOICE="25"
      fi
      ;;
    esac
  }
  # Invoke the nat_keepalive function to set the NAT keepalive interval.
  nat_keepalive

  # Define a function to configure the Maximum Transmission Unit (MTU) settings.
  function mtu_set() {
    # Ask the user to specify the MTU settings.
    echo "What MTU do you want to use?"
    # Provide the user with options for setting the MTU.
    echo "  1) 1420 for Interface, 1280 for Peer (Recommended)"
    echo "  2) Custom (Advanced)"
    # Continue prompting the user until a valid option (1 or 2) is selected.
    until [[ "${MTU_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user for their MTU choice, with 1 as the default option.
      read -rp "MTU Choice [1-2]:" -e -i 1 MTU_CHOICE_SETTINGS
    done
    # Set the MTU variables based on the user's choice.
    case ${MTU_CHOICE_SETTINGS} in
    1)
      # If the user chose the default option, set the Interface MTU to 1420 and Peer MTU to 1280.
      INTERFACE_MTU_CHOICE="1420"
      PEER_MTU_CHOICE="1280"
      ;;
    2)
      # If the user chose the custom option, prompt them to enter a custom MTU for Interface and Peer.
      until [[ "${INTERFACE_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${INTERFACE_MTU_CHOICE}" -ge 1 ] && [ "${INTERFACE_MTU_CHOICE}" -le 3000 ]; do
        read -rp "Custom Interface MTU [1-3000]:" INTERFACE_MTU_CHOICE
      done
      # If no custom Interface MTU is entered, set the INTERFACE_MTU_CHOICE variable to the default of 1420.
      if [ -z "${INTERFACE_MTU_CHOICE}" ]; then
        INTERFACE_MTU_CHOICE="1420"
      fi
      until [[ "${PEER_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${PEER_MTU_CHOICE}" -ge 1 ] && [ "${PEER_MTU_CHOICE}" -le 3000 ]; do
        read -rp "Custom Peer MTU [1-3000]:" PEER_MTU_CHOICE
      done
      # If no custom Peer MTU is entered, set the PEER_MTU_CHOICE variable to the default of 1280.
      if [ -z "${PEER_MTU_CHOICE}" ]; then
        PEER_MTU_CHOICE="1280"
      fi
      ;;
    esac
  }

  # Invoke the mtu_set function to configure the MTU settings.
  mtu_set

  # Define a function to select the IP version for the WireGuard server.
  function ipvx_select() {
    # Ask the user to specify the IP version to use for connecting to the WireGuard server.
    echo "Which IP version do you want to use for the WireGuard server?"
    # Provide the user with options for setting the IP version.
    echo "  1) IPv4 (Recommended)"
    echo "  2) IPv6"
    # Continue prompting the user until a valid option (1 or 2) is selected.
    until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user for their IP version choice, with 1 as the default option.
      read -rp "IP Version Choice [1-2]:" -e -i 1 SERVER_HOST_SETTINGS
    done
    # Set the SERVER_HOST variable based on the user's choice.
    case ${SERVER_HOST_SETTINGS} in
    1)
      # If the user chose IPv4 and a default IPv4 interface is available, use it.
      if [ -n "${DEFAULT_INTERFACE_IPV4}" ]; then
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}"
      else
        # If no default IPv4 interface is available, use the default IPv6 interface.
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]"
      fi
      ;;
    2)
      # If the user chose IPv6 and a default IPv6 interface is available, use it.
      if [ -n "${DEFAULT_INTERFACE_IPV6}" ]; then
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]"
      else
        # If no default IPv6 interface is available, use the default IPv4 interface.
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}"
      fi
      ;;
    esac
  }

  # Invoke the ipvx_select function to select the IP version for the WireGuard server.
  ipvx_select

  # Define a function to configure the type of traffic the client is allowed to forward through WireGuard.
  function client_allowed_ip() {
    # Ask the user to specify the type of traffic to be forwarded.
    echo "What type of traffic do you want the client to forward through WireGuard?"
    # Provide the user with options for setting the traffic type.
    echo "  1) All Traffic (Recommended)"
    echo "  2) Custom Traffic (Advanced)"
    # Continue prompting the user until a valid option (1 or 2) is selected.
    until [[ "${CLIENT_ALLOWED_IP_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user for their traffic type choice, with 1 as the default option.
      read -rp "Traffic Type Choice [1-2]:" -e -i 1 CLIENT_ALLOWED_IP_SETTINGS
    done
    # Set the CLIENT_ALLOWED_IP variable based on the user's choice.
    case ${CLIENT_ALLOWED_IP_SETTINGS} in
    1)
      # If the user chose the default option, set the CLIENT_ALLOWED_IP to allow all traffic.
      CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      ;;
    2)
      # If the user chose the custom option, prompt them to enter a custom IP range.
      read -rp "Custom IP Range:" CLIENT_ALLOWED_IP
      # If no custom IP range is entered, set the CLIENT_ALLOWED_IP variable to allow all traffic.
      if [ -z "${CLIENT_ALLOWED_IP}" ]; then
        CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      fi
      ;;
    esac
  }

  # Invoke the client_allowed_ip function to configure the type of traffic the client is allowed to forward.
  client_allowed_ip

  # Function to configure automatic updates
  function enable_automatic_updates() {
    # Prompt the user to decide if they want to enable automatic updates
    echo "Would you like to setup real-time updates?"
    # Option 1: Enable automatic updates
    echo "  1) Yes (Recommended)"
    # Option 2: Disable automatic updates
    echo "  2) No (Advanced)"
    # Loop until a valid choice (1 or 2) is made
    until [[ "${AUTOMATIC_UPDATES_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Read user input for automatic updates setting
      read -rp "Automatic Updates [1-2]:" -e -i 1 AUTOMATIC_UPDATES_SETTINGS
    done
    # Evaluate user choice for automatic updates
    case ${AUTOMATIC_UPDATES_SETTINGS} in
    1)
      # If user chose to enable automatic updates, set up a cron job
      crontab -l | {
        cat
        # Add a cron job to run the script with --update option every day at midnight
        echo "0 0 * * * ${CURRENT_FILE_PATH} --update"
      } | crontab -
      # Manage the service based on the init system
      if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      # If user chose to disable automatic updates, display a confirmation message
      echo "Real-time Updates Disabled"
      ;;
    esac
  }

  # Invoke the function to configure automatic updates
  enable_automatic_updates

  # Function to configure automatic backup
  function enable_automatic_backup() {
    # Prompt the user to decide if they want to enable automatic backup
    echo "Would you like to setup real-time backup?"
    # Option 1: Enable automatic backup
    echo "  1) Yes (Recommended)"
    # Option 2: Disable automatic backup
    echo "  2) No (Advanced)"
    # Loop until a valid choice (1 or 2) is made
    until [[ "${AUTOMATIC_BACKUP_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Read user input for automatic backup setting
      read -rp "Automatic Backup [1-2]:" -e -i 1 AUTOMATIC_BACKUP_SETTINGS
    done
    # Evaluate user choice for automatic backup
    case ${AUTOMATIC_BACKUP_SETTINGS} in
    1)
      # If user chose to enable automatic backup, set up a cron job
      crontab -l | {
        cat
        # Add a cron job to run the script with --backup option every day at midnight
        echo "0 0 * * * ${CURRENT_FILE_PATH} --backup"
      } | crontab -
      # Manage the service based on the init system
      if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      # If user chose to disable automatic backup, display a confirmation message
      echo "Real-time Backup Disabled"
      ;;
    esac
  }

  # Invoke the function to configure automatic backup
  enable_automatic_backup

  # Function to prompt the user for their preferred DNS provider.
  function ask_install_dns() {
    # Display the DNS provider options to the user.
    echo "Which DNS provider would you like to use?"
    echo "  1) Unbound (Recommended)"
    echo "  2) Custom (Advanced)"
    # Continue prompting until the user enters a valid choice (1 or 2).
    until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Read the user's DNS provider choice and store it in DNS_PROVIDER_SETTINGS.
      read -rp "DNS provider [1-2]:" -e -i 1 DNS_PROVIDER_SETTINGS
    done
    # Set variables based on the user's DNS provider choice.
    case ${DNS_PROVIDER_SETTINGS} in
    1)
      # If the user chose Unbound, set INSTALL_UNBOUND to true.
      INSTALL_UNBOUND=true
      # Ask the user if they want to install a content-blocker.
      echo "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker?"
      echo "  1) Yes (Recommended)"
      echo "  2) No"
      # Continue prompting until the user enters a valid choice (1 or 2).
      until [[ "${CONTENT_BLOCKER_SETTINGS}" =~ ^[1-2]$ ]]; do
        # Read the user's content blocker choice and store it in CONTENT_BLOCKER_SETTINGS.
        read -rp "Content Blocker Choice [1-2]:" -e -i 1 CONTENT_BLOCKER_SETTINGS
      done
      # Set INSTALL_BLOCK_LIST based on the user's content blocker choice.
      case ${CONTENT_BLOCKER_SETTINGS} in
      1)
        # If the user chose to install the content blocker, set INSTALL_BLOCK_LIST to true.
        INSTALL_BLOCK_LIST=true
        ;;
      2)
        # If the user chose not to install the content blocker, set INSTALL_BLOCK_LIST to false.
        INSTALL_BLOCK_LIST=false
        ;;
      esac
      ;;
    2)
      # If the user chose to use a custom DNS provider, set CUSTOM_DNS to true.
      CUSTOM_DNS=true
      ;;
    esac
  }

  # Invoke the ask_install_dns function to begin the DNS provider selection process.
  ask_install_dns

  # Function to allow users to select a custom DNS provider.
  function custom_dns() {
    # If the custom DNS option is enabled, proceed with the DNS selection.
    if [ "${CUSTOM_DNS}" == true ]; then
      # Present the user with a list of DNS providers to choose from.
      echo "Select the DNS provider you wish to use with your WireGuard connection:"
      echo "  1) Cloudflare (Recommended)"
      echo "  2) AdGuard"
      echo "  3) NextDNS"
      echo "  4) OpenDNS"
      echo "  5) Google"
      echo "  6) Verisign"
      echo "  7) Quad9"
      echo "  8) FDN"
      echo "  9) Custom (Advanced)"
      # If Pi-Hole is installed, add it as an option.
      if [ -x "$(command -v pihole)" ]; then
        echo "  10) Pi-Hole (Advanced)"
      fi
      # Prompt the user to make a selection from the list of DNS providers.
      until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 10 ]; do
        read -rp "DNS [1-10]:" -e -i 1 CLIENT_DNS_SETTINGS
      done
      # Based on the user's selection, set the DNS addresses.
      case ${CLIENT_DNS_SETTINGS} in
      1)
        # Set DNS addresses for Cloudflare.
        CLIENT_DNS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
        ;;
      2)
        # Set DNS addresses for AdGuard.
        CLIENT_DNS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
        ;;
      3)
        # Set DNS addresses for NextDNS.
        CLIENT_DNS="45.90.28.167,45.90.30.167,2a07:a8c0::12:cf53,2a07:a8c1::12:cf53"
        ;;
      4)
        # Set DNS addresses for OpenDNS.
        CLIENT_DNS="208.67.222.222,208.67.220.220,2620:119:35::35,2620:119:53::53"
        ;;
      5)
        # Set DNS addresses for Google.
        CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        ;;
      6)
        # Set DNS addresses for Verisign.
        CLIENT_DNS="64.6.64.6,64.6.65.6,2620:74:1b::1:1,2620:74:1c::2:2"
        ;;
      7)
        # Set DNS addresses for Quad9.
        CLIENT_DNS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
        ;;
      8)
        # Set DNS addresses for FDN.
        CLIENT_DNS="80.67.169.40,80.67.169.12,2001:910:800::40,2001:910:800::12"
        ;;
      9)
        # Prompt the user to enter a custom DNS address.
        read -rp "Custom DNS:" CLIENT_DNS
        # If the user doesn't provide a custom DNS, default to Google's DNS.
        if [ -z "${CLIENT_DNS}" ]; then
          CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        fi
        ;;
      10)
        # If Pi-Hole is installed, use its DNS. Otherwise, install Unbound and enable the block list.
        if [ -x "$(command -v pihole)" ]; then
          CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
        else
          INSTALL_UNBOUND=true
          INSTALL_BLOCK_LIST=true
        fi
        ;;
      esac
    fi
  }

  # Invoke the custom_dns function to allow the user to select a DNS provider.
  custom_dns

  # Function to prompt for the name of the first WireGuard peer.
  function client_name() {
    # If CLIENT_NAME variable is not set, prompt the user for input.
    if [ -z "${CLIENT_NAME}" ]; then
      # Display naming rules to the user.
      echo "Please provide a name for the WireGuard Peer. The name should be a single word, without special characters or spaces."
      # Read the user's input, offering a random string as the default name.
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" CLIENT_NAME
    fi
    # Input validation loop to ensure the name is alphanumeric.
    while [[ ! "$CLIENT_NAME" =~ ^[a-zA-Z0-9]+$ ]]; do
      echo "Invalid name. The name should contain only letters and numbers (no spaces or special characters)."
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" CLIENT_NAME
    done
    # If no name is provided by the user, assign a random string as the name.
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 5)"
    fi
  }

  # Invoke the function to prompt for the first WireGuard peer's name.
  client_name

  # Function to set up automatic deletion of WireGuard peers.
  function auto_remove_config() {
    # Ask the user if they want to set an expiration date for the peer.
    echo "Do you want to set an expiration date for the peer?"
    echo "  1) No, do not expire (Recommended)"
    echo "  2) Yes, expire after one year"
    # Keep asking until the user enters 1 or 2.
    until [[ "${AUTOMATIC_CONFIG_REMOVER}" =~ ^[1-2]$ ]]; do
      read -rp "Choose an option for peer expiration [1-2]:" -e -i 1 AUTOMATIC_CONFIG_REMOVER
    done
    # Execute actions based on the user's choice.
    case ${AUTOMATIC_CONFIG_REMOVER} in
    1)
      # If the user chose not to expire the peer, set the expiration flag to false.
      AUTOMATIC_WIREGUARD_EXPIRATION=false
      ;;
    2)
      # If the user chose to expire the peer, set the expiration flag to true.
      AUTOMATIC_WIREGUARD_EXPIRATION=true
      # Manage the service based on the init system
      if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    esac
  }

  # Invoke the function to set up automatic deletion of WireGuard peers.
  auto_remove_config

  # Function to verify kernel version and install necessary kernel headers.
  function install_kernel_headers() {
    # Define the minimum kernel version required and extract its major and minor version numbers.
    MINIMUM_KERNEL_VERSION="5.6"
    MINIMUM_KERNEL_MAJOR_VERSION=$(echo ${MINIMUM_KERNEL_VERSION} | cut --delimiter="." --fields=1)
    MINIMUM_KERNEL_MINOR_VERSION=$(echo ${MINIMUM_KERNEL_VERSION} | cut --delimiter="." --fields=2)
    # Check if the current kernel version is less than or equal to the minimum required version.
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" -le "${MINIMUM_KERNEL_MAJOR_VERSION}" ]; then
      INSTALL_LINUX_HEADERS=true
    fi
    # If the current kernel major version matches the minimum required major version, compare minor versions.
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${MINIMUM_KERNEL_MAJOR_VERSION}" ]; then
      # If the current minor version is less than the required, set flag to install headers.
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${MINIMUM_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=true
      fi
      # If the current minor version is greater than or equal to the required, set flag to not install headers.
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -ge "${MINIMUM_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=false
      fi
    fi
    # If the flag to install headers is set, install appropriate headers based on the Linux distribution.
    if [ "${INSTALL_LINUX_HEADERS}" == true ]; then
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install linux-headers-"$(uname --kernel-release)" -y
      elif [ "${CURRENT_DISTRO}" == "raspbian" ]; then
        apt-get update
        apt-get install raspberrypi-kernel-headers -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed linux-headers
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
        yum check-update
        yum install kernel-headers-"$(uname --kernel-release)" kernel-devel-"$(uname --kernel-release)" -y
      elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum check-update
        yum install kernel-headers-"$(uname --kernel-release)" kernel-devel-"$(uname --kernel-release)" -y
      fi
    fi
  }

  # Invoke the function to verify kernel version and install necessary kernel headers.
  install_kernel_headers

  # Function to install the WireGuard server if it's not already installed.
  function install_wireguard_server() {
    # Verify if the WireGuard command (wg) is available on the system.
    if [ ! -x "$(command -v wg)" ]; then
      # For Debian-based distributions, update the package list and install WireGuard.
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install wireguard -y
      # For Arch-based distributions, update the package list and install WireGuard tools.
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed wireguard-tools
      elif [ "${CURRENT_DISTRO}" = "fedora" ]; then
        dnf check-update
        dnf copr enable jdoss/wireguard -y
        dnf install wireguard-tools -y
      # For CentOS, update the package list and install WireGuard tools and kernel module.
      elif [ "${CURRENT_DISTRO}" == "centos" ]; then
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
      # For RHEL, install necessary repositories and then install WireGuard tools and kernel module.
      elif [ "${CURRENT_DISTRO}" == "rhel" ]; then
        yum check-update
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-"${CURRENT_DISTRO_MAJOR_VERSION}".noarch.rpm https://www.elrepo.org/elrepo-release-"${CURRENT_DISTRO_MAJOR_VERSION}".el"${CURRENT_DISTRO_MAJOR_VERSION}".elrepo.noarch.rpm
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
      # For Alpine Linux, update the package list and install WireGuard tools.
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk add wireguard-tools
      # For FreeBSD, update the package list and install WireGuard.
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg install wireguard
      # For AlmaLinux and Rocky, update the package list and install WireGuard tools and kernel module.
      elif { [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
      # For Oracle Linux, configure necessary repositories and then install WireGuard tools.
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        yum check-update
        yum install oraclelinux-developer-release-el"${CURRENT_DISTRO_MAJOR_VERSION}" -y
        yum config-manager --disable ol"${CURRENT_DISTRO_MAJOR_VERSION}"_developer
        yum config-manager --enable ol"${CURRENT_DISTRO_MAJOR_VERSION}"_developer_UEKR6
        yum config-manager --save --setopt=ol"${CURRENT_DISTRO_MAJOR_VERSION}"_developer_UEKR6.includepkgs='wireguard-tools*'
        yum install wireguard-tools -y
      fi
    fi
  }

  # Invoke the function to install the WireGuard server.
  install_wireguard_server

  # Function to install Unbound, a DNS resolver, if required and not already installed.
  function install_unbound() {
    # If INSTALL_UNBOUND is true and Unbound is not installed, proceed with installation.
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
        # Check if the root hints file does not exist.
        if [ ! -f ${UNBOUND_ROOT_HINTS} ]; then
          # If the root hints file is missing, download it from the specified URL.
          LOCAL_UNBOUND_ROOT_HINTS_COPY=$(curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}")
        fi
        # Check if we are install unbound blocker
        if [ "${INSTALL_BLOCK_LIST}" == true ]; then
          # Check if the block list file does not exist.
          if [ ! -f ${UNBOUND_CONFIG_HOST} ]; then
            # If the block list file is missing, download it from the specified URL.
            LOCAL_UNBOUND_BLOCKLIST_COPY=$(curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}')
          fi
        fi
        # Installation commands for Unbound vary based on the Linux distribution.
        # The following checks the distribution and installs Unbound accordingly.
        # For Debian-based distributions:
        if { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          apt-get install unbound unbound-host unbound-anchor -y
          # If the distribution is Ubuntu, disable systemd-resolved.
          if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
            systemctl disable --now systemd-resolved
          elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
            service systemd-resolved stop
          fi
        # For CentOS, RHEL, AlmaLinux, and Rocky:
        elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum install unbound unbound-host unbound-anchor -y
        # For Fedora:
        elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
          dnf install unbound unbound-host unbound-anchor -y
        # For Arch-based distributions:
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Su --noconfirm --needed unbound
        # For Alpine Linux:
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk add unbound unbound-host unbound-anchor
        # For FreeBSD:
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg install unbound unbound-host unbound-anchor
        # For Oracle Linux:
        elif [ "${CURRENT_DISTRO}" == "ol" ]; then
          yum install unbound unbound-host unbound-anchor -y
        fi
      fi
      # Configure Unbound to use the auto-trust-anchor-file.
      unbound-anchor -a ${UNBOUND_ANCHOR}
      # Configure Unbound to use the root hints file.
      printf "%s" "${LOCAL_UNBOUND_ROOT_HINTS_COPY}" >${UNBOUND_ROOT_HINTS}
      # Configure Unbound settings.
      # The settings are stored in a temporary variable and then written to the Unbound configuration file.
      # If INSTALL_BLOCK_LIST is true, include a block list in the Unbound configuration.
      # Configure Unbound settings.
      UNBOUND_TEMP_INTERFACE_INFO="server:
\tnum-threads: $(nproc)
\tverbosity: 0
\troot-hints: ${UNBOUND_ROOT_HINTS}
\tauto-trust-anchor-file: ${UNBOUND_ANCHOR}
\tinterface: 0.0.0.0
\tinterface: ::0
\tport: 53
\tmax-udp-size: 3072
\taccess-control: 0.0.0.0/0\trefuse
\taccess-control: ::0\trefuse
\taccess-control: ${PRIVATE_SUBNET_V4}\tallow
\taccess-control: ${PRIVATE_SUBNET_V6}\tallow
\taccess-control: 127.0.0.1\tallow
\taccess-control: ::1\tallow
\tprivate-address: ${PRIVATE_SUBNET_V4}
\tprivate-address: ${PRIVATE_SUBNET_V6}
\tprivate-address: 10.0.0.0/8
\tprivate-address: 127.0.0.0/8
\tprivate-address: 169.254.0.0/16
\tprivate-address: 172.16.0.0/12
\tprivate-address: 192.168.0.0/16
\tprivate-address: ::ffff:0:0/96
\tprivate-address: fd00::/8
\tprivate-address: fe80::/10
\tdo-ip4: yes
\tdo-ip6: yes
\tdo-udp: yes
\tdo-tcp: yes
\tchroot: \"\"
\thide-identity: yes
\thide-version: yes
\tharden-glue: yes
\tharden-dnssec-stripped: yes
\tharden-referral-path: yes
\tunwanted-reply-threshold: 10000000
\tcache-min-ttl: 86400
\tcache-max-ttl: 2592000
\tprefetch: yes
\tqname-minimisation: yes
\tprefetch-key: yes"
      echo -e "${UNBOUND_TEMP_INTERFACE_INFO}" | awk '!seen[$0]++' >${UNBOUND_CONFIG}
      # Check if we are installing a block list.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # Include the block list in the Unbound configuration.
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
      fi
      # If INSTALL_BLOCK_LIST is true, make the unbound directory.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # If the Unbound configuration directory does not exist, create it.
        if [ ! -d "${UNBOUND_CONFIG_DIRECTORY}" ]; then
          # Create the Unbound configuration directory.
          mkdir --parents "${UNBOUND_CONFIG_DIRECTORY}"
        fi
      fi
      # If the block list is enabled, configure Unbound to use the block list.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # Write the block list to the Unbound configuration block file.
        printf "%s" "${LOCAL_UNBOUND_BLOCKLIST_COPY}" >${UNBOUND_CONFIG_HOST}
      fi
      # Update ownership of Unbound's root directory.
      chown --recursive "${USER}":"${USER}" ${UNBOUND_ROOT}
      # Update the resolv.conf file to use Unbound.
      if [ -f "${RESOLV_CONFIG_OLD}" ]; then
        rm --force ${RESOLV_CONFIG_OLD}
      fi
      if [ -f "${RESOLV_CONFIG}" ]; then
        chattr -i ${RESOLV_CONFIG}
        mv ${RESOLV_CONFIG} ${RESOLV_CONFIG_OLD}
      fi
      echo "nameserver 127.0.0.1" >${RESOLV_CONFIG}
      echo "nameserver ::1" >>${RESOLV_CONFIG}
      chattr +i ${RESOLV_CONFIG}
      # Set CLIENT_DNS to use gateway addresses.
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Call the function to install Unbound.
  install_unbound

  # Function to configure WireGuard settings
  function wireguard_setconf() {
    # Generate server private and public keys
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "${SERVER_PRIVKEY}" | wg pubkey)
    # Generate client private and public keys
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
    # Assign client IPv4 and IPv6 addresses
    CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).2
    CLIENT_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-4):2
    # Generate pre-shared key and random port for the client
    PRESHARED_KEY=$(wg genpsk)
    PEER_PORT=$(shuf --input-range=1024-65535 --head-count=1)
    # Create the wireguard directory
    mkdir --parents ${WIREGUARD_PATH}
    # Create the client configuration directory
    mkdir --parents ${WIREGUARD_CLIENT_PATH}
    # Set up nftables rules depending on whether Unbound is installed
    if [ "${INSTALL_UNBOUND}" == true ]; then
      # Set up nftables rules for when Unbound is installed
      NFTABLES_POSTUP="sysctl --write net.ipv4.ip_forward=1; sysctl --write net.ipv6.conf.all.forwarding=1; nft add table inet wireguard-${WIREGUARD_PUB_NIC}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain {type nat hook postrouting priority srcnat\;}; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain oifname ${SERVER_PUB_NIC} masquerade"
      NFTABLES_POSTDOWN="sysctl --write net.ipv4.ip_forward=0; sysctl --write net.ipv6.conf.all.forwarding=0; nft delete table inet wireguard-${WIREGUARD_PUB_NIC}"
    else
      # Set up nftables rules for when Unbound is not installed
      NFTABLES_POSTUP="sysctl --write net.ipv4.ip_forward=1; sysctl --write net.ipv6.conf.all.forwarding=1; nft add table inet wireguard-${WIREGUARD_PUB_NIC}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} PREROUTING {type nat hook prerouting priority 0\;}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING {type nat hook postrouting priority 100\;}; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING ip saddr ${PRIVATE_SUBNET_V4} oifname ${SERVER_PUB_NIC} masquerade; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING ip6 saddr ${PRIVATE_SUBNET_V6} oifname ${SERVER_PUB_NIC} masquerade"
      NFTABLES_POSTDOWN="sysctl --write net.ipv4.ip_forward=0; sysctl --write net.ipv6.conf.all.forwarding=0; nft delete table inet wireguard-${WIREGUARD_PUB_NIC}"
    fi
    # Create server WireGuard configuration file
    echo "# ${PRIVATE_SUBNET_V4} ${PRIVATE_SUBNET_V6} ${SERVER_HOST}:${SERVER_PORT} ${SERVER_PUBKEY} ${CLIENT_DNS} ${PEER_MTU_CHOICE} ${NAT_CHOICE} ${CLIENT_ALLOWED_IP}
[Interface]
Address = ${GATEWAY_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${GATEWAY_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
ListenPort = ${SERVER_PORT}
MTU = ${INTERFACE_MTU_CHOICE}
PrivateKey = ${SERVER_PRIVKEY}
PostUp = ${NFTABLES_POSTUP}
PostDown = ${NFTABLES_POSTDOWN}
SaveConfig = false
# ${CLIENT_NAME} start
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${CLIENT_NAME} end" >>${WIREGUARD_CONFIG}

    # Generate client-specific WireGuard configuration file
    echo "# ${WIREGUARD_WEBSITE_URL}
[Interface]
Address = ${CLIENT_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${CLIENT_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${PEER_PORT}
MTU = ${PEER_MTU_CHOICE}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = ${CLIENT_ALLOWED_IP}
Endpoint = ${SERVER_HOST}:${SERVER_PORT}
PersistentKeepalive = ${NAT_CHOICE}
PresharedKey = ${PRESHARED_KEY}
PublicKey = ${SERVER_PUBKEY}" >>${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Apply appropriate permissions to directories (700)
    find ${WIREGUARD_PATH} -type d -exec chmod 700 {} \;
    # Apply appropriate permissions to configuration files (600)
    find ${WIREGUARD_PATH} -type f -exec chmod 600 {} \;
    # Ensure all files and directories are owned by root:root
    find ${WIREGUARD_PATH} -exec chown root:root {} \;
    # Schedule automatic WireGuard expiration if enabled
    if [ "${AUTOMATIC_WIREGUARD_EXPIRATION}" == true ]; then
      crontab -l | {
        cat
        echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
      } | crontab -
    fi
    # Manage the service based on the init system
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl enable --now nftables
      systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
      if [ "${INSTALL_UNBOUND}" == true ]; then
        systemctl enable --now unbound
        systemctl restart unbound
      fi
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service nftables start
      service wg-quick@${WIREGUARD_PUB_NIC} start
      if [ "${INSTALL_UNBOUND}" == true ]; then
        service unbound restart
      fi
    fi
    # Create a QR code for the client configuration for easy scanning
    qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Display the client configuration details in the terminal
    cat ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Show the path where the client configuration file is stored
    echo "Client Config --> ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
  }

  # Configuring WireGuard settings
  wireguard_setconf

# After WireGuard Install
else

  # Function to display the WireGuard configuration
  function display_wireguard_config() {
    wg show ${WIREGUARD_PUB_NIC}
  }

  # Function to initiate the WireGuard service
  function initiate_wireguard_service() {
    wg-quick up ${WIREGUARD_PUB_NIC}
  }

  # Function to terminate the WireGuard service
  function terminate_wireguard_service() {
    wg-quick down ${WIREGUARD_PUB_NIC}
  }

  # Function to restart the WireGuard service
  function restart_wireguard_service() {
    wg-quick down ${WIREGUARD_PUB_NIC}
    wg-quick up ${WIREGUARD_PUB_NIC}
  }

  # Function to ad a new user to wireguard
  function add_wireguard_peer() {
    # Adding a new peer to WireGuard
    # If a client name isn't supplied, the script will request one
    if [ -z "${NEW_CLIENT_NAME}" ]; then
      echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
      read -rp "New client peer:" -e -i "$(openssl rand -hex 5)" NEW_CLIENT_NAME
    fi
    # Input validation loop to ensure the name is alphanumeric.
    while [[ ! "$NEW_CLIENT_NAME" =~ ^[a-zA-Z0-9]+$ ]]; do
      echo "Invalid name. The name should contain only letters and numbers (no spaces or special characters)."
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" NEW_CLIENT_NAME
    done
    # If no client name is provided, use openssl to generate a random name
    if [ -z "${NEW_CLIENT_NAME}" ]; then
      NEW_CLIENT_NAME="$(openssl rand -hex 5)"
    fi
    # Extract the last IPv4 address used in the WireGuard configuration file
    LASTIPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | tail --lines=1)
    # Extract the last IPv6 address used in the WireGuard configuration file
    LASTIPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | tail --lines=1)
    # If no IPv4 and IPv6 addresses are found in the configuration file, set the initial values to 1
    if { [ -z "${LASTIPV4}" ] && [ -z "${LASTIPV6}" ]; }; then
      LASTIPV4=1
      LASTIPV6=1
    fi
    # Find the smallest used IPv4 address in the WireGuard configuration file
    SMALLEST_USED_IPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort | head --lines=1)
    # Find the largest used IPv4 address in the WireGuard configuration file
    LARGEST_USED_IPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort | tail --lines=1)
    # Create a list of used IPv4 addresses in the WireGuard configuration file
    USED_IPV4_LIST=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort)
    # Loop through IPv4 addresses and find an unused one
    while [ "${SMALLEST_USED_IPV4}" -le "${LARGEST_USED_IPV4}" ]; do
      if [[ ! ${USED_IPV4_LIST[*]} =~ ${SMALLEST_USED_IPV4} ]]; then
        FIND_UNUSED_IPV4=${SMALLEST_USED_IPV4}
        break
      fi
      SMALLEST_USED_IPV4=$((SMALLEST_USED_IPV4 + 1))
    done
    # Find the smallest used IPv6 address in the WireGuard configuration file
    SMALLEST_USED_IPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort | head --lines=1)
    # Find the largest used IPv6 address in the WireGuard configuration file
    LARGEST_USED_IPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort | tail --lines=1)
    # Create a list of used IPv6 addresses in the WireGuard configuration file
    USED_IPV6_LIST=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort)
    # Loop through IPv6 addresses and find an unused one
    while [ "${SMALLEST_USED_IPV6}" -le "${LARGEST_USED_IPV6}" ]; do
      if [[ ! ${USED_IPV6_LIST[*]} =~ ${SMALLEST_USED_IPV6} ]]; then
        FIND_UNUSED_IPV6=${SMALLEST_USED_IPV6}
        break
      fi
      SMALLEST_USED_IPV6=$((SMALLEST_USED_IPV6 + 1))
    done
    # If unused IPv4 and IPv6 addresses are found, set them as the last IPv4 and IPv6 addresses
    if { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
      LASTIPV4=$(echo "${FIND_UNUSED_IPV4}" | head --lines=1)
      LASTIPV6=$(echo "${FIND_UNUSED_IPV6}" | head --lines=1)
    fi
    if { [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
      # Get the current IPv4 and IPv6 ranges from the WireGuard config file
      CURRENT_IPV4_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      CURRENT_IPV6_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3)
      # Get the last octet of the IPv4 range and the fifth hextet of the IPv6 range
      IPV4_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4)
      IPV6_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5)
      # Get the second octet of the IPv4 range and the second hextet of the IPv6 range
      IPV4_AFTER_FIRST=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=2)
      IPV6_AFTER_FIRST=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=2)
      # Get the second and third octets of the IPv4 range and the third and fourth hextets of the IPv6 range
      SECOND_IPV4_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=2)
      SECOND_IPV6_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=2)
      THIRD_IPV4_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=3)
      THIRD_IPV6_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=3)
      # Calculate the next IPv4 and IPv6 ranges
      NEXT_IPV4_RANGE=$((THIRD_IPV4_IN_RANGE + 1))
      NEXT_IPV6_RANGE=$((THIRD_IPV6_IN_RANGE + 1))
      # Get the CIDR notation for the current IPv4 and IPv6 ranges
      CURRENT_IPV4_RANGE_CIDR=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=2)
      CURRENT_IPV6_RANGE_CIDR=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=2)
      FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=1,2)".${NEXT_IPV4_RANGE}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
      FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=1,2)":${NEXT_IPV6_RANGE}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
      if { [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ]; }; then
        if { [ "${SECOND_IPV4_IN_RANGE}" -ge 255 ] && [ "${SECOND_IPV6_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ] && [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
          # If all IP ranges are at their maximum value, then exit with an error message
          echo "Error: You are unable to add any more peers."
          exit
        fi
        # Calculate the next IPv4 and IPv6 ranges
        NEXT_IPV4_RANGE=$((SECOND_IPV4_IN_RANGE + 1))
        NEXT_IPV6_RANGE=$((SECOND_IPV6_IN_RANGE + 1))
        # Calculate the final IPv4 and IPv6 ranges
        FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=1)".${NEXT_IPV4_RANGE}.${IPV4_AFTER_FIRST}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
        FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=1)":${NEXT_IPV6_RANGE}:${IPV6_AFTER_FIRST}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
      fi
      # Replace the current IPv4 and IPv6 ranges with the final IPv4 and IPv6 ranges in the WireGuard config file
      sed --in-place "1s|${CURRENT_IPV4_RANGE}|${FINAL_IPV4_RANGE}|" ${WIREGUARD_CONFIG}
      sed --in-place "1s|${CURRENT_IPV6_RANGE}|${FINAL_IPV6_RANGE}|" ${WIREGUARD_CONFIG}
      # Set LASTIPV4 and LASTIPV6 to their maximum values to indicate that no more peers can be added
      LASTIPV4=1
      LASTIPV6=1
    fi
    # Generate a private key for the client
    CLIENT_PRIVKEY=$(wg genkey)
    # Derive the public key from the private key
    CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
    # Generate a preshared key for the client and server to use
    PRESHARED_KEY=$(wg genpsk)
    # Choose a random port number for the peer
    PEER_PORT=$(shuf --input-range=1024-65535 --head-count=1)
    # Get the private subnet and subnet mask from the WireGuard config file
    PRIVATE_SUBNET_V4=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
    PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2)
    PRIVATE_SUBNET_V6=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3)
    PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2)
    # Get the server host and public key from the WireGuard config file
    SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4)
    SERVER_PUBKEY=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=5)
    # Get the client DNS server, MTU choice, NAT choice, and allowed IP address from the WireGuard config file
    CLIENT_DNS=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=6)
    MTU_CHOICE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=7)
    NAT_CHOICE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=8)
    CLIENT_ALLOWED_IP=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=9)
    # Calculate the client's IP addresses based on the last IP addresses used
    CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).$((LASTIPV4 + 1))
    CLIENT_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-4):$((LASTIPV6 + 1))
    # Check if there are any unused IP addresses available
    if { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
      CLIENT_ADDRESS_V4=$(echo "${CLIENT_ADDRESS_V4}" | cut --delimiter="." --fields=1-3).${LASTIPV4}
      CLIENT_ADDRESS_V6=$(echo "${CLIENT_ADDRESS_V6}" | cut --delimiter=":" --fields=1-4):${LASTIPV6}
    fi
    # Create a temporary file to store the new client information
    WIREGUARD_TEMP_NEW_CLIENT_INFO="# ${NEW_CLIENT_NAME} start
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${NEW_CLIENT_NAME} end"
    # Write the temporary new client information to the 'add peer' configuration file
    echo "${WIREGUARD_TEMP_NEW_CLIENT_INFO}" >${WIREGUARD_ADD_PEER_CONFIG}
    # Add the new peer configuration to the WireGuard interface
    wg addconf ${WIREGUARD_PUB_NIC} ${WIREGUARD_ADD_PEER_CONFIG}
    # If there are no unused IPv4 and IPv6 addresses, append the new client information to the WireGuard configuration file
    if { [ -z "${FIND_UNUSED_IPV4}" ] && [ -z "${FIND_UNUSED_IPV6}" ]; }; then
      echo "${WIREGUARD_TEMP_NEW_CLIENT_INFO}" >>${WIREGUARD_CONFIG}
    # If there are unused IPv4 and IPv6 addresses, modify the 'add peer' configuration file and insert the new client information into the WireGuard configuration file
    elif { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
      sed --in-place "s|$|\\\n|" "${WIREGUARD_ADD_PEER_CONFIG}"
      sed --in-place "6s|\\\n||" "${WIREGUARD_ADD_PEER_CONFIG}"
      # Remove newline characters from the 'add peer' configuration file
      WIREGUARD_TEMPORARY_PEER_DATA=$(tr --delete "\n" <"${WIREGUARD_ADD_PEER_CONFIG}")
      # Calculate the line number where the new client information should be inserted
      TEMP_WRITE_LINE=$((LASTIPV4 - 2))
      # Insert the new client information into the WireGuard configuration file
      sed --in-place $((TEMP_WRITE_LINE * 6 + 11))i"${WIREGUARD_TEMPORARY_PEER_DATA}" ${WIREGUARD_CONFIG}
    fi
    # Remove the wireguard add peer config file
    rm --force ${WIREGUARD_ADD_PEER_CONFIG}
    # Create the client configuration file
    echo "# ${WIREGUARD_WEBSITE_URL}
[Interface]
Address = ${CLIENT_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${CLIENT_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${PEER_PORT}
MTU = ${MTU_CHOICE}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = ${CLIENT_ALLOWED_IP}
Endpoint = ${SERVER_HOST}
PersistentKeepalive = ${NAT_CHOICE}
PresharedKey = ${PRESHARED_KEY}
PublicKey = ${SERVER_PUBKEY}" >>${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Add the WireGuard interface configuration, stripping any unnecessary fields
    wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
    # Check if automatic WireGuard expiration is enabled, and if so, set the expiration date
    if crontab -l | grep -q "${CURRENT_FILE_PATH} --remove"; then
      crontab -l | {
        cat
        # Add a new cron job to remove the new client at the specified expiration date
        echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${NEW_CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
      } | crontab -
    fi
    # Generate and display a QR code for the new client configuration
    qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Output the new client configuration file content
    cat ${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Display the path of the new client configuration file
    echo "Client config --> ${WIREGUARD_CLIENT_PATH}/${NEW_CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
  }

  # Function to remove a WireGuard peer
  function remove_wireguard_peer() {
    # If the user passed the peer name as an argument, use that
    if [ -n "$1" ]; then
      REMOVECLIENT="$1"
    else
      # Prompt the user to choose a WireGuard peer to remove
      echo "Which WireGuard peer would you like to remove?"

      # List all the peers' names with numbers
      PEERS=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      PS3="Select a peer (enter the number): "
      select PEER in $PEERS; do
        if [ -n "$PEER" ]; then
          REMOVECLIENT="$PEER"
          break
        else
          echo "Invalid selection. Please choose a valid number."
        fi
      done
    fi
    # Extract the public key of the selected peer from the configuration file
    CLIENTKEY=$(sed -n "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | cut --delimiter=" " --fields=3)
    # Remove the selected peer from the WireGuard interface using the extracted public key
    wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
    # Remove the selected peer's configuration block from the WireGuard configuration file
    sed --in-place "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/d" ${WIREGUARD_CONFIG}
    # If the selected peer has a configuration file in the client path, remove it
    if [ -f "${WIREGUARD_CLIENT_PATH}/${REMOVECLIENT}-${WIREGUARD_PUB_NIC}.conf" ]; then
      rm --force ${WIREGUARD_CLIENT_PATH}/"${REMOVECLIENT}"-${WIREGUARD_PUB_NIC}.conf
    fi
    # Reload the WireGuard interface configuration to apply the changes
    wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
    # Remove any cronjobs associated with the removed peer
    crontab -l | grep --invert-match "${REMOVECLIENT}" | crontab -
  }

  # Function to reinstall the WireGuard service
  function reinstall_wireguard() {
    # Reinstall WireGuard
    # Check if the current init system is systemd, and if so, disable and stop the WireGuard service
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
    # Check if the current init system is init, and if so, stop the WireGuard service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service wg-quick@${WIREGUARD_PUB_NIC} stop
    fi
    # Bring down the WireGuard interface
    wg-quick down ${WIREGUARD_PUB_NIC}
    # Reinstall or update WireGuard based on the current Linux distribution
    if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
      dpkg-reconfigure wireguard-dkms
      modprobe wireguard
    elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
      yum reinstall wireguard-tools -y
    elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
      pacman -Su --noconfirm wireguard-tools
    elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
      apk fix wireguard-tools
    elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
      pkg check wireguard
    elif [ "${CURRENT_DISTRO}" == "ol" ]; then
      yum reinstall wireguard-tools -y
    fi
    # Enable and start the WireGuard service based on the current init system
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service wg-quick@${WIREGUARD_PUB_NIC} restart
    fi
  }

  # Function to uninstall the WireGuard service
  function uninstall_wireguard() {
    # Uninstall WireGuard and purging files
    # Check if the current init system is systemd and disable the WireGuard service
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
      # If the init system is not systemd, check if it is init and stop the WireGuard service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service wg-quick@${WIREGUARD_PUB_NIC} stop
    fi
    # Bring down the WireGuard interface
    wg-quick down ${WIREGUARD_PUB_NIC}
    # Removing Wireguard Files
    # Check if the WireGuard directory exists and remove it
    if [ -d "${WIREGUARD_PATH}" ]; then
      rm --recursive --force ${WIREGUARD_PATH}
    fi
    # Remove WireGuard and qrencode packages based on the current distribution
    # For CentOS, AlmaLinux, and Rocky Linux distributions
    if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
      yum remove wireguard qrencode -y
      # For Ubuntu, Debian, Raspbian, Pop!_OS, Kali Linux, Linux Mint, and KDE Neon distributions
    elif { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
      apt-get remove --purge wireguard qrencode -y
      # Remove backports repository and keys if they exist
      if [ -f "/etc/apt/sources.list.d/backports.list" ]; then
        rm --force /etc/apt/sources.list.d/backports.list
        apt-key del 648ACFD622F3D138
        apt-key del 0E98404D386FA1D9
      fi
      # For Arch, Arch ARM, and Manjaro distributions
    elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
      pacman -Rs --noconfirm wireguard-tools qrencode
      # For Fedora distribution
    elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
      dnf remove wireguard qrencode -y
      # Remove WireGuard repository if it exists
      if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
        rm --force /etc/yum.repos.d/wireguard.repo
      fi
      # For RHEL distribution
    elif [ "${CURRENT_DISTRO}" == "rhel" ]; then
      yum remove wireguard qrencode -y
      # Remove WireGuard repository if it exists
      if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
        rm --force /etc/yum.repos.d/wireguard.repo
      fi
      # For Alpine Linux distribution
    elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
      apk del wireguard-tools libqrencode
      # For FreeBSD distribution
    elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
      pkg delete wireguard libqrencode
    # For Oracle Linux distribution
    elif [ "${CURRENT_DISTRO}" == "ol" ]; then
      yum remove wireguard qrencode -y
    fi
    # Delete WireGuard backup
    if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
      rm --force ${WIREGUARD_CONFIG_BACKUP}
      if [ -f "${WIREGUARD_BACKUP_PASSWORD_PATH}" ]; then
        rm --force "${WIREGUARD_BACKUP_PASSWORD_PATH}"
      fi
    fi
    # Uninstall unbound
    # Check if the 'unbound' command is available on the system
    if [ -x "$(command -v unbound)" ]; then
      # Check if the current init system is systemd and disable the Unbound service
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl disable --now unbound
      # If the init system is not systemd, check if it is init and stop the Unbound service
      elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
        service unbound stop
      fi
      # If a backup of the resolv.conf file exists, restore it and set the immutable flag
      if [ -f "${RESOLV_CONFIG_OLD}" ]; then
        chattr -i ${RESOLV_CONFIG}
        rm --force ${RESOLV_CONFIG}
        mv ${RESOLV_CONFIG_OLD} ${RESOLV_CONFIG}
        chattr +i ${RESOLV_CONFIG}
      fi
      # Remove Unbound package based on the current distribution
      # For CentOS, RHEL, AlmaLinux, and Rocky Linux distributions
      if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum remove unbound -y
      # For Ubuntu, Debian, Raspbian, Pop!_OS, Kali Linux, Linux Mint, and KDE Neon distributions
      elif { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        # If the distribution is Ubuntu, restart systemd-resolved service based on the init system
        if [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
          if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
            systemctl enable --now systemd-resolved
          elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
            service systemd-resolved restart
          fi
        fi
        apt-get remove --purge unbound -y
      # For Arch, Arch ARM, and Manjaro distributions
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Rs --noconfirm unbound
      # For Fedora and Oracle Linux distributions
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
        yum remove unbound -y
      # For Alpine Linux distribution
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk del unbound
      # For FreeBSD distribution
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg delete unbound
      fi
      # Remove Unbound root directory if it exists
      if [ -d "${UNBOUND_ROOT}" ]; then
        rm --recursive --force ${UNBOUND_ROOT}
      fi
      # Remove Unbound root anchor file if it exists
      if [ -f "${UNBOUND_ANCHOR}" ]; then
        rm --force ${UNBOUND_ANCHOR}
      fi
    fi
    # If any cronjobs are identified, they should be removed.
    crontab -l | grep --invert-match "${CURRENT_FILE_PATH}" | crontab -
  }

  # Function to update the WiregGuard Script
  function update_wireguard_script() {
    # Update WireGuard Manager script.
    # Calculate the SHA3-512 hash of the current WireGuard Manager script
    CURRENT_WIREGUARD_MANAGER_HASH=$(openssl dgst -sha3-512 "${CURRENT_FILE_PATH}" | cut --delimiter=" " --fields=2)
    # Calculate the SHA3-512 hash of the latest WireGuard Manager script from the remote source
    NEW_WIREGUARD_MANAGER_HASH=$(curl --silent "${WIREGUARD_MANAGER_UPDATE}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
    # If the hashes don't match, update the local WireGuard Manager script
    if [ "${CURRENT_WIREGUARD_MANAGER_HASH}" != "${NEW_WIREGUARD_MANAGER_HASH}" ]; then
      curl "${WIREGUARD_MANAGER_UPDATE}" -o "${CURRENT_FILE_PATH}"
      chmod +x "${CURRENT_FILE_PATH}"
      echo "Updating WireGuard Manager script..."
    fi
    # Update the unbound configs if the unbound command is available on the system
    if [ -x "$(command -v unbound)" ]; then
      # Update the unbound root hints file if it exists
      if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
        CURRENT_ROOT_HINTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_ROOT_HINTS}" | cut --delimiter=" " --fields=2)
        NEW_ROOT_HINTS_HASH=$(curl --silent "${UNBOUND_ROOT_SERVER_CONFIG_URL}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
        if [ "${CURRENT_ROOT_HINTS_HASH}" != "${NEW_ROOT_HINTS_HASH}" ]; then
          curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o ${UNBOUND_ROOT_HINTS}
          echo "Updating root hints file..."
          LOCAL_RESTART_UNBOUND=true
        fi
      fi
      # Update the unbound config host file if it exists
      if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
        CURRENT_UNBOUND_HOSTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_CONFIG_HOST}" | cut --delimiter=" " --fields=2)
        NEW_UNBOUND_HOSTS_HASH=$(curl --silent "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
        if [ "${CURRENT_UNBOUND_HOSTS_HASH}" != "${NEW_UNBOUND_HOSTS_HASH}" ]; then
          curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
          echo "Updating unbound config host file..."
          LOCAL_RESTART_UNBOUND=true
        fi
      fi
      # Check if the local unbound restart flag is set to true and restart the unbound service
      if [ "${LOCAL_RESTART_UNBOUND}" == "true" ]; then
        # Once everything is completed, restart the unbound service
        if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
          systemctl restart unbound
          echo "Restarting unbound service..."
        elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
          service unbound restart
          echo "Restarting unbound service..."
        fi
      fi
    fi
  }

  # Function to backup the WireGuard configuration
  function backup_wireguard_config() {
    # If the WireGuard config backup file exists, remove it
    if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
      rm --force ${WIREGUARD_CONFIG_BACKUP}
      echo "Removing existing backup..."
    fi
    # If the system backup path directory does not exist, create it along with any necessary parent directories
    if [ ! -d "${SYSTEM_BACKUP_PATH}" ]; then
      mkdir --parents ${SYSTEM_BACKUP_PATH}
      echo "Creating backup directory..."
    fi
    # If the WireGuard path directory exists, proceed with the backup process
    if [ -d "${WIREGUARD_PATH}" ]; then
      # Generate a random 50-character hexadecimal backup password and store it in a file
      BACKUP_PASSWORD="$(openssl rand -hex 10)"
      echo "${BACKUP_PASSWORD}" >"${WIREGUARD_BACKUP_PASSWORD_PATH}"
      # Zip the WireGuard config file using the generated backup password and save it as a backup
      zip -P "${BACKUP_PASSWORD}" -rj ${WIREGUARD_CONFIG_BACKUP} ${WIREGUARD_CONFIG}
      # Echo the backup password and path to the terminal
      echo "Backup Password: ${BACKUP_PASSWORD}"
      echo "Backup Path: ${WIREGUARD_CONFIG_BACKUP}"
      echo "Please save the backup password and path in a secure location."
    fi
  }

  # Function to restore the WireGuard configuration
  function restore_wireguard_config() {
    # Restore WireGuard Config
    # Check if the WireGuard config backup file does not exist, and if so, exit the script
    if [ ! -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
      echo "Error: The WireGuard configuration backup file could not be found. Please ensure it exists and try again."
      exit
    fi
    # Prompt the user to enter the backup password and store it in the WIREGUARD_BACKUP_PASSWORD variable
    read -rp "Backup Password: " -e -i "$(cat "${WIREGUARD_BACKUP_PASSWORD_PATH}")" WIREGUARD_BACKUP_PASSWORD
    # If the WIREGUARD_BACKUP_PASSWORD variable is empty, exit the script
    if [ -z "${WIREGUARD_BACKUP_PASSWORD}" ]; then
      echo "Error: The backup password field is empty. Please provide a valid password."
      exit
    fi
    # Unzip the backup file, overwriting existing files, using the specified backup password, and extract the contents to the WireGuard path
    unzip -o -P "${WIREGUARD_BACKUP_PASSWORD}" "${WIREGUARD_CONFIG_BACKUP}" -d "${WIREGUARD_PATH}"
    # If the current init system is systemd, enable and start the wg-quick service
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
    # If the current init system is init, restart the wg-quick service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service wg-quick@${WIREGUARD_PUB_NIC} restart
    fi
  }

  # Function to update the WireGuard interface IP
  function update_wireguard_interface-ip() {
    echo "How would you like to update the IP address?"
    echo "  1) Automatically detect the current IP"
    echo "  2) Manually specify the IP"
    # Prompt the user until they enter a valid choice
    until [[ "${IP_UPDATE_METHOD}" =~ ^[1-2]$ ]]; do
      read -rp "Update Method [1-2]:" -e -i 1 IP_UPDATE_METHOD
    done
    case ${IP_UPDATE_METHOD} in
    1)
      # Change the IP address of your wireguard interface.
      get_network_information
      # Extract the current IP address method from the WireGuard config file
      CURRENT_IP_METHORD=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4)
      # If the current IP address method is IPv4, extract the old server host and set the new server host to DEFAULT_INTERFACE_IPV4
      if [[ ${CURRENT_IP_METHORD} != *"["* ]]; then
        OLD_SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter=":" --fields=1)
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV4}
      fi
      # If the current IP address method is IPv6, extract the old server host and set the new server host to DEFAULT_INTERFACE_IPV6
      if [[ ${CURRENT_IP_METHORD} == *"["* ]]; then
        OLD_SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter="[" --fields=2 | cut --delimiter="]" --fields=1)
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV6}
      fi
      # If the old server host is different from the new server host, update the server host in the WireGuard config file
      if [ "${OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
        sed --in-place "1s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" ${WIREGUARD_CONFIG}
      fi
      # Create a list of existing WireGuard clients from the WireGuard config file
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      # Add the clients to the USER_LIST array
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
      done
      # Loop through the clients in the USER_LIST array
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        # Check if the client's config file exists
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          # Update the server host in the client's config file
          sed --in-place "s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
        fi
      done
      ;;
    2)
      # Manually specify the IP
      read -rp "Enter the new server IP address: " NEW_SERVER_HOST
      if [ -z "${NEW_SERVER_HOST}" ]; then
        echo "No IP address provided. Aborting."
        exit 1
      fi
      # Extract the current server host for manual update
      CURRENT_IP_METHOD=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4)
      if [[ ${CURRENT_IP_METHOD} != *"["* ]]; then
        OLD_SERVER_HOST=$(echo "${CURRENT_IP_METHOD}" | cut --delimiter=":" --fields=1)
      else
        OLD_SERVER_HOST=$(echo "${CURRENT_IP_METHOD}" | cut --delimiter="[" --fields=2 | cut --delimiter="]" --fields=1)
      fi
      sed --in-place "1s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" ${WIREGUARD_CONFIG}
      # Update client configurations
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$((${ADD_CONTENT} + 1))
      done
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          sed --in-place "s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
        fi
      done
      ;;
    esac
  }

  # Function to update the WireGuard interface port
  function update_wireguard_interface_port() {
    # Change the wireguard interface's port number.
    # Extract the old server port from the WireGuard config file
    OLD_SERVER_PORT=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter=":" --fields=2)
    # Prompt the user to enter a valid custom port (between 1 and 65535) and store it in NEW_SERVER_PORT
    until [[ "${NEW_SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${NEW_SERVER_PORT}" -ge 1 ] && [ "${NEW_SERVER_PORT}" -le 65535 ]; do
      read -rp "Enter a custom port number (between 1 and 65535): " -e -i 51820 NEW_SERVER_PORT
    done
    # Check if the chosen port is already in use by another application
    if [ "$(lsof -i UDP:"${NEW_SERVER_PORT}")" ]; then
      # If the port is in use, print an error message and exit the script
      echo "Error: The port number ${NEW_SERVER_PORT} is already in use by another application. Please try a different port number."
      exit
    fi
    # If the old server port is different from the new server port, update the server port in the WireGuard config file
    if [ "${OLD_SERVER_PORT}" != "${NEW_SERVER_PORT}" ]; then
      sed --in-place "s/${OLD_SERVER_PORT}/${NEW_SERVER_PORT}/g" ${WIREGUARD_CONFIG}
      echo "The server port has changed from ${OLD_SERVER_PORT} to ${NEW_SERVER_PORT} in ${WIREGUARD_CONFIG}."
    fi
    # Create a list of existing WireGuard clients from the WireGuard config file
    COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
    # Add the clients to the USER_LIST array
    for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
      USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
      ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
    done
    # Loop through the clients in the USER_LIST array
    for CLIENT_NAME in "${USER_LIST[@]}"; do
      # Check if the client's config file exists
      if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
        # Update the server port in the client's config file
        sed --in-place "s/${OLD_SERVER_PORT}/${NEW_SERVER_PORT}/" "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
        echo "The server port has changed from ${OLD_SERVER_PORT} to ${NEW_SERVER_PORT} in ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf."
      fi
    done
  }

  # Function to purge all WireGuard peers
  function purge_all_wireguard_peers() {
    # Remove all the peers from the interface.
    COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
    # This line gets the list of clients in the config file by searching for the string "start" and then extracting the second field (the client name) from each line.
    for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
      USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
      ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
    done
    # This loop iterates over each client in the list and adds it to an array called USER_LIST.
    for CLIENT_NAME in "${USER_LIST[@]}"; do
      CLIENTKEY=$(sed -n "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | cut --delimiter=" " --fields=3)
      # This line extracts the client's public key from the config file.
      wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
      # This line removes the client from the server.
      sed --in-place "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/d" ${WIREGUARD_CONFIG}
      # This line removes the client's config from the server.
      if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
        rm --force ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      else
        echo "The client config file for ${CLIENT_NAME} does not exist."
      fi
      # This line removes the client's config file from the server.
      wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      # This line removes the client's config from the running server.
      crontab -l | grep --invert-match "${CLIENT_NAME}" | crontab -
      # This line removes the client from the cron job.
    done
  }

  # Function to generate a QR code for the WireGuard configuration
  function generate_wireguard_qr_code() {
    # Generate a QR code for a WireGuard peer.
    # Print a prompt asking the user to choose a WireGuard peer for generating a QR code
    echo "Which WireGuard peer would you like to generate a QR code for?"
    # Extract and display a list of peer names from the WireGuard config file
    grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2
    # Prompt the user to enter the desired peer's name and store it in the VIEW_CLIENT_INFO variable
    read -rp "Enter the name of the peer you want to view information for: " VIEW_CLIENT_INFO
    # Check if the config file for the specified peer exists
    if [ -f "${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf" ]; then
      # Generate a QR code for the specified peer's config file and display it in the terminal
      qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${VIEW_CLIENT_INFO}"-${WIREGUARD_PUB_NIC}.conf
      # Print the file path of the specified peer's config file
      echo "Peer's config --> ${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf"
    else
      # If the config file for the specified peer does not exist, print an error message
      echo "Error: The peer you specified could not be found. Please ensure you've entered the correct information."
      exit
    fi
  }

  # Function to verify the WireGuard configurations
  function verify_wireguard_configurations() {
    # Check if the `unbound` command is available on the system by checking if it is executable
    if [ -x "$(command -v unbound)" ]; then
      # Check if the output of `unbound-checkconf` run on `UNBOUND_CONFIG` contains "no errors"
      if [[ "$(unbound-checkconf ${UNBOUND_CONFIG})" != *"no errors"* ]]; then
        # If "no errors" was not found in output of previous command, print an error message
        "$(unbound-checkconf ${UNBOUND_CONFIG})"
        echo "Error: We found an error on your unbound config file located at ${UNBOUND_CONFIG}"
        exit
      fi
      # Check if output of `unbound-host` run on `UNBOUND_CONFIG` with arguments `-C`, `-v`, and `cloudflare.com` contains "secure"
      if [[ "$(unbound-host -C ${UNBOUND_CONFIG} -v cloudflare.com)" != *"secure"* ]]; then
        # If "secure" was not found in output of previous command, print an error message
        "$(unbound-host -C ${UNBOUND_CONFIG} -v cloudflare.com)"
        echo "Error: We found an error on your unbound DNS-SEC config file loacted at ${UNBOUND_CONFIG}"
        exit
      fi
      echo "Your unbound config file located at ${UNBOUND_CONFIG} is valid."
    fi
    # Check if the `wg` command is available on the system by checking if it is executable
    if [ -x "$(command -v wg)" ]; then
      # Check if the output of `wg` contains "interface" and "public key"
      if [[ "$(wg)" != *"interface"* ]] && [[ "$(wg)" != *"public key"* ]]; then
        # If "interface" and "public key" were not found in output of previous command, print an error message
        echo "Error: We found an error on your WireGuard interface."
        exit
      fi
      echo "Your WireGuard interface is valid."
    fi
  }

  # What to do if the software is already installed?
  function wireguard_next_questions_interface() {
    echo "Please select an action:"
    echo "   1) Display WireGuard configuration"
    echo "   2) Initiate WireGuard service"
    echo "   3) Terminate WireGuard service"
    echo "   4) Restart WireGuard service"
    echo "   5) Add a new WireGuard peer (client)"
    echo "   6) Remove a WireGuard peer (client)"
    echo "   7) Reinstall WireGuard service"
    echo "   8) Uninstall WireGuard service"
    echo "   9) Update this management script"
    echo "   10) Backup WireGuard configuration"
    echo "   11) Restore WireGuard configuration"
    echo "   12) Update WireGuard interface IP"
    echo "   13) Update WireGuard interface port"
    echo "   14) Purge all WireGuard peers"
    echo "   15) Generate a QR code for WireGuard configuration"
    echo "   16) Verify WireGuard configurations"
    until [[ "${WIREGUARD_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${WIREGUARD_OPTIONS}" -ge 1 ] && [ "${WIREGUARD_OPTIONS}" -le 16 ]; do
      read -rp "Select an Option [1-16]:" -e -i 0 WIREGUARD_OPTIONS
    done
    case ${WIREGUARD_OPTIONS} in
    1)
      # Display WireGuard configuration
      display_wireguard_config
      ;;
    2)
      # Initiate WireGuard service
      initiate_wireguard_service
      ;;
    3)
      # Terminate WireGuard service
      terminate_wireguard_service
      ;;
    4)
      # Restart WireGuard service
      restart_wireguard_service
      ;;
    5)
      # Add a new WireGuard peer (client)
      add_wireguard_peer
      ;;
    6)
      # Remove a WireGuard peer (client)
      remove_wireguard_peer
      ;;
    7)
      # Reinstall WireGuard service
      reinstall_wireguard
      ;;
    8)
      # Uninstall WireGuard service
      uninstall_wireguard
      ;;
    9)
      # Update this management script
      update_wireguard_script
      ;;
    10)
      # Backup WireGuard configuration
      backup_wireguard_config
      ;;
    11)
      # Restore WireGuard configuration
      restore_wireguard_config
      ;;
    12)
      # Update WireGuard interface IP
      update_wireguard_interface-ip
      ;;
    13)
      # Update WireGuard interface port
      update_wireguard_interface_port
      ;;
    14)
      # Purge all WireGuard peers
      purge_all_wireguard_peers
      ;;
    15)
      # Generate a QR code for WireGuard configuration
      generate_wireguard_qr_code
      ;;
    16)
      # Verify WireGuard configurations
      verify_wireguard_configurations
      ;;
    esac
  }

  # Running Questions Command
  wireguard_next_questions_interface

fi
