#!/bin/bash 

LDAP_ADMIN="cn=Manager,dc=hpc,dc=local"
BASE_DN="dc=hpc,dc=local"

USERNAME=$1

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

echo
echo "=================================="
echo "Deleting LDAP User"
echo "=================================="
echo "Username : ${USERNAME}"
echo "=================================="

echo
echo "Deleting LDAP user entry..."

ldapdelete -x \
-D "${LDAP_ADMIN}" \
-W \
"uid=${USERNAME},ou=People,${BASE_DN}"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to delete LDAP user!"
    exit 1
fi

echo
echo "LDAP user deleted successfully."

# Ask about deleting group
echo
read -p "Delete LDAP group '${USERNAME}'? (y/n): " DELETE_GROUP

case $DELETE_GROUP in
    y|Y)

        ldapdelete -x \
        -D "${LDAP_ADMIN}" \
        -W \
        "cn=${USERNAME},ou=Groups,${BASE_DN}"

        if [ $? -eq 0 ]; then
            echo "LDAP group deleted successfully."
        else
            echo "WARNING: Failed to delete LDAP group."
        fi
        ;;

    n|N)
        echo "Skipping LDAP group deletion."
        ;;

    *)
        echo "Invalid option. Skipping group deletion."
        ;;
esac

# Ask about deleting home directory
echo
read -p "Delete home directory '/home/${USERNAME}'? (y/n): " DELETE_HOME

case $DELETE_HOME in
    y|Y)

        if [ -d "/home/${USERNAME}" ]; then
            sudo rm -rf "/home/${USERNAME}"

            if [ $? -eq 0 ]; then
                echo "Home directory deleted successfully."
            else
                echo "WARNING: Failed to delete home directory."
            fi
        else
            echo "Home directory does not exist."
        fi
        ;;

    n|N)
        echo "Skipping home directory deletion."
        ;;

    *)
        echo "Invalid option. Skipping home deletion."
        ;;
esac

echo
echo "=================================="
echo "User cleanup completed"
echo "=================================="
