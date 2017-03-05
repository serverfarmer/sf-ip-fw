#!/bin/bash

if [ "$1" = "" ]; then
	echo "usage: $0 <interface>"
	exit 1
elif ! [[ $1 =~ ^[0-9a-zA-Z:-]+$ ]]; then
	echo "error: parameter $1 not conforming network interface name format"
	exit 1
fi

iptables -t nat -A POSTROUTING -o $1 -j MASQUERADE
