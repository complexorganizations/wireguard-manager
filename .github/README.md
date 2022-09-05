<h1 align="center">WireGuard-Manager 👋</h1>
<h5 align="center">Your privacy is the default settings here.</h5>
<p align="center">
	<a href="https://github.com/complexorganizations/wireguard-manager/releases">
		<img alt="Release" src="https://img.shields.io/github/v/release/complexorganizations/wireguard-manager" target="_blank" />
	</a>
	<a href="https://github.com/complexorganizations/wireguard-manager/actions/workflows/wireguard-manager.yml">
		<img alt="ShellCheck" src="https://github.com/complexorganizations/wireguard-manager/workflows/ShellCheck/badge.svg" target="_blank" />
	</a>
	<a href="https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-build.yml">
		<img alt="Auto-Build" src="https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-build.yml/badge.svg" target="_blank" />
	</a>
	<a href="https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-update-named-cache.yml">
		<img alt="Auto-Update" src="https://github.com/complexorganizations/wireguard-manager/actions/workflows/auto-update-named-cache.yml/badge.svg" target="_blank" />
	</a>
	<a href="https://github.com/complexorganizations/wireguard-manager/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/complexorganizations/wireguard-manager" target="_blank" />
	</a>
	<a href="https://github.com/sponsors/Prajwal-Koirala">
		<img alt="Sponsors" src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub" target="_blank" />
	</a>
	<a href="https://github.com/complexorganizations/wireguard-manager/pulls">
		<img alt="PullRequest" src="https://img.shields.io/github/issues-pr/complexorganizations/wireguard-manager" target="_blank" />
	</a>
	<a href="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/.github/LICENSE">
		<img alt="License" src="https://img.shields.io/github/license/complexorganizations/wireguard-manager" target="_blank" />
	</a>
</p>

---
### 🤷 What is VPN ?
A Virtual Private Network (VPN) allows users to send and receive data through shared or public networks as if their computing devices were directly connected to the private network. Thus, applications running on an end-system (PC, smartphone, etc.) over a VPN may benefit from individual network features, protection, and management. Encryption is a standard aspect of a VPN connection but not an intrinsic one.

### 📶 What is WireGuard❓
WireGuard is a straightforward yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general-purpose VPN for running on embedded interfaces and super computers alike, fit for many circumstances. Initially released for the Linux kernel, it is now cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable. It is currently under a massive development, but it already might be regarded as the most secure, most comfortable to use, and the simplest VPN solution in the industry.

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
### 🐧 Installation
Lets first use `curl` and save the file in `/usr/local/bin/`
``` bash
curl https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh --create-dirs -o /usr/local/bin/wireguard-manager.sh
```
Then let's make the script user executable
``` bash
chmod +x /usr/local/bin/wireguard-manager.sh
```
It's finally time to execute the script
``` bash
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
* `PRIVATE_SUBNET_V4_SETTINGS` - By default, the private IPv4 subnet configuration is `10.0.0.0/8`.
* `PRIVATE_SUBNET_V6_SETTINGS` - `fd00:00:00::0/8` is the default private IPv6 subnet.
* `SERVER_HOST_V4_SETTINGS` - Curl detects a public IPv4 address by default.
* `SERVER_HOST_V6_SETTINGS` - Curl by default finds a public IPv6 address.
* `SERVER_PUB_NIC_SETTINGS` - Using the ip command, to find the local public network interface.
* `SERVER_PORT_SETTINGS` - `51820` is the default public port for the wireguard interface.
* `NAT_CHOICE_SETTINGS` - Determine whether or not to use the vpn tunnel's keep alive feature.
* `MTU_CHOICE_SETTINGS` - The wireguard peers will utilize this MTU.
* `SERVER_HOST_SETTINGS` -
* `CLIENT_ALLOWED_IP_SETTINGS` - Using an IP range, choose what should be sent to the VPN.
* `AUTOMATIC_UPDATES_SETTINGS` -
* `AUTOMATIC_BACKUP_SETTINGS` -
* `DNS_PROVIDER_SETTINGS` - You'll have to utilize another DNS if you don't have Unbound.
* `CONTENT_BLOCKER_SETTINGS` -
* `CLIENT_NAME` - The wireguard peer's name.
* `AUTOMATIC_CONFIG_REMOVER` -

---
### 👉👈 Compatibility with Linux Distro
| OS              | i386               | amd64              | armhf              | arm64              |
| --------------  | ------------------ | ------------------ | ------------------ | ------------------ |
| Ubuntu 14 ≤     |:x:                 |:x:                 |:x:                 |:x:                 |
| Ubuntu 16 ≥     |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Debian 7 ≤      |:x:                 |:x:                 |:x:                 |:x:                 |
| Debian 8 ≥      |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| CentOS 6 ≤      |:x:                 |:x:                 |:x:                 |:x:                 |
| CentOS 7 ≥      |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Fedora 29 ≤     |:x:                 |:x:                 |:x:                 |:x:                 |
| Fedora 30 ≥     |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| RedHat 6 ≤      |:x:                 |:x:                 |:x:                 |:x:                 |
| RedHat 7 ≥      |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Kali 1.0 ≤      |:x:                 |:x:                 |:x:                 |:x:                 |
| Kali 1.1 ≥      |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Arch            |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Raspbian        |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| PopOS           |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Manjaro         |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Mint            |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Alma            |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Alpine          |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| FreeBSD         |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Neon            |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Rocky           |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |
| Oracle          |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |:heavy_check_mark:  |

### ☁️ Compatibility with Cloud Providers
| Cloud           | Supported          |
| --------------  | ------------------ |
| AWS             |:heavy_check_mark:  |
| Google Cloud    |:heavy_check_mark:  |
| Linode          |:heavy_check_mark:  |
| Digital Ocean   |:heavy_check_mark:  |
| Vultr           |:heavy_check_mark:  |
| Microsoft Azure |:heavy_check_mark:  |
| OpenStack       |:heavy_check_mark:  |
| Rackspace       |:heavy_check_mark:  |
| Scaleway        |:heavy_check_mark:  |
| EuroVPS         |:heavy_check_mark:  |
| Hetzner Cloud   |:x:                 |
| Strato          |:x:                 |

### 🛡️ Compatibility with Virtualization
| Virtualization  | Supported          |
| --------------  | ------------------ |
| KVM             |:heavy_check_mark:  |
| None            |:heavy_check_mark:  |
| Qemu            |:heavy_check_mark:  |
| LXC             |:heavy_check_mark:  |
| Microsoft       |:heavy_check_mark:  |
| Vmware          |:heavy_check_mark:  |
| OpenVZ          |:x:                 |
| Docker          |:x:                 |
| Wsl             |:x:                 |

### 💻 Compatibility with Linux Kernel
| Kernel                 | Supported              |
| ---------------------  | ---------------------  |
| Linux Kernel 3.0 ≤     |:x:                     |
| Linux Kernel 3.1 ≥     |:heavy_check_mark:      |

---
### 🙋 Q&A
Which hosting provider do you recommend?
- [Google Cloud](https://cloud.google.com): Worldwide locations, IPv4 support, starting at $3.50/month
- [Amazon Web Services](https://aws.amazon.com): Worldwide locations, IPv4 support, starting at $5.00/month
- [Microsoft Azure](https://azure.microsoft.com): Worldwide locations, IPv4 support, starting at $5.00/month
- [Linode](https://www.linode.com): Worldwide locations, IPv4 & IPv6 support, starting at $5.00/month
- [Vultr](https://www.vultr.com): Worldwide locations, IPv4 & IPv6 support, starting at $3.50/month

Which WireGuard client do you recommend?
- Windows: [WireGuard](https://www.wireguard.com/install).
- Android: [WireGuard](https://play.google.com/store/apps/details?id=com.wireguard.android).
- macOS: [WireGuard](https://itunes.apple.com/us/app/wireguard/id1451685025).
- iOS: [WireGuard](https://itunes.apple.com/us/app/wireguard/id1441195209).

Is there WireGuard documentation?
- Yes, please head to the [WireGuard Manual](https://www.wireguard.com), which references all the options.

How do I install a wireguard without the questions? (Headless Install)
- ```./wireguard-manager.sh --install```

Are there any good alternative to self-hosting vpn?
- [CloudFlare Warp](https://1.1.1.1)

Why is all the code in one place?
- Consider a remote control, you can have thirty different remotes each doing a different job, or you may have a single remote that does everything.

Which port do I need to forward for wireguard, and which protocol should I use?
- On the udp protocol, either the port of your choice or the default port of `51820` must be forwarded.

For unbound, which ports do I need to forward?
- Because all DNS traffic is routed through the vpn, you don't need to forward those ports `53`.

What is blocked if I enable the content blocker?
- Advertisement, Tracking, malware, and phishing are all prohibited.

What kind of information is collected and how is it gathered?
- We do not collect or retain any logs; everything takes place on the system, and logs are never sent outside of it.

If I want to set up my own VPN server, what should I purchase?
- [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b)
- [Micro SD](https://www.amazon.com/dp/B06XWMQ81P)
- [Case](https://www.raspberrypi.com/products/raspberry-pi-4-case)
- [Case Fan](https://www.raspberrypi.com/products/raspberry-pi-4-case-fan)
- [Power Supply](https://www.raspberrypi.com/products/type-c-power-supply)
- [Ethernet Cable](https://www.amazon.com/dp/B00N2VIALK)
- [SD Card Reader](https://www.amazon.com/dp/B0957HQ4D1)

How much should the entire cost of constructing your own VPN be?
- The hardware has a one-time cost of roughly $75 USD, as well as monthly costs of energy and internet.

Official Links
- Homepage: https://www.wireguard.com
- Install: https://www.wireguard.com/install/
- QuickStart: https://www.wireguard.com/quickstart/
- Compiling: https://www.wireguard.com/compilation/
- Whitepaper: https://www.wireguard.com/papers/wireguard.pdf

---
### 🙅 No Content-Blocking vs. Content-Blocking
https://user-images.githubusercontent.com/16564273/125283630-9845d180-e2e6-11eb-8b7d-f30a8f2eae8a.mp4

---
### 📐 Architecture
![image](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/Wireguard-Manager.png)

---
### 🤝 Developing
Developing the code without having to clone the repository

[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/complexorganizations/wireguard-manager)

### 🐛 Debugging
After cloning the repo, Then start debugging the code.

``` bash
git clone https://github.com/complexorganizations/wireguard-manager /root/
bash -x /root/wireguard-manager/wireguard-manager.sh >>/root/wireguard-manager/wireguard-manager.log
```

---
### ⛑️ Support
Give a ⭐️ and 🍴 if this project helped you!

<p align="center">
	<a href="https://github.com/sponsors/Prajwal-Koirala">
		<img alt="Sponsors" src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub" target="_blank" />
	</a>
</p>

- Ethereum : `0xd3c5449C298433cEd4aC0E57D1F750d89A3FECC7`
- USD Coin : `0xF1f09037b85766F014DF2D028f76Cce47541Fb53`

---
### ❤️ Credits
Open Source Community

---
### 🤝 Sponsors
<table>
  <tbody>
    <tr>
      <td align="center" valign="middle">
        <a href="https://m.do.co/c/fb46acb2b3b1" target="_blank">
          <img width="200px" src="https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/assets/digitalocean.png">
        </a>
      </td>
      </td>
    </tr><tr></tr>
  </tbody>
</table>

---
### 📝 License
[Apache License Version 2.0](https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/.github/LICENSE)
