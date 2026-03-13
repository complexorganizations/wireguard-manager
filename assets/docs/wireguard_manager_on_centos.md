### WireGuard Manager Installation Guide for CentOS

#### Prerequisites

- A CentOS system (CentOS 7 or later recommended).
- Sudo privileges.
- Internet connection.

#### 1. System Update

- Start by updating your CentOS system to ensure all packages are current:
  ```bash
  sudo yum update -y
  ```

#### 2. Install EPEL Repository and Required Packages

- CentOS often requires the EPEL (Extra Packages for Enterprise Linux) repository for additional packages:
  ```bash
  sudo yum install epel-release -y
  ```
- Install essential tools including Curl:
  ```bash
  sudo yum install curl -y
  ```

#### 3. Download the WireGuard Manager Script

- Utilize Curl to download the WireGuard Manager script:
  ```bash
  curl -L https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh -o /usr/local/bin/wireguard-manager.sh
  ```

#### 4. Make the Script Executable and Run It

- Adjust the script's permissions to make it executable:
  ```bash
  chmod +x /usr/local/bin/wireguard-manager.sh
  ```
- Run the script to initiate the installation process:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```
- Follow the on-screen prompts to complete the WireGuard installation.

#### 5. Configuring and Managing WireGuard

- To manage your WireGuard configuration or add VPN clients, rerun the script:
  ```bash
  sudo bash /usr/local/bin/wireguard-manager.sh
  ```

#### 6. Testing and Validation

- After setting up, test the VPN connection using the generated configuration files on your client devices.
- Check the status of the WireGuard interface:
  ```bash
  sudo wg show
  ```

#### Conclusion

This guide details the steps for installing and managing WireGuard Manager on a CentOS system. Regular updates and security checks are recommended to maintain a robust and efficient VPN network.
