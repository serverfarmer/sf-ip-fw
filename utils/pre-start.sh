#!/bin/sh

ip6tables --flush
ip6tables --policy INPUT DROP
ip6tables --policy OUTPUT DROP
ip6tables --policy FORWARD DROP

iptables --flush INPUT
iptables --flush OUTPUT

iptables --policy INPUT DROP
iptables --policy OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
