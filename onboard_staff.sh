=#!/bin/bash
# VNigeria Staff Onboarding Tool
# Interactive menu: batch onboarding, on-the-fly single user add, login status check, log viewer, and deactivate user

STAFF_FILE="/tmp/new_staff.txt"
GROUP="it-team"
LOG_FILE="/tmp/onboarding_log.txt"
NOTIFY_FILE="/tmp/notifications.log"
touch "$NOTIFY_FILE" "$LOG_FILE"
chmod 600 "$NOTIFY_FILE" "$LOG_FILE"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0;0m'

if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}This script must be run as root (use sudo).${NC}"
	exit 1
fi
if ! getent group "$GROUP" > /dev/null 2>&1; then
	groupadd "$GROUP"
fi

create_user() {
	local username="$1"

	if id "$username" > /dev/null 2>&1; then
		echo -e "${YELLOW}	SKIPPED (already exists): $username${NC}"
		echo "SKIPPED (already exists):  $username" | tee -a "$LOG_FILE" > /dev/null
		return 1
	fi

	if useradd -m -s /bin/bash "$username"; then
		local genpass
		genpass=$(openssl rand -base64 12)
		echo "$username:$genpass" | chpasswd
		chage -d 0 "$username"
		echo -e "${GREEN}	CREATED${NC} -- account active, password reset required at first login"
                echo "CREATED:  $username" | tee -a "$LOG_FILE" > /dev/null

		{
			echo "To: $username@vnigeria.local"
                	echo "Subject: Welcome to VNigeria -- Your account is ready"
                	echo "Body: Hi $username, your account has been created."
         	      	echo "		Temporary password: $genpass (change required at first login)"
			echo "---"
		} >> "$NOTIFY_FILE"
		echo -e "${GREEN}	 NOTIFIED${NC} -- welcome email logged"
                return 0
	else
		echo -e "${RED}      FAILED to create: $username${NC}"
                echo "FAILED to create:  $username" | tee -a "$LOG_FILE" > /dev/null
                return 1
	fi
}

batch_onboard() {
        echo ""
        echo -e "${CYAN}---  Batch Onboarding from ${STAFF_FILE} ---${NC}"
        echo ""

	if [ ! -f "$STAFF_FILE" ]; then
		echo -e "${RED}Staff list not found at $STAFF_FILE${NC}"
                return
        fi
	echo "========================================" | tee -a "$LOG_FILE"
        echo "Batch Onboarding - $(date)" | tee -a "$LOG_FILE"
	echo "========================================" | tee -a "$LOG_FILE"

	local created=0
	local skipped=0

	while IFS= read -r username; do
                [ -z "$username" ] && continue
                echo -e "${CYAN}--> Processing; $username${NC}"
                if create_user "$username"; then
                        created=$((created + 1))
                 else
                 	skipped=$((skipped + 1))
                fi
                echo ""
        done < "$STAFF_FILE"

        echo "Batch complete. Created: $created  Skipped: $skipped" | tee -a "$LOG_FILE"
        echo ""
}

add_single_user() {
	echo ""
	echo -e "${CYAN}--- Add a New User ---${NC}"
	read -p "Enter new username: " newuser

	if [ -z "$newuser" ]; then
		echo -e "${RED}No username entered. Cancelled.${NC}"
		return
	fi

	read -p "Confirm: create user '$newuser' (y/n): " confirm
	if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
		echo -e "${YELLOW}Cancelled.${NC}"
		return
	fi

	echo ""
	echo -e "${CYAN}--> Processing: $newuser${NC}"
	if create_user "$newuser"; then
		read -p "Grant this user IT-team access? (y/n): " grant_it
		if [ "$grant_it" = "y" ] || [ "$grant_it" = "Y" ]; then
			usermod -aG "$GROUP" "$newuser"
		echo -e "${GREEN}	Added to $GROUP${NC}"
		fi
	fi
	echo ""
	echo -e "${CYAN}Verifying access immediately:${NC}"
	id "$newuser"
}

check_login_status() {
	echo ""
	echo -e "${CYAN}--- Login Status (it-team members) ---${NC}"
	local members
	local gid
	gid=$(getent group "$GROUP" | cut -d: -f3)
	members=$(getent passwd | awk -F: -v g="$gid" '$4==g {print $1}')
	if [ -z "$members" ]; then
		echo -e "${YELLOW}No members in $GROUP yet.${NC}"
		return
	fi
	for u in $members;do
		status=$(lastlog -u "$u" | tail -1)
		echo -e "${YELLOW}$u:${NC} $status"
	done
	echo ""
}

view_log() {
	echo ""
	echo -e "${CYAN}--- Onboarding Log ---${NC}"
	if [ -f "$LOG_FILE" ]; then
		cat "$LOG_FILE"
	else
		echo -e "${YELLOW}No log yet.${NC}"
	fi
	echo ""
}

deactivate_user() {
	echo ""
	echo -e "${CYAN}--- Deactivate a User ---${NC}"
	read -p "Enter username to deactivate: " target

	if [ -z "$target" ]; then
		echo -e "${RED}No username entered. Cancelled.${NC}"
		return
	fi

	if ! id "$target" > /dev/null 2>&1; then
		echo -e "${RED}No such user: $target${NC}"
		return
	fi

	read -p "Confirm: lock account '$target'? (y/n): " confirm
	if [ "$confirm" != "y" ]; then
		echo -e "${YELLOW}Cancelled.${NC}"
		return
	fi

	if usermod -L "$target"; then
		echo -e "${GREEN}	LOCKED${NC} -- $target can no longer log in"
		echo "DEACTIVATED: $target" | tee -a "$LOG_FILE" > /dev/null
	else
		echo -e "${RED}		FAILED to lock: $target${NC}"
	fi
		echo ""
}

while true; do
	clear
	echo -e "${CYAN}=======================================================${NC}"
	echo -e "${CYAN}   VNigeria Staff Onboarding Tool${NC}"
	echo -e "${CYAN}=======================================================${NC}"
	echo "1) Batch onboard staff from list"
	echo "2) Add a new user on the fly"
	echo "3) Check login status of it-team"
	echo "4) View onboarding log"
	echo "5) Deactivate a user"
	echo "6) Exit"
	echo ""
	read -p "Choose an option (1-6): " choice

	case "$choice" in
		1) batch_onboard ;;
		2) add_single_user ;;
		3) check_login_status ;;
		4) view_log ;;
		5) deactivate_user ;;
		6) echo -e "${GREEN}Goodbye.${NC}"; exit 0 ;;
		*) echo -e "${RED}Invalid option.${NC}" ;;
	esac

	echo""
	read -p "Press Enter to return to menu..." dummy
done


