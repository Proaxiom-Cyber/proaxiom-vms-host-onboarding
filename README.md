# Proaxiom VMS Configuration Script

This script configures a Proaxiom VMS environment by performing the following actions:
- Clearing the screen
- Checking if the script is run as root
- Displaying the Proaxiom VMS logo
- Detecting the operating system
- Checking for the package manager
- Checking and installing necessary packages
- Creating a user and configuring SSH
- Configuring sudoers

## Prerequisites

Ensure that you have the following:
- Root or sudo access
- A compatible operating system (Linux, macOS, or FreeBSD)
- An internet connection for installing packages

## Usage

Run the script with root privileges:

```bash
sudo ./script.sh```

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
