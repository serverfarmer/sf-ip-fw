#!/bin/sh
. /etc/farmconfig

if [ "`uname`" = "Linux" ] && [ "$HWTYPE" != "container" ] && [ "$HWTYPE" != "lxc" ]; then
	if ! /sbin/lsmod 2>/dev/null |grep -q conntrack_ftp; then
		echo -n "Inserting kernel ftp firewall module: "
		modprobe ip_conntrack_ftp || exit 0
		echo "done."
	fi
fi
