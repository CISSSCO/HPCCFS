#!/bin/bash

LDAP_ADMIN="cn=Manager,dc=hpc,dc=local"
BASE_DN="dc=hpc,dc=local"

USERNAME=$1

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# Check if user exists
USER_EXISTS=$(ldapsearch -x \
-b "ou=People,${BASE_DN}" "(uid=${USERNAME})" dn \
| grep "^dn:")

if [ -z "$USER_EXISTS" ]; then
    echo "ERROR: User ${USERNAME} does not exist!"
    exit 1
fi

echo
echo "=================================="
echo "LDAP Password Change"
echo "=================================="
echo "Username : ${USERNAME}"
echo "=================================="

# Take password securely
echo
read -s -p "Enter new password: " PASSWORD1
echo

read -s -p "Confirm new password: " PASSWORD2
echo

# Check password match
if [ "$PASSWORD1" != "$PASSWORD2" ]; then
    echo
    echo "ERROR: Passwords do not match!"
    exit 1
fi

# Generate LDAP password hash
PASSWORD_HASH=$(slappasswd -s "$PASSWORD1")

# Create LDIF file
cat > /tmp/${USERNAME}_password.ldif <<EOF
dn: uid=${USERNAME},ou=People,${BASE_DN}
changetype: modify
replace: userPassword
userPassword: ${PASSWORD_HASH}
EOF

echo
echo "Updating LDAP password..."

ldapmodify -x \
-D "${LDAP_ADMIN}" \
-W \
-f /tmp/${USERNAME}_password.ldif

if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Failed to change password!"
    exit 1
fi

echo
echo "=================================="
echo "Password updated successfully"
echo "=================================="
echo "Username : ${USERNAME}"
echo "=================================="
