#!/bin/sh

iptables --flush INPUT
iptables --flush OUTPUT

iptables --policy INPUT DROP
iptables --policy OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
