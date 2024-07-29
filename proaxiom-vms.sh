#!/bin/bash

# Clear the screen
clear

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Function to display the Proaxiom VMS logo
display_logo() {
  cat << "EOF"

    dMMMMb  dMMMMb  .aMMMb  .aMMMb  dMP dMP dMP .aMMMb  dMMMMMMMMb
   dMP.dMP dMP.dMP dMP"dMP dMP"dMP dMK.dMP amr dMP"dMP dMP"dMP"dMP
  dMMMMP" dMMMMK" dMP dMP dMMMMMP .dMMMK" dMP dMP dMP dMP dMP dMP
dMP     dMP"AMF dMP.aMP dMP dMP dMP"AMF dMP dMP.aMP dMP dMP dMP
dMP     dMP dMP  VMMMP" dMP dMP dMP dMP dMP  VMMMP" dMP dMP dMP

  dMP dMP dMMMMMMMMb  .dMMMb
dMP dMP dMP"dMP"dMP dMP" VP
dMP dMP dMP dMP dMP  VMMMb
YMvAP" dMP dMP dMP dP .dMP
VP"  dMP dMP dMP  VMMMP"

EOF
}

# Function to detect the operating system
detect_os() {
    echo "Detecting operating system..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        else
            OS=$(uname -s)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS="freebsd"
    else
        echo "Error: Unsupported OS: $OSTYPE"
        exit 1
    fi
    echo "Operating system detected: $OS"
}

# Function to check for package manager
check_package_manager() {
    echo "Checking for package manager..."
    case "$OS" in
        ubuntu|debian)
            PKG_MANAGER="apt-get"
            ;;
        rhel|centos|rocky)
            PKG_MANAGER="yum"
            ;;
        macos)
            if command -v brew &> /dev/null; then
                PKG_MANAGER="brew"
            else
                echo "Error: Homebrew is not installed."
                exit 1
            fi
            ;;
        freebsd)
            PKG_MANAGER="pkg"
            ;;
        *)
            echo "Error: No known package manager for OS: $OS"
            exit 1
            ;;
    esac
    echo "Package manager detected: $PKG_MANAGER"
}


# Function to check and optionally install packages
check_and_install_packages() {
    echo "Checking and installing packages if needed..."
    local packages=(
        "bash" "cat" "date" "egrep" "find" "grep" "host" "id" "ip" "lastlog"
        "locate" "ls" "md5sum" "mlocate" "netstat" "perl" "ps" "sh" "sha1sum"
        "slocate" "uname" "uptime" "whereis" "which"
    )

    local locate_packages=("locate" "mlocate" "slocate")
    local locate_installed=false

    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            if [[ " ${locate_packages[@]} " =~ " ${pkg} " ]]; then
                for locate_pkg in "${locate_packages[@]}"; do
                    if command -v "$locate_pkg" &> /dev/null; then
                        locate_installed=true
                        break
                    fi
                done
                if [ "$locate_installed" = true ]; then
                    continue
                fi
            fi
            echo "$pkg is not installed."
            read -p "Do you want to install $pkg? (y/n) " choice
            if [[ "$choice" == "y" ]]; then
                echo "Installing $pkg..."
                sudo $PKG_MANAGER install -y $pkg
                echo "$pkg installed."
            else
                echo "$pkg installation skipped."
            fi
        fi
    done
}

# Function to create user and configure SSH
configure_user_ssh() {
  username="proaxiom-vms"
  ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZlSZ759oE0M671iZuQbl3kEluXfi3+u5SlnTw9cUK4TvjEbWjuO3sTy5zCIpVm4Ebm/LOI1X61nqN50i3suPX5MvWNb5ikPZr15dTywc51MBlmLHcugQwGL0r/3ygLjnZc23fBw46PHyLGnj2aK0iZzhDWuk4Kz3oL07AAuwiXOtczkXtkbpWuYdwZPumEGhE2scv6tXga1q4dRLka3Ci46JdWOyZBvzssrGQ267BglhXwkhYOK8++4PBH+/Q8tbMdCRPKxJRvXkiKoVn2JyRtFaSXFS59IlukPpOQ9aLCMIRVU/TSw6S83FrEClH7hSWuMpvNW+/YsxfCP/14bGXBOvLOyODbMgzoX4tMsWmpTo0Ab/U0SRYKONb7hz3xQuhrZwkru5FuptGJwLvlLGDCM56pu2pQ6BmqBgN2FnDV5vqfz8TauRTwTfcBYpebi7jvEvIimdZ4Xo1ignlJoffVkIVGL4YIny/KLbtOVjKiadZ1UDk/VduqWtJFMCuu8DI08513khNnjIl/rOMQOUA+tH9d1Y1aGjBcJa0nO4/kkNRhiVOE8fEvLTSmc2Qww5GXcIMYcbSQIVHydWmsYXnxVkjpnOViQBe/GVivkbc1SobCkdEVmFkVZ2N+uXlIGHfVSZ+r7uJnBSJ4/8yzp6xwlSRarx1wUTqVx2yV/BNQ=="

  # Create user if it doesn't exist
  if ! id "$username" &> /dev/null; then
    echo "Creating user $username..."
    useradd -m "$username"
  else
    echo "User $username already exists."
  fi

  # Add SSH key
  echo "Configuring SSH key for $username..."
  mkdir -p /home/$username/.ssh
  echo "$ssh_key" > /home/$username/.ssh/authorized_keys
  chown -R $username:$username /home/$username/.ssh
  chmod 600 /home/$username/.ssh/authorized_keys
  chmod 700 /home/$username/.ssh

  # Configure SSHD
  echo "Configuring SSHD..."
  sshd_config="/etc/ssh/sshd_config"
  if grep -q "^[#]*PubkeyAuthentication" "$sshd_config"; then
    echo "Updating PubkeyAuthentication to yes..."
    sed -i 's/^[#]*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"
  else
    echo "PubkeyAuthentication is not set. Adding configuration..."
    echo "PubkeyAuthentication yes" >> "$sshd_config"
  fi

  if ! grep -q "^MaxSessions 10" "$sshd_config"; then
    echo "Setting MaxSessions to 10..."
    echo "MaxSessions 10" >> "$sshd_config"
  else
    echo "MaxSessions is already set to 10."
  fi

  if ! grep -q "^MaxAuthTries 6" "$sshd_config"; then
    echo "Setting MaxAuthTries to 6..."
    echo "MaxAuthTries 6" >> "$sshd_config"
  else
    echo "MaxAuthTries is already set to 6."
  fi

  # Add Match User block
  if ! grep -q "Match User $username" "$sshd_config"; then
    echo "Adding Match User block for $username..."
    cat <<EOL >> "$sshd_config"

Match User $username
    PasswordAuthentication no
    PubkeyAuthentication yes
EOL
  else
    echo "Match User block for $username already exists."
  fi

  echo "Restarting sshd service..."
  systemctl restart sshd
}

# Function to configure sudoers
configure_sudoers() {
  username="proaxiom-vms"
  if ! grep -q "$username" /etc/sudoers; then
    echo "Configuring sudoers for $username..."
    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  else
    echo "Sudoers configuration for $username already exists."
  fi
}

# Run functions
display_logo
detect_os
check_package_manager
check_and_install_packages
configure_user_ssh
configure_sudoers

echo "Configuration complete."
 
