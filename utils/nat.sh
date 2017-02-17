#!/bin/bash
# https://upload.wikimedia.org/wikipedia/commons/3/37/Netfilter-packet-flow.svg

if [ "$7" = "" ]; then
	echo "usage: $0 <public-interface> <nat-loopback-interface> <protocol> <port> <target-host> <target-port> <ip-range> [ip-range] [...]"
	exit 1
elif ! [[ $1 =~ ^[0-9a-zA-Z:-]+$ ]]; then
	echo "error: parameter $1 not conforming network interface name format"
	exit 1
elif ! [[ $2 =~ ^[0-9a-zA-Z:-]+$ ]]; then
	echo "error: parameter $2 not conforming network interface name format"
	exit 1
elif [ "$3" != "tcp" ] && [ "$3" != "udp" ]; then
	echo "error: invalid protocol specified"
	exit 1
elif ! [[ $4 =~ ^[0-9]+$ ]]; then
	echo "error: parameter $4 not conforming port format"
	exit 1
elif ! [[ $6 =~ ^[0-9]+$ ]]; then
	echo "error: parameter $6 not conforming port format"
	exit 1
fi

if [[ $5 =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$ ]]; then
	target=$5:$6
elif [ "`getent hosts $5 |grep -v ^127 |grep -v :`" != "" ]; then
	ip=`getent hosts $5 |cut -f1 -d' '`
	target=$ip:$6
elif [ "`cat /var/lib/misc/dnsmasq.*.leases |cut -f3,4 -d' ' |grep $5$`" != "" ]; then
	ip=`cat /var/lib/misc/dnsmasq.*.leases |cut -f3,4 -d' ' |grep $5$ |cut -f1 -d' '`
	target=$ip:$6
else
	echo "error: parameter $5 not conforming ip/hostname format"
	exit 1
fi

public_interface=$1
nat_lo_interface=$2
protocol=$3
port=$4
shift
shift
shift
shift
shift
shift

iptables -t nat -A OUTPUT -o lo ! -s 127.0.0.0/8 -p $protocol --dport $port -j DNAT --to $target

if [ "$1" = "any" ]; then
	iptables -t nat -A PREROUTING -i $public_interface -p $protocol --dport $port -j DNAT --to $target
	iptables -t nat -A PREROUTING -i $nat_lo_interface -p $protocol --dport $port -j DNAT --to $target
else
	for ip in $@; do
		if [[ $ip =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9/]+$ ]]; then
			iptables -t nat -A PREROUTING -i $public_interface -p $protocol -s $ip --dport $port -j DNAT --to $target
			iptables -t nat -A PREROUTING -i $nat_lo_interface -p $protocol -s $ip --dport $port -j DNAT --to $target
		elif [ "`getent hosts $ip |grep -v ^127 |grep -v :`" != "" ]; then
			ip2=`getent hosts $ip |cut -f1 -d' '`
			iptables -t nat -A PREROUTING -i $public_interface -p $protocol -s $ip2 --dport $port -j DNAT --to $target
			iptables -t nat -A PREROUTING -i $nat_lo_interface -p $protocol -s $ip2 --dport $port -j DNAT --to $target
		else
			echo "error: parameter $ip not conforming ip range format, skipping it"
		fi
	done
fi
