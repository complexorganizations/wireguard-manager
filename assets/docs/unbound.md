# Managing Unbound DNS: Blocking Domains, Enabling Logging, and Troubleshooting

This guide explains how to configure Unbound for domain blocking, enable detailed logging, and troubleshoot common issues.

---

## **Blocking Domains Using Unbound**

To block specific domains, you need to update Unbound's configuration and apply the changes:

1. **Update the Main Configuration File**  
   Add a directive to include the `hosts.conf` file in the main Unbound configuration.

   ```bash
   echo -e "\tinclude: /etc/unbound/unbound.conf.d/hosts.conf" >> /etc/unbound/unbound.conf
   ```

2. **Fetch and Format the Blocklist**  
   Download a list of domains to block and format them for Unbound. The following command fetches the blocklist and converts it into Unbound's `local-zone` format:

   ```bash
   curl "https://raw.githubusercontent.com/complexorganizations/content-blocker/main/assets/hosts" | awk '{print "local-zone: \""$1"\" always_refuse"}' > /etc/unbound/unbound.conf.d/hosts.conf
   ```

3. **Restart the Unbound Service**  
   Apply the updated configuration by restarting Unbound:

   ```bash
   systemctl restart unbound || service unbound restart
   ```

---

## **Enabling Logging in Unbound**

Detailed logging helps in monitoring and troubleshooting Unbound's behavior.

1. **Increase Verbosity**  
   Modify the verbosity level to `5` (maximum detail):

   ```bash
   sed -i "s|verbosity: 0|verbosity: 5|" /etc/unbound/unbound.conf
   ```

2. **Enable Query Logging**  
   Specify the log file location and enable query logging:

   ```bash
   echo -e "\tlogfile: /var/log/unbound.log\n\tlog-queries: yes" >> /etc/unbound/unbound.conf
   ```

3. **Prepare the Log File**  
   Create the log file and set the necessary permissions:

   ```bash
   touch /var/log/unbound.log
   chown unbound:unbound /var/log/unbound.log
   ```

4. **Restart Unbound**  
   Restart the service to apply the logging changes:

   ```bash
   systemctl restart unbound || service unbound restart
   ```

5. **View Logs in Real-Time**  
   Use the `tail` command to monitor logs as they are written:

   ```bash
   tail -f /var/log/unbound.log
   ```

---

## **Troubleshooting: Resolving Domain Issues**

If Unbound is failing to resolve domains, the issue might be with the trust anchor file. To fix this:

1. **Comment Out the Trust Anchor Setting**  
   Modify the configuration to disable the `auto-trust-anchor-file` directive:

   ```bash
   sed -i "s|auto-trust-anchor-file: /var/lib/unbound/root.key|# auto-trust-anchor-file: /var/lib/unbound/root.key|" /etc/unbound/unbound.conf
   ```

2. **Restart Unbound**  
   Apply the change by restarting the service:

   ```bash
   systemctl restart unbound || service unbound restart
   ```

---

## **Additional Notes**

- **Checking Unbound Status**  
  Use the following command to verify that Unbound is running properly:

  ```bash
  systemctl status unbound
  ```

- **Testing DNS Resolution**  
  Test Unbound's resolution capabilities using the `dig` or `nslookup` command:

  ```bash
  dig example.com @127.0.0.1
  ```

- **Viewing Blocked Domains**  
  Check the `hosts.conf` file to verify that the blocklist was applied correctly:

  ```bash
  less /etc/unbound/unbound.conf.d/hosts.conf
  ```

By following these steps, you can effectively block unwanted domains, enable logging for better analysis, and troubleshoot common issues in Unbound.
