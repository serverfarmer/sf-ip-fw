#!/bin/sh

iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -j DROP

ip6tables --flush
ip6tables --policy INPUT DROP
ip6tables --policy OUTPUT DROP
ip6tables --policy FORWARD DROP
