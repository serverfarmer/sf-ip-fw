#!/bin/sh
#
# Init file for Server Farmer Firewall
#
# chkconfig: 2345 08 92
# description: Server Farmer Firewall


if [ ! -x /opt/farm/ext/firewall/start.sh ] || [ -f /etc/sysconfig/iptables ] || [ -f /etc/sysconfig/ip6tables ]; then
	exit 1
fi

case "$1" in
	start)
		echo -n "Starting firewall:"
		/opt/farm/ext/firewall/start.sh
		echo " done."
		;;
	stop)
		echo -n "Stopping firewall:"
		/opt/farm/ext/ip-fw/utils/stop.sh
		echo " done."
		;;
	restart)
		$0 stop && $0 start
		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
		;;
esac
