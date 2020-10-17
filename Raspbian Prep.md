## Overview
Using a Raspberry Pi powered via the under-utilized USB interface on the Palo Alto firewall is great for lab environments. Below are the instructions for getting a Raspberry Pi up and running to act as your AutoSSL gCertbot

## Raspberry Pi Configuration - Networking
 During initial setup, you will need a keyboard, monitor and mouse connected to the Pi. Below are the steps to get the Pi ready for phase 2 of the configuration. If you are using another Linux distribution, you simply need to ensure the same software packages are installed to handle the automation.

### Prerequisites
 * Monitor, Mouse, and Keyboard attached to Pi
 * Internet connectivity for Pi

### Instructions
1. Install Raspbian
1. Install updates
1. Reboot
1. Install more updates (be sure to address any kept back packages)
    ```bash
    sudo apt list --upgradeable
    sudo apt install <pkg name>
    ```
1. Reboot again
1. Configure NTP and SSH using raspi-config
1. Disable any unnecessary components
    * EX: bluetooth, wifi
1. Shutdown and connect to L2 interface on PA.

## Raspberry Pi Configuration - Hardening and Application Setup
As we will be exposing this device to the internet for DNS name validation, we will need to ensure we limit our exposire to any malfeasence by locking our Pi down.

### Instruction
1. Change the default password for our Pi
1. Change pi hostname
1. Change pi login to console require login (B1)
1. Restrict SSH access except from internal address spaces
1. Install openssl, python3-pip, dnsutils, nginx, ddclient, certbot, and the certbot python3 scripts for nginx
    ```bash
    sudo apt-get update
    sudo apt-get install software-properties-common
    sudo add-apt-repository universe
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install openssl python3 python3-pip dnsutils nginx certbot python3-certbot-nginx ddclient
    ```
1. Install pan-python
    ```bash
    sudo pip3 install pan-python
    ```
    
1. Configure DDclient via config file
    * For NameCheap
        * protocol=namecheap
        * use=web, web=canhazip.com
        * server=dynamicdns.park-your-domain.com
        * login=<domain name>
        * password=<password from dyndns section in NameCheap>
        <hostname>
