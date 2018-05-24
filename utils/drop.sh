#!/bin/bash

drop_rule() {
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

	iptables -A INPUT -p $protocol -j DROP $sip $dport
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
fi

protocol=$1
port=$2
shift
shift

for ip in $@; do
	if [[ $ip =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9/]+$ ]]; then
		drop_rule $protocol $port $ip
	elif [ "`getent hosts $ip |grep -v ^127 |grep -v :`" != "" ]; then
		ip2=`getent hosts $ip |cut -f1 -d' '`
		drop_rule $protocol $port $ip2
	else
		echo "error: parameter $ip not conforming ip range format, skipping it"
	fi
done
