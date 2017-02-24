#!/bin/sh
### BEGIN INIT INFO
# Provides:          sf-firewall
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Server Farmer Firewall
### END INIT INFO


if [ ! -x /opt/farm/ext/firewall/start.sh ]; then
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
