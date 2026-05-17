#!/bin/bash 

LDAP_ADMIN="cn=Manager,dc=hpc,dc=local"
BASE_DN="dc=hpc,dc=local"

USERNAME=$1
UIDNUM=$2
GIDNUM=$3

if [ $# -ne 3 ]; then
    echo "Usage: $0 <username> <uid> <gid>"
    exit 1
fi

# Check if user already exists
USER_EXISTS=$(ldapsearch -x \
-b "ou=People,${BASE_DN}" "(uid=${USERNAME})" dn \
| grep "^dn:")

if [ ! -z "$USER_EXISTS" ]; then
    echo "ERROR: User ${USERNAME} already exists!"
    exit 1
fi

# Check if group already exists
GROUP_EXISTS=$(ldapsearch -x \
-b "ou=Groups,${BASE_DN}" "(cn=${USERNAME})" dn \
| grep "^dn:")

if [ ! -z "$GROUP_EXISTS" ]; then
    echo "ERROR: Group ${USERNAME} already exists!"
    exit 1
fi

PASSWORD="${USERNAME}@@123"

PASSWORD_HASH=$(slappasswd -s "$PASSWORD")

echo
echo "=================================="
echo "Creating LDAP User"
echo "=================================="
echo "Username : ${USERNAME}"
echo "UID      : ${UIDNUM}"
echo "GID      : ${GIDNUM}"
echo "=================================="

# Create private group LDIF
cat > /tmp/${USERNAME}_group.ldif <<EOF
dn: cn=${USERNAME},ou=Groups,${BASE_DN}
objectClass: posixGroup
cn: ${USERNAME}
gidNumber: ${GIDNUM}
EOF

# Create user LDIF
cat > /tmp/${USERNAME}.ldif <<EOF
dn: uid=${USERNAME},ou=People,${BASE_DN}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ${USERNAME}
sn: ${USERNAME}
uid: ${USERNAME}
uidNumber: ${UIDNUM}
gidNumber: ${GIDNUM}
homeDirectory: /home/${USERNAME}
loginShell: /bin/bash
userPassword: ${PASSWORD_HASH}
EOF

echo
echo "Adding LDAP group..."

ldapadd -x \
-D "${LDAP_ADMIN}" \
-W \
-f /tmp/${USERNAME}_group.ldif

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create LDAP group!"
    exit 1
fi

echo
echo "Adding LDAP user..."

ldapadd -x \
-D "${LDAP_ADMIN}" \
-W \
-f /tmp/${USERNAME}.ldif

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create LDAP user!"
    exit 1
fi

echo
echo "=================================="
echo "LDAP User Created Successfully"
echo "=================================="
echo "Username : ${USERNAME}"
echo "Password : ${PASSWORD}"
echo "UID      : ${UIDNUM}"
echo "GID      : ${GIDNUM}"
echo "=================================="
