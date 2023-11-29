# WireGuard-Manager: Secure Your Network 👋

### 🔰 Introduction

Welcome to WireGuard-Manager, where we prioritize your privacy and offer a robust solution for your VPN needs. Our tool simplifies setting up WireGuard, a cutting-edge VPN protocol known for its speed and security.

### Quality and Reliability

- **Releases Status**: Stay updated with our latest releases: ![Release Badge](https://img.shields.io/github/v/release/complexorganizations/wireguard-manager)
- **Code Quality**: Assured by ShellCheck. ![ShellCheck Badge](https://github.com/complexorganizations/wireguard-manager/workflows/ShellCheck/badge.svg)
- **Build Status**: Monitored by GitHub Actions. ![Auto-Build Badge](https://github.com/complexorganizations/wireguard-manager/actions/workflows/wireguard-manager.yml/badge.svg)
- **Build Status**: Stay updated on our automated build process. [![Auto-Build Status](https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-build.yml/badge.svg)](https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-build.yml)
- **Update Status**: Track our automated updates. [![Auto-Update Status](https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-update-named-cache.yml/badge.svg)](https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-update-named-cache.yml)
- **Code Quality**: Our commitment to code quality with ShellCheck. [![ShellCheck Status](https://github.com/complexorganizations/wireguard-manager/actions/workflows/pages.yml/badge.svg)](https://github.com/complexorganizations/wireguard-manager/actions/workflows/pages.yml)
- **Issue Tracking**: Current open issues. [![Open Issues](https://img.shields.io/github/issues/complexorganizations/wireguard-manager)](https://github.com/complexorganizations/wireguard-manager/issues)
- **Contribution Opportunities**: Explore and contribute to our open pull requests. [![Pull Requests](https://img.shields.io/github/issues-pr/complexorganizations/wireguard-manager)](https://github.com/complexorganizations/wireguard-manager/pulls)
- **Project License**: Licensed under [Apache 2.0]. [![License](https://img.shields.io/github/license/complexorganizations/wireguard-manager)](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/.github/LICENSE)

### ✊ Show Your Support

If you've found this project useful, please consider giving it a star ⭐️ and forking it 🍴, Your support is greatly appreciated!

---

### 🤷 What is VPN ?

A Virtual Private Network (VPN) allows users to send and receive data through shared or public networks as if their computing devices were directly connected to the private network. Thus, applications running on an end-system (PC, smartphone, etc.) over a VPN may benefit from individual network features, protection, and management. Encryption is a standard aspect of a VPN connection but not an intrinsic one.

### 📶 What is WireGuard❓

WireGuard is a straightforward yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general-purpose VPN for running on embedded interfaces and super computers alike, fit for many circumstances. Initially released for the Linux kernel, it is now cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable. It is currently under a massive development, but it already might be regarded as the most secure, most comfortable to use, and the simplest VPN solution in the industry.

### 💻 Why WireGuard-Manager?

- **Security First**: With top-notch encryption and privacy features.
- **User-Friendly**: Easy to install and manage, regardless of your tech-savviness.
- **High Performance**: Enjoy fast and reliable connections.
- **Open Source**: Built and improved by the community.

### ⛳ Goals

- robust and modern security by default
- minimal config and critical management
- fast, both low-latency and high-bandwidth
- simple internals and small protocol surface area
- simple CLI and seamless integration with system networking

---

### 🌲 Prerequisite

- Alma, Alpine, Arch, Archarm, CentOS, Debian, Fedora, FreeBSD, Kali, Mint, Manjaro, Neon, Oracle, Pop, Raspbian, RHEL, Rocky, Ubuntu
- Linux `Kernel 3.1` or newer
- You will need superuser access or a user account with `sudo` privilege.

---

### 🚦 Getting Started

1. **Installation**: Simple and quick installation process.
2. **Configuration**: Easy-to-follow configuration steps.
3. **Management**: User-friendly interface for managing your VPN.

---

### 🐧 Installation

Lets first use `curl` and save the file in `/usr/local/bin/`

```bash
curl https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh --create-dirs -o /usr/local/bin/wireguard-manager.sh
```

Then let's make the script user executable

```bash
chmod +x /usr/local/bin/wireguard-manager.sh
```

It's finally time to execute the script

```bash
bash /usr/local/bin/wireguard-manager.sh
```

In your `/etc/wireguard/clients` directory, you will have `.conf` files. These are the peer configuration files. Download them from your WireGuard Interface and connect using your favorite WireGuard Peer.

---

### 💣 After Installation

- Show WireGuard Interface
- Start WireGuard Interface
- Stop WireGuard Interface
- Restart WireGuard Interface
- Add WireGuard Peer
- Remove WireGuard Peer
- Uninstall WireGuard Interface
- Update this script
- Encrypt & Backup Configs
- Restore WireGuard Configs

---

### 🔑 Usage

```
usage: ./wireguard-manager.sh <command>
  --install     Install WireGuard
  --start       Start WireGuard
  --stop        Stop WireGuard
  --restart     Restart WireGuard
  --list        Show WireGuard
  --add         Add WireGuard Peer
  --remove      Remove WireGuard Peer
  --reinstall   Reinstall WireGuard
  --uninstall   Uninstall WireGuard
  --update      Update WireGuard Manager
  --ddns        Update WireGuard IP Address
  --backup      Backup WireGuard
  --restore     Restore WireGuard
  --purge       Purge WireGuard Peer(s)
  --help        Show Usage Guide
```

---

### 🥰 Features

- Install & Configure WireGuard Interface
- Backup & Restore WireGuard
- Expiration of peer configurations on autopilot
- (IPv4|IPv6) Supported, Leak Protection
- Variety of Public DNS to be pushed to the peers
- Choice to use a self-hosted resolver with Unbound **Prevent DNS Leaks, DNSSEC Supported**
- Nftables rules and forwarding managed in a seamless way
- Remove & Uninstall WireGuard Interface
- Preshared-key for an extra layer of security. **Required**
- Many other little things!

---

### 💡 Options

- `PRIVATE_SUBNET_V4_SETTINGS` - Specifies the private IPv4 subnet to be used within the VPN. The default is `10.0.0.0/8`, which is a standard private IP range.
- `PRIVATE_SUBNET_V6_SETTINGS` - Defines the private IPv6 subnet. The default `fd00:00:00::0/8` is a typical private IPv6 range.
- `SERVER_HOST_V4_SETTINGS` - This setting is for detecting the public IPv4 address of the server, commonly used for establishing connections from outside the local network.
- `SERVER_HOST_V6_SETTINGS` - Similar to the IPv4 setting, but for detecting the server's public IPv6 address.
- `SERVER_PUB_NIC_SETTINGS` - Determines the local public network interface using the `ip` command. This is essential for the server to communicate on the public network.
- `SERVER_PORT_SETTINGS` - Specifies the default public port (`51820`) for the WireGuard interface. This is the port through which VPN traffic will pass.
- `NAT_CHOICE_SETTINGS` - Configures whether or not to use the VPN tunnel's keep-alive feature, which helps maintain the connection active.
- `MTU_CHOICE_SETTINGS` - Sets the Maximum Transmission Unit (MTU) for WireGuard peers. This value impacts the size of packets transmitted over the network.
- `SERVER_HOST_SETTINGS` - This might be a general setting for defining server-specific configurations, but it's not clear without more context.
- `CLIENT_ALLOWED_IP_SETTINGS` - Defines the IP range allowed for clients connecting to the VPN. This can restrict which devices can connect.
- `AUTOMATIC_UPDATES_SETTINGS` - Likely relates to whether the system will automatically update software or configurations.
- `AUTOMATIC_BACKUP_SETTINGS` - Pertains to the automatic backup of system configurations or data.
- `DNS_PROVIDER_SETTINGS` - Involves setting up a DNS provider for the network. If you're not using Unbound, you'll need to specify another DNS service.
- `CONTENT_BLOCKER_SETTINGS` - Might relate to settings for blocking certain types of content through the network.
- `CLIENT_NAME` - The name assigned to a WireGuard peer (client) in the VPN.
- `AUTOMATIC_CONFIG_REMOVER` - Possibly a setting to automatically remove certain configurations after they are no longer needed or after a set period.

---

### 👉👈 Compatibility with Linux Distro

| OS          | i386               | amd64              | armhf              | arm64              |
| ----------- | ------------------ | ------------------ | ------------------ | ------------------ |
| Ubuntu 14 ≤ | :x:                | :x:                | :x:                | :x:                |
| Ubuntu 16 ≥ | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Debian 7 ≤  | :x:                | :x:                | :x:                | :x:                |
| Debian 8 ≥  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| CentOS 6 ≤  | :x:                | :x:                | :x:                | :x:                |
| CentOS 7 ≥  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Fedora 29 ≤ | :x:                | :x:                | :x:                | :x:                |
| Fedora 30 ≥ | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| RedHat 6 ≤  | :x:                | :x:                | :x:                | :x:                |
| RedHat 7 ≥  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Kali 1.0 ≤  | :x:                | :x:                | :x:                | :x:                |
| Kali 1.1 ≥  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Arch        | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Raspbian    | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| PopOS       | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Manjaro     | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Mint        | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Alma        | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Alpine      | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| FreeBSD     | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Neon        | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Rocky       | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Oracle      | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |

### ☁️ Compatibility with Cloud Providers

| Cloud           | Supported          |
| --------------- | ------------------ |
| AWS             | :heavy_check_mark: |
| Google Cloud    | :heavy_check_mark: |
| Linode          | :heavy_check_mark: |
| Digital Ocean   | :heavy_check_mark: |
| Vultr           | :heavy_check_mark: |
| Microsoft Azure | :heavy_check_mark: |
| OpenStack       | :heavy_check_mark: |
| Rackspace       | :heavy_check_mark: |
| Scaleway        | :heavy_check_mark: |
| EuroVPS         | :heavy_check_mark: |
| Hetzner Cloud   | :x:                |
| Strato          | :x:                |

### 🛡️ Compatibility with Virtualization

| Virtualization | Supported          |
| -------------- | ------------------ |
| KVM            | :heavy_check_mark: |
| None           | :heavy_check_mark: |
| Qemu           | :heavy_check_mark: |
| LXC            | :heavy_check_mark: |
| Microsoft      | :heavy_check_mark: |
| Vmware         | :heavy_check_mark: |
| OpenVZ         | :x:                |
| Docker         | :x:                |
| WSL            | :x:                |

### 💻 Compatibility with Linux Kernel

| Kernel             | Supported          |
| ------------------ | ------------------ |
| Linux Kernel 3.0 ≤ | :x:                |
| Linux Kernel 3.1 ≥ | :heavy_check_mark: |

---

### 🙋 Q&A Session

**What hosting providers are recommended?**

- **Google Cloud**: Offers global locations and IPv4 support, prices start at $3.50/month. [Visit Google Cloud](https://cloud.google.com)
- **Amazon Web Services**: Provides global locations, IPv4 support, starting from $5.00/month. [Visit AWS](https://aws.amazon.com)
- **Microsoft Azure**: Features worldwide locations, IPv4 support, with plans beginning at $5.00/month. [Visit Azure](https://azure.microsoft.com)
- **Linode**: Includes global locations, supports both IPv4 & IPv6, starting at $5.00/month. [Visit Linode](https://www.linode.com)
- **Vultr**: Offers worldwide locations, supports IPv4 & IPv6, prices start at $3.50/month. [Visit Vultr](https://www.vultr.com)

**Which WireGuard clients are recommended?**

- **Windows**: Download WireGuard [here](https://www.wireguard.com/install).
- **Android**: Get WireGuard from the [Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android).
- **macOS**: WireGuard is available [here](https://itunes.apple.com/us/app/wireguard/id1451685025).
- **iOS**: Download WireGuard from the [App Store](https://itunes.apple.com/us/app/wireguard/id1441195209).

**Where can I find WireGuard documentation?**

- The [WireGuard Manual](https://www.wireguard.com) offers comprehensive information on all options.

**How to install WireGuard without interactive prompts? (Headless Install)**

- Use the command: `./wireguard-manager.sh --install`

**Are there alternatives to self-hosting a VPN?**

- Yes, [CloudFlare Warp](https://1.1.1.1) is a notable option.

**Why is all the code centralized in one place?**

- Think of it like a universal remote: it's more convenient to have one device (or codebase) that does everything than multiple specialized ones.

**Which port and protocol are needed for WireGuard?**

- Forward your chosen port or the default port `51820` using the UDP protocol.

**What ports need forwarding for Unbound?**

- Port forwarding isn't necessary for Unbound since DNS traffic goes through the VPN (`port 53`).

**What gets blocked by the content blocker?**

- The blocker restricts ads, trackers, malware, and phishing attempts.

**What information is collected and how?**

- No logs are collected or retained; all operations are confined to the system, with no external log transmission.

**What do I need for setting up my own VPN server?**
Purchase these items:

- [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b)
- [Micro SD Card](https://www.amazon.com/dp/B06XWMQ81P)
- [Case for Raspberry Pi](https://www.raspberrypi.com/products/raspberry-pi-4-case)
- [Case Fan](https://www.raspberrypi.com/products/raspberry-pi-4-case-fan)
- [Power Supply](https://www.raspberrypi.com/products/type-c-power-supply)
- [Ethernet Cable](https://www.amazon.com/dp/B00N2VIALK)
- [SD Card Reader](https://www.amazon.com/dp/B0957HQ4D1)

**What's the estimated cost for building your own VPN?**

- Expect a one-time hardware cost around $75 USD, plus ongoing expenses for electricity and internet.

**Official WireGuard Links**

- Homepage: [WireGuard Official Site](https://www.wireguard.com)
- Installation Guide: [Install WireGuard](https://www.wireguard.com/install/)
- Quick Start: [WireGuard QuickStart](https://www.wireguard.com/quickstart/)
- Compilation Instructions: [Compile WireGuard](https://www.wireguard.com/compilation/)
- Whitepaper: [WireGuard Whitepaper](https://www.wireguard.com/papers/wireguard.pdf)

---

### 🙅 No Content-Blocking vs. Content-Blocking

https://user-images.githubusercontent.com/16564273/125283630-9845d180-e2e6-11eb-8b7d-f30a8f2eae8a.mp4

---

### 📐 Architecture

![image](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/Wireguard-Manager.png)

---

### 🤝 Code Development

**Effortlessly Develop Code Without Cloning the Repository**

You can work on the code directly without the need to clone the entire repository. This is made possible through Visual Studio Code's online platform. By clicking the link below, you can preview and edit the code in your browser, utilizing the user-friendly interface of Visual Studio Code. This approach simplifies the development process, especially for those who want to make quick changes or don't wish to set up the entire repository on their local machine.

[![Open in Visual Studio Code](https://img.shields.io/badge/preview%20in-vscode.dev-blue)](https://open.vscode.dev/complexorganizations/wireguard-manager)

### 🐛 Code Debugging

**Step-by-Step Debugging Process After Cloning the Repository**

For a more in-depth debugging process, you may prefer to clone the repository to your local system. This approach allows you to thoroughly test and debug the code in your environment. Follow these steps to clone the repository and initiate the debugging process:

1. **Clone the Repository**: Use the Git command to clone the repository to your preferred directory, such as `/root/` in this example. This step copies all the code from the online repository to your local machine.

```bash
  git clone https://github.com/complexorganizations/wireguard-manager /root/
```

2. **Begin Debugging**: After cloning, navigate to the script's directory and start the debugging process. The script will be executed in debug mode, providing detailed output of each step. This output is redirected to a log file for easier examination. The log file, located in the same directory, stores all the debugging information, making it simple to trace any issues or understand the script's behavior.

```bash
  bash -x /root/wireguard-manager/wireguard-manager.sh >>/root/wireguard-manager/wireguard-manager.log
```

By following these steps, you can either quickly modify the code online without cloning or perform a more thorough debugging process by cloning the repository to your local machine. Each method offers different advantages depending on your needs and the scope of your work with the WireGuard Manager script.

Certainly! Improving the debugging process for a broad range of developers involves ensuring the steps are clear, accessible, and cover various scenarios and tools that developers might use. Here’s an expanded and more detailed guide to enhance the debugging experience:

### Expanded Debugging Steps for WireGuard Manager

1. **Environment Setup**

   - **Ensure Prerequisites**: Verify that all required software, including Git, Bash, and any dependencies specified by the WireGuard Manager, are installed on your system.
   - **Choose a Suitable IDE**: While the example uses Visual Studio Code, developers may use any IDE they are comfortable with, which supports Git and Bash.

2. **Clone the Repository**

   - **Use Git to Clone**: Clone the WireGuard Manager repository to a local directory.
     ```bash
     git clone https://github.com/complexorganizations/wireguard-manager /path/to/local-directory
     ```
   - **Choose an Appropriate Directory**: Avoid using root directories for development. Choose a user directory to ensure safety and manage permissions easily.

3. **Familiarize with the Codebase**

   - **Code Review**: Before diving into debugging, take time to understand the code structure, coding conventions, and documentation provided.
   - **Utilize Documentation**: Check the repository for a README file or wiki pages that may offer insights into the codebase.

4. **Set Up Debugging Tools**

   - **Configure Your IDE**: Use the debugging tools available in your IDE. Set breakpoints, watch variables, and use step-through debugging features.
   - **Logging**: Make sure logging is set up correctly in the script to capture sufficient details for debugging.

5. **Run the Script in Debug Mode**

   - **Execute with Bash Debugging Enabled**: Run the script with `bash -x` to get detailed trace outputs.
     ```bash
     bash -x /path/to/local-directory/wireguard-manager/wireguard-manager.sh >> /path/to/local-directory/wireguard-manager.log
     ```
   - **Monitor the Log File**: Regularly review the log file for errors or unexpected behavior.

6. **Test in Different Environments**

   - **Use Virtual Machines or Containers**: Test the script in isolated environments like Docker containers or VMs to understand how it behaves in different settings.
   - **Cross-Platform Testing**: If possible, test on different operating systems to ensure compatibility.

7. **Collaborate and Seek Feedback**

   - **Use Version Control Smartly**: Commit changes to a new branch and use pull requests for reviews.
   - **Code Reviews**: Request code reviews from peers to get different perspectives on potential issues.

8. **Document Your Findings**

   - **Update Documentation**: If you find undocumented behavior or fixes, update the project documentation.
   - **Report Issues**: Use the repository's issue tracker to report bugs or suggest enhancements.

9. **Automate Testing**

   - **Write Test Cases**: Create automated tests for critical functionalities to catch bugs early.
   - **Continuous Integration**: Use CI tools to automate testing with every commit or pull request.

10. **Stay Updated with the Repository**
    - **Pull Regular Updates**: Regularly update your local repository with changes from the main project to stay in sync and avoid conflicts.

By following these steps and adapting them to their own development environment and workflow, developers can more effectively debug and contribute to the WireGuard Manager project. This comprehensive approach caters to various skill levels and preferences, thereby facilitating a more inclusive and efficient development process.

---

### 💋 Credits

Open Source Community

---

### 📱 Community and Contributions

[![Discord](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/images/icons/discord.svg)](https://discord.gg/HyhugYT9u7)
[![Slack](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/images/icons/slack.svg)](https://parking-unitedcom.slack.com/archives/C05QM7PS9GV/p1693631754500589)

---

### 🤝 Sponsors

[![Digital Ocean](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/images/icons/digitalocean.svg)](https://www.digitalocean.com)

---

### 📝 License

WireGuard-Manager is licensed under the Apache License Version 2.0. For more details, see our [License File](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/.github/LICENSE).
