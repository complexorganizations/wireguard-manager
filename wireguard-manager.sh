#!/bin/bash
# https://github.com/complexorganizations/wireguard-manager

# Require script to be run as root
function super-user-check() {
  if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=${ID}
    DISTRO_VERSION=${VERSION_ID}
  fi
}

# Check Operating System
dist-check

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ] || [ "${DISTRO}" == "freebsd" ] || [ "${DISTRO}" == "neon" ]; }; then
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v iptables)" ] || [ ! -x "$(command -v bc)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v cron)" ] || [ ! -x "$(command -v sed)" ] || [ ! -x "$(command -v zip)" ] || [ ! -x "$(command -v unzip)" ] || [ ! -x "$(command -v grep)" ] || [ ! -x "$(command -v awk)" ] || [ ! -x "$(command -v shuf)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v ntpd)" ] || [ ! -x "$(command -v lsof)" ]; }; then
      if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "neon" ]; }; then
        apt-get update && apt-get install iptables curl coreutils bc jq sed e2fsprogs zip unzip grep gawk iproute2 systemd openssl cron ntp lsof -y
      elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
        yum update -y && yum install iptables curl coreutils bc jq sed e2fsprogs zip unzip grep gawk systemd openssl cron ntp lsof -y
      elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm --needed bc jq zip unzip cronie ntp lsof
      elif [ "${DISTRO}" == "alpine" ]; then
        apk update && apk add iptables curl bc jq sed zip unzip grep gawk iproute2 systemd coreutils openssl cron ntp lsof
      elif [ "${DISTRO}" == "freebsd" ]; then
        pkg update && pkg install curl jq zip unzip gawk openssl cron ntp lsof
      fi
    fi
  else
    echo "Error: ${DISTRO} is not supported."
    exit
  fi
}

# Run the function and check for requirements
installing-system-requirements

# Checking For Virtualization
function virt-check() {
  # Deny OpenVZ Virtualization
  if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ virtualization is not supported (yet)."
    exit
  # Deny LXC Virtualization
  elif [ "$(systemd-detect-virt)" == "lxc" ]; then
    echo "LXC virtualization is not supported (yet)."
    exit
  fi
}

# Virtualization Check
virt-check

# Check for docker stuff
function docker-check() {
  if [ -f /.dockerenv ]; then
    DOCKER_KERNEL_VERSION_LIMIT=5.6
    DOCKER_KERNEL_CURRENT_VERSION=$(uname -r | cut -d'.' -f1-2)
    if (($(echo "${DOCKER_KERNEL_CURRENT_VERSION} >= ${DOCKER_KERNEL_VERSION_LIMIT}" | bc -l))); then
      echo "Correct: Kernel ${DOCKER_KERNEL_CURRENT_VERSION} supported." >>/dev/null
    else
      echo "Error: Kernel ${DOCKER_KERNEL_CURRENT_VERSION} not supported, please update to ${DOCKER_KERNEL_VERSION_LIMIT}"
      exit
    fi
  fi
}

# Docker Check
docker-check

# Lets check the kernel version
function kernel-check() {
  KERNEL_VERSION_LIMIT=3.1
  KERNEL_CURRENT_VERSION=$(uname -r | cut -d'.' -f1-2)
  if (($(echo "${KERNEL_CURRENT_VERSION} >= ${KERNEL_VERSION_LIMIT}" | bc -l))); then
    echo "Correct: Kernel ${KERNEL_CURRENT_VERSION} supported." >>/dev/null
  else
    echo "Error: Kernel ${KERNEL_CURRENT_VERSION} not supported, please update to ${KERNEL_VERSION_LIMIT}"
    exit
  fi
}

# Kernel Version
kernel-check

# Global variables
WIREGUARD_WEBSITE_URL="https://www.wireguard.com"
WIREGUARD_PATH="/etc/wireguard"
WIREGUARD_CLIENT_PATH="${WIREGUARD_PATH}/clients"
WIREGUARD_PUB_NIC="wg0"
WIREGUARD_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}.conf"
WIREGUARD_ADD_PEER_CONFIG="${WIREGUARD_PATH}/${WIREGUARD_PUB_NIC}-add-peer.conf"
WIREGUARD_MANAGER="${WIREGUARD_PATH}/wireguard-manager"
WIREGUARD_INTERFACE="${WIREGUARD_PATH}/wireguard-interface"
WIREGUARD_PEER="${WIREGUARD_PATH}/wireguard-peer"
WIREGUARD_MANAGER_UPDATE="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh"
SYSTEM_BACKUP_PATH="/var/backups"
WIREGUARD_CONFIG_BACKUP="${SYSTEM_BACKUP_PATH}/wireguard-manager.zip"
WIREGUARD_OLD_BACKUP="${SYSTEM_BACKUP_PATH}/OLD_WIREGUARD_FILES"
WIREGUARD_BACKUP_PASSWORD_PATH="${HOME}/.wireguard-manager"
WIREGUARD_IP_FORWARDING_CONFIG="/etc/sysctl.d/wireguard.conf"
RESOLV_CONFIG="/etc/resolv.conf"
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"
COREDNS_ROOT="/etc/coredns"
COREDNS_BUILD="${COREDNS_ROOT}/coredns"
COREDNS_CONFIG="${COREDNS_ROOT}/Corefile"
COREDNS_HOSTFILE="${COREDNS_ROOT}/hosts"
COREDNS_MANAGER="${COREDNS_ROOT}/wireguard-manager"
COREDNS_SERVICE_FILE="/etc/systemd/system/coredns.service"
CONTENT_BLOCKER_URL="https://raw.githubusercontent.com/complexorganizations/content-blocker/main/configs/hosts"

# Verify that it is an old installation or another installer
function previous-wireguard-installation() {
  if [ -d "${WIREGUARD_PATH}" ]; then
    if [ ! -f "${WIREGUARD_MANAGER}" ]; then
      rm -rf ${WIREGUARD_PATH}
    fi
  fi
}

# Run the function to eliminate old installation or another installer
previous-wireguard-installation

# Which would you like to install interface or peer?
function interface-or-peer() {
  if [ ! -f "${WIREGUARD_MANAGER}" ]; then
    echo "Do you want the interface (server) or peer (client) to be installed?"
    echo "  1) Interface"
    echo "  2) Peer"
    until [[ "${INTERFACE_OR_PEER}" =~ ^[1-2]$ ]]; do
      read -rp "Interface Or Peer [1-2]: " -e -i 1 INTERFACE_OR_PEER
    done
    case ${INTERFACE_OR_PEER} in
    1)
      if [ -d "${WIREGUARD_PATH}" ]; then
        cp -R ${WIREGUARD_PATH} ${WIREGUARD_OLD_BACKUP}
        if [ -f "${WIREGUARD_PEER}" ]; then
          rm -rf ${WIREGUARD_PATH}
        fi
      fi
      if [ ! -d "${WIREGUARD_PATH}" ]; then
        mkdir -p ${WIREGUARD_PATH}
      fi
      if [ ! -f "${WIREGUARD_INTERFACE}" ]; then
        echo "WireGuard Interface: true" >>${WIREGUARD_INTERFACE}
      fi
      ;;
    2)
      if [ -d "${WIREGUARD_PATH}" ]; then
        cp -R ${WIREGUARD_PATH} ${WIREGUARD_OLD_BACKUP}
        if [ -f "${WIREGUARD_INTERFACE}" ]; then
          rm -rf ${WIREGUARD_PATH}
        fi
      fi
      if [ ! -d "${WIREGUARD_PATH}" ]; then
        mkdir -p ${WIREGUARD_PATH}
      fi
      if [ ! -f "${WIREGUARD_PEER}" ]; then
        echo "WireGuard Peer: true" >>${WIREGUARD_PEER}
      fi
      ;;
    esac
  fi
}

# Interface or Peer
interface-or-peer

# Usage Guide
function usage-guide() {
  if [ -f "${WIREGUARD_INTERFACE}" ]; then
    echo "usage: ./$(basename "$0") <command>"
    echo "  --install     Install WireGuard"
    echo "  --start       Start WireGuard"
    echo "  --stop        Stop WireGuard"
    echo "  --restart     Restart WireGuard"
    echo "  --list        Show WireGuard"
    echo "  --add         Add WireGuard Peer"
    echo "  --remove      Remove WireGuard Peer"
    echo "  --reinstall   Reinstall WireGuard"
    echo "  --uninstall   Uninstall WireGuard"
    echo "  --update      Update WireGuard Manager"
    echo "  --backup      Backup WireGuard"
    echo "  --restore     Restore WireGuard"
    echo "  --help        Show Usage Guide"
  fi
}

# The usage of the script
function usage() {
  if [ -f "${WIREGUARD_INTERFACE}" ]; then
    while [ $# -ne 0 ]; do
      case ${1} in
      --install)
        shift
        HEADLESS_INSTALL=${HEADLESS_INSTALL:-y}
        ;;
      --start)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-2}
        ;;
      --stop)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-3}
        ;;
      --restart)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-4}
        ;;
      --list)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-1}
        ;;
      --add)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-5}
        ;;
      --remove)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-6}
        ;;
      --reinstall)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-7}
        ;;
      --uninstall)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-8}
        ;;
      --update)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-9}
        ;;
      --backup)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-10}
        ;;
      --restore)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-11}
        ;;
      --notification)
        shift
        WIREGUARD_OPTIONS=${WIREGUARD_OPTIONS:-12}
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
  fi
}

usage "$@"

# Skips all questions and just get a client conf after install.
function headless-install() {
  if [[ ${HEADLESS_INSTALL} =~ ^[Yy]$ ]]; then
    INTERFACE_OR_PEER=${INTERFACE_OR_PEER:-1}
    IPV4_SUBNET_SETTINGS=${IPV4_SUBNET_SETTINGS:-1}
    IPV6_SUBNET_SETTINGS=${IPV6_SUBNET_SETTINGS:-1}
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS:-1}
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS:-1}
    SERVER_PUB_NIC_SETTINGS=${SERVER_PUB_NIC_SETTINGS:-1}
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS:-1}
    NAT_CHOICE_SETTINGS=${NAT_CHOICE_SETTINGS:-1}
    MTU_CHOICE_SETTINGS=${MTU_CHOICE_SETTINGS:-1}
    SERVER_HOST_SETTINGS=${SERVER_HOST_SETTINGS:-1}
    DISABLE_HOST_SETTINGS=${DISABLE_HOST_SETTINGS:-1}
    CLIENT_ALLOWED_IP_SETTINGS=${CLIENT_ALLOWED_IP_SETTINGS:-1}
    AUTOMATIC_UPDATES_SETTINGS=${AUTOMATIC_UPDATES_SETTINGS:-1}
    NOTIFICATIONS_PREFERENCE_SETTINGS=${NOTIFICATIONS_PREFERENCE_SETTINGS:-1}
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS:-1}
    CLIENT_NAME=${CLIENT_NAME:-client}
  fi
}

# No GUI
headless-install

if [ ! -f "${WIREGUARD_CONFIG}" ]; then

  # Custom IPv4 subnet
  function set-ipv4-subnet() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What IPv4 subnet do you want to use?"
      echo "  1) 10.8.0.0/24 (Recommended)"
      echo "  2) 10.0.0.0/24"
      echo "  3) Custom (Advanced)"
      until [[ "${IPV4_SUBNET_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Subnet Choice [1-3]: " -e -i 1 IPV4_SUBNET_SETTINGS
      done
      case ${IPV4_SUBNET_SETTINGS} in
      1)
        IPV4_SUBNET="10.8.0.0/24"
        ;;
      2)
        IPV4_SUBNET="10.0.0.0/24"
        ;;
      3)
        read -rp "Custom Subnet: " -e -i "10.8.0.0/24" IPV4_SUBNET
        if [ -z "${IPV4_SUBNET}" ]; then
          IPV4_SUBNET="10.8.0.0/24"
        fi
        ;;
      esac
    fi
  }

  # Custom IPv4 Subnet
  set-ipv4-subnet

  # Custom IPv6 subnet
  function set-ipv6-subnet() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What IPv6 subnet do you want to use?"
      echo "  1) fd42:42:42::0/64 (Recommended)"
      echo "  2) fd86:ea04:1115::0/64"
      echo "  3) Custom (Advanced)"
      until [[ "${IPV6_SUBNET_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Subnet Choice [1-3]: " -e -i 1 IPV6_SUBNET_SETTINGS
      done
      case ${IPV6_SUBNET_SETTINGS} in
      1)
        IPV6_SUBNET="fd42:42:42::0/64"
        ;;
      2)
        IPV6_SUBNET="fd86:ea04:1115::0/64"
        ;;
      3)
        read -rp "Custom Subnet: " -e -i "fd42:42:42::0/64" IPV6_SUBNET
        if [ -z "${IPV6_SUBNET}" ]; then
          IPV6_SUBNET="fd42:42:42::0/64"
        fi
        ;;
      esac
    fi
  }

  # Custom IPv6 Subnet
  set-ipv6-subnet

  if [ -f "${WIREGUARD_INTERFACE}" ]; then
    # Private Subnet Ipv4
    PRIVATE_SUBNET_V4=${PRIVATE_SUBNET_V4:-"${IPV4_SUBNET}"}
    # Private Subnet Mask IPv4
    PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d "/" -f 2)
    # IPv4 Getaway
    GATEWAY_ADDRESS_V4="${PRIVATE_SUBNET_V4::-4}1"
    # Private Subnet Ipv6
    PRIVATE_SUBNET_V6=${PRIVATE_SUBNET_V6:-"${IPV6_SUBNET}"}
    # Private Subnet Mask IPv6
    PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut -d "/" -f 2)
    # IPv6 Getaway
    GATEWAY_ADDRESS_V6="${PRIVATE_SUBNET_V6::-4}1"
  fi

  # Get the IPv4
  function test-connectivity-v4() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "How would you like to detect IPv4?"
      echo "  1) Curl (Recommended)"
      echo "  2) IP (Advanced)"
      echo "  3) Custom (Advanced)"
      until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "IPv4 Choice [1-3]: " -e -i 1 SERVER_HOST_V4_SETTINGS
      done
      case ${SERVER_HOST_V4_SETTINGS} in
      1)
        SERVER_HOST_V4="$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
        if [ -z "${SERVER_HOST_V4}" ]; then
          echo "Error: Curl unable to locate your server's public IP address."
          exit
        fi
        ;;
      2)
        SERVER_HOST_V4="$(ip route get 8.8.8.8 | grep src | sed 's/.*src \(.* \)/\1/g' | cut -f1 -d ' ')"
        if [ -z "${SERVER_HOST_V4}" ]; then
          echo "Error: IP unable to locate your server's public IP address."
          exit
        fi
        ;;
      3)
        read -rp "Custom IPv4: " -e -i "$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')" SERVER_HOST_V4
        if [ -z "${SERVER_HOST_V4}" ]; then
          SERVER_HOST_V4="$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
        fi
        ;;
      esac
    fi
  }

  # Get the IPv4
  test-connectivity-v4

  # Determine IPv6
  function test-connectivity-v6() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "How would you like to detect IPv6?"
      echo "  1) Curl (Recommended)"
      echo "  2) IP (Advanced)"
      echo "  3) Custom (Advanced)"
      until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "IPv6 Choice [1-3]: " -e -i 1 SERVER_HOST_V6_SETTINGS
      done
      case ${SERVER_HOST_V6_SETTINGS} in
      1)
        SERVER_HOST_V6="$(curl -6 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
        if [ -z "${SERVER_HOST_V6}" ]; then
          echo "Error: Curl unable to locate your server's public IP address."
          exit
        fi
        ;;
      2)
        SERVER_HOST_V6="$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)"
        if [ -z "${SERVER_HOST_V6}" ]; then
          echo "Error: IP unable to locate your server's public IP address."
          exit
        fi
        ;;
      3)
        read -rp "Custom IPv6: " -e -i "$(curl -6 -s 'https://api.ipengine.dev' | jq -r '.network.ip')" SERVER_HOST_V6
        if [ -z "${SERVER_HOST_V6}" ]; then
          SERVER_HOST_V6="$(curl -6 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
        fi
        ;;
      esac
    fi
  }

  # Get the IPv6
  test-connectivity-v6

  # Determine public NIC
  function server-pub-nic() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "How would you like to detect NIC?"
      echo "  1) IP (Recommended)"
      echo "  2) Custom (Advanced)"
      until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "nic Choice [1-2]: " -e -i 1 SERVER_PUB_NIC_SETTINGS
      done
      case ${SERVER_PUB_NIC_SETTINGS} in
      1)
        SERVER_PUB_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
        if [ -z "${SERVER_PUB_NIC}" ]; then
          echo "Error: Your server's public network interface could not be found."
          exit
        fi
        ;;
      2)
        read -rp "Custom NAT: " -e -i "$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)" SERVER_PUB_NIC
        if [ -z "${SERVER_PUB_NIC}" ]; then
          SERVER_PUB_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
          exit
        fi
        ;;
      esac
    fi
  }

  # Determine public NIC
  server-pub-nic

  # Determine host port
  function set-port() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What port do you want WireGuard server to listen to?"
      echo "  1) 51820 (Recommended)"
      echo "  2) Custom (Advanced)"
      echo "  3) Random [1024-65535]"
      until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Port Choice [1-3]: " -e -i 1 SERVER_PORT_SETTINGS
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
          read -rp "Custom port [1-65535]: " -e -i 51820 SERVER_PORT
        done
        if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
          echo "Error: The port ${SERVER_PORT} is already used by a different application, please use a different port."
          exit
        fi
        ;;
      3)
        SERVER_PORT=$(shuf -i1024-65535 -n1)
        if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
          SERVER_PORT=$(shuf -i1024-65535 -n1)
        else
          echo "Random Port: ${SERVER_PORT}"
        fi
        ;;
      esac
    fi
  }

  # Set port
  set-port

  # Determine Keepalive interval.
  function nat-keepalive() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What do you want your keepalive interval to be?"
      echo "  1) 25 (Default)"
      echo "  2) Custom (Advanced)"
      echo "  3) Random [1024-65535]"
      until [[ "${NAT_CHOICE_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Nat Choice [1-3]: " -e -i 1 NAT_CHOICE_SETTINGS
      done
      case ${NAT_CHOICE_SETTINGS} in
      1)
        NAT_CHOICE="25"
        ;;
      2)
        until [[ "${NAT_CHOICE}" =~ ^[0-9]+$ ]] && [ "${NAT_CHOICE}" -ge 1 ] && [ "${NAT_CHOICE}" -le 65535 ]; do
          read -rp "Custom NAT [1-65535]: " -e -i 25 NAT_CHOICE
        done
        ;;
      3)
        NAT_CHOICE=$(shuf -i1024-65535 -n1)
        ;;
      esac
    fi
  }

  # Keepalive
  nat-keepalive

  # Custom MTU or default settings
  function mtu-set() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What MTU do you want to use?"
      echo "  1) 1280 (Recommended)"
      echo "  2) 1420"
      echo "  3) Custom (Advanced)"
      until [[ "${MTU_CHOICE_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "MTU Choice [1-3]: " -e -i 1 MTU_CHOICE_SETTINGS
      done
      case ${MTU_CHOICE_SETTINGS} in
      1)
        MTU_CHOICE="1280"
        ;;
      2)
        MTU_CHOICE="1420"
        ;;
      3)
        until [[ "${MTU_CHOICE}" =~ ^[0-9]+$ ]] && [ "${MTU_CHOICE}" -ge 1 ] && [ "${MTU_CHOICE}" -le 65535 ]; do
          read -rp "Custom MTU [1-65535]: " -e -i 1280 MTU_CHOICE
        done
        ;;
      esac
    fi
  }

  # Set MTU
  mtu-set

  # What IP version would you like to be available on this WireGuard server?
  function ipvx-select() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What IPv do you want to use to connect to the WireGuard server?"
      echo "  1) IPv4 (Recommended)"
      echo "  2) IPv6"
      echo "  3) Custom (Advanced)"
      until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "IP Choice [1-3]: " -e -i 1 SERVER_HOST_SETTINGS
      done
      case ${SERVER_HOST_SETTINGS} in
      1)
        if [ -n "${SERVER_HOST_V4}" ]; then
          SERVER_HOST="${SERVER_HOST_V4}"
        else
          SERVER_HOST="[${SERVER_HOST_V6}]"
        fi
        ;;
      2)
        if [ -n "${SERVER_HOST_V6}" ]; then
          SERVER_HOST="[${SERVER_HOST_V6}]"
        else
          SERVER_HOST="${SERVER_HOST_V4}"
        fi
        ;;
      3)
        read -rp "Custom Domain: " -e -i "$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.hostname')" SERVER_HOST
        if [ -z "${SERVER_HOST}" ]; then
          SERVER_HOST="$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
        fi
        ;;
      esac
    fi
  }

  # IPv4 or IPv6 Selector
  ipvx-select

  # Do you want to disable IPv4 or IPv6 or leave them both enabled?
  function disable-ipvx() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "Do you want to disable IPv4 or IPv6 on the server?"
      echo "  1) No (Recommended)"
      echo "  2) Disable IPv4"
      echo "  3) Disable IPv6"
      until [[ "${DISABLE_HOST_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Disable Host Choice [1-3]: " -e -i 1 DISABLE_HOST_SETTINGS
      done
      case ${DISABLE_HOST_SETTINGS} in
      1)
        if [ -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          rm -f ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        if [ ! -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          echo "net.ipv4.ip_forward=1" >>${WIREGUARD_IP_FORWARDING_CONFIG}
          echo "net.ipv6.conf.all.forwarding=1" >>${WIREGUARD_IP_FORWARDING_CONFIG}
          sysctl -p ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        ;;
      2)
        if [ -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          rm -f ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        if [ ! -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          echo "net.ipv6.conf.all.forwarding=1" >>${WIREGUARD_IP_FORWARDING_CONFIG}
          sysctl -p ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        ;;
      3)
        if [ -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          rm -f ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        if [ ! -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
          echo "net.ipv4.ip_forward=1" >>${WIREGUARD_IP_FORWARDING_CONFIG}
          sysctl -p ${WIREGUARD_IP_FORWARDING_CONFIG}
        fi
        ;;
      esac
    fi
  }

  # Disable IPv4 or IPv6
  disable-ipvx

  # Would you like to allow connections to your LAN neighbors?
  function client-allowed-ip() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "What traffic do you want the client to forward through WireGuard?"
      echo "  1) Everything (Recommended)"
      echo "  2) Exclude Private IPs"
      echo "  3) Custom (Advanced)"
      until [[ "${CLIENT_ALLOWED_IP_SETTINGS}" =~ ^[1-3]$ ]]; do
        read -rp "Client Allowed IP Choice [1-3]: " -e -i 1 CLIENT_ALLOWED_IP_SETTINGS
      done
      case ${CLIENT_ALLOWED_IP_SETTINGS} in
      1)
        CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
        ;;
      2)
        CLIENT_ALLOWED_IP="0.0.0.0/5,8.0.0.0/7,11.0.0.0/8,12.0.0.0/6,16.0.0.0/4,32.0.0.0/3,64.0.0.0/2,128.0.0.0/3,160.0.0.0/5,168.0.0.0/6,172.0.0.0/12,172.32.0.0/11,172.64.0.0/10,172.128.0.0/9,173.0.0.0/8,174.0.0.0/7,176.0.0.0/4,192.0.0.0/9,192.128.0.0/11,192.160.0.0/13,192.169.0.0/16,192.170.0.0/15,192.172.0.0/14,192.176.0.0/12,192.192.0.0/10,193.0.0.0/8,194.0.0.0/7,196.0.0.0/6,200.0.0.0/5,208.0.0.0/4,::/0,${GATEWAY_ADDRESS_V4}/32"
        ;;
      3)
        read -rp "Custom IPs: " -e -i "0.0.0.0/0,::/0" CLIENT_ALLOWED_IP
        if [ -z "${CLIENT_ALLOWED_IP}" ]; then
          CLIENT_ALLOWED_IP="0.0.0.0/0,::/0"
        fi
        ;;
      esac
    fi
  }

  # Traffic Forwarding
  client-allowed-ip

  # real-time updates
  function enable-automatic-updates() {
    if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
      echo "Would you like to setup real-time updates?"
      echo "  1) Yes (Recommended)"
      echo "  2) No (Advanced)"
      until [[ "${AUTOMATIC_UPDATES_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "Automatic Updates [1-2]: " -e -i 1 AUTOMATIC_UPDATES_SETTINGS
      done
      case ${AUTOMATIC_UPDATES_SETTINGS} in
      1)
        crontab -l | {
          cat
          echo "0 0 * * * $(realpath "$0") --update"
        } | crontab -
        if pgrep systemd-journal; then
          systemctl enable cron
          systemctl start cron
        else
          service cron enable
          service cron start
        fi
        ;;
      2)
        echo "Real-time Updates Disabled"
        ;;
      esac
    fi
  }

  # real-time updates
  enable-automatic-updates

  # real-time backup
  function enable-automatic-backup() {
    if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
      echo "Would you like to setup real-time backup?"
      echo "  1) Yes (Recommended)"
      echo "  2) No (Advanced)"
      until [[ "${AUTOMATIC_BACKUP_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "Automatic Backup [1-2]: " -e -i 1 AUTOMATIC_BACKUP_SETTINGS
      done
      case ${AUTOMATIC_BACKUP_SETTINGS} in
      1)
        crontab -l | {
          cat
          echo "0 0 * * * $(realpath "$0") --backup"
        } | crontab -
        if pgrep systemd-journal; then
          systemctl enable cron
          systemctl start cron
        else
          service cron enable
          service cron start
        fi
        ;;
      2)
        echo "Real-time Backup Disabled"
        ;;
      esac
    fi
  }

  # real-time backup
  enable-automatic-backup

  # Send real time notifications
  function real-time-notifications() {
    if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
      echo "Would you like to setup notifications?"
      echo "  1) No (Recommended)"
      echo "  2) Twilio (Advanced)"
      until [[ "${NOTIFICATIONS_PREFERENCE_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "Notifications setup [1-2]: " -e -i 1 NOTIFICATIONS_PREFERENCE_SETTINGS
      done
      case ${NOTIFICATIONS_PREFERENCE_SETTINGS} in
      1)
        echo "Real-time Notifications Disabled"
        ;;
      2)
        read -rp "Twilio Account SID: " -e -i "" TWILIO_ACCOUNT_SID
        if [ -z "${TWILIO_ACCOUNT_SID}" ]; then
          TWILIO_ACCOUNT_SID="$(openssl rand -hex 10)"
        fi
        read -rp "Twilio Auth Token: " -e -i "" TWILIO_AUTH_TOKEN
        if [ -z "${TWILIO_AUTH_TOKEN}" ]; then
          TWILIO_AUTH_TOKEN="$(openssl rand -hex 10)"
        fi
        read -rp "Twilio From Number: " -e -i "" TWILIO_FROM_NUMBER
        if [ -z "${TWILIO_FROM_NUMBER}" ]; then
          TWILIO_FROM_NUMBER="$(openssl rand -hex 10)"
        fi
        read -rp "Twilio To Number: " -e -i "" TWILIO_TO_NUMBER
        if [ -z "${TWILIO_TO_NUMBER}" ]; then
          TWILIO_TO_NUMBER="$(openssl rand -hex 10)"
        fi
        crontab -l | {
          cat
          echo "* * * * * $(realpath "$0") --notification"
        } | crontab -
        if pgrep systemd-journal; then
          systemctl enable cron
          systemctl start cron
        else
          service cron enable
          service cron start
        fi
        ;;
      esac
    fi
  }

  # real time notifications updates
  real-time-notifications

  # Would you like to install coredns.
  function ask-install-dns() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      echo "Which DNS provider would you like to use?"
      echo "  1) Coredns (Recommended)"
      echo "  2) Custom (Advanced)"
      until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
        read -rp "DNS provider [1-2]: " -e -i 1 DNS_PROVIDER_SETTINGS
      done
      case ${DNS_PROVIDER_SETTINGS} in
      1)
        INSTALL_COREDNS="y"
        if [ "${INSTALL_COREDNS}" = "y" ]; then
          read -rp "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker? (y/n):" INSTALL_BLOCK_LIST
        fi
        ;;
      2)
        CUSTOM_DNS="y"
        ;;
      esac
    fi
  }

  # Ask To Install DNS
  ask-install-dns

  # Use custom dns
  function custom-dns() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      if [ "${CUSTOM_DNS}" == "y" ]; then
        echo "Which DNS do you want to use with the WireGuard connection?"
        echo "  1) Google (Recommended)"
        echo "  2) AdGuard"
        echo "  3) NextDNS"
        echo "  4) OpenDNS"
        echo "  5) Cloudflare"
        echo "  6) Verisign"
        echo "  7) Quad9"
        echo "  8) FDN"
        echo "  9) Custom (Advanced)"
        until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 9 ]; do
          read -rp "DNS [1-9]: " -e -i 1 CLIENT_DNS_SETTINGS
        done
        case ${CLIENT_DNS_SETTINGS} in
        1)
          CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
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
          CLIENT_DNS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
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
          read -rp "Custom DNS (IPv4 IPv6):" -e -i "8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844" CLIENT_DNS
          if [ -z "${CLIENT_DNS}" ]; then
            CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
          fi
          ;;
        esac
      fi
    fi
  }

  # use custom dns
  custom-dns

  # What would you like to name your first WireGuard peer?
  function client-name() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      if [ -z "${CLIENT_NAME}" ]; then
        echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
        read -rp "Client name: " -e CLIENT_NAME
      fi
      if [ -z "${CLIENT_NAME}" ]; then
        CLIENT_NAME="$(openssl rand -hex 50)"
      fi
    fi
  }

  # Client Name
  client-name

  # Lets check the kernel version and check if headers are required
  function install-kernel-headers() {
    if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
      LINUX_HEADER_KERNEL_VERSION_LIMIT=5.6
      LINUX_HEADER_KERNEL_CURRENT_VERSION=$(uname -r | cut -d'.' -f1-2)
      if (($(echo "${LINUX_HEADER_KERNEL_CURRENT_VERSION} <= ${LINUX_HEADER_KERNEL_VERSION_LIMIT}" | bc -l))); then
        if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "neon" ]; }; then
          apt-get update
          apt-get install linux-headers-"$(uname -r)" -y
        elif [ "${DISTRO}" == "raspbian" ]; then
          apt-get update
          apt-get install raspberrypi-kernel-headers -y
        elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; }; then
          pacman -Syu --noconfirm --needed linux-headers
        elif [ "${DISTRO}" == "fedora" ]; then
          dnf update -y
          dnf install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" -y
        elif { [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
          yum update -y
          yum install kernel-headers-"$(uname -r)" kernel-devel-"$(uname -r)" -y
        fi
      else
        echo "Correct: You do not need kernel headers." >/dev/null 2>&1
      fi
    fi
  }

  # Kernel Version
  install-kernel-headers

  # Install WireGuard Server
  function install-wireguard-server() {
    if { [ ! -x "$(command -v wg)" ] || [ ! -x "$(command -v qrencode)" ]; }; then
      if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
        if [ "${DISTRO}" == "ubuntu" ] && { [ "${DISTRO_VERSION}" == "21.10" ] || [ "${DISTRO_VERSION}" == "21.04" ] || [ "${DISTRO_VERSION}" == "20.10" ] || [ "${DISTRO_VERSION}" == "20.04" ] || [ "${DISTRO_VERSION}" == "19.10" ]; }; then
          apt-get update
          apt-get install wireguard qrencode haveged ifupdown resolvconf -y
        elif [ "${DISTRO}" == "ubuntu" ] && { [ "${DISTRO_VERSION}" == "16.04" ] || [ "${DISTRO_VERSION}" == "18.04" ]; }; then
          apt-get update
          apt-get install software-properties-common -y
          add-apt-repository ppa:wireguard/wireguard -y
          apt-get update
          apt-get install wireguard qrencode haveged ifupdown resolvconf -y
        elif { [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "neon" ]; }; then
          apt-get update
          apt-get install wireguard qrencode haveged ifupdown resolvconf -y
        elif { [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "kali" ]; }; then
          apt-get update
          if [ ! -f "/etc/apt/sources.list.d/unstable.list" ]; then
            echo "deb http://deb.debian.org/debian/ unstable main" >>/etc/apt/sources.list.d/unstable.list
          fi
          if [ ! -f "/etc/apt/preferences.d/limit-unstable" ]; then
            printf "Package: *\nPin: release a=unstable\nPin-Priority: 90\n" >>/etc/apt/preferences.d/limit-unstable
          fi
          apt-get update
          apt-get install wireguard qrencode haveged ifupdown resolvconf -y
        elif [ "${DISTRO}" == "raspbian" ]; then
          apt-get update
          apt-get install dirmngr -y
          apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
          if [ ! -f "/etc/apt/sources.list.d/unstable.list" ]; then
            echo "deb http://deb.debian.org/debian/ unstable main" >>/etc/apt/sources.list.d/unstable.list
          fi
          if [ ! -f "/etc/apt/preferences.d/limit-unstable" ]; then
            printf "Package: *\nPin: release a=unstable\nPin-Priority: 90\n" >>/etc/apt/preferences.d/limit-unstable
          fi
          apt-get update
          apt-get install wireguard qrencode haveged ifupdown resolvconf -y
        elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; }; then
          pacman -Syu --noconfirm --needed haveged qrencode openresolv wireguard-tools
        elif [ "${DISTRO}" = "fedora" ] && [ "${DISTRO_VERSION}" == "32" ]; then
          dnf update -y
          dnf install qrencode wireguard-tools haveged resolvconf -y
        elif [ "${DISTRO}" = "fedora" ] && { [ "${DISTRO_VERSION}" == "30" ] || [ "${DISTRO_VERSION}" == "31" ]; }; then
          dnf update -y
          dnf copr enable jdoss/wireguard -y
          dnf install qrencode wireguard-dkms wireguard-tools haveged resolvconf -y
        elif [ "${DISTRO}" == "centos" ] && { [ "${DISTRO_VERSION}" == "8" ] || [ "${DISTRO_VERSION}" == "8.1" ] || [ "${DISTRO_VERSION}" == "8.2" ]; }; then
          yum update -y
          yum install elrepo-release epel-release -y
          yum install kmod-wireguard wireguard-tools qrencode haveged -y
        elif [ "${DISTRO}" == "centos" ] && [ "${DISTRO_VERSION}" == "7" ]; then
          yum update -y
          if [ ! -f "/etc/yum.repos.d/wireguard.repo" ]; then
            curl https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo --create-dirs -o /etc/yum.repos.d/wireguard.repo
          fi
          yum update -y
          yum install wireguard-dkms wireguard-tools qrencode haveged resolvconf -y
        elif [ "${DISTRO}" == "rhel" ] && [ "${DISTRO_VERSION}" == "8" ]; then
          yum update -y
          yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
          yum update -y
          subscription-manager repos --enable codeready-builder-for-rhel-8-"$(arch)"-rpms
          yum copr enable jdoss/wireguard
          yum install epel-release wireguard-dkms wireguard-tools qrencode haveged resolvconf -y
        elif [ "${DISTRO}" == "rhel" ] && [ "${DISTRO_VERSION}" == "7" ]; then
          yum update -y
          if [ ! -f "/etc/yum.repos.d/wireguard.repo" ]; then
            curl https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo --create-dirs -o /etc/yum.repos.d/wireguard.repo
          fi
          yum update -y
          yum install epel-release wireguard-dkms wireguard-tools qrencode haveged resolvconf -y
        elif [ "${DISTRO}" == "alpine" ]; then
          apk update
          apk add wireguard-tools libqrencode haveged
        elif [ "${DISTRO}" == "freebsd" ]; then
          pkg update
          pkg install wireguard libqrencode
        fi
      fi
    fi
  }

  # Install WireGuard Server
  install-wireguard-server

  function install-coredns-server() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      if [ "${INSTALL_COREDNS}" = "y" ]; then
        if [ ! -x "$(command -v coredns)" ]; then
          # Download Coredns
          mkdir -P ${COREDNS_ROOT}
          # Coredns Config
          if [ "${INSTALL_BLOCK_LIST}" = "y" ]; then
            echo ". {
    bind 127.0.0.1 ::1
    acl {
        allow net 127.0.0.1 ${IPV4_SUBNET} ${IPV6_SUBNET}
        block
    }
    hosts ${COREDNS_HOSTFILE} {
        fallthrough
    }
    forward . tls://1.1.1.1 tls://1.0.0.1 {
        tls_servername cloudflare-dns.com
        health_check 5s
    }
    any
    errors
    loop
    cache
    minimal
    reload
}" >>${COREDNS_CONFIG}
            curl -o ${COREDNS_HOSTFILE} ${CONTENT_BLOCKER_URL}
            sed -i -e "s/^/0.0.0.0 /" ${COREDNS_HOSTFILE}
          else
            echo ". {
    bind 127.0.0.1 ::1
    acl {
        allow net 127.0.0.1 ${IPV4_SUBNET} ${IPV6_SUBNET}
        block
    }
    forward . tls://1.1.1.1 tls://1.0.0.1 {
        tls_servername cloudflare-dns.com
        health_check 5s
    }
    any
    errors
    loop
    cache
    minimal
    reload
}" >>${COREDNS_CONFIG}
          fi
          if [ ! -f "${COREDNS_SERVICE_FILE}" ]; then
            echo "[Unit]
Description=CoreDNS DNS server
After=network.target

[Service]
Type=simple
ExecStart=${COREDNS_BUILD} -conf=${COREDNS_CONFIG}
Restart=on-failure

[Install]
WantedBy=multi-user.target" >>${COREDNS_SERVICE_FILE}
            systemctl daemon-reload
            if pgrep systemd-journal; then
              systemctl enable coredns
              systemctl start coredns
            else
              service coredns enable
              service coredns start
            fi
          fi
          if [ -f "${RESOLV_CONFIG}" ]; then
            chattr -i ${RESOLV_CONFIG}
            mv ${RESOLV_CONFIG} ${RESOLV_CONFIG_OLD}
            echo "nameserver 127.0.0.1" >>${RESOLV_CONFIG}
            echo "nameserver ::1" >>${RESOLV_CONFIG}
            chattr +i ${RESOLV_CONFIG}
          else
            echo "nameserver 127.0.0.1" >>${RESOLV_CONFIG}
            echo "nameserver ::1" >>${RESOLV_CONFIG}
          fi
          echo "Coredns: true" >>${COREDNS_MANAGER}
        fi
      fi
    fi
  }

  # Install WireGuard manager config
  function install-wireguard-manager-file() {
    if [ -d "${WIREGUARD_PATH}" ]; then
      if [ ! -f "${WIREGUARD_MANAGER}" ]; then
        echo "WireGuard: true" >>${WIREGUARD_MANAGER}
      fi
    fi
  }

  # WireGuard manager config
  install-wireguard-manager-file

  # WireGuard Set Config
  function wireguard-setconf() {
    if [ -f "${WIREGUARD_INTERFACE}" ]; then
      SERVER_PRIVKEY=$(wg genkey)
      SERVER_PUBKEY=$(echo "${SERVER_PRIVKEY}" | wg pubkey)
      CLIENT_PRIVKEY=$(wg genkey)
      CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
      CLIENT_ADDRESS_V4="${PRIVATE_SUBNET_V4::-4}3"
      CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-4}3"
      PRESHARED_KEY=$(wg genpsk)
      PEER_PORT=$(shuf -i1024-65535 -n1)
      mkdir -p ${WIREGUARD_CLIENT_PATH}
      touch ${WIREGUARD_CONFIG} && chmod 600 ${WIREGUARD_CONFIG}
      if [ -f "${COREDNS_MANAGER}" ]; then
        IPTABLES_POSTUP="iptables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; iptables -A INPUT -s ${PRIVATE_SUBNET_V4} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT; ip6tables -A INPUT -s ${PRIVATE_SUBNET_V6} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT"
        IPTABLES_POSTDOWN="iptables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; iptables -D INPUT -s ${PRIVATE_SUBNET_V4} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT; ip6tables -D INPUT -s ${PRIVATE_SUBNET_V6} -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT"
      else
        IPTABLES_POSTUP="iptables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -A FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
        IPTABLES_POSTDOWN="iptables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${WIREGUARD_PUB_NIC} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE"
      fi
      # Set WireGuard settings for this host and first peer.
      echo "# ${PRIVATE_SUBNET_V4} ${PRIVATE_SUBNET_V6} ${SERVER_HOST}:${SERVER_PORT} ${SERVER_PUBKEY} ${CLIENT_DNS} ${MTU_CHOICE} ${NAT_CHOICE} ${CLIENT_ALLOWED_IP}
# ${TWILIO_ACCOUNT_SID} ${TWILIO_AUTH_TOKEN} ${TWILIO_FROM_NUMBER} ${TWILIO_TO_NUMBER}
[Interface]
Address = ${GATEWAY_ADDRESS_V4}/${PRIVATE_SUBNET_MASK_V4},${GATEWAY_ADDRESS_V6}/${PRIVATE_SUBNET_MASK_V6}
DNS = ${CLIENT_DNS}
ListenPort = ${SERVER_PORT}
MTU = ${MTU_CHOICE}
PrivateKey = ${SERVER_PRIVKEY}
PostUp = ${IPTABLES_POSTUP}
PostDown = ${IPTABLES_POSTDOWN}
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
MTU = ${MTU_CHOICE}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = ${CLIENT_ALLOWED_IP}
Endpoint = ${SERVER_HOST}:${SERVER_PORT}
PersistentKeepalive = ${NAT_CHOICE}
PresharedKey = ${PRESHARED_KEY}
PublicKey = ${SERVER_PUBKEY}" >>${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      # Service Restart
      if pgrep systemd-journal; then
        systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
        systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
        systemctl reenable ntp
        systemctl restart ntp
      else
        service wg-quick@${WIREGUARD_PUB_NIC} enable
        service wg-quick@${WIREGUARD_PUB_NIC} restart
        service ntp enable
        service ntp restart
      fi
      ntpq -p
      # Generate QR Code
      qrencode -t ansiutf8 -l L <${WIREGUARD_CLIENT_PATH}/"${CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
      echo "Client Config --> ${WIREGUARD_CLIENT_PATH}/${CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
    fi
  }

  # Setting Up WireGuard Config
  wireguard-setconf

# After WireGuard Install
else

  # Already installed what next?
  function wireguard-next-questions-interface() {
    if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
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
      echo "   12) Check WireGuard Status"
      until [[ "${WIREGUARD_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${WIREGUARD_OPTIONS}" -ge 1 ] && [ "${WIREGUARD_OPTIONS}" -le 12 ]; do
        read -rp "Select an Option [1-12]: " -e -i 1 WIREGUARD_OPTIONS
      done
      case ${WIREGUARD_OPTIONS} in
      1) # WG Show
        if [ -x "$(command -v wg)" ]; then
          wg show
        fi
        ;;
      2) # Enable & Start WireGuard
        if [ -x "$(command -v wg)" ]; then
          if pgrep systemd-journal; then
            systemctl enable wg-quick@${WIREGUARD_PUB_NIC}
            systemctl start wg-quick@${WIREGUARD_PUB_NIC}
          else
            service wg-quick@${WIREGUARD_PUB_NIC} enable
            service wg-quick@${WIREGUARD_PUB_NIC} start
          fi
        fi
        ;;
      3) # Disable & Stop WireGuard
        if [ -x "$(command -v wg)" ]; then
          if pgrep systemd-journal; then
            systemctl disable wg-quick@${WIREGUARD_PUB_NIC}
            systemctl stop wg-quick@${WIREGUARD_PUB_NIC}
          else
            service wg-quick@${WIREGUARD_PUB_NIC} disable
            service wg-quick@${WIREGUARD_PUB_NIC} stop
          fi
        fi
        ;;
      4) # Restart WireGuard
        if [ -x "$(command -v wg)" ]; then
          if pgrep systemd-journal; then
            systemctl start wg-quick@${WIREGUARD_PUB_NIC}
          else
            service wg-quick@${WIREGUARD_PUB_NIC} start
          fi
        fi
        ;;
      5) # WireGuard add Peer
        if [ -f "${WIREGUARD_INTERFACE}" ]; then
          if { [ -x "$(command -v wg)" ] || [ -x "$(command -v qrencode)" ]; }; then
            if [ -z "${NEW_CLIENT_NAME}" ]; then
              echo "Let's name the WireGuard Peer. Use one word only, no special characters, no spaces."
              read -rp "New client peer: " -e NEW_CLIENT_NAME
            fi
            if [ -z "${NEW_CLIENT_NAME}" ]; then
              NEW_CLIENT_NAME="$(openssl rand -hex 50)"
            fi
            CLIENT_PRIVKEY=$(wg genkey)
            CLIENT_PUBKEY=$(echo "${CLIENT_PRIVKEY}" | wg pubkey)
            PRESHARED_KEY=$(wg genpsk)
            PEER_PORT=$(shuf -i1024-65535 -n1)
            PRIVATE_SUBNET_V4=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $2}')
            PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut -d "/" -f 2)
            PRIVATE_SUBNET_V6=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $3}')
            PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut -d "/" -f 2)
            SERVER_HOST=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $4}')
            SERVER_PUBKEY=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $5}')
            CLIENT_DNS=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $6}')
            MTU_CHOICE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $7}')
            NAT_CHOICE=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $8}')
            CLIENT_ALLOWED_IP=$(head -n1 ${WIREGUARD_CONFIG} | awk '{print $9}')
            LASTIPV4=$(grep "/32" ${WIREGUARD_CONFIG} | tail -n1 | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4)
            LASTIPV6=$(grep "/128" ${WIREGUARD_CONFIG} | tail -n1 | awk '{print $3}' | cut -d "/" -f 1 | cut -d "." -f 4)
            CLIENT_ADDRESS_V4="${PRIVATE_SUBNET_V4::-4}$((LASTIPV4 + 1))"
            CLIENT_ADDRESS_V6="${PRIVATE_SUBNET_V6::-4}$((LASTIPV6 + 1))"
            if [ "${LASTIPV4}" -ge "255" ]; then
              echo "Error: You have ${LASTIPV4} peers. The max is 255."
              exit
            fi
            echo "# ${NEW_CLIENT_NAME} start
[Peer]
PublicKey = ${CLIENT_PUBKEY}
PresharedKey = ${PRESHARED_KEY}
AllowedIPs = ${CLIENT_ADDRESS_V4}/32,${CLIENT_ADDRESS_V6}/128
# ${NEW_CLIENT_NAME} end" >${WIREGUARD_ADD_PEER_CONFIG}
            wg addconf ${WIREGUARD_PUB_NIC} ${WIREGUARD_ADD_PEER_CONFIG}
            cat ${WIREGUARD_ADD_PEER_CONFIG} >>${WIREGUARD_CONFIG}
            rm -f ${WIREGUARD_ADD_PEER_CONFIG}
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
            qrencode -t ansiutf8 -l L <${WIREGUARD_CLIENT_PATH}/"${NEW_CLIENT_NAME}"-${WIREGUARD_PUB_NIC}.conf
            echo "Client config --> ${WIREGUARD_CLIENT_PATH}/${NEW_CLIENT_NAME}-${WIREGUARD_PUB_NIC}.conf"
          fi
        fi
        ;;
      6) # Remove WireGuard Peer
        if [ -f "${WIREGUARD_INTERFACE}" ]; then
          if [ -x "$(command -v wg)" ]; then
            echo "Which WireGuard client do you want to remove?"
            # shellcheck disable=SC2002
            cat ${WIREGUARD_CONFIG} | grep start | awk '{ print $2 }'
            read -rp "Type in Client Name : " -e REMOVECLIENT
            read -rp "Are you sure you want to remove ${REMOVECLIENT} ? (y/n): " -n 1 -r
            if [[ ${REPLY} =~ ^[Yy]$ ]]; then
              CLIENTKEY=$(sed -n "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/p" ${WIREGUARD_CONFIG} | grep PublicKey | awk ' { print $3 } ')
              wg set ${WIREGUARD_PUB_NIC} peer "${CLIENTKEY}" remove
              sed -i "/\# ${REMOVECLIENT} start/,/\# ${REMOVECLIENT} end/d" ${WIREGUARD_CONFIG}
              rm -f ${WIREGUARD_CLIENT_PATH}/"${REMOVECLIENT}"-${WIREGUARD_PUB_NIC}.conf
              echo "Client ${REMOVECLIENT} has been removed."
            elif [[ ${REPLY} =~ ^[Nn]$ ]]; then
              exit
            fi
            wg addconf ${WIREGUARD_PUB_NIC} <(wg-quick strip ${WIREGUARD_PUB_NIC})
          fi
        fi
        ;;
      7) # Reinstall WireGuard
        if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "neon" ]; }; then
          dpkg-reconfigure wireguard-dkms
          modprobe wireguard
          systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
          systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
        elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
          yum reinstall wireguard-tools -y
          service wg-quick@${WIREGUARD_PUB_NIC} restart
        elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; }; then
          pacman -S --noconfirm wireguard-tools
          systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
          systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
        elif [ "${DISTRO}" == "alpine" ]; then
          apk fix wireguard-tools
        elif [ "${DISTRO}" == "freebsd" ]; then
          pkg check wireguard
        fi
        ;;
      8) # Uninstall WireGuard and purging files
        if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
          if [ -x "$(command -v wg)" ]; then
            if pgrep systemd-journal; then
              systemctl disable wg-quick@${WIREGUARD_PUB_NIC}
              systemctl stop wg-quick@${WIREGUARD_PUB_NIC}
              wg-quick down ${WIREGUARD_PUB_NIC}
            else
              service wg-quick@${WIREGUARD_PUB_NIC} disable
              service wg-quick@${WIREGUARD_PUB_NIC} stop
              wg-quick down ${WIREGUARD_PUB_NIC}
            fi
            # Removing Wireguard Files
            if [ -d "${WIREGUARD_PATH}" ]; then
              rm -rf ${WIREGUARD_PATH}
            fi
            if [ -d "${WIREGUARD_CLIENT_PATH}" ]; then
              rm -rf ${WIREGUARD_CLIENT_PATH}
            fi
            if [ -f "${WIREGUARD_CONFIG}" ]; then
              rm -f ${WIREGUARD_CONFIG}
            fi
            if [ -f "${WIREGUARD_IP_FORWARDING_CONFIG}" ]; then
              rm -f ${WIREGUARD_IP_FORWARDING_CONFIG}
            fi
            if [ "${DISTRO}" == "centos" ]; then
              yum remove wireguard qrencode haveged -y
            elif { [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "kali" ]; }; then
              apt-get remove --purge wireguard qrencode -y
              if [ -f "/etc/apt/sources.list.d/unstable.list" ]; then
                rm -f /etc/apt/sources.list.d/unstable.list
              fi
              if [ -f "/etc/apt/preferences.d/limit-unstable" ]; then
                rm -f /etc/apt/preferences.d/limit-unstable
              fi
            elif { [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "neon" ]; }; then
              apt-get remove --purge wireguard qrencode haveged -y
            elif [ "${DISTRO}" == "ubuntu" ]; then
              apt-get remove --purge wireguard qrencode haveged -y
              if pgrep systemd-journal; then
                systemctl reenable systemd-resolved
                systemctl restart systemd-resolved
              else
                service systemd-resolved enable
                service systemd-resolved restart
              fi
            elif [ "${DISTRO}" == "raspbian" ]; then
              apt-key del 04EE7237B7D453EC
              apt-get remove --purge wireguard qrencode haveged dirmngr -y
              if [ -f "/etc/apt/sources.list.d/unstable.list" ]; then
                rm -f /etc/apt/sources.list.d/unstable.list
              fi
              if [ -f "/etc/apt/preferences.d/limit-unstable" ]; then
                rm -f /etc/apt/preferences.d/limit-unstable
              fi
            elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "archarm" ] || [ "${DISTRO}" == "manjaro" ]; }; then
              pacman -Rs --noconfirm wireguard-tools qrencode haveged
            elif [ "${DISTRO}" == "fedora" ]; then
              dnf remove wireguard qrencode haveged -y
              if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
                rm -f /etc/yum.repos.d/wireguard.repo
              fi
            elif [ "${DISTRO}" == "rhel" ]; then
              yum remove wireguard qrencode haveged -y
              if [ -f "/etc/yum.repos.d/wireguard.repo" ]; then
                rm -f /etc/yum.repos.d/wireguard.repo
              fi
            elif [ "${DISTRO}" == "alpine" ]; then
              apk del wireguard-tools libqrencode haveged
            elif [ "${DISTRO}" == "freebsd" ]; then
              pkg delete wireguard libqrencode
            fi
          fi
        fi
        # Delete WireGuard backup
        if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
          read -rp "Are you sure you want to remove WireGuard backup? (y/n): " -n 1 -r
          if [[ ${REPLY} =~ ^[Yy]$ ]]; then
            rm -f ${WIREGUARD_CONFIG_BACKUP}
            if [ -f "${WIREGUARD_BACKUP_PASSWORD_PATH}" ]; then
              rm -f "${WIREGUARD_BACKUP_PASSWORD_PATH}"
            fi
          elif [[ ${REPLY} =~ ^[Nn]$ ]]; then
            exit
          fi
        fi
        # Delete crontab
        if [ -x "$(command -v cron)" ]; then
          crontab -r
        fi
        # Completely remove coredns and the service.
        if [ -d "${COREDNS_ROOT}" ]; then
          rm -rf ${COREDNS_ROOT}
          # Remove the coredns service from your system.
          if [ -f "${COREDNS_SERVICE_FILE}" ]; then
            rm -f ${COREDNS_SERVICE_FILE}
          fi
        fi
        ;;
      9) # Update the script
        if [ -x "$(command -v wg)" ]; then
          CURRENT_FILE_PATH="$(realpath "$0")"
          if [ -f "${CURRENT_FILE_PATH}" ]; then
            curl -o "${CURRENT_FILE_PATH}" ${WIREGUARD_MANAGER_UPDATE}
            chmod +x "${CURRENT_FILE_PATH}" || exit
          fi
        fi
        # The block list should be updated.
        if [ -f "${COREDNS_HOSTFILE}" ]; then
          rm -f ${COREDNS_HOSTFILE}
          curl -o ${COREDNS_HOSTFILE} ${CONTENT_BLOCKER_URL}
          sed -i -e "s/^/0.0.0.0 /" ${COREDNS_HOSTFILE}
        fi
        ;;
      10) # Backup WireGuard Config
        if [ -x "$(command -v wg)" ]; then
          if [ -d "${WIREGUARD_PATH}" ]; then
            if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
              rm -f ${WIREGUARD_CONFIG_BACKUP}
            fi
            if [ -f "${WIREGUARD_BACKUP_PASSWORD_PATH}" ]; then
              rm -f "${WIREGUARD_BACKUP_PASSWORD_PATH}"
            fi
            if [ -f "${WIREGUARD_MANAGER}" ]; then
              BACKUP_PASSWORD="$(openssl rand -hex 25)"
              echo "${BACKUP_PASSWORD}" >>"${WIREGUARD_BACKUP_PASSWORD_PATH}"
              zip -P "${BACKUP_PASSWORD}" -rj ${WIREGUARD_CONFIG_BACKUP} ${WIREGUARD_CONFIG} ${WIREGUARD_MANAGER} ${WIREGUARD_INTERFACE} ${WIREGUARD_PEER}
            else
              exit
            fi
          fi
        fi
        ;;
      11) # Restore WireGuard Config
        if [ -f "${WIREGUARD_CONFIG_BACKUP}" ]; then
          if [ -d "${WIREGUARD_PATH}" ]; then
            rm -rf ${WIREGUARD_PATH}
          fi
          if [ -x "$(command -v wg)" ]; then
            unzip ${WIREGUARD_CONFIG_BACKUP} -d ${WIREGUARD_PATH}
          else
            exit
          fi
          # Restart WireGuard
          if pgrep systemd-journal; then
            systemctl reenable wg-quick@${WIREGUARD_PUB_NIC}
            systemctl restart wg-quick@${WIREGUARD_PUB_NIC}
          else
            service wg-quick@${WIREGUARD_PUB_NIC} enable
            service wg-quick@${WIREGUARD_PUB_NIC} restart
          fi
        fi
        ;;
      12)
        if { [ -f "${WIREGUARD_INTERFACE}" ] || [ -f "${WIREGUARD_PEER}" ]; }; then
          TWILIO_ACCOUNT_SID=$(head -2 ${WIREGUARD_CONFIG} | tail +2 | awk '{print $1}')
          TWILIO_AUTH_TOKEN=$(head -2 ${WIREGUARD_CONFIG} | tail +2 | awk '{print $2}')
          TWILIO_FROM_NUMBER=$(head -2 ${WIREGUARD_CONFIG} | tail +2 | awk '{print $3}')
          TWILIO_TO_NUMBER=$(head -2 ${WIREGUARD_CONFIG} | tail +2 | awk '{print $4}')
          if [ -x "$(command -v wg)" ]; then
            if [ "$(systemctl is-active wg-quick@"${WIREGUARD_PUB_NIC}")" == "inactive" ]; then
              if { [ -n "${TWILIO_ACCOUNT_SID}" ] && [ -n "${TWILIO_AUTH_TOKEN}" ] && [ -n "${TWILIO_FROM_NUMBER}" ] && [ -n "${TWILIO_TO_NUMBER}" ]; }; then
                curl -X POST https://api.twilio.com/2010-04-01/Accounts/"${TWILIO_ACCOUNT_SID}"/Messages.json --data-urlencode "Body=Hello, WireGuard has gone down ${SERVER_HOST}." --data-urlencode "From=${TWILIO_FROM_NUMBER}" --data-urlencode "To=${TWILIO_TO_NUMBER}" -u "${TWILIO_ACCOUNT_SID}":"${TWILIO_AUTH_TOKEN}"
              fi
            fi
          fi
        fi
        ;;
      esac
    fi
  }

  # Running Questions Command
  wireguard-next-questions-interface

fi
