Sure, let's start with creating a detailed installation guide for each distribution. We'll begin with AlmaLinux.

---

### WireGuard Manager Installation Guide for AlmaLinux

#### Prerequisites

- A system running AlmaLinux.
- Sudo privileges.
- Internet connection.

#### 1. System Update

- Begin by updating your system to ensure all packages are up to date:
  ```bash
  sudo dnf update -y
  ```

#### 2. Install Required Packages

- Install EPEL (Extra Packages for Enterprise Linux) repository, which contains additional packages, including those required for WireGuard:
  ```bash
  sudo dnf install epel-release -y
  ```
- Install necessary tools including Curl:
  ```bash
  sudo dnf install curl -y
  ```

#### 3. Download the WireGuard Manager Script

- Use Curl to download the script:
  ```bash
  curl -L https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh -o /usr/local/bin/wireguard-manager.sh
  ```
- This command places the script in a globally accessible location.

#### 4. Make the Script Executable and Run It

- Change the script's permissions to make it executable:
  ```bash
  chmod +x /usr/local/bin/wireguard-manager.sh
  ```
- Run the script to start the installation:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- Follow the on-screen instructions for installation and initial setup.

#### 5. Configuring and Managing WireGuard

- To configure or manage WireGuard VPN, re-run the script:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- Choose the appropriate options to add clients, remove clients, or adjust settings.

#### 6. Testing and Validation

- After setting up, test the VPN connection using the configuration files on the client devices.
- Ensure WireGuard is functioning correctly with:
  ```bash
  sudo wg show
  ```

#### Conclusion

This guide provides a comprehensive approach to setting up WireGuard Manager on AlmaLinux. Regular system and WireGuard updates are crucial for security and performance.