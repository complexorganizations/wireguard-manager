#!/usr/bin/env bash
# https://github.com/complexorganizations/wireguard-manager

# Require script to be run as root
function super-user-check() {
  # This code checks to see if the script is running with root privileges.
  # If it is not, it will exit with an error message.
  if [ "${EUID}" -ne 0 ]; then
    echo "Error: You need to run this script as administrator."
    exit
  fi
}

# Check for root
super-user-check

# Get the current system information
function system-information() {
  # CURRENT_DISTRO is the ID of the current system
  # CURRENT_DISTRO_VERSION is the VERSION_ID of the current system
  # CURRENT_DISTRO_MAJOR_VERSION is the major version of the current system (e.g. "16" for Ubuntu 16.04)
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    CURRENT_DISTRO=${ID}
    CURRENT_DISTRO_VERSION=${VERSION_ID}
    CURRENT_DISTRO_MAJOR_VERSION=$(echo "${CURRENT_DISTRO_VERSION}" | cut --delimiter="." --fields=1)
  fi
}

# Get the current system information
system-information

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v cron)" ] || [ ! -x "$(command -v awk)" ] || [ ! -x "$(command -v ps)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v qrencode)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v nft)" ] || [ ! -x "$(command -v ifup)" ] || [ ! -x "$(command -v chattr)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v systemd-detect-virt)" ]; }; then
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

# check for requirements
installing-system-requirements

# Checking For Virtualization
function virt-check() {
  # This code checks if the system is running in a supported virtualization.
  # It returns the name of the virtualization if it is supported, or "none" if
  # it is not supported. This code is used to check if the system is running in
  # a virtual machine, and if so, if it is running in a supported virtualization.
  CURRENT_SYSTEM_VIRTUALIZATION=$(systemd-detect-virt)
  case ${CURRENT_SYSTEM_VIRTUALIZATION} in
  "kvm" | "none" | "qemu" | "lxc" | "microsoft" | "vmware" | "xen" | "amazon") ;;
  *)
    echo "${CURRENT_SYSTEM_VIRTUALIZATION} virtualization is not supported (yet)."
    exit
    ;;
  esac
}

# Virtualization Check
virt-check

# Lets check the kernel version
function kernel-check() {
  # Check that the kernel version is at least 3.1.0
  # This is necessary because the kernel version is used to
  # determine if the correct kernel modules are installed
  # and the correct device name for the network interface
  # is set.
  CURRENT_KERNEL_VERSION=$(uname --kernel-release | cut --delimiter="." --fields=1-2)
  CURRENT_KERNEL_MAJOR_VERSION=$(echo "${CURRENT_KERNEL_VERSION}" | cut --delimiter="." --fields=1)
  CURRENT_KERNEL_MINOR_VERSION=$(echo "${CURRENT_KERNEL_VERSION}" | cut --delimiter="." --fields=2)
  ALLOWED_KERNEL_VERSION="3.1"
  ALLOWED_KERNEL_MAJOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=1)
  ALLOWED_KERNEL_MINOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=2)
  if [ "${CURRENT_KERNEL_MAJOR_VERSION}" -lt "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
    echo "Error: Kernel ${CURRENT_KERNEL_VERSION} not supported, please update to ${ALLOWED_KERNEL_VERSION}."
    exit
  fi
  if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
    if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
      echo "Error: Kernel ${CURRENT_KERNEL_VERSION} not supported, please update to ${ALLOWED_KERNEL_VERSION}."
      exit
    fi
  fi
}

kernel-check

# Only allow certain init systems
function check-current-init-system() {
  # This code checks if the current init system is systemd or sysvinit
  # If it is neither, the script exits
  CURRENT_INIT_SYSTEM=$(ps --no-headers -o comm 1)
  case ${CURRENT_INIT_SYSTEM} in
  *"systemd"* | *"init"*) ;;
  *)
    echo "${CURRENT_INIT_SYSTEM} init is not supported (yet)."
    exit
    ;;
  esac
}

# Check if the current init system is supported
check-current-init-system

# Check if there are enough space to continue with the installation.
function check-disk-space() {
  # Checks to see if there is more than 1 GB of free space on the drive
  # where the user is installing to. If there is not, it will exit the
  # script.
  FREE_SPACE_ON_DRIVE_IN_MB=$(df -m / | tr --squeeze-repeats " " | tail -n1 | cut --delimiter=" " --fields=4)
  if [ "${FREE_SPACE_ON_DRIVE_IN_MB}" -le 1024 ]; then
    echo "Error: More than 1 GB of free space is needed to install everything."
    exit
  fi
}

# Check if there is enough disk space
check-disk-space

# Global variables
CURRENT_FILE_PATH=$(realpath "${0}")
WIREGUARD_WEBSITE_URL="https://www.wireguard.com"
WIREGUARD_PATH="/etc/wireguard"
WIREGUARD_CLIENT_PATH="${WIREGUARD_PATH}/clients"
WIREGUARD_PUB_NIC="wg0"
WIREGUARD_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}.conf"
WIREGUARD_ADD_PEER_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}-add-peer.conf"
SYSTEM_BACKUP_PATH="/var/backups"
WIREGUARD_CONFIG_BACKUP="${SYSTEM_BACKUP_PATH}/wireguard-manager.zip"
WIREGUARD_BACKUP_PASSWORD_PATH="${HOME}/.wireguard-manager"
RESOLV_CONFIG="/etc/resolv.conf"
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"
UNBOUND_ROOT="/etc/unbound"
UNBOUND_MANAGER="${UNBOUND_ROOT}/wireguard-manager"
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
if { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
  UNBOUND_ANCHOR="${UNBOUND_ROOT}/root.key"
fi
UNBOUND_CONFIG_DIRECTORY="${UNBOUND_ROOT}/unbound.conf.d"
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
if { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
  SYSTEM_CRON_NAME="crond"
elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
  SYSTEM_CRON_NAME="cronie"
else
  SYSTEM_CRON_NAME="cron"
fi

# Get the network information
function get-network-information() {
  # This function will return the IPv4 address of the default interface
  DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://api.ipengine.dev' | jq -r '.network.ip')"
  if [ -z "${DEFAULT_INTERFACE_IPV4}" ]; then
    DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
  fi
  DEFAULT_INTERFACE_IPV6="$(curl --ipv6 --connect-timeout 5 --tlsv1.3 --silent 'https://api.ipengine.dev' | jq -r '.network.ip')"
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

# The usage of the script
function usage() {
  while [ $# -ne 0 ]; do
    case ${1} in
    --install)
      shift
      HEADLESS_INSTALL=${HEADLESS_INSTALL=true}
      ;;
    --start)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=2}
      ;;
    --stop)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=3}
      ;;
    --restart)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=4}
      ;;
    --list)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=1}
      ;;
    --add)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=5}
      ;;
    --remove)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=6}
      ;;
    --reinstall)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=7}
      ;;
    --uninstall)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=8}
      ;;
    --update)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=9}
      ;;
    --backup)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=10}
      ;;
    --restore)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=11}
      ;;
    --ddns)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=12}
      ;;
    --purge)
      shift
      WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS=14}
      ;;
    --help)
      shift
      usage-guide
      ;;
    *)
      echo "Invalid argument: ${1}"
      usage-guide
      exit
      ;;
    esac
  done
}

usage "$@"

# All questions are skipped, and wireguard is installed and a configuration is generated.
function headless-install() {
  if [ "${HEADLESS_INSTALL}" == true ]; then
    PRIVATE_SUBNET_V4_SETTINGS=${PRIVATE_SUBNET_V4_SETTINGS=1}
    PRIVATE_SUBNET_V6_SETTINGS=${PRIVATE_SUBNET_V6_SETTINGS=1}
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS=1}
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS=1}
    SERVER_PUB_NIC_SETTINGS=${SERVER_PUB_NIC_SETTINGS=1}
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS=1}
    NAT_CHOICE_SETTINGS=${NAT_CHOICE_SETTINGS=1}
    MTU_CHOICE_SETTINGS=${MTU_CHOICE_SETTINGS=1}
    SERVER_HOST_SETTINGS=${SERVER_HOST_SETTINGS=1}
    CLIENT_ALLOWED_IP_SETTINGS=${CLIENT_ALLOWED_IP_SETTINGS=1}
    AUTOMATIC_UPDATES_SETTINGS=${AUTOMATIC_UPDATES_SETTINGS=1}
    AUTOMATIC_BACKUP_SETTINGS=${AUTOMATIC_BACKUP_SETTINGS=1}
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS=1}
    CONTENT_BLOCKER_SETTINGS=${CONTENT_BLOCKER_SETTINGS=1}
    CLIENT_NAME=${CLIENT_NAME=$(openssl rand -hex 50)}
    AUTOMATIC_CONFIG_REMOVER=${AUTOMATIC_CONFIG_REMOVER=1}
  fi
}

# No GUI
headless-install

# Set up the wireguard, if config it isn't already there.
if [ ! -f "${WIREGUARD_CONFIG}" ]; then

  # Custom IPv4 subnet
  function set-ipv4-subnet() {
    echo "What IPv4 subnet do you want to use?"
    echo "  1) 10.0.0.0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${PRIVATE_SUBNET_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V4_SETTINGS
    done
    case ${PRIVATE_SUBNET_V4_SETTINGS} in
    1)
      PRIVATE_SUBNET_V4="10.0.0.0/8"
      ;;
    2)
      read -rp "Custom IPv4 Subnet:" PRIVATE_SUBNET_V4
      if [ -z "${PRIVATE_SUBNET_V4}" ]; then
        PRIVATE_SUBNET_V4="10.0.0.0/8"
      fi
      ;;
    esac
  }

  # Custom IPv4 Subnet
  set-ipv4-subnet

  # Custom IPv6 subnet
  function set-ipv6-subnet() {
    echo "What IPv6 subnet do you want to use?"
    echo "  1) fd00:00:00::0/8 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${PRIVATE_SUBNET_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V6_SETTINGS
    done
    case ${PRIVATE_SUBNET_V6_SETTINGS} in
    1)
      PRIVATE_SUBNET_V6="fd00:00:00::0/8"
      ;;
    2)
      read -rp "Custom IPv6 Subnet:" PRIVATE_SUBNET_V6
      if [ -z "${PRIVATE_SUBNET_V6}" ]; then
        PRIVATE_SUBNET_V6="fd00:00:00::0/8"
      fi
      ;;
    esac
  }

  # Custom IPv6 Subnet
  set-ipv6-subnet

  # Private Subnet Mask IPv4
  PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2)
  # IPv4 Getaway
  GATEWAY_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).1
  # Private Subnet Mask IPv6
  PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2)
  # IPv6 Getaway
  GATEWAY_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-3)::1
  # Get the networking data
  get-network-information

  # Get the IPv4
  function test-connectivity-v4() {
    echo "How would you like to detect IPv4?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS
    done
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      ;;
    2)
      read -rp "Custom IPv4:" SERVER_HOST_V4
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      fi
      ;;
    esac
  }

  # Get the IPv4
  test-connectivity-v4

  # Determine IPv6
  function test-connectivity-v6() {
    echo "How would you like to detect IPv6?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS
    done
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      ;;
    2)
      read -rp "Custom IPv6:" SERVER_HOST_V6
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      fi
      ;;
    esac
  }

  # Get the IPv6
  test-connectivity-v6

  # Determine public NIC
  function server-pub-nic() {
    echo "How would you like to detect NIC?"
    echo "  1) IP (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Nic Choice [1-2]:" -e -i 1 SERVER_PUB_NIC_SETTINGS
    done
    case ${SERVER_PUB_NIC_SETTINGS} in
    1)
      SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      if [ -z "${SERVER_PUB_NIC}" ]; then
        echo "Error: Your server's public network interface could not be found."
        exit
      fi
      ;;
    2)
      read -rp "Custom NAT:" SERVER_PUB_NIC
      if [ -z "${SERVER_PUB_NIC}" ]; then
        SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      fi
      ;;
    esac
  }

  # Determine public NIC
  server-pub-nic

  # Determine host port
  function set-port() {
    echo "What port do you want WireGuard server to listen to?"
    echo "  1) 51820 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Port Choice [1-2]:" -e -i 1 SERVER_PORT_SETTINGS
    done
    case ${SERVER_PORT_SETTINGS} in
    1)
      SERVER_PORT="51820"
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: Please use a different port because ${SERVER_PORT} is already in use."
        exit
      fi
      ;;
    2)
      until [[ "${SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]:" SERVER_PORT
      done
      if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT="51820"
      fi
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        echo "Error: The port ${SERVER_PORT} is already used by a different application, please use a different port."
        exit
      fi
      ;;
    esac
  }

  # Set port
  set-port

  # Determine Keepalive interval.
  function nat-keepalive() {
    echo "What do you want your keepalive interval to be?"
    echo "  1) 25 (Default)"
    echo "  2) Custom (Advanced)"
    until [[ "${NAT_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Keepalive Choice [1-2]:" -e -i 1 NAT_CHOICE_SETTINGS
    done
    case ${NAT_CHOICE_SETTINGS} in
    1)
      NAT_CHOICE="25"
      ;;
    2)
      until [[ "${NAT_CHOICE}" =~ ^[0-9]+$ ]] && [ "${NAT_CHOICE}" -ge 1 ] && [ "${NAT_CHOICE}" -le 65535 ]; do
        read -rp "Custom NAT [1-65535]:" NAT_CHOICE
      done
      if [ -z "${NAT_CHOICE}" ]; then
        NAT_CHOICE="25"
      fi
      ;;
    esac
  }

  # Keepalive interval
  nat-keepalive

  # Custom MTU or default settings
  function mtu-set() {
    echo "What MTU do you want to use?"
    echo "  1) 1420|1280 (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${MTU_CHOICE_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "MTU Choice [1-2]:" -e -i 1 MTU_CHOICE_SETTINGS
    done
    case ${MTU_CHOICE_SETTINGS} in
    1)
      INTERFACE_MTU_CHOICE="1420"
      PEER_MTU_CHOICE="1280"
      ;;
    2)
      until [[ "${INTERFACE_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${INTERFACE_MTU_CHOICE}" -ge 1 ] && [ "${INTERFACE_MTU_CHOICE}" -le 65535 ]; do
        read -rp "Custom Interface MTU [1-65535]:" INTERFACE_MTU_CHOICE
      done
      if [ -z "${INTERFACE_MTU_CHOICE}" ]; then
        INTERFACE_MTU_CHOICE="1420"
      fi
      until [[ "${PEER_MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${PEER_MTU_CHOICE}" -ge 1 ] && [ "${PEER_MTU_CHOICE}" -le 65535 ]; do
        read -rp "Custom Peer MTU [1-65535]:" PEER_MTU_CHOICE
      done
      if [ -z "${PEER_MTU_CHOICE}" ]; then
        PEER_MTU_CHOICE="1280"
      fi
      ;;
    esac
  }

  # Set MTU
  mtu-set

  # What IP version would you like to be available on this WireGuard server?
  function ipvx-select() {
    echo "What IPv do you want to use to connect to the WireGuard server?"
    echo "  1) IPv4 (Recommended)"
    echo "  2) IPv6"
    until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IP Choice [1-2]:" -e -i 1 SERVER_HOST_SETTINGS
    done
    case ${SERVER_HOST_SETTINGS} in
    1)
      if [ -n "${DEFAULT_INTERFACE_IPV4}" ]; then
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}"
      else
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]"
      fi
      ;;
    2)
      if [ -n "${DEFAULT_INTERFACE_IPV6}" ]; then
        SERVER_HOST="[${DEFAULT_INTERFACE_IPV6}]"
      else
        SERVER_HOST="${DEFAULT_INTERFACE_IPV4}"
      fi
      ;;
    esac
  }

  # IPv4 or IPv6 Selector
  ipvx-select

  # Would you like to allow connections to your LAN neighbors?
  function client-allowed-ip() {
    echo "What traffic do you want the client to forward through WireGuard?"
    echo "  1) Everything (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${CLIENT_ALLOWED_IP_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Client Allowed IP Choice [1-2]:" -e -i 1 CLIENT_ALLOWED_IP_SETTINGS
    done
    case ${CLIENT_ALLOWED_IP_SETTINGS} in
    1)
      CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      ;;
    2)
      read -rp "Custom IPs:" CLIENT_ALLOWED_IP
      if [ -z "${CLIENT_ALLOWED_IP}" ]; then
        CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
      fi
      ;;
    esac
  }

  # Traffic Forwarding
  client-allowed-ip

  # real-time updates
  function enable-automatic-updates() {
    echo "Would you like to setup real-time updates?"
    echo "  1) Yes (Recommended)"
    echo "  2) No (Advanced)"
    until [[ "${AUTOMATIC_UPDATES_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic Updates [1-2]:" -e -i 1 AUTOMATIC_UPDATES_SETTINGS
    done
    case ${AUTOMATIC_UPDATES_SETTINGS} in
    1)
      crontab -l | {
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --update"
      } | crontab -
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      echo "Real-time Updates Disabled"
      ;;
    esac
  }

  # real-time updates
  enable-automatic-updates

  # real-time backup
  function enable-automatic-backup() {
    echo "Would you like to setup real-time backup?"
    echo "  1) Yes (Recommended)"
    echo "  2) No (Advanced)"
    until [[ "${AUTOMATIC_BACKUP_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic Backup [1-2]:" -e -i 1 AUTOMATIC_BACKUP_SETTINGS
    done
    case ${AUTOMATIC_BACKUP_SETTINGS} in
    1)
      crontab -l | {
        cat
        echo "0 0 * * * ${CURRENT_FILE_PATH} --backup"
      } | crontab -
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      echo "Real-time Backup Disabled"
      ;;
    esac
  }

  # real-time backup
  enable-automatic-backup

  # Would you like to install unbound.
  function ask-install-dns() {
    echo "Which DNS provider would you like to use?"
    echo "  1) Unbound (Recommended)"
    echo "  2) Custom (Advanced)"
    until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "DNS provider [1-2]:" -e -i 1 DNS_PROVIDER_SETTINGS
    done
    case ${DNS_PROVIDER_SETTINGS} in
    1)
      INSTALL_UNBOUND=true
      echo "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker?"
      echo "  1) Yes (Recommended)"
      echo "  2) No"
      until [[ "${CONTENT_BLOCKER_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "Content Blocker Choice [1-2]:" -e -i 1 CONTENT_BLOCKER_SETTINGS
      done
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
      CUSTOM_DNS=true
      ;;
    esac
  }

  # Ask To Install DNS
  ask-install-dns

  # Let the users choose their custom dns provider.
  function custom-dns() {
    if [ "${CUSTOM_DNS}" == true ]; then
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
      until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 10 ]; do
        read -rp "DNS [1-10]:" -e -i 1 CLIENT_DNS_SETTINGS
      done
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
        read -rp "Custom DNS:" CLIENT_DNS
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

  # use custom dns
  custom-dns

  # What would you like to name your first WireGuard peer?
  function client-name() {
    # If the CLIENT_NAME variable is empty, then prompt the user for a name.
    # If the user doesn't enter a name, then generate a random name for them.
    # If the user enters a name, then use that name.
    if [ -z "${CLIENT_NAME}" ]; then
      echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
      read -rp "Client name:" -e -i "$(openssl rand -hex 50)" CLIENT_NAME
    fi
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 50)"
    fi
  }

  # Client Name
  client-name

  # Automatically remove wireguard peers after a period of time.
  function auto-remove-confg() {
    # Ask the user if they would like to expire the peer after a certain period of time.
    # If the user chooses to expire the peer after a certain period of time, it will enable the cron service.
    # If the user chooses not to expire the peer after a certain period of time, it will not enable the cron service. 
    echo "Would you like to expire the peer after a certain period of time?"
    echo "  1) Every Year (Recommended)"
    echo "  2) No"
    until [[ "${AUTOMATIC_CONFIG_REMOVER}" =~ ^[1-2]$ ]]; do
      read -rp "Automatic config expire [1-2]:" -e -i 1 AUTOMATIC_CONFIG_REMOVER
    done
    case ${AUTOMATIC_CONFIG_REMOVER} in
    1)
      AUTOMATIC_WIREGUARD_EXPIRATION=true
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now ${SYSTEM_CRON_NAME}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service ${SYSTEM_CRON_NAME} start
      fi
      ;;
    2)
      AUTOMATIC_WIREGUARD_EXPIRATION=false
      ;;
    esac
  }

  # Automatic Remove Config
  auto-remove-confg

  # Lets check the kernel version and check if headers are required
  function install-kernel-headers() {
    # Checks the current kernel version.
    # Checks if the current kernel version is older than the allowed kernel version.
    # Checks the current Linux distribution.
    # Installs the kernel headers for the current kernel version.
    ALLOWED_KERNEL_VERSION="5.6"
    ALLOWED_KERNEL_MAJOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=1)
    ALLOWED_KERNEL_MINOR_VERSION=$(echo ${ALLOWED_KERNEL_VERSION} | cut --delimiter="." --fields=2)
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" -le "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
      INSTALL_LINUX_HEADERS=true
    fi
    if [ "${CURRENT_KERNEL_MAJOR_VERSION}" == "${ALLOWED_KERNEL_MAJOR_VERSION}" ]; then
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -lt "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=true
      fi
      if [ "${CURRENT_KERNEL_MINOR_VERSION}" -ge "${ALLOWED_KERNEL_MINOR_VERSION}" ]; then
        INSTALL_LINUX_HEADERS=false
      fi
    fi
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

  # Kernel Version
  install-kernel-headers

  # Install resolvconf OR openresolv
  function install-resolvconf-or-openresolv() {
    # It checks if resolvconf is already installed.
    # If resolvconf is not installed, it will check what distribution you are running, and install the appropriate package.
    # If your distribution is not listed, it will not install resolvconf.
    # If you want to have resolvconf installed, you will have to install it manually.
    if [ ! -x "$(command -v resolvconf)" ]; then
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get install resolvconf -y
      elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
          yum copr enable macieks/openresolv -y
        fi
        yum install openresolv -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
        yum install openresolv -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed resolvconf
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk add resolvconf
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg install resolvconf
      fi
    fi
  }

  # Install resolvconf OR openresolv
  install-resolvconf-or-openresolv

  # Install WireGuard Server
  function install-wireguard-server() {
    if [ ! -x "$(command -v wg)" ]; then
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        if [ ! -f "/etc/apt/sources.list.d/backports.list" ]; then
          echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list.d/backports.list
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
          apt-get update
        fi
        apt-get install wireguard -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Su --noconfirm --needed wireguard-tools
      elif [ "${CURRENT_DISTRO}" = "fedora" ]; then
        dnf check-update
        dnf copr enable jdoss/wireguard -y
        dnf install wireguard-tools -y
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

  # Function to install Unbound
  function install-unbound() {
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
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
      unbound-anchor -a ${UNBOUND_ANCHOR}
      curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" --create-dirs -o ${UNBOUND_ROOT_HINTS}
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
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
        if [ ! -d "${UNBOUND_CONFIG_DIRECTORY}" ]; then
          mkdir --parents "${UNBOUND_CONFIG_DIRECTORY}"
        fi
        curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
      fi
      chown --recursive "${USER}":"${USER}" ${UNBOUND_ROOT}
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
      echo "Unbound: true" >${UNBOUND_MANAGER}
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Running Install Unbound
  install-unbound

  # WireGuard Set Config
  function wireguard-setconf() {
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(echo "${SERVER_PRIVKEY}" | wg pubkey)
    CLIENT_PRIVKEY=$(wg genkey)
    CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
    CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).2
    CLIENT_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-4):2
    PRESHARED_KEY=$(wg genpsk)
    PEER_PORT=$(shuf --input-range=1024-65535 --head-count=1)
    mkdir --parents ${WIREGUARD_CLIENT_PATH}
    if [ "${INSTALL_UNBOUND}" == true ]; then
      NFTABLES_POSTUP="sysctl --write net.ipv4.ip_forward=1; sysctl --write net.ipv6.conf.all.forwarding=1; nft add table inet wireguard-${WIREGUARD_PUB_NIC}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain {type nat hook postrouting priority srcnat\;}; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} wireguard_chain oifname ${SERVER_PUB_NIC} masquerade"
      NFTABLES_POSTDOWN="sysctl --write net.ipv4.ip_forward=0; sysctl --write net.ipv6.conf.all.forwarding=0; nft delete table inet wireguard-${WIREGUARD_PUB_NIC}"
    else
      NFTABLES_POSTUP="sysctl --write net.ipv4.ip_forward=1; sysctl --write net.ipv6.conf.all.forwarding=1; nft add table inet wireguard-${WIREGUARD_PUB_NIC}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} PREROUTING {type nat hook prerouting priority 0\;}; nft add chain inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING {type nat hook postrouting priority 100\;}; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING ip saddr ${PRIVATE_SUBNET_V4} oifname ${SERVER_PUB_NIC} masquerade; nft add rule inet wireguard-${WIREGUARD_PUB_NIC} POSTROUTING ip6 saddr ${PRIVATE_SUBNET_V6} oifname ${SERVER_PUB_NIC} masquerade"
      NFTABLES_POSTDOWN="sysctl --write net.ipv4.ip_forward=0; sysctl --write net.ipv6.conf.all.forwarding=0; nft delete table inet wireguard-${WIREGUARD_PUB_NIC}"
    fi
    # Set WireGuard settings for this host and first peer.
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
    chown --recursive root:root ${WIREGUARD_PATH}
    if [ "${AUTOMATIC_WIREGUARD_EXPIRATION}" == true ]; then
      crontab -l | {
        cat
        echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
      } | crontab -
    fi
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
    qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
    cat ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
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
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
        read -rp "New client peer:" -e -i "$(openssl rand -hex 50)" NEW_CLIENT_NAME
      fi
      if [ -z "${NEW_CLIENT_NAME}" ]; then
        NEW_CLIENT_NAME="$(openssl rand -hex 50)"
      fi
      LASTIPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | tail --lines=1)
      LASTIPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | tail --lines=1)
      if { [ -z "${LASTIPV4}" ] && [ -z "${LASTIPV6}" ]; }; then
        LASTIPV4=1
        LASTIPV6=1
      fi
      SMALLEST_USED_IPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort | head --lines=1)
      LARGEST_USED_IPV4=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort | tail --lines=1)
      USED_IPV4_LIST=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4 | sort --numeric-sort)
      while [ "${SMALLEST_USED_IPV4}" -le "${LARGEST_USED_IPV4}" ]; do
        if [[ ! ${USED_IPV4_LIST[*]} =~ ${SMALLEST_USED_IPV4} ]]; then
          FIND_UNUSED_IPV4=${SMALLEST_USED_IPV4}
          break
        fi
        SMALLEST_USED_IPV4=$((SMALLEST_USED_IPV4 + 1))
      done
      SMALLEST_USED_IPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort | head --lines=1)
      LARGEST_USED_IPV6=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort | tail --lines=1)
      USED_IPV6_LIST=$(grep "AllowedIPs" ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="," --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5 | sort --numeric-sort)
      while [ "${SMALLEST_USED_IPV6}" -le "${LARGEST_USED_IPV6}" ]; do
        if [[ ! ${USED_IPV6_LIST[*]} =~ ${SMALLEST_USED_IPV6} ]]; then
          FIND_UNUSED_IPV6=${SMALLEST_USED_IPV6}
          break
        fi
        SMALLEST_USED_IPV6=$((SMALLEST_USED_IPV6 + 1))
      done
      if { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
        LASTIPV4=$(echo "${FIND_UNUSED_IPV4}" | head --lines=1)
        LASTIPV6=$(echo "${FIND_UNUSED_IPV6}" | head --lines=1)
      fi
      if { [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
        CURRENT_IPV4_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
        CURRENT_IPV6_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3)
        IPV4_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=4)
        IPV6_BEFORE_BACKSLASH=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=5)
        IPV4_AFTER_FIRST=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=2)
        IPV6_AFTER_FIRST=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=2)
        SECOND_IPV4_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=2)
        SECOND_IPV6_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=2)
        THIRD_IPV4_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=3)
        THIRD_IPV6_IN_RANGE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=3)
        NEXT_IPV4_RANGE=$((THIRD_IPV4_IN_RANGE + 1))
        NEXT_IPV6_RANGE=$((THIRD_IPV6_IN_RANGE + 1))
        CURRENT_IPV4_RANGE_CIDR=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2 | cut --delimiter="/" --fields=2)
        CURRENT_IPV6_RANGE_CIDR=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3 | cut --delimiter="/" --fields=2)
        FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=1,2)".${NEXT_IPV4_RANGE}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
        FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=1,2)":${NEXT_IPV6_RANGE}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
        if { [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ]; }; then
          if { [ "${SECOND_IPV4_IN_RANGE}" -ge 255 ] && [ "${SECOND_IPV6_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV4_IN_RANGE}" -ge 255 ] && [ "${THIRD_IPV6_IN_RANGE}" -ge 255 ] && [ "${LASTIPV4}" -ge 255 ] && [ "${LASTIPV6}" -ge 255 ]; }; then
            echo "Error: You are unable to add any more peers."
            exit
          fi
          NEXT_IPV4_RANGE=$((SECOND_IPV4_IN_RANGE + 1))
          NEXT_IPV6_RANGE=$((SECOND_IPV6_IN_RANGE + 1))
          FINAL_IPV4_RANGE=$(echo "${CURRENT_IPV4_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter="." --fields=1)".${NEXT_IPV4_RANGE}.${IPV4_AFTER_FIRST}.${IPV4_BEFORE_BACKSLASH}/${CURRENT_IPV4_RANGE_CIDR}"
          FINAL_IPV6_RANGE=$(echo "${CURRENT_IPV6_RANGE}" | cut --delimiter="/" --fields=1 | cut --delimiter=":" --fields=1)":${NEXT_IPV6_RANGE}:${IPV6_AFTER_FIRST}::${IPV6_BEFORE_BACKSLASH}/${CURRENT_IPV6_RANGE_CIDR}"
        fi
        sed --in-place "1s|${CURRENT_IPV4_RANGE}|${FINAL_IPV4_RANGE}|" ${WIREGUARD_CONFIG}
        sed --in-place "1s|${CURRENT_IPV6_RANGE}|${FINAL_IPV6_RANGE}|" ${WIREGUARD_CONFIG}
        LASTIPV4=1
        LASTIPV6=1
      fi
      CLIENT_PRIVKEY=$(wg genkey)
      CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
      PRESHARED_KEY=$(wg genpsk)
      PEER_PORT=$(shuf --input-range=1024-65535 --head-count=1)
      PRIVATE_SUBNET_V4=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2)
      PRIVATE_SUBNET_V6=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=3)
      PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2)
      SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4)
      SERVER_PUBKEY=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=5)
      CLIENT_DNS=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=6)
      MTU_CHOICE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=7)
      NAT_CHOICE=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=8)
      CLIENT_ALLOWED_IP=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=9)
      CLIENT_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).$((LASTIPV4 + 1))
      CLIENT_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-4):$((LASTIPV6 + 1))
      # Check for any unused IP address.
      if { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
        CLIENT_ADDRESS_V4=$(echo "${CLIENT_ADDRESS_V4}" | cut --delimiter="." --fields=1-3).${LASTIPV4}
        CLIENT_ADDRESS_V6=$(echo "${CLIENT_ADDRESS_V6}" | cut --delimiter=":" --fields=1-4):${LASTIPV6}
      fi
      WIREGUARD_TEMP_NEW_CLIENT_INFO="# ${NEW_CLIENT_NAME} start
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${NEW_CLIENT_NAME} end"
      echo "${WIREGUARD_TEMP_NEW_CLIENT_INFO}" >${WIREGUARD_ADD_PEER_CONFIG}
      wg addconf ${WIREGUARD_PUB_NIC} ${WIREGUARD_ADD_PEER_CONFIG}
      if { [ -z "${FIND_UNUSED_IPV4}" ] && [ -z "${FIND_UNUSED_IPV6}" ]; }; then
        echo "${WIREGUARD_TEMP_NEW_CLIENT_INFO}" >>${WIREGUARD_CONFIG}
      elif { [ -n "${FIND_UNUSED_IPV4}" ] && [ -n "${FIND_UNUSED_IPV6}" ]; }; then
        sed --in-place "s|$|\\\n|" "${WIREGUARD_ADD_PEER_CONFIG}"
        sed --in-place "6s|\\\n||" "${WIREGUARD_ADD_PEER_CONFIG}"
        WIREGUARD_TEMPORARY_PEER_DATA=$(tr --delete "\n" <"${WIREGUARD_ADD_PEER_CONFIG}")
        TEMP_WRITE_LINE=$((LASTIPV4 - 2))
        sed --in-place $((TEMP_WRITE_LINE * 6 + 11))i"${WIREGUARD_TEMPORARY_PEER_DATA}" ${WIREGUARD_CONFIG}
      fi
      rm --force ${WIREGUARD_ADD_PEER_CONFIG}
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
      wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      # If automaic wireguard expiration is enabled than set the expiration date.
      if crontab -l | grep -q "${CURRENT_FILE_PATH} --remove"; then
        crontab -l | {
          cat
          echo "$(date +%M) $(date +%H) $(date +%d) $(date +%m) * echo -e \"${NEW_CLIENT_NAME}\" | ${CURRENT_FILE_PATH} --remove"
        } | crontab -
      fi
      qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      cat ${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      echo "Client config --> ${WIREGUARD_CLIENT_PATH}/${NEW_CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
      ;;
    6) # Remove WireGuard Peer
      # It lists all the WireGuard clients that you can remove
      # It asks you to select a WireGuard client that you would like to remove
      # It removes the client from WireGuard
      # It removes the client's config file from your server
      echo "Which WireGuard peer would you like to remove?"
      grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2
      read -rp "Peer's name:" REMOVECLIENT
      CLIENTKEY=$(sed -n "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | cut --delimiter=" " --fields=3)
      wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
      sed --in-place "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/d" ${WIREGUARD_CONFIG}
      if [ -f "${WIREGUARD_CLIENT_PATH}/${REMOVECLIENT}-${WIREGUARD_PUB_NIC}.conf" ]; then
        rm --force ${WIREGUARD_CLIENT_PATH}/"${REMOVECLIENT}"-${WIREGUARD_PUB_NIC}.conf
      fi
      wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
      crontab -l | grep --invert-match "${REMOVECLIENT}" | crontab -
      ;;
    7) # Reinstall WireGuard
      # Grabs the current init system
      # Grabs the current distribution
      # Disables, stops, and removes the WireGuard interface
      # Checks the distribution and reinstalls the WireGuard tools
      # Re-enables and restarts the WireGuard interface
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} stop
      fi
      wg-quick down ${WIREGUARD_PUB_NIC}
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
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    8) # Uninstall WireGuard and purging files
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl disable --now wg-quick@${WIREGUARD_PUB_NIC}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} stop
      fi
      wg-quick down ${WIREGUARD_PUB_NIC}
      # Removing Wireguard Files
      if [ -d "${WIREGUARD_PATH}" ]; then
        rm --recursive --force ${WIREGUARD_PATH}
      fi
      if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
        yum remove wireguard qrencode -y
      elif { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get remove --purge wireguard qrencode -y
        if [ -f "/etc/apt/sources.list.d/backports.list" ]; then
          rm --force /etc/apt/sources.list.d/backports.list
          apt-key del 648ACFD622F3D138
          apt-key del 0E98404D386FA1D9
        fi
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Rs --noconfirm wireguard-tools qrencode
      elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
        dnf remove wireguard qrencode -y
        if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
          rm --force /etc/yum.repos.d/wireguard.repo
        fi
      elif [ "${CURRENT_DISTRO}" == "rhel" ]; then
        yum remove wireguard qrencode -y
        if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
          rm --force /etc/yum.repos.d/wireguard.repo
        fi
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk del wireguard-tools libqrencode
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg delete wireguard libqrencode
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
      if [ -x "$(command -v unbound)" ]; then
        if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
          systemctl disable --now unbound
        elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
          service unbound stop
        fi
        if [ -f "${RESOLV_CONFIG_OLD}" ]; then
          chattr -i ${RESOLV_CONFIG}
          rm --force ${RESOLV_CONFIG}
          mv ${RESOLV_CONFIG_OLD} ${RESOLV_CONFIG}
          chattr +i ${RESOLV_CONFIG}
        fi
        if { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum remove unbound -y
        elif { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          if [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
            if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
              systemctl enable --now systemd-resolved
            elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
              service systemd-resolved restart
            fi
          fi
          apt-get remove --purge unbound -y
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Rs --noconfirm unbound
        elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
          yum remove unbound -y
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk del unbound
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg delete unbound
        fi
        if [ -d "${UNBOUND_ROOT}" ]; then
          rm --recursive --force ${UNBOUND_ROOT}
        fi
        if [ -f "${UNBOUND_ANCHOR}" ]; then
          rm --force ${UNBOUND_ANCHOR}
        fi
      fi
      # If any cronjobs are identified, they should be removed.
      crontab -l | grep --invert-match "${CURRENT_FILE_PATH}" | crontab -
      ;;
    9) # Update the script
      # Check for updates to WireGuard Manager.
      # Check for updates to the Unbound root hints file.
      # Check for updates to the Unbound hosts file.
      # If any of the above files are updated, restart Unbound.
      CURRENT_WIREGUARD_MANAGER_HASH=$(openssl dgst -sha3-512 "${CURRENT_FILE_PATH}" | cut --delimiter=" " --fields=2)
      NEW_WIREGUARD_MANAGER_HASH=$(curl --silent "${WIREGUARD_MANAGER_UPDATE}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
      if [ "${CURRENT_WIREGUARD_MANAGER_HASH}" != "${NEW_WIREGUARD_MANAGER_HASH}" ]; then
        curl "${WIREGUARD_MANAGER_UPDATE}" -o "${CURRENT_FILE_PATH}"
        chmod +x "${CURRENT_FILE_PATH}"
      fi
      # Update the unbound configs
      if [ -x "$(command -v unbound)" ]; then
        if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
          CURRENT_ROOT_HINTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_ROOT_HINTS}" | cut --delimiter=" " --fields=2)
          NEW_ROOT_HINTS_HASH=$(curl --silent "${UNBOUND_ROOT_SERVER_CONFIG_URL}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
          if [ "${CURRENT_ROOT_HINTS_HASH}" != "${NEW_ROOT_HINTS_HASH}" ]; then
            curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o ${UNBOUND_ROOT_HINTS}
          fi
        fi
        if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
          CURRENT_UNBOUND_HOSTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_CONFIG_HOST}" | cut --delimiter=" " --fields=2)
          NEW_UNBOUND_HOSTS_HASH=$(curl --silent "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
          if [ "${CURRENT_UNBOUND_HOSTS_HASH}" != "${NEW_UNBOUND_HOSTS_HASH}" ]; then
            curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
          fi
        fi
        # Once everything is completed, restart the service.
        if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
          systemctl restart unbound
        elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
          service unbound restart
        fi
      fi
      ;;
    10) # Backup WireGuard Config
      # It checks if a backup file already exists and removes it if it does.
      # It checks if a folder for the backup exists and creates it if it doesn't.
      # It checks if the WireGuard config folder exists and creates a backup if it does.
      # It generates a random password and saves it to a file for later use.
      # It creates a ZIP file of the WireGuard config folder and encrypts it using the password.
      if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        rm --force ${WIREGUARD_CONFIG_BACKUP}
      fi
      if [ ! -d "${SYSTEM_BACKUP_PATH}" ]; then
        mkdir --parents ${SYSTEM_BACKUP_PATH}
      fi
      if [ -d "${WIREGUARD_PATH}" ]; then
        BACKUP_PASSWORD="$(openssl rand -hex 50)"
        echo "${BACKUP_PASSWORD}" >"${WIREGUARD_BACKUP_PASSWORD_PATH}"
        zip -P "${BACKUP_PASSWORD}" -rj ${WIREGUARD_CONFIG_BACKUP} ${WIREGUARD_CONFIG}
      fi
      ;;
    11) # Restore WireGuard Config
      # Checks if the backup file exists
      # Asks the user for the backup password
      # If the password is empty, the process stops
      # If the password is not empty, the backup is extracted to the original WireGuard config folder
      # The WireGuard service is restarted to apply the changes
      if [ ! -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
        exit
      fi
      read -rp "Backup Password: " -e -i "$(cat "${WIREGUARD_BACKUP_PASSWORD_PATH}")" WIREGUARD_BACKUP_PASSWORD
      if [ -z "${WIREGUARD_BACKUP_PASSWORD}" ]; then
        exit
      fi
      unzip -o -P "${WIREGUARD_BACKUP_PASSWORD}" "${WIREGUARD_CONFIG_BACKUP}" -d "${WIREGUARD_PATH}"
      # Restart WireGuard
      if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
        systemctl enable --now wg-quick@${WIREGUARD_PUB_NIC}
      elif [[ "${CURRENT_INIT_SYSTEM}" == *"init"* ]]; then
        service wg-quick@${WIREGUARD_PUB_NIC} restart
      fi
      ;;
    12) # Change the IP address of your wireguard interface.
      # Check if the public interface is using IPv4 or IPv6
      # If the public interface is using IPv4 / IPv6 it will replace the old server host with the new server host in the WireGuard configuration file
      # It will also replace the old server host with the new server host in all the client configuration files
      get-network-information
      CURRENT_IP_METHORD=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4)
      if [[ ${CURRENT_IP_METHORD} != *"["* ]]; then
        OLD_SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter=":" --fields=1)
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV4}
      fi
      if [[ ${CURRENT_IP_METHORD} == *"["* ]]; then
        OLD_SERVER_HOST=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter="[" --fields=2 | cut --delimiter="]" --fields=1)
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV6}
      fi
      if [ "${OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
        sed --in-place "1s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" ${WIREGUARD_CONFIG}
      fi
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
      done
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          sed --in-place "s/${OLD_SERVER_HOST}/${NEW_SERVER_HOST}/" "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
        fi
      done
      ;;
    13) # Change the wireguard interface's port number.
      # Read the first line of the WireGuard config file and extract the port number from it.
      # Until the NEW_SERVER_PORT is a number between 1 and 65535, ask for a custom port.
      # If the port is already in use, exit the script
      # If the port is different from the current port, replace the port number in the config file.
      # Read the client names from the config file and create a list of them.
      # For each client name, replace the port number in the client config fille.
      OLD_SERVER_PORT=$(head --lines=1 ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=4 | cut --delimiter=":" --fields=2)
      until [[ "${NEW_SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${NEW_SERVER_PORT}" -ge 1 ] && [ "${NEW_SERVER_PORT}" -le 65535 ]; do
        read -rp "Custom port [1-65535]: " -e -i 51820 NEW_SERVER_PORT
      done
      if [ "$(lsof -i UDP:"${NEW_SERVER_PORT}")" ]; then
        echo "Error: The port ${NEW_SERVER_PORT} is already used by a different application, please use a different port."
        exit
      fi
      if [ "${OLD_SERVER_PORT}" != "${NEW_SERVER_PORT}" ]; then
        sed --in-place "s/${OLD_SERVER_PORT}/${NEW_SERVER_PORT}/g" ${WIREGUARD_CONFIG}
        echo "The server port has changed from ${OLD_SERVER_PORT} to ${NEW_SERVER_PORT} in ${WIREGUARD_CONFIG}."
      fi
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
      done
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          sed --in-place "s/${OLD_SERVER_PORT}/${NEW_SERVER_PORT}/" "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
          echo "The server port has changed from ${OLD_SERVER_PORT} to ${NEW_SERVER_PORT} in ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf."
        fi
      done
      ;;
    14) # All wireguard peers should be removed from your interface
      # Grabs the list of clients in the config file
      # Iterates over each client and:
      # Removes the client from the server
      # Removes the client's config from the server
      # Removes the client from the cron job
      COMPLETE_CLIENT_LIST=$(grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2)
      for CLIENT_LIST_ARRAY in ${COMPLETE_CLIENT_LIST}; do
        USER_LIST[ADD_CONTENT]=${CLIENT_LIST_ARRAY}
        ADD_CONTENT=$(("${ADD_CONTENT}" + 1))
      done
      for CLIENT_NAME in "${USER_LIST[@]}"; do
        CLIENTKEY=$(sed -n "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | cut --delimiter=" " --fields=3)
        wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
        sed --in-place "/\# ${CLIENT_NAME} start/,/\# ${CLIENT_NAME} end/d" ${WIREGUARD_CONFIG}
        if [ -f "${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf" ]; then
          rm --force ${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
        fi
        wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
        crontab -l | grep --invert-match "${CLIENT_NAME}" | crontab -
      done
      ;;
    15) # Generate QR code.
      # Asks for the name of the peer for which you want to generate a QR code.
      # Lists all available peers.
      # Reads the user input.
      # Checks if a configuration file with the same name exists.
      # If it exists, it generates a QR code and prints the path to the configuration file.
      echo "Which WireGuard peer would you like to generate a QR code for?"
      grep start ${WIREGUARD_CONFIG} | cut --delimiter=" " --fields=2
      read -rp "Peer's name:" VIEW_CLIENT_INFO
      if [ -f "${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf" ]; then
        qrencode -t ansiutf8 <${WIREGUARD_CLIENT_PATH}/"${VIEW_CLIENT_INFO}"-${WIREGUARD_PUB_NIC}.conf
        echo "Peer's config --> ${WIREGUARD_CLIENT_PATH}/${VIEW_CLIENT_INFO}-${WIREGUARD_PUB_NIC}.conf"
      fi
      ;;
    16)
      # This code checks for unbound and runs the unbound-checkconf and unbound-host commands to check the config file.
      # It looks for the "no errors" string to see if there are any errors in the config file
      # and the "secure" string to see if the DNS-SEC is configured correctly.
      # If it finds an error, it will write a message to the log file.
      # If the checks are successful, there will be no output.
      # The unbound-host command uses the api.ipengine.dev domain to check for DNS-SEC.
      # This domain is used because it is a domain that is signed by Cloudflare.
      if [ -x "$(command -v unbound)" ]; then
        if [[ "$(unbound-checkconf ${UNBOUND_CONFIG})" != *"no errors"* ]]; then
          echo "We found an error on your unbound config file located at ${UNBOUND_CONFIG}"
        fi
        if [[ "$(unbound-host -C ${UNBOUND_CONFIG} -v api.ipengine.dev)" != *"secure"* ]]; then
          echo "We found an error on your unbound DNS-SEC config file loacted at ${UNBOUND_CONFIG}"
        fi
      fi
      ;;
    esac
  }

  # Running Questions Command
  wireguard-next-questions-interface

fi
