#!/bin/bash
# https://upload.wikimedia.org/wikipedia/commons/3/37/Netfilter-packet-flow.svg

if [ "$5" = "" ]; then
	echo "usage: $0 <input-interface> <protocol> <port> <target-host> <target-port>"
	exit 1
elif ! [[ $1 =~ ^[0-9a-zA-Z:-]+$ ]]; then
	echo "error: parameter $1 not conforming network interface name format"
	exit 1
elif [ "$2" != "tcp" ] && [ "$2" != "udp" ]; then
	echo "error: invalid protocol specified"
	exit 1
elif ! [[ $3 =~ ^[0-9]+$ ]]; then
	echo "error: parameter $3 not conforming port format"
	exit 1
elif ! [[ $5 =~ ^[0-9]+$ ]]; then
	echo "error: parameter $5 not conforming port format"
	exit 1
fi

if [[ $4 =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$ ]]; then
	target=$4:$5
elif [ "`getent hosts $4 |grep -v ^127`" != "" ]; then
	ip=`getent hosts $4 |cut -f1 -d' '`
	target=$ip:$5
elif [ "`cat /var/lib/misc/dnsmasq.*.leases |cut -f3,4 -d' ' |grep $4$`" != "" ]; then
	ip=`cat /var/lib/misc/dnsmasq.*.leases |cut -f3,4 -d' ' |grep $4$ |cut -f1 -d' '`
	target=$ip:$5
else
	echo "error: parameter $4 not conforming ip/hostname format"
	exit 1
fi

interface=$1
protocol=$2
port=$3

iptables -t nat -A OUTPUT -o lo ! -s 127.0.0.0/8 -p $protocol --dport $port -j DNAT --to $target
iptables -t nat -A PREROUTING -i $interface      -p $protocol --dport $port -j DNAT --to $target
