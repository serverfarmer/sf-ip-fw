#!/bin/sh

# obvious way, unfortunately incompatible with DNAT:
# iptables -t nat --flush PREROUTING

rules=`iptables -nvL -t nat --line-numbers |grep DOCKER |grep ADDRTYPE |cut -f1 -d' ' |tac`

for rule in $rules; do
	iptables -t nat -D PREROUTING $rule
done
