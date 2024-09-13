#!/bin/bash

# Default Variables (change via command-line arguments)
REMOTE_USER="root"            # Default SSH user is root
REMOTE_HOST=""
REMOTE_DB_USER=""
REMOTE_DB_PASS=""
REMOTE_DB_NAMES="ALL"         # Default to import all databases
LOCAL_DB_USER="root"          # Default local MySQL user is root
LOCAL_DB_PASS=""

# Optional: Custom port for SSH (default is 22)
SSH_PORT=22

# Function to show usage/help
help_screen() {
    echo "Usage: $0 [options]"
    echo ""
    echo "This script imports a MySQL/MariaDB database from a remote server over SSH."
    echo "By default, it imports all databases using the root SSH user and root local MySQL user."
    echo ""
    echo "Options:"
    echo "  --remote-user=<ssh_user>        Remote SSH user (default: root)"
    echo "  --remote-host=<ssh_host>        Remote SSH server hostname or IP address (required)"
    echo "  --remote-db-user=<mysql_user>   Remote MySQL/MariaDB username (required)"
    echo "  --remote-db-pass=<mysql_pass>   Remote MySQL/MariaDB password (required)"
    echo "  --remote-db-names=<databases>   Specify 'ALL' for all databases or a comma-separated list (default: ALL)"
    echo "  --local-db-user=<mysql_user>    Local MySQL/MariaDB username (default: root)"
    echo "  --local-db-pass=<mysql_pass>    Local MySQL/MariaDB password (required)"
    echo "  --ssh-port=<port>               SSH port to connect to remote server (default: 22)"
    echo "  --help                          Display this help message"
    echo ""
    exit 0
}

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --remote-user=*)
        REMOTE_USER="${arg#*=}"
        shift
        ;;
        --remote-host=*)
        REMOTE_HOST="${arg#*=}"
        shift
        ;;
        --remote-db-user=*)
        REMOTE_DB_USER="${arg#*=}"
        shift
        ;;
        --remote-db-pass=*)
        REMOTE_DB_PASS="${arg#*=}"
        shift
        ;;
        --remote-db-names=*)
        REMOTE_DB_NAMES="${arg#*=}"
        shift
        ;;
        --local-db-user=*)
        LOCAL_DB_USER="${arg#*=}"
        shift
        ;;
        --local-db-pass=*)
        LOCAL_DB_PASS="${arg#*=}"
        shift
        ;;
        --ssh-port=*)
        SSH_PORT="${arg#*=}"
        shift
        ;;
        --help)
        help_screen
        ;;
        *)
        echo "Unknown option: $arg"
        help_screen
        ;;
    esac
done

# Check if required parameters are provided
if [[ -z "$REMOTE_HOST" || -z "$REMOTE_DB_USER" || -z "$REMOTE_DB_PASS" || -z "$LOCAL_DB_PASS" ]]; then
    echo "Error: Missing required parameters."
    help_screen
fi

# Function to import all databases
import_all_databases() {
    echo "Importing all databases from $REMOTE_HOST using $REMOTE_USER..."
    ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "sudo mysqldump --all-databases -u $REMOTE_DB_USER -p$REMOTE_DB_PASS" | mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASS"
}

# Function to import specific databases
import_specific_databases() {
    echo "Importing specific databases: $REMOTE_DB_NAMES from $REMOTE_HOST..."
    IFS=',' read -r -a db_array <<< "$REMOTE_DB_NAMES" # Split comma-separated DB names
    for db in "${db_array[@]}"
    do
        echo "Importing $db..."
        ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "sudo mysqldump -u $REMOTE_DB_USER -p$REMOTE_DB_PASS $db" | mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASS" "$db"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to import database $db"
        else
            echo "Successfully imported $db"
        fi
    done
}

# Step 2: Perform the database import based on the user's choice (all or specific)
if [[ "$REMOTE_DB_NAMES" == "ALL" ]]; then
    import_all_databases
else
    import_specific_databases
fi

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Database import failed."
    exit 1
fi

echo "Database import completed successfully."
