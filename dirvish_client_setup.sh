#!/bin/bash

# Variables
USER="dirvish"
SSH_DIR="/home/$USER/.ssh"
AUTHORIZED_KEYS_FILE="$SSH_DIR/authorized_keys2"

# Parse command line arguments
for arg in "$@"
do
    case $arg in
        --dirvish-server-key=*)
        SSH_KEY="${arg#*=}"
        shift # Remove argument from processing
        ;;
        *)
        echo "Usage: $0 --dirvish-server-key=<your-ssh-key>"
        exit 1
        ;;
    esac
done

# Check if SSH_KEY is set
if [ -z "$SSH_KEY" ]; then
    echo "Error: SSH key not provided. Use --dirvish-server-key=<your-ssh-key>"
    exit 1
fi

# Create dirvish user if not exists
if id "$USER" &>/dev/null; then
    echo "User $USER already exists."
else
    adduser --disabled-password --gecos "Dirvish backup user" $USER
    echo "User $USER created."
fi

# Add user to sudoers for rsync without password
if ! grep -q "$USER ALL = NOPASSWD: /usr/bin/rsync" /etc/sudoers; then
    echo "$USER ALL = NOPASSWD: /usr/bin/rsync" >> /etc/sudoers
    echo "Added $USER to sudoers for NOPASSWD rsync."
else
    echo "$USER already has sudoers permissions for rsync."
fi

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
  mkdir -p "$SSH_DIR"
  echo "Directory $SSH_DIR created."
else
  echo "Directory $SSH_DIR already exists."
fi

# Change ownership and permissions of .ssh directory
chown $USER:$USER "$SSH_DIR"
chmod 700 "$SSH_DIR"
echo "Ownership and permissions set for $SSH_DIR."

# Create the authorized keys file and add the SSH key
echo "$SSH_KEY" > "$AUTHORIZED_KEYS_FILE"
chown $USER:$USER "$AUTHORIZED_KEYS_FILE"
chmod 600 "$AUTHORIZED_KEYS_FILE"
echo "SSH key added to $AUTHORIZED_KEYS_FILE, and permissions set."
