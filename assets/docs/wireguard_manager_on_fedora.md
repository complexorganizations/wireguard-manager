### WireGuard Manager Installation Guide for Fedora

#### Prerequisites

- A Fedora system.
- Sudo privileges.
- Internet connection.

#### 1. System Update

- Begin by updating your Fedora system:
  ```bash
  sudo dnf update -y
  ```

#### 2. Install Required Packages

- Fedora uses `dnf` as its package manager. Install necessary tools including Curl:
  ```bash
  sudo dnf install curl -y
  ```

#### 3. Download the WireGuard Manager Script

- Use Curl to download the WireGuard Manager script:
  ```bash
  curl -L https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh -o /usr/local/bin/wireguard-manager.sh
  ```

#### 4. Make the Script Executable and Run It

- Change the script's permissions to make it executable:
  ```bash
  chmod +x /usr/local/bin/wireguard-manager.sh
  ```
- Execute the script to begin the installation process:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- Follow the prompts to install and configure WireGuard.

#### 5. Configuring and Managing WireGuard

- To configure or manage WireGuard VPN, rerun the script:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```

#### 6. Testing and Validation

- Test the VPN connection using the configuration files provided for the client devices.
- Check the status of the WireGuard interface with:
  ```bash
  sudo wg show
  ```

#### Conclusion

This guide outlines the procedure for installing and managing WireGuard Manager on a Fedora system. Regular system updates and WireGuard management are essential for maintaining a secure and efficient VPN.
