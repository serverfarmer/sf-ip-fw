#!/bin/sh

# obvious way, unfortunately incompatible with DNAT:
# iptables -t nat --flush PREROUTING

if [ ! -x /usr/bin/dockerd ]; then
	echo "warning: no dockerd found, skipping PREROUTING table changes"
	exit 0
fi

rules=`iptables -nvL -t nat --line-numbers |grep DOCKER |grep ADDRTYPE |grep -v 127 |cut -f1 -d' ' |tac`

for rule in $rules; do
	iptables -t nat -D PREROUTING $rule
done
