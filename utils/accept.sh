#!/bin/bash

append_rule() {
	protocol=$1
	port=$2
	ip=$3

	if [ "$protocol" = "tcp" ]; then
		iptables -A INPUT -p tcp -m state --state NEW -j ACCEPT -s $ip --dport $port
	else
		iptables -A INPUT -p udp -j ACCEPT -s $ip --dport $port
	fi
}


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

if [ "$1" = "any" ]; then
	if [ "$protocol" = "tcp" ]; then
		iptables -A INPUT -p tcp -m state --state NEW -j ACCEPT --dport $port
	else
		iptables -A INPUT -p udp -j ACCEPT --dport $port
	fi
else
	for ip in $@; do
		if [[ $ip =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9/]+$ ]]; then
			append_rule $protocol $port $ip
		elif [ "`getent hosts $ip`" != "" ]; then
			ip2=`getent hosts $ip |cut -f1 -d' '`
			append_rule $protocol $port $ip2
		else
			echo "error: parameter $ip not conforming ip range format, skipping it"
		fi
	done
fi
