# Proaxiom VMS Configuration Script

This script prepares a Linux host for Proaxiom vulnerability management scanners, including runZero, Greenbone OpenVAS and Tenable Nessus.

The script creates a proaxiom-vms user account that is authenticated via private key authentication, and adds this user account to the sudoers group.

## Prerequisites

Ensure that you have the following:
- Root or sudo access
- A compatible operating system (Linux, macOS, or FreeBSD)
- An internet connection for installing packages

## Usage

Run the script with root privileges:

```bash
sudo ./proaxiom-vms-linux.sh
```

## Functions
### display_logo
Displays the Proaxiom VMS logo.

### detect_os
Detects the operating system and sets the OS variable accordingly.

### check_package_manager
Determines the package manager based on the detected operating system.

### check_and_install_packages
Checks for the presence of necessary packages and installs them if they are missing. Prompts the user for permission before installing each package.

### configure_user_ssh
Creates a user named proaxiom-vms and configures SSH key-based authentication for this user. It also updates the SSH daemon configuration.

### configure_sudoers
Configures sudoers to allow the proaxiom-vms user to execute commands without a password.
