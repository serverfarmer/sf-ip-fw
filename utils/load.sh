#!/bin/sh
. /etc/farmconfig

if [ "`uname`" = "Linux" ] && [ "$HWTYPE" != "container" ] && [ "$HWTYPE" != "lxc" ]; then
	if ! /sbin/lsmod 2>/dev/null |grep -q ip_tables; then
		echo -n "Inserting kernel firewall modules: "
		modprobe -a ip_tables iptable_filter ip_conntrack ipt_state || exit 0
		echo "done."
	fi
fi
