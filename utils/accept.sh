#!/bin/bash

append_rule() {
	protocol=$1
	port=$2
	ip=$3

	if [ "$port" = "any" ]; then
		dport=""
	else
		dport="--dport $port"
	fi

	if [ "$ip" = "any" ]; then
		sip=""
	else
		sip="-s $ip"
	fi

	if [ "$protocol" = "tcp" ]; then
		iptables -A INPUT -p tcp -m state --state NEW -j ACCEPT $sip $dport
	else
		iptables -A INPUT -p udp -j ACCEPT $sip $dport
	fi
}


if [ "$3" = "" ]; then
	echo "usage: $0 <protocol> <port> <ip-range> [ip-range] [...]"
	exit 1
elif [ "$1" != "tcp" ] && [ "$1" != "udp" ]; then
	echo "error: invalid protocol specified"
	exit 1
elif ! [[ $2 =~ ^[0-9:]+$ ]] && [ "$2" != "any" ]; then
	echo "error: parameter $2 not conforming port(s) format"
	exit 1
elif [ "$2" = "any" ] && [ "$3" = "any" ]; then
	echo "error: cannot set both port and source ip to any, choose only one of them"
	exit 1
fi

protocol=$1
port=$2
shift
shift

if [ "$1" = "any" ]; then
	append_rule $protocol $port $1
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
