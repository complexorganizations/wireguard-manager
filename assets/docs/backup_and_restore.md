# **WireGuard Manager Backup Guide**

This guide provides a comprehensive process for backing up WireGuard Manager, ensuring smooth transfer and restoration of configurations between systems. Proper backup is critical for maintaining your network setup, especially in the event of a server migration or failure.

---

## **Essential Backup Files**

To ensure a successful backup, it is important to include the following critical file:

### 1. **WireGuard Configuration File**

- **Path:** `/etc/wireguard/wg0.conf`
- **Description:** This file contains all the necessary configurations for WireGuard, such as interface settings, peer configurations, and private/public keys. Without this file, you will lose the WireGuard network configuration.

### Additional Files to Consider

While the configuration file is the most crucial for WireGuard's operation, consider backing up other system configurations and associated files, such as:

- **Private Keys:** Ensure that any private keys associated with WireGuard peers are secured.
- **System-Specific Files:** If you have custom scripts or additional configuration files (e.g., firewall rules or systemd service configurations), ensure they are included in your backup.

---

## **Backup Storage**

It is essential to securely store the backup in a format that allows for easy restoration. The backup is packaged into a ZIP archive for easy transfer and storage.

### **Backup Archive**

- **Location:** `/var/backups/wireguard-manager.zip`
- **Description:** This archive contains the WireGuard configuration file and any other necessary files required for full restoration. Compressing the backup helps in minimizing the space and makes it easy to transfer to another system.

### **Backup Storage Tips**

- **Secure Locations:** Store backups in multiple locations, such as external drives or cloud storage, to prevent data loss.
- **Regular Backups:** Schedule regular backups to ensure that the latest configurations are always backed up.

---

## **Secure Password Management**

It is critical to securely store the password required to access the backup. The password should be managed separately from the backup file itself.

### **Password File**

- **Location:** `${HOME}/.wireguard-manager`
- **Description:** This hidden file contains the access password for the backup archive. By keeping it outside the archive, it ensures that the backup remains secure, even if the backup file is compromised.

### **Password Security Recommendations**

- **Strong Passwords:** Use complex, unique passwords to ensure the security of your backup.
- **Encryption:** Consider encrypting the backup archive itself with a strong passphrase for additional protection.
- **Access Control:** Restrict access to the password file to only trusted users.

---

## **Backup Process**

### Step 1: **Identify the Files to Backup**

Before beginning the backup, ensure that you have the necessary files:

- `/etc/wireguard/wg0.conf` (WireGuard configuration)
- Any additional configuration files (e.g., custom scripts, firewall rules)
- The password file located at `${HOME}/.wireguard-manager`

### Step 2: **Create a Compressed Backup Archive**

Use a command to compress the necessary files into a single backup file. Here's an example command to create the backup:

```bash
zip -r /var/backups/wireguard-manager.zip /etc/wireguard/wg0.conf ${HOME}/.wireguard-manager
```

### Step 3: **Verify the Backup**

After creating the archive, verify that it contains all the necessary files. You can check the contents of the ZIP file by running:

```bash
unzip -l /var/backups/wireguard-manager.zip
```

---

## **Restoration Process**

Restoring WireGuard Manager from the backup involves extracting the archive and restoring the configuration files to their respective locations.

### Step 1: **Transfer the Backup Archive**

- Transfer the backup archive (`wireguard-manager.zip`) to the target system. This can be done via secure file transfer methods like `scp` or `rsync`.

### Step 2: **Extract the Backup Archive**

Once the backup file is on the target system, extract it using the `unzip` command:

```bash
unzip /var/backups/wireguard-manager.zip -d /tmp
```

This will extract the files into the `/tmp` directory or a directory of your choosing.

### Step 3: **Restore Configuration Files**

After extracting the backup, restore the configuration files to their original locations:

```bash
mv /tmp/wg0.conf /etc/wireguard/wg0.conf
mv /tmp/.wireguard-manager ${HOME}/.wireguard-manager
```

Ensure that the file permissions are correct and that the files are owned by the proper user (e.g., `root` for WireGuard configuration).

### Step 4: **Verify the Restoration**

To confirm that the restoration was successful, you can check the WireGuard service status and ensure the interface is up:

```bash
systemctl status wg-quick@wg0
```

You can also test connectivity by pinging a peer or accessing the network.

---

## **Additional Tips for Backup and Restoration**

### **Automating Backups**

Consider automating your backup process using cron jobs or systemd timers to ensure that regular backups are performed without manual intervention.

For example, create a cron job that runs daily at midnight:

```bash
0 0 * * * /usr/bin/zip -r /var/backups/wireguard-manager.zip /etc/wireguard/wg0.conf ${HOME}/.wireguard-manager
```

### **Testing the Backup**

Perform regular tests of your backup and restoration process to ensure that your system will work as expected in case of an emergency.

### **Multiple Backup Locations**

For maximum redundancy, store backups in multiple locations (e.g., external hard drives, cloud storage, etc.) and ensure that the backup is encrypted for added security.

---

## **Conclusion**

A proper backup process is essential for safeguarding your WireGuard Manager configuration. By following this guide, you can ensure that your configurations are easily backed up, securely stored, and quickly restored if necessary.

If you have any questions or need further assistance, feel free to reach out for support!
