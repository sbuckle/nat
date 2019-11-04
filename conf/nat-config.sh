#!/bin/bash

function log { logger -t "vpc" -- $1; }

ETH0_MAC=$(cat /sys/class/net/eth0/address)
if [ $? -ne 0 ] ; then
	log "Unable to determine MAC address on eth0" 
	exit 1
fi

log "Determining the MAC address on eth0..."
VPC_CIDR=$(curl --silent --fail --retry 3 http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ETH0_MAC/vpc-ipv4-cidr-blocks)
if [ $? -ne 0 ] ; then
	VPC_CIDR="0.0.0.0/0"
else
	log "Retrieved the VPC CIDR range: ${VPC_CIDR}" 
fi

/sbin/iptables -t nat -A POSTROUTING -o eth0 -s ${VPC_CIDR} -j MASQUERADE

if [ $? -ne 0 ] ; then
	log "Configuration of NAT instance failed" 
	exit 1
fi

/sbin/iptables -n -t nat -L POSTROUTING | log

log "NAT configuration complete."
exit 0
