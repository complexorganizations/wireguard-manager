```bash
#!/usr/bin/env bash
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

# Get the current system information
function system-information() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        CURRENT_DISTRO=${ID}
        CURRENT_DISTRO_VERSION=${VERSION_ID}
    fi
}

# Get the current system information
system-information

# Pre-Checks system requirements
function installing-system-requirements() {
    if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ]; }; then
        if [ ! -x "$(command -v curl)" ]; then
            if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
                apt-get update
                apt-get install curl -y
            elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
                yum update
                yum install curl -y
            elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
                pacman -Syu --noconfirm --needed curl
            elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
                apk update
                apk add curl
            elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
                pkg update
                pkg install curl
            fi
        fi
    else
        echo "Error: ${CURRENT_DISTRO} is not supported."
        exit
    fi
}

# Run the function and check for requirements
installing-system-requirements

# Save the script
function save-the-script() {
    WIREGUARD_MANAGER_UPDATE="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh"
    WIREGUARD_MANAGER_PATH="/usr/local/bin/wireguard-manager.sh"
    if [ ! -f "${WIREGUARD_MANAGER_PATH}" ]; then
        curl -o "${WIREGUARD_MANAGER_PATH}" ${WIREGUARD_MANAGER_UPDATE}
        chmod +x "${WIREGUARD_MANAGER_PATH}" || exit
    fi
}

# Run the function to save the script
save-the-script
```
