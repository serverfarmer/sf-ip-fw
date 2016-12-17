#!/bin/sh

iptables --flush INPUT
iptables --flush OUTPUT

iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT

ip6tables --flush
ip6tables --policy INPUT ACCEPT
ip6tables --policy OUTPUT ACCEPT
ip6tables --policy FORWARD ACCEPT
