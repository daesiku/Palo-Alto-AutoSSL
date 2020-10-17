# Overview
 The goal of this project is to create a web server that will handle the Let's Encrypt SSL certificate process, and automatically push our certificate to our Palo Alto firewall each time the certificate updates. As this setup is ideal for a lab environment, details to configure a Raspberry Pi are included in an instructional doc.

### Prerequisite
* Functional Global Protect Client VPN Setup
* Admin access to Palo Alto Firewall
* Linux host with access to management interface and Internet
* SUDO access to Linux host
* SSH access to Linux host
* Service account on Linux host
* [Optional] Disable SUDO password prompt for service account (required for fully automated renewal)

### Considerations
* If your WAN interface does not have a static IP, you will want to also configure a dynamic DNS client to keep your FQDN up to date with your WAN IP. In my test environment I've configured DDCLIENT with Namecheap. Configuration file example included within the Raspberry Prep instructions.
* Test deployment performed on a Raspberry Pi powered via Palo Alto USB port
* Linux distro used for testing was Debian base, so scripts may need to be adapted for other distros

See Raspbian Prep.md for more granular instructions.

### Firewall Configuration - Recommendations
General network design recommendations for deployment

* Place Linux host in a DMZ zone with very restricted access
* Limit access to Linux host from Untrusted zone
* Limit access to Palo Alto MGMT interface
* Deny access from DMZ zone to Trust zone (default Interzone)
* Permit HTTP (80) traffic to Linux host in DMZ for testing


## Firewall Configuration - Required
Configure inbount NAT and Security policies to allow Let's Encrypt servers communicate with nginx

### Instructions
1. Create security rule to route inbound HTTP (TCP 80) to Linux host
1. Create NAT rule to route inbound HTTP (TCP 80) to Linux host

### Validation Test
1. Confirm you can access the nginx default page from l3_trust
1. Confirm you can access the nginx default page from external via your DNS name

## Linux host configuration
Now that our host is able to determine our public IP and update our DNS record, we are ready to configure our PAN automation and request our certificate. The steps to success include obtaining the certificate from Let's Encrypt, establishing an API key to talk to our PA, updating the PA with our new certificate, and configuring a cron job to automate renewals.<br>


This process is based heavily on and inspired by the letsencrypt_paloalto project and Steve Borba's blog post, both linked below<br>
[letsencrypt_paloalto](https://github.com/psiri/letsencrypt_paloalto) by [psiri](https://github.com/psiri)<br>
[Global Protect Portal - Let's Encrypt](https://www.steveborba.com/global-protect-portal-lets-encrypt/) by [Steve Borba](https://www.steveborba.com/)

### Instructions
1. Create a role with only the permissions needed (least access permissions)
  * XML/REST API
    * Configuration (For updating config)
    * Operational Requests (For clearing DNS Cache. Not required in all cases)
    * Commit (For applying changes)
    * Import (For uploading SSL certificate)
1. Create user and and give it the newly defined role
1. Confirm both pan_autossl_setup.sh and pan_autossl_renew.sh 
1. Run pan_autossl_setup.sh to accomplish the following tasks
* Obtain API key
* Create config file for cron job
* Request initial certificate
* Push certificate to Palo Alto
* Configure cron job

## Validation and Troubleshooting
Confirm cron job has been created
crontab -l

Confirm ~/pan_autossl folder exists with config file and cron script