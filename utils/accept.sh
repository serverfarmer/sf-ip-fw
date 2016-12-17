#!/bin/bash

if [ "$3" = "" ]; then
	echo "usage: $0 <protocol> <port> <ip-range> [ip-range] [...]"
	exit 1
elif [ "$1" != "tcp" ] && [ "$1" != "udp" ]; then
	echo "error: invalid protocol specified"
	exit 1
elif ! [[ $2 =~ ^[0-9:]+$ ]]; then
	echo "error: parameter $2 not conforming port(s) format"
	exit 1
fi

protocol=$1
port=$2
shift
shift

if [ "$1" = "all" ]; then
	if [ "$protocol" = "tcp" ]; then
		iptables -A INPUT -p tcp -m state --state NEW -j ACCEPT --dport $port
	else
		iptables -A INPUT -p udp -j ACCEPT --dport $port
	fi
else
	for ip in $@; do
		if ! [[ $ip =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9/]+$ ]]; then
			echo "error: parameter $ip not conforming ip range format, skipping it"
		elif [ "$protocol" = "tcp" ]; then
			iptables -A INPUT -p tcp -m state --state NEW -j ACCEPT -s $ip --dport $port
		else
			iptables -A INPUT -p udp -j ACCEPT -s $ip --dport $port
		fi
	done
fi
