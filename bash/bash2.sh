# This script is to be run after having taken the following actions first:
# apt-get update -y
# apt-get install virtualbox-guest-utils virtualbox-guest-dkms -y
# reboot

# Configuring the client's hostname
hostnamectl set-hostname DNS-Client

# Configuring the network interface
ifconfig enp0s3 192.168.1.10 netmask 255.255.255.0

# Specifying the DNS resolver
sed -i 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/192.168.1.254/g' /etc/resolv.conf

# Removing the 'search station' like from the /etc/resolv.conf file
sed -i 's/search\sstation//g' /etc/resolv.conf

exit 0


#-------------------

### Description: This script checks whether the user's input matches an existing mapping inside the /etc/hosts file in order to avoid duplication.
### Written by: Nicholas Doropoulos
### Version: 1
echo "Enter a hostname or an IP address : "
read input
if grep -qF "$input" /etc/hosts; then
   echo "The supplied input already exists in the mapping(s) below: "
   echo ""
   grep -n $input /etc/hosts
else
   echo "There is no mapping in the hosts file that matches your input."
fi

exit 0


#--------------

### Description: This script configures a cache-only DNS server
### Written by: Nicholas Doropoulos
### Version: 1

#=========#
# MAIN BODY
#=========#

# Update the software repositories
apt-get update -y

# Install the bind service
apt-get install bind9 bind9utils -y

# Configure the network interface
ifconfig enp0s3 192.168.1.254 netmask 255.255.255.0

# Navigate into bind
cd /etc/bind/

# Populate the named.conf.options file
cat > named.conf.options <<- "EOF"
acl "trusted" {

	192.168.1.0/24;

};

options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable 
	// nameservers, you probably want to use them as forwarders.  
	// Uncomment the following block, and insert the addresses replacing 
	// the all-0's placeholder.
	
	recursion yes;
	allow-query { localhost; trusted; };
	allow-query-cache { localhost; trusted; };
	allow-recursion { localhost; trusted; };
	
	forwarders {
	 	192.168.1.1;
	};

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	
	forward only;
	//dnssec-validation auto;

	auth-nxdomain no;    # conform to RFC1035
};
EOF

# Populate the named.conf.local file
cat > named.conf.local <<- "EOF"
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "intranet.local" {

	type forward;
	forward only;
	
	forwarders {
		
		192.168.1.100;
		192.168.1.101;
	
	};

};
EOF

# Verify the syntax of the named.conf file
named-checkconf -z named.conf

# Restart the bind service for the changes to take effect
systemctl restart bind9

exit 0


#------------------------------


#!/bin/bash
### Description: This script configures an authoritative DNS server
### Written by: Nicholas Doropoulos
### Version: 1

#=========#
# MAIN BODY
#=========#

# Update the software repositories
apt-get update -y

# Install the bind service
apt-get install bind9 bind9utils -y

# Create a 'zones' directory for easier management
mkdir /etc/bind/zones

# Create the zones in the /etc/bind/named.conf.local file
echo -e "zone \"mydomain.com\" IN { \ntype master; \nfile \"/etc/bind/zones/forward.mydomain.com\"; \nallow-query { any; }; \n}; \n \nzone \"1.1.10.in-addr.arpa\" IN { \ntype master; \nfile \"/etc/bind/zones/reverse.mydomain.com\"; \n};" >> /etc/bind/named.conf.local

# Create the DNS forward and reverse lookup zones
touch /etc/bind/zones/forward.mydomain.com /etc/bind/zones/reverse.mydomain.com

# Assign the correct permissions inside the bind directory
chown -R bind:bind /etc/bind
chmod -R 755 /etc/bind

# Allow the bind service through the firewall
ufw allow bind9

# Create the forward.mydomain.com file
cat > /etc/bind/zones/forward.mydomain.com <<- "EOF"
$TTL 86400
@       IN      SOA     nameserver.mydomain.com.        mydomain.com. (
                        2       ; Serial
                        604800  ; Refresh
                        86400   ; Retry
                        2419200 ; Expire
                        604800  ; Negative Cache TTL
)
; NAMESERVER DEFINITIONS
@       IN      NS      nameserver.mydomain.com.
; A RECORD DEFINITIONS
nameserver      IN      A       10.1.1.80
EOF

# Create the reverse.mydomain.com file
cat > /etc/bind/zones/reverse.mydomain.com <<- "EOF"
$TTL 86400
@       IN      SOA     nameserver.mydomain.com.        mydomain.com. (
                        2       ; Serial
                        604800  ; Refresh
                        86400   ; Retry
                        2419200 ; Expire
                        604800  ; Negative Cache TTL
)
; NAMESERVER DEFINITIONS
@       IN      NS      nameserver.mydomain.com.
; POINTER RECORDS
80      IN      PTR     nameserver.mydomain.com.
EOF

# Restart the bind service in order for the changes to take effect
systemctl restart bind9

# Enable the bind service to survive reboots
systemctl enable bind9

# Verify the syntax of the named.conf file
named-checkconf -z /etc/bind/named.conf

# Validate the zones' syntax
named-checkzone mydomain.com /etc/bind/zones/forward.mydomain.com
named-checkzone 1.1.10.in-addr.arpa /etc/bind/zones/reverse.mydomain.com

# Verify that the DNS server is listening on port 53
netstat -tulpen | grep 53

exit 0
