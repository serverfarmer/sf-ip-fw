#!/bin/sh

# TODO: FreeBSD ipfw support:
#   https://gist.github.com/rwoeber/1010044/55de2c1920e0df6c488ac4d14f3cc2eca796efb4
#   https://www.cyberciti.biz/faq/howto-setup-freebsd-ipfw-firewall/
#   https://www.babaei.net/blog/2015/07/30/freebsd-block-brute-force-attacks-using-sshguard-and-ipfw-firewall/

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
