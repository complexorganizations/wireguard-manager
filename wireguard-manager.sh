#!/usr/bin/env bash
# This line sets the interpreter for the script as the Bash shell.

# https://github.com/complexorganizations/wireguard-manager
# This line provides a link to the GitHub repository for the WireGuard manager project.

# The script requires root privileges.
function super-user-check() {
  # This function checks if the script is running as the root user.
  if [ "${EUID}" -ne 0 ]; then
    # If the effective user ID is not 0 (root), display an error message and exit.
    echo "Error: You need to run this script as administrator."
    exit
  fi
}

# The script checks if the user is the root user.

super-user-check
# Calls the super-user-check function.

# The following function retrieves the current system information.
function system-information() {
  # This function retrieves the ID, version, and major version of the current system.
  if [ -f /etc/os-release ]; then
    # Check if the /etc/os-release file exists, and if so, source it to get the system information.
    # shellcheck source=/dev/null
    source /etc/os-release
    CURRENT_DISTRO=${ID}                                                                              # CURRENT_DISTRO is the ID of the current system
    CURRENT_DISTRO_VERSION=${VERSION_ID}                                                              # CURRENT_DISTRO_VERSION is the VERSION_ID of the current system
    CURRENT_DISTRO_MAJOR_VERSION=$(echo "${CURRENT_DISTRO_VERSION}" | cut --delimiter="." --fields=1) # CURRENT_DISTRO_MAJOR_VERSION is the major version of the current system (e.g. "16" for Ubuntu 16.04)
  fi
}

# The system-information function is being called.

system-information
# Calls the system-information function.

# Define a function to check system requirements
function installing-system-requirements() {
  # Check if the current Linux distribution is supported
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
    # Check if required packages are already installed
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v cron)" ] || [ ! -x "$(command -v awk)" ] || [ ! -x "$(command -v ps)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v qrencode)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v nft)" ] || [ ! -x "$(command -v ifup)" ] || [ ! -x "$(command -v chattr)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v systemd-detect-virt)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install curl coreutils jq iproute2 lsof cron gawk procps grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum check-update
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" -ge 7 ]; then
          yum install epel-release elrepo-release -y
        fi
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
          yum install yum-plugin-elrepo -y
        fi
        yum install curl coreutils jq iproute lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables NetworkManager e2fsprogs gnupg systemd -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Sy --noconfirm archlinux-keyring
        pacman -Su --noconfirm --needed curl coreutils jq iproute2 lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk add curl coreutils jq iproute2 lsof cronie gawk procps grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg install curl coreutils jq iproute2 lsof cronie gawk procps grep qrencode sed zip unzip openssl nftables ifupdown e2fsprogs gnupg systemd
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        yum check-update
        yum install curl coreutils jq iproute lsof cronie gawk procps-ng grep qrencode sed zip unzip openssl nftables NetworkManager e2fsprogs gnupg systemd -y
      fi
    fi
  else
    echo "Error: ${CURRENT_DISTRO} ${CURRENT_DISTRO_VERSION} is not supported."
    exit
  fi
}

# Call the function to check for system requirements and install necessary packages if needed
installing-system-requirements

# Checking For Virtualization
function virt-check() {
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
  "kvm" | "none" | "qemu" | "lxc" | "microsoft" | "vmware" | "xen" | "amazon") ;;
  *)
    echo "${CURRENT_SYSTEM_VIRTUALIZATION} virtualization is not supported (yet)."
    exit
    ;;
  esac
}

# Call the virt-check function to check for supported virtualization.
virt-check

# The following function checks the kernel version.
function kernel-check() {
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
    echo "Error: Kernel ${CURRENT_KERNEL_VERSION} not supported, please update to ${ALLOWED_KERNEL_VERSION}."
    exit
  fi
  if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
    # If the current major version is equal to the allowed major version, check the minor version.
    if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
      # If the current minor version is less than the allowed minor version, show an error message and exit.
      echo "Error: Kernel ${CURRENT_KERNEL_VERSION} not supported, please update to ${ALLOWED_KERNEL_VERSION}."
      exit
    fi
  fi
}

# Call the kernel-check function to verify the kernel version.
kernel-check

# The following function checks if the current init system is one of the allowed options.
function check-current-init-system() {
  # This function checks if the current init system is systemd or sysvinit.
  # If it is neither, the script exits.
  CURRENT_INIT_SYSTEM=$(ps --no-headers -o comm 1)
  # This line retrieves the current init system by checking the process name of PID 1.
  case ${CURRENT_INIT_SYSTEM} in
  # The case statement checks if the retrieved init system is one of the allowed options.
  *"systemd"* | *"init"*)
    # If the init system is systemd or sysvinit (init), continue with the script.
    ;;
  *)
    # If the init system is not one of the allowed options, display an error message and exit.
    echo "${CURRENT_INIT_SYSTEM} init is not supported (yet)."
    exit
    ;;
  esac
}

# The check-current-init-system function is being called.

check-current-init-system
# Calls the check-current-init-system function.

# The following function checks if there's enough disk space to proceed with the installation.
function check-disk-space() {
  # This function checks if there is more than 1 GB of free space on the drive.
  FREE_SPACE_ON_DRIVE_IN_MB=$(df -m / | tr --squeeze-repeats " " | tail -n1 | cut --delimiter=" " --fields=4)
  # This line calculates the available free space on the root partition in MB.
  if [ "${FREE_SPACE_ON_DRIVE_IN_MB}" -le 1024 ]; then
    # If the available free space is less than or equal to 1024 MB (1 GB), display an error message and exit.
    echo "Error: More than 1 GB of free space is needed to install everything."
    exit
  fi
}

# The check-disk-space function is being called.

check-disk-space
# Calls the check-disk-space function.

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
# Assigns a path for the WireGuard Manager script
UNBOUND_MANAGER="${UNBOUND_ROOT}/wireguard-manager"
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
case $(shuf --input-range=1-5 --head-count=1) in
1)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/named.cache"
  ;;
2)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://cdn.statically.io/gh/complexorganizations/wireguard-manager/main/assets/named.cache"
  ;;
3)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://cdn.jsdelivr.net/gh/complexorganizations/wireguard-manager/assets/named.cache"
  ;;
4)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://www.internic.net/domain/named.cache"
  ;;
5)
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://complexorganizations.github.io/wireguard-manager/assets/named.cache"
  ;;
esac
case $(shuf --input-range=1-5 --head-count=1) in
1)
  UNBOUND_CONFIG_HOST_URL="https://raw.githubusercontent.com/complexorganizations/content-blocker/main/assets/hosts"
  ;;
2)
  UNBOUND_CONFIG_HOST_URL="https://cdn.statically.io/gh/complexorganizations/content-blocker/main/assets/hosts"
  ;;
3)
  UNBOUND_CONFIG_HOST_URL="https://cdn.jsdelivr.net/gh/complexorganizations/content-blocker/assets/hosts"
  ;;
4)
  UNBOUND_CONFIG_HOST_URL="https://combinatronics.io/complexorganizations/content-blocker/main/assets/hosts"
  ;;
5)
  UNBOUND_CONFIG_HOST_URL="https://complexorganizations.github.io/wireguard-manager/assets/hosts"
  ;;
esac
case $(shuf --input-range=1-5 --head-count=1) in
1)
  WIREGUARD_MANAGER_UPDATE="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh"
  ;;
2)
  WIREGUARD_MANAGER_UPDATE="https://cdn.statically.io/gh/complexorganizations/wireguard-manager/main/wireguard-manager.sh"
  ;;
3)
  WIREGUARD_MANAGER_UPDATE="https://cdn.jsdelivr.net/gh/complexorganizations/wireguard-manager/wireguard-manager.sh"
  ;;
4)
  WIREGUARD_MANAGER_UPDATE="https://combinatronics.io/complexorganizations/wireguard-manager/main/wireguard-manager.sh"
  ;;
5)
  WIREGUARD_MANAGER_UPDATE="https://complexorganizations.github.io/wireguard-manager/wireguard-manager.sh"
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

# This is a Bash function named "get-network-information" that retrieves network information.
function get-network-information() {
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
function usage-guide() {
  echo "usage: ./$(basename "${0}") <command>"
  echo "  --install     Install WireGuard Interface"
  echo "  --start       Start WireGuard Interface"
  echo "  --stop        Stop WireGuard Interface"
  echo "  --restart     Restart WireGuard Interface"
  echo "  --list        Show WireGuard Peer(s)"
  echo "  --add         Add WireGuard Peer"
  echo "  --remove      Remove WireGuard Peer"
  echo "  --reinstall   Reinstall WireGuard Interface"
  echo "  --uninstall   Uninstall WireGuard Interface"
  echo "  --update      Update WireGuard Manager"
  echo "  --ddns        Update WireGuard IP Address"
  echo "  --backup      Backup WireGuard"
  echo "  --restore     Restore WireGuard"
  echo "  --purge       Purge WireGuard Peer(s)"
  echo "  --help        Show Usage Guide"
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
    --help) # If it's "--help", call the function usage-guide
      shift
      usage-guide
      ;;
    *) # If it's anything else, print an error message and call the function usage-guide, then exit
      echo "Invalid argument: ${1}"
      usage-guide
      exit
      ;;
    esac
  done
}

# Call the function usage with all the command line arguments
usage "$@"

# The function defines default values for configuration variables when installing WireGuard in headless mode.
# These variables include private subnet settings, server host settings, NAT choice, MTU choice, client allowed IP settings, automatic updates, automatic backup, DNS provider settings, content blocker settings, client name, and automatic config remover.
function headless-install() {
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
    CLIENT_NAME=${CLIENT_NAME=$(openssl rand -hex 50)}         # Generate a random client name if not specified
    AUTOMATIC_CONFIG_REMOVER=${AUTOMATIC_CONFIG_REMOVER=1}     # Default to 1 if not specified
  fi
}

# Call the headless-install function to set default values for configuration variables in headless mode.
headless-install

# Set up the wireguard, if config it isn't already there.
if [ ! -f "${WIREGUARD_CONFIG}" ]; then

  # Define a function to set a custom IPv4 subnet
  function set-ipv4-subnet() {
    # Prompt the user for the desired IPv4 subnet
    echo "What IPv4 subnet do you want to use?"
    echo "  1) 10.0.0.0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Keep prompting the user until they enter a valid subnet choice
    until [[ "${PRIVATE_SUBNET_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V4_SETTINGS
    done
    # Based on the user's choice, set the private IPv4 subnet
    case ${PRIVATE_SUBNET_V4_SETTINGS} in
    1)
      PRIVATE_SUBNET_V4="10.0.0.0/8" # Set a default IPv4 subnet
      ;;
    2)
      read -rp "Custom IPv4 Subnet:" PRIVATE_SUBNET_V4 # Prompt user for custom subnet
      if [ -z "${PRIVATE_SUBNET_V4}" ]; then           # If the user did not enter a subnet, set default
        PRIVATE_SUBNET_V4="10.0.0.0/8"
      fi
      ;;
    esac
  }

  # Call the function to set the custom IPv4 subnet
  set-ipv4-subnet

  # Define a function to set a custom IPv6 subnet
  function set-ipv6-subnet() {
    # Ask the user which IPv6 subnet they want to use
    echo "What IPv6 subnet do you want to use?"
    echo "  1) fd00:00:00::0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Use a loop to ensure the user inputs a valid option
    until [[ "${PRIVATE_SUBNET_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V6_SETTINGS
    done
    # Use a case statement to set the IPv6 subnet based on the user's choice
    case ${PRIVATE_SUBNET_V6_SETTINGS} in
    1)
      # Use the recommended IPv6 subnet if the user chooses option 1
      PRIVATE_SUBNET_V6="fd00:00:00::0/8"
      ;;
    2)
      # Ask the user for a custom IPv6 subnet if they choose option 2
      read -rp "Custom IPv6 Subnet:" PRIVATE_SUBNET_V6
      # If the user does not input a subnet, use the recommended one
      if [ -z "${PRIVATE_SUBNET_V6}" ]; then
        PRIVATE_SUBNET_V6="fd00:00:00::0/8"
      fi
      ;;
    esac
  }

  # Call the set-ipv6-subnet function to set the custom IPv6 subnet
  set-ipv6-subnet

  # Private Subnet Mask IPv4
  PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv4
  # IPv4 Gateway
  GATEWAY_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).1 # Get the gateway address of IPv4
  # Private Subnet Mask IPv6
  PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv6
  # IPv6 Gateway
  GATEWAY_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-3)::1 # Get the gateway address of IPv6
  # Get the networking data
  get-network-information # Call a function to get the networking data

  # Get the IPv4
  function test-connectivity-v4() {
    # Prompt user to select the IPv4 detection method
    echo "How would you like to detect IPv4?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until input is valid
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS
    done
    # Select the IPv4 detection method
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4} # Use the default IPv4 address
      ;;
    2)
      # Prompt user to specify a custom IPv4 address
      read -rp "Custom IPv4:" SERVER_HOST_V4
      # If input is empty, use default IPv4
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      fi
      ;;
    esac
  }

  # Call the function to get the IPv4
  test-connectivity-v4 # Call a function to get the IPv4 address

  # Determine IPv6
  function test-connectivity-v6() {
    # Ask the user how they would like to detect IPv6
    echo "How would you like to detect IPv6?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Ask the user to choose between the two options
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS
    done
    # If the user selected option 1
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      # Set the IPv6 to the default interface
      SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      ;;
    2)
      # Ask the user to input a custom IPv6
      read -rp "Custom IPv6:" SERVER_HOST_V6
      # If the user did not input a custom IPv6
      if [ -z "${SERVER_HOST_V6}" ]; then
        # Set the IPv6 to the default interface
        SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      fi
      ;;
    esac
  }

  # Get the IPv6
  test-connectivity-v6

  # Define a function to determine the public NIC.
  function server-pub-nic() {
    # Ask the user how to detect the NIC.
    echo "How would you like to detect NIC?"
    echo "  1) IP (Recommended)"
    echo "  2) Custom (Advanced)"
    # Wait until the user inputs 1 or 2.
    until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Nic Choice [1-2]:" -e -i 1 SERVER_PUB_NIC_SETTINGS
    done
    # Execute a case statement to check the user's choice.
    case ${SERVER_PUB_NIC_SETTINGS} in
    1)
      # Use the IP route to determine the NIC.
      SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      # If no NIC is found, exit with an error.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        echo "Error: Your server's public network interface could not be found."
        exit
      fi
      ;;
    2)
      # Ask the user to input a custom NAT.
      read -rp "Custom NAT:" SERVER_PUB_NIC
      # If the user input is empty, use the IP route to determine the NIC.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      fi
      ;;
    esac
  }

  # Execute the function to determine the public NIC.
  server-pub-nic

  # Define a function to set the WireGuard server port
  function set-port() {
    # Display message to ask for user input regarding the port to listen on
    echo "What port do you want WireGuard server to listen to?"
    # Display options for the user to select
    echo "  1) 51820 (Recommended)"
    echo "  2) Custom (Advanced)"

    # Loop until a valid port setting is selected (either 1 or 2)
    until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Prompt user for port choice and allow them to edit (-e) with the default value of 1 (-i 1)
      read -rp "Port Choice [1-2]:" -e -i 1 SERVER_PORT_SETTINGS
    done
    # Check which option was selected and set the SERVER_PORT variable accordingly
    case ${SERVER_PORT_SETTINGS} in
    1)
      SERVER_PORT="51820"
      # Check if the selected port is already in use by another application and exit if it is
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: Please use a different port because ${SERVER_PORT} is already in use."
        exit
      fi
      ;;
    2)
      # Loop until a valid custom port number between 1 and 65535 is entered
      until [[ "${SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]:" SERVER_PORT
      done
      # If no custom port is entered, set the SERVER_PORT variable to the default of 51820
      if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT="51820"
      fi
      # Check if the selected port is already in use by another application and exit if it is
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: The port ${SERVER_PORT} is already used by a different application, please use a different port."
        exit
      fi
      ;;
    esac
  }

  # Call the set-port function to set the WireGuard server port
  set-port

  # Determine Keepalive interval.
  function nat-keepalive() {                                         # Define a function called nat-keepalive
    echo "What do you want your keepalive interval to be?"           # Prompt user for keepalive interval
    echo "  1) 25 (Default)"                                         # Option 1: default interval of 25
    echo "  2) Custom (Advanced)"                                    # Option 2: custom interval
    until [[ "${NAT_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do              # Loop until a valid choice (1 or 2) is made
      read -rp "Keepalive Choice [1-2]:" -e -i 1 NAT_CHOICE_SETTINGS # Read user input
    done
    case ${NAT_CHOICE_SETTINGS} in # Evaluate user choice
    1)                             # If user chose option 1
      NAT_CHOICE="25"              # Set NAT_CHOICE to default interval (25)
      ;;
    2)                                                                                                          # If user chose option 2
      until [[ "${NAT_CHOICE}" =~ ^[0-9]+$ ]] && [ "${NAT_CHOICE}" -ge 1 ] && [ "${NAT_CHOICE}" -le 65535 ]; do # Loop until a valid custom interval is entered
        read -rp "Custom NAT [1-65535]:" NAT_CHOICE                                                             # Read user input for custom interval
      done
      if [ -z "${NAT_CHOICE}" ]; then # If NAT_CHOICE is empty
        NAT_CHOICE="25"               # Set NAT_CHOICE to default interval (25)
      fi
      ;;
    esac
  }
  # Keepalive interval
  nat-keepalive # Call the nat-keepalive function

  # Custom MTU or default settings
  function mtu-set() {                                         # Define a function called mtu-set
    echo "What MTU do you want to use?"                        # Prompt user for MTU setting
    echo "  1) 1420|1280 (Recommended)"                        # Option 1: recommended MTU settings
    echo "  2) Custom (Advanced)"                              # Option 2: custom MTU settings
    until [[ "${MTU_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do        # Loop until a valid choice (1 or 2) is made
      read -rp "MTU Choice [1-2]:" -e -i 1 MTU_CHOICE_SETTINGS # Read user input
    done
    case ${MTU_CHOICE_SETTINGS} in # Evaluate user choice
    1)                             # If user chose option 1
      INTERFACE_MTU_CHOICE="1420"  # Set INTERFACE_MTU_CHOICE to recommended value (1420)
      PEER_MTU_CHOICE="1280"       # Set PEER_MTU_CHOICE to recommended value (1280)
      ;;
    2)                                                                                                                                        # If user chose option 2
      until [[ "${INTERFACE_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${INTERFACE_MTU_CHOICE}" -ge 1 ] && [ "${INTERFACE_MTU_CHOICE}" -le 65535 ]; do # Loop until a valid custom interface MTU is entered
        read -rp "Custom Interface MTU [1-65535]:" INTERFACE_MTU_CHOICE                                                                       # Read user input for custom interface MTU
      done
      if [ -z "${INTERFACE_MTU_CHOICE}" ]; then # If INTERFACE_MTU_CHOICE is empty
        INTERFACE_MTU_CHOICE="1420"             # Set INTERFACE_MTU_CHOICE to recommended value (1420)
      fi
      until [[ "${PEER_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${PEER_MTU_CHOICE}" -ge 1 ] && [ "${PEER_MTU_CHOICE}" -le 65535 ]; do # Loop until a valid custom peer MTU is entered
        read -rp "Custom Peer MTU [1-65535]:" PEER_MTU_CHOICE                                                                  # Read user input for custom peer MTU
      done
      if [ -z "${PEER_MTU_CHOICE}" ]; then # If PEER_MTU_CHOICE is empty
        PEER_MTU_CHOICE="1280"             # Set PEER_MTU_CHOICE to recommended value (1280)
      fi
      ;;
    esac
  }

  # Set MTU
  mtu-set # Call the mtu-set function

  # What IP version would you like to be available on this WireGuard server?
  function ipvx-select() {                                                 # Define a function called ipvx-select
    echo "What IPv do you want to use to connect to the WireGuard server?" # Prompt user for IP version to use
    echo "  1) IPv4 (Recommended)"                                         # Option 1: recommended IPv4
    echo "  2) IPv6"                                                       # Option 2: IPv6
    until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-2]$ ]]; do                   # Loop until a valid choice (1 or 2) is made
      read -rp "IP Choice [1-2]:" -e -i 1 SERVER_HOST_SETTINGS             # Read user input
    done
    case ${SERVER_HOST_SETTINGS} in               # Evaluate user choice
    1)                                            # If user chose option 1
      if [ -n "${DEFAULT_INTERFACE_IPV4}" ]; then # If DEFAULT_INTERFACE_IPV4 is not empty
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}"   # Set SERVER_HOST to DEFAULT_INTERFACE_IPV4
      else
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]" # Set SERVER_HOST to DEFAULT_INTERFACE_IPV6 (surrounded by brackets to indicate IPv6 address)
      fi
      ;;
    2)                                            # If user chose option 2
      if [ -n "${DEFAULT_INTERFACE_IPV6}" ]; then # If DEFAULT_INTERFACE_IPV6 is not empty
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]" # Set SERVER_HOST to DEFAULT_INTERFACE_IPV6 (surrounded by brackets to indicate IPv6 address)
      else
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}" # Set SERVER_HOST to DEFAULT_INTERFACE_IPV4
      fi
      ;;
    esac
  }

  # IPv4 or IPv6 Selector
  ipvx-select # Call the ipvx-select function

  # Would you like to allow connections to your LAN neighbors?
  function client-allowed-ip() {                                                    # Define a function called client-allowed-ip
    echo "What traffic do you want the client to forward through WireGuard?"        # Prompt user for allowed traffic
    echo "  1) Everything (Recommended)"                                            # Option 1: allow all traffic
    echo "  2) Custom (Advanced)"                                                   # Option 2: allow custom traffic
    until [[ "${CLIENT_ALLOWED_IP_SETTINGS}" =~ ^[1-2]$ ]]; do                      # Loop until a valid choice (1 or 2) is made
      read -rp "Client Allowed IP Choice [1-2]:" -e -i 1 CLIENT_ALLOWED_IP_SETTINGS # Read user input
    done
    case ${CLIENT_ALLOWED_IP_SETTINGS} in # Evaluate user choice
    1)                                    # If user chose option 1
      CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"  # Set CLIENT_ALLOWED_IP to allow all traffic
      ;;
    2)                                         # If user chose option 2
      read -rp "Custom IPs:" CLIENT_ALLOWED_IP # Prompt user for custom allowed IPs
      if [ -z "${CLIENT_ALLOWED_IP}" ]; then   # If CLIENT_ALLOWED_IP is empty
        CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"     # Set CLIENT_ALLOWED_IP to allow all traffic
      fi
      ;;
    esac
  }

  # Traffic Forwarding
  client-allowed-ip # Call the client-allowed-ip function

  # real-time updates
  function enable-automatic-updates() {                                      # Define a function called enable-automatic-updates
    echo "Would you like to setup real-time updates?"                        # Prompt user for real-time updates setting
    echo "  1) Yes (Recommended)"                                            # Option 1: enable real-time updates
    echo "  2) No (Advanced)"                                                # Option 2: disable real-time updates
    until [[ "${AUTOMATIC_UPDATES_SETTINGS}" =~ ^[1-2]$ ]]; do               # Loop until a valid choice (1 or 2) is made
      read -rp "Automatic Updates [1-2]:" -e -i 1 AUTOMATIC_UPDATES_SETTINGS # Read user input
    done
    case ${AUTOMATIC_UPDATES_SETTINGS} in # Evaluate user choice
    1)                                    # If user chose option 1
      crontab -l | {                      # Append to existing crontab or create a new one if none exists
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --update" # Add cron job to run the script with --update option every day at midnight
      } | crontab -
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then # If using systemd init system
        systemctl enable --now ${SYSTEM_CRON_NAME}           # Enable and start the cron service
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then  # If using initd init system
        service ${SYSTEM_CRON_NAME} start                    # Start the cron service
      fi
      ;;
    2)                                  # If user chose option 2
      echo "Real-time Updates Disabled" # Display message indicating real-time updates are disabled
      ;;
    esac
  }

  # real-time updates
  enable-automatic-updates # Call the enable-automatic-updates function

  # Define a function to enable automatic backup
  function enable-automatic-backup() {
    # Ask the user if they want to setup real-time backup
    echo "Would you like to setup real-time backup?"
    # Show two options
    echo "  1) Yes (Recommended)"
    echo "  2) No (Advanced)"
    # Until the user inputs a valid option, keep asking
    until [[ "${AUTOMATIC_BACKUP_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Read user input and set it to AUTOMATIC_BACKUP_SETTINGS variable
      read -rp "Automatic Backup [1-2]:" -e -i 1 AUTOMATIC_BACKUP_SETTINGS
    done
    # Based on user input, execute the appropriate block of code
    case ${AUTOMATIC_BACKUP_SETTINGS} in
    # If user chooses option 1
    1)
      # Append a cron job to backup current file path everyday at midnight
      crontab -l | {
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --backup"
      } | crontab -
      # If current init system is systemd, enable and start the cron job
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      # Otherwise, if current init system is init, start the cron job
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2) # If user chooses option 2
      # Inform the user that real-time backup is disabled
      echo "Real-time Backup Disabled"
      ;;
    esac
  }

  # Call the function to enable automatic backup
  enable-automatic-backup

  # Define a function to ask the user which DNS provider to use.
  function ask-install-dns() {
    # Print out the available DNS provider options.
    echo "Which DNS provider would you like to use?"
    echo "  1) Unbound (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until the user inputs a valid option.
    until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Prompt the user for their choice and save it to DNS_PROVIDER_SETTINGS.
      read -rp "DNS provider [1-2]:" -e -i 1 DNS_PROVIDER_SETTINGS
    done
    # Depending on the user's choice, set some variables.
    case ${DNS_PROVIDER_SETTINGS} in
    1)
      # The user chose Unbound.
      INSTALL_UNBOUND=true
      # Ask the user if they want to install a content-blocker.
      echo "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker?"
      echo "  1) Yes (Recommended)"
      echo "  2) No"
      # Loop until the user inputs a valid option.
      until [[ "${CONTENT_BLOCKER_SETTINGS}" =~ ^[1-2]$ ]]; do
        # Prompt the user for their choice and save it to CONTENT_BLOCKER_SETTINGS.
        read -rp "Content Blocker Choice [1-2]:" -e -i 1 CONTENT_BLOCKER_SETTINGS
      done
      # Depending on the user's choice, set INSTALL_BLOCK_LIST to true or false.
      case ${CONTENT_BLOCKER_SETTINGS} in
      1)
        INSTALL_BLOCK_LIST=true
        ;;
      2)
        INSTALL_BLOCK_LIST=false
        ;;
      esac
      ;;
    2)
      # The user chose Custom.
      CUSTOM_DNS=true
      ;;
    esac
  }

  # Call the ask-install-dns function to start the DNS installation process.
  ask-install-dns

  # Define a function to let users choose their custom DNS provider.
  function custom-dns() {
    # Check if the custom DNS option is enabled.
    if [ "${CUSTOM_DNS}" == true ]; then
      # Display the available DNS options to the user.
      echo "Which DNS do you want to use with the WireGuard connection?"
      echo "  1) Cloudflare (Recommended)"
      echo "  2) AdGuard"
      echo "  3) NextDNS"
      echo "  4) OpenDNS"
      echo "  5) Google"
      echo "  6) Verisign"
      echo "  7) Quad9"
      echo "  8) FDN"
      echo "  9) Custom (Advanced)"
      if [ -x "$(command -v pihole)" ]; then
        echo "  10) Pi-Hole (Advanced)"
      fi
      # Prompt the user to enter their DNS choice.
      until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 10 ]; do
        read -rp "DNS [1-10]:" -e -i 1 CLIENT_DNS_SETTINGS
      done
      # Set the appropriate DNS based on the user's choice.
      case ${CLIENT_DNS_SETTINGS} in
      1)
        CLIENT_DNS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
        ;;
      2)
        CLIENT_DNS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
        ;;
      3)
        CLIENT_DNS="45.90.28.167,45.90.30.167,2a07:a8c0::12:cf53,2a07:a8c1::12:cf53"
        ;;
      4)
        CLIENT_DNS="208.67.222.222,208.67.220.220,2620:119:35::35,2620:119:53::53"
        ;;
      5)
        CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        ;;
      6)
        CLIENT_DNS="64.6.64.6,64.6.65.6,2620:74:1b::1:1,2620:74:1c::2:2"
        ;;
      7)
        CLIENT_DNS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
        ;;
      8)
        CLIENT_DNS="80.67.169.40,80.67.169.12,2001:910:800::40,2001:910:800::12"
        ;;
      9)
        # Prompt the user to enter a custom DNS.
        read -rp "Custom DNS:" CLIENT_DNS
        # If the user doesn't provide a custom DNS, use Google's DNS as the default.
        if [ -z "${CLIENT_DNS}" ]; then
          CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        fi
        ;;
      10)
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

  # Call the function to let users choose their custom DNS provider.
  custom-dns

  # Define a function to ask for the first WireGuard peer's name.
  function client-name() {
    # Check if the CLIENT_NAME variable is empty.
    if [ -z "${CLIENT_NAME}" ]; then
      # Prompt the user for a client name with rules for naming.
      echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
      # Read the user input and provide a random name as the default value.
      read -rp "Client name:" -e -i "$(openssl rand -hex 50)" CLIENT_NAME
    fi
    # If the user doesn't provide a name, generate a random name.
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 50)"
    fi
  }

  # Call the function to ask for the first WireGuard peer's name.
  client-name

  # Define a function to automatically remove WireGuard peers after a period of time.
  function auto-remove-config() {
    # Prompt the user to choose if they want to expire the peer after a certain period of time.
    echo "Would you like to expire the peer after a certain period of time?"
    echo "  1) Every Year (Recommended)"
    echo "  2) No"
    # Loop until the user enters a valid choice (1 or 2).
    until [[ "${AUTOMATIC_CONFIG_REMOVER}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic config expire [1-2]:" -e -i 1 AUTOMATIC_CONFIG_REMOVER
    done
    # Perform actions based on the user's choice.
    case ${AUTOMATIC_CONFIG_REMOVER} in
    1)
      # Set the variable to enable automatic WireGuard peer expiration.
      AUTOMATIC_WIREGUARD_EXPIRATION=true
      # Enable and start the cron service depending on the init system being used.
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      # Set the variable to disable automatic WireGuard peer expiration.
      AUTOMATIC_WIREGUARD_EXPIRATION=false
      ;;
    esac
  }

  # Call the function to configure automatic removal of WireGuard peers.
  auto-remove-config

  # Define a function to check the kernel version and install kernel headers if required.
  function install-kernel-headers() {
    # Set the allowed kernel version and extract its major and minor version numbers.
    ALLOWED_KERNEL_VERSION="5.6"
    ALLOWED_KERNEL_MAJOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=1)
    ALLOWED_KERNEL_MINOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=2)
    # Determine if the current kernel version is less than or equal to the allowed version.
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" -le "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
      INSTALL_LINUX_HEADERS=true
    fi
    # Determine if the current kernel version is the same as the allowed version.
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
      # Check if the current kernel minor version is less than the allowed minor version.
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=true
      fi
      # Check if the current kernel minor version is greater than or equal to the allowed minor version.
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -ge "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=false
      fi
    fi
    # Install kernel headers for the current kernel version based on the Linux distribution.
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

  # Call the function to check the kernel version and install kernel headers if required.
  install-kernel-headers

  # Define a function to install resolvconf or openresolv.
  function install-resolvconf-or-openresolv() {
    # Check if resolvconf is already installed.
    if [ ! -x "$(command -v resolvconf)" ]; then
      # Install resolvconf for various distributions.
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get install resolvconf -y
      # Install openresolv for various distributions.
      elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        # Enable the copr repository for CentOS 7.
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
          yum copr enable macieks/openresolv -y
        fi
        yum install openresolv -y
      # Install openresolv for Fedora and Oracle Linux distributions.
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
        yum install openresolv -y
      # Install resolvconf for Arch-based distributions.
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed resolvconf
      # Install resolvconf for Alpine Linux.
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk add resolvconf
      # Install resolvconf for FreeBSD.
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg install resolvconf
      fi
    fi
  }

  # Call the function to install resolvconf or openresolv.
  install-resolvconf-or-openresolv

  # Define a function to install the WireGuard server.
  function install-wireguard-server() {
    # Check if the WireGuard command (wg) is not already installed.
    if [ ! -x "$(command -v wg)" ]; then
      # Install WireGuard for Debian-based distributions.
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        if [ ! -f "/etc/apt/sources.list.d/backports.list" ]; then
          echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list.d/backports.list
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
          apt-get update
        fi
        apt-get install wireguard -y
      # Install WireGuard for Arch-based distributions.
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed wireguard-tools
      elif [ "${CURRENT_DISTRO}" = "fedora" ]; then
        dnf check-update
        dnf copr enable jdoss/wireguard -y
        dnf install wireguard-tools -y
      # Install WireGuard for other distributions (Fedora, CentOS, RHEL, etc.).
      elif [ "${CURRENT_DISTRO}" == "centos" ]; then
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "rhel" ]; then
        yum check-update
        yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-"${CURRENT_DISTRO_MAJOR_VERSION}".noarch.rpm https://www.elrepo.org/elrepo-release-"${CURRENT_DISTRO_MAJOR_VERSION}".el"${CURRENT_DISTRO_MAJOR_VERSION}".elrepo.noarch.rpm
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk add wireguard-tools
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg install wireguard
      elif { [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum check-update
        yum install kmod-wireguard wireguard-tools -y
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

  # Install WireGuard Server
  install-wireguard-server

  # Define a function to install Unbound, a DNS resolver.
  function install-unbound() {
    # Check if the INSTALL_UNBOUND variable is true and Unbound is not already installed.
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
        # Install Unbound for different Linux distributions.
        if { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          apt-get install unbound unbound-host unbound-anchor -y
          if [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
            if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
              systemctl disable --now systemd-resolved
            elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
              service systemd-resolved stop
            fi
          fi
        elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum install unbound unbound-host unbound-anchor -y
        elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
          dnf install unbound unbound-host unbound-anchor -y
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Su --noconfirm --needed unbound
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk add unbound unbound-host unbound-anchor
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg install unbound unbound-host unbound-anchor
        elif [ "${CURRENT_DISTRO}" == "ol" ]; then
          yum install unbound unbound-host unbound-anchor -y
        fi
      fi
      # Configure Unbound using anchor and root hints.
      unbound-anchor -a ${UNBOUND_ANCHOR}
      # Download root hints.
      curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" --create-dirs -o ${UNBOUND_ROOT_HINTS}
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
      # Configure block list if INSTALL_BLOCK_LIST is true.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
        if [ ! -d "${UNBOUND_CONFIG_DIRECTORY}" ]; then
          mkdir --parents "${UNBOUND_CONFIG_DIRECTORY}"
        fi
        curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
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
      # Save Unbound status to UNBOUND_MANAGER file.
      echo "Unbound: true" >${UNBOUND_MANAGER}
      # Set CLIENT_DNS to use gateway addresses.
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Call the function to install Unbound.
  install-unbound

  # Define a function to set WireGuard configuration
  function wireguard-setconf() {
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
      NFTABLES_POSTUP="sysctl --write net.ipv4.ip_forward=1; sysctl --write net.ipv6.conf.all.forwarding=1; nft add table inet wireguard-${WIREGUARD_PUB_NIC}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain {type nat hook postrouting priority srcnat\;}; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain oifname ${SERVER_PUB_NIC} masquerade"
      NFTABLES_POSTDOWN="sysctl --write net.ipv4.ip_forward=0; sysctl --write net.ipv6.conf.all.forwarding=0; nft delete table inet wireguard-${WIREGUARD_PUB_NIC}"
    else
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

    # Create client WireGuard configuration file
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
    # Change ownership of WireGuard configuration directory to root
    chown --recursive root:root ${WIREGUARD_PATH}
    # Set the correct permissions for the WireGuard configuration directory
    find ${WIREGUARD_PATH} -type d -exec chmod 755 {} +
    # Set the correct permissions for the WireGuard configuration file
    find ${WIREGUARD_PATH} -type f -exec chmod 644 {} +
    # Set up automatic WireGuard expiration (if enabled)
    if [ "${AUTOMATIC_WIREGUARD_EXPIRATION}" == true ]; then
      crontab -l | {
        cat
        echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
      } | crontab -
    fi
    # Start and enable the required services based on the init system (systemd or init)
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl enable --now nftables
      systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
      if [ "${INSTALL_UNBOUND}" == true ]; then
        systemctl enable --now unbound
        systemctl restart unbound
      fi
    elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
      service nftables start
      service wg-quick@${WIREGUARD_PUB_NIC} start
      if [ "${INSTALL_UNBOUND}" == true ]; then
        service unbound restart
      fi
    fi
    # Generate a QR code for the client configuration
    qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Print the client configuration to the console
    cat ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    # Print the client configuration file path
    echo "Client Config --> ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
  }

  # Setting Up WireGuard Config
  wireguard-setconf

# After WireGuard Install
else

  # Already installed what next?
  function wireguard-next-questions-interface() {
    echo "What do you want to do?"
    echo "   1) Show WireGuard"
    echo "   2) Start WireGuard"
    echo "   3) Stop WireGuard"
    echo "   4) Restart WireGuard"
    echo "   5) Add WireGuard Peer (client)"
    echo "   6) Remove WireGuard Peer (client)"
    echo "   7) Reinstall WireGuard"
    echo "   8) Uninstall WireGuard"
    echo "   9) Update this script"
    echo "   10) Backup WireGuard"
    echo "   11) Restore WireGuard"
    echo "   12) Update Interface IP"
    echo "   13) Update Interface Port"
    echo "   14) Purge WireGuard Peers"
    echo "   15) Generate QR Code"
    echo "   16) Check Configs"
    until [[ "${WIREGUARD_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${WIREGUARD_OPTIONS}" -ge 1 ] && [ "${WIREGUARD_OPTIONS}" -le 16 ]; do
      read -rp "Select an Option [1-16]:" -e -i 0 WIREGUARD_OPTIONS
    done
    case ${WIREGUARD_OPTIONS} in
    1) # WG Show
      wg show ${WIREGUARD_PUB_NIC}
      ;;
    2) # Start WireGuard
      wg-quick up ${WIREGUARD_PUB_NIC}
      ;;
    3) # Stop WireGuard
      wg-quick down ${WIREGUARD_PUB_NIC}
      ;;
    4) # Restart WireGuard
      # It checks whether the init system is "systemd" or "init"
      # It restarts the WireGuard service accordingly.
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    5) # WireGuard add Peer
      # Check if a new client name is provided; if not, prompt for a name
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
        read -rp "New client peer:" -e -i "$(openssl rand -hex 50)" NEW_CLIENT_NAME
      fi
      # If a new client name is still not provided, generate a random name using openssl
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        NEW_CLIENT_NAME="$(openssl rand -hex 50)"
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
Endpoint = ${SERVER_HOST}${SERVER_PORT}
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
      ;;
    6) # Remove WireGuard Peer
      # Prompt the user to choose a WireGuard peer to remove
      echo "Which WireGuard peer would you like to remove?"
      # List all the peers' names in the WireGuard configuration file
      grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2
      # Read the user input for the peer's name
      read -rp "Peer's name:" REMOVECLIENT
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
      ;;
    7) # Reinstall WireGuard
      # Check if the current init system is systemd, and if so, disable and stop the WireGuard service
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
      # Check if the current init system is init, and if so, stop the WireGuard service
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
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
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    8) # Uninstall WireGuard and purging files
      # Check if the current init system is systemd and disable the WireGuard service
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
        # If the init system is not systemd, check if it is init and stop the WireGuard service
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
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
        elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
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
            elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
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
      ;;
    9) # Update WireGuard Manager script.
      # Calculate the SHA3-512 hash of the current WireGuard Manager script
      CURRENT_WIREGUARD_MANAGER_HASH=$(openssl dgst -sha3-512 "${CURRENT_FILE_PATH}" | cut --delimiter=" " --fields=2)
      # Calculate the SHA3-512 hash of the latest WireGuard Manager script from the remote source
      NEW_WIREGUARD_MANAGER_HASH=$(curl --silent "${WIREGUARD_MANAGER_UPDATE}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
      # If the hashes don't match, update the local WireGuard Manager script
      if [ "${CURRENT_WIREGUARD_MANAGER_HASH}" != "${NEW_WIREGUARD_MANAGER_HASH}" ]; then
        curl "${WIREGUARD_MANAGER_UPDATE}" -o "${CURRENT_FILE_PATH}"
        chmod +x "${CURRENT_FILE_PATH}"
      fi
      # Update the unbound configs if the unbound command is available on the system
      if [ -x "$(command -v unbound)" ]; then
        # Update the unbound root hints file if it exists
        if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
          CURRENT_ROOT_HINTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_ROOT_HINTS}" | cut --delimiter=" " --fields=2)
          NEW_ROOT_HINTS_HASH=$(curl --silent "${UNBOUND_ROOT_SERVER_CONFIG_URL}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
          if [ "${CURRENT_ROOT_HINTS_HASH}" != "${NEW_ROOT_HINTS_HASH}" ]; then
            curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o ${UNBOUND_ROOT_HINTS}
          fi
        fi
        # Update the unbound config host file if it exists
        if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
          CURRENT_UNBOUND_HOSTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_CONFIG_HOST}" | cut --delimiter=" " --fields=2)
          NEW_UNBOUND_HOSTS_HASH=$(curl --silent "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
          if [ "${CURRENT_UNBOUND_HOSTS_HASH}" != "${NEW_UNBOUND_HOSTS_HASH}" ]; then
            curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
          fi
        fi
        # Once everything is completed, restart the unbound service
        if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
          systemctl restart unbound
        elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
          service unbound restart
        fi
      fi
      ;;
    10) # Backup WireGuard Config
      # If the WireGuard config backup file exists, remove it
      if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        rm --force ${WIREGUARD_CONFIG_BACKUP}
      fi
      # If the system backup path directory does not exist, create it along with any necessary parent directories
      if [ ! -d "${SYSTEM_BACKUP_PATH}" ]; then
        mkdir --parents ${SYSTEM_BACKUP_PATH}
      fi
      # If the WireGuard path directory exists, proceed with the backup process
      if [ -d "${WIREGUARD_PATH}" ]; then
        # Generate a random 50-character hexadecimal backup password and store it in a file
        BACKUP_PASSWORD="$(openssl rand -hex 50)"
        echo "${BACKUP_PASSWORD}" >"${WIREGUARD_BACKUP_PASSWORD_PATH}"
        # Zip the WireGuard config file using the generated backup password and save it as a backup
        zip -P "${BACKUP_PASSWORD}" -rj ${WIREGUARD_CONFIG_BACKUP} ${WIREGUARD_CONFIG}
      fi

      ;;
    11) # Restore WireGuard Config
      # Check if the WireGuard config backup file does not exist, and if so, exit the script
      if [ ! -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        echo "Error: WireGuard config backup file does not exist."
        exit
      fi
      # Prompt the user to enter the backup password and store it in the WIREGUARD_BACKUP_PASSWORD variable
      read -rp "Backup Password: " -e -i "$(cat "${WIREGUARD_BACKUP_PASSWORD_PATH}")" WIREGUARD_BACKUP_PASSWORD
      # If the WIREGUARD_BACKUP_PASSWORD variable is empty, exit the script
      if [ -z "${WIREGUARD_BACKUP_PASSWORD}" ]; then
        echo "Error: Backup password cannot be empty."
        exit
      fi
      # Unzip the backup file, overwriting existing files, using the specified backup password, and extract the contents to the WireGuard path
      unzip -o -P "${WIREGUARD_BACKUP_PASSWORD}" "${WIREGUARD_CONFIG_BACKUP}" -d "${WIREGUARD_PATH}"
      # If the current init system is systemd, enable and start the wg-quick service
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
      # If the current init system is init, restart the wg-quick service
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    12) # Change the IP address of your wireguard interface.
      get-network-information
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
    13) # Change the wireguard interface's port number.
      # Extract the old server port from the WireGuard config file
      OLD_SERVER_PORT=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter=":" --fields=2)
      # Prompt the user to enter a valid custom port (between 1 and 65535) and store it in NEW_SERVER_PORT
      until [[ "${NEW_SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${NEW_SERVER_PORT}" -ge 1 ] && [ "${NEW_SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]: " -e -i 51820 NEW_SERVER_PORT
      done
      # Check if the chosen port is already in use by another application
      if [ "$(lsof -i UDP:"${NEW_SERVER_PORT}")" ]; then
        # If the port is in use, print an error message and exit the script
        echo "Error: The port ${NEW_SERVER_PORT} is already used by a different application, please use a different port."
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
      ;;
    14) # Remove all the peers from the interface.
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
      ;;
    15) # Generate a QR code for a WireGuard peer.
      # Print a prompt asking the user to choose a WireGuard peer for generating a QR code
      echo "Which WireGuard peer would you like to generate a QR code for?"
      # Extract and display a list of peer names from the WireGuard config file
      grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2
      # Prompt the user to enter the desired peer's name and store it in the VIEW_CLIENT_INFO variable
      read -rp "Peer's name:" VIEW_CLIENT_INFO
      # Check if the config file for the specified peer exists
      if [ -f "${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf" ]; then
        # Generate a QR code for the specified peer's config file and display it in the terminal
        qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${VIEW_CLIENT_INFO}"-${WIREGUARD_PUB_NIC}.conf
        # Print the file path of the specified peer's config file
        echo "Peer's config --> ${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf"
      else
        # If the config file for the specified peer does not exist, print an error message
        echo "Error: The specified peer does not exist."
        exit
      fi
      ;;
    16)
      # Check if the `unbound` command is available on the system by checking if it is executable
      if [ -x "$(command -v unbound)" ]; then
        # Check if the output of `unbound-checkconf` run on `UNBOUND_CONFIG` contains "no errors"
        if [[ "$(unbound-checkconf ${UNBOUND_CONFIG})" != *"no errors"* ]]; then
          # If "no errors" was not found in output of previous command, print an error message
          echo "Error: We found an error on your unbound config file located at ${UNBOUND_CONFIG}"
          exit
        fi
        # Check if output of `unbound-host` run on `UNBOUND_CONFIG` with arguments `-C`, `-v`, and `cloudflare.com` contains "secure"
        if [[ "$(unbound-host -C ${UNBOUND_CONFIG} -v cloudflare.com)" != *"secure"* ]]; then
          # If "secure" was not found in output of previous command, print an error message
          echo "Error: We found an error on your unbound DNS-SEC config file loacted at ${UNBOUND_CONFIG}"
          exit
        fi
        echo "Your unbound config file located at ${UNBOUND_CONFIG} is valid."
      fi
      ;;
    esac
  }

  # Running Questions Command
  wireguard-next-questions-interface

fi
