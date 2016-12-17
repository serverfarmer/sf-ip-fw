#!/bin/bash
# https://upload.wikimedia.org/wikipedia/commons/3/37/Netfilter-packet-flow.svg

if [ "$4" = "" ]; then
	echo "usage: $0 <input-interface> <protocol> <port> <target-host-and-port>"
	exit 1
elif ! [[ $1 =~ ^[0-9a-zA-Z:-]+$ ]]; then
	echo "error: parameter $1 not conforming network interface name format"
	exit 1
elif [ "$2" != "tcp" ]; then
	echo "error: only tcp protocol is supported for now"
	exit 1
elif ! [[ $3 =~ ^[0-9]+$ ]]; then
	echo "error: parameter $3 not conforming port format"
	exit 1
elif ! [[ $4 =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+[:][0-9]+$ ]]; then
	echo "error: parameter $4 not conforming host:port format"
	exit 1
fi

interface=$1
port=$3
target=$4

iptables -t nat -A PREROUTING -i $interface -p tcp --dport $port -j DNAT --to $target
