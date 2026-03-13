### WireGuard Manager Installation Guide for Rocky Linux

#### Prerequisites

- A system running Rocky Linux.
- Sudo or root privileges.
- A stable internet connection.
- Basic knowledge of Linux terminal and command-line operations.

#### 1. System Update and Upgrade

- Start by ensuring your Rocky Linux system is fully updated for security and functionality:
  ```bash
  sudo dnf update -y
  ```
- This step updates all installed packages to their latest versions and is crucial for maintaining system integrity.

#### 2. Installing Necessary Tools and Dependencies

- Rocky Linux may require some additional tools for a smooth WireGuard installation. Begin by installing the EPEL repository:
  ```bash
  sudo dnf install epel-release -y
  ```
- Install Curl, a tool for downloading files from the internet:
  ```bash
  sudo dnf install curl -y
  ```

#### 3. Downloading the WireGuard Manager Script

- The WireGuard Manager script automates the installation and setup of WireGuard:
  ```bash
  curl -L https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh -o /usr/local/bin/wireguard-manager.sh
  ```
- This command downloads the script to a standard location, making it easily accessible for execution.

#### 4. Running the Installation Script

- Adjust the script permissions to make it executable:
  ```bash
  chmod +x /usr/local/bin/wireguard-manager.sh
  ```
- Execute the script to initiate the WireGuard installation process:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- The script will guide you through various configuration steps, including server setup and client management.

#### 5. Configuring and Managing the WireGuard VPN

- For configuration adjustments or to manage VPN clients, rerun the script:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- This command allows you to add or remove clients, change server settings, and perform other management tasks.

#### 6. Validating the VPN Setup

- Testing the VPN connection is vital to confirm successful installation:
  - Connect to the VPN using the client configuration files.
  - Verify the status of the WireGuard interface:
    ```bash
    sudo wg show
    ```

#### 7. Routine Maintenance and Security

- Regularly updating your Rocky Linux system and WireGuard ensures security and efficiency:
  - Periodically perform system updates:
    ```bash
    sudo dnf update -y
    ```
  - Consistently review and update your WireGuard configurations and security settings.

#### Conclusion

This detailed guide outlines the process for installing and configuring WireGuard Manager on Rocky Linux. Adhering to regular updates, maintaining vigilant configuration management, and following security best practices are crucial for a secure and reliable VPN service.
