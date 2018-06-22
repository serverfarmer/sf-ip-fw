#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.install


if [ "$HWTYPE" = "container" ]; then
	echo "skipping firewall setup on container"
	exit 0
elif [ -f /etc/sysconfig/iptables ] || [ -f /etc/sysconfig/ip6tables ]; then
	echo "skipping firewall setup (RHEL firewall is active)"
	exit 0
fi

if [ "$OSTYPE" = "debian" ]; then
	/opt/farm/ext/packages/utils/install.sh iptables

	if [ "`which ufw`" != "" ]; then
		echo "disabling ufw firewall"
		ufw status >/etc/local/.config/ufw.last-status
		ufw disable
		/opt/farm/ext/packages/utils/uninstall.sh ufw
	fi

	if ! grep -qFx $OSVER /opt/farm/ext/ip-fw/config/use-systemd.conf; then
		echo "setting up classic firewall"
		f=/etc/init.d/sf-firewall
		remove_link $f
		install_copy /opt/farm/ext/ip-fw/service/rc-debian.sh $f
		update-rc.d sf-firewall start 21 2 3 4 5 . stop 89 0 1 6 .
		$f restart
	elif [ ! -f /etc/systemd/system/sf-firewall.service ]; then
		echo "setting up systemd-based firewall"
		install_copy /opt/farm/ext/ip-fw/service/sf-firewall.service /etc/systemd/system/
		systemctl daemon-reload
		systemctl enable sf-firewall.service
		systemctl start sf-firewall.service
	else
		service sf-firewall restart
	fi

elif [ "$OSTYPE" = "redhat" ] && [ -x /sbin/chkconfig ]; then

	echo "setting up firewall"
	f=/etc/init.d/sf-firewall
	if [ "`chkconfig --list |grep sf-firewall`" = "" ]; then
		remove_link $f
		install_copy /opt/farm/ext/ip-fw/service/rc-redhat.sh $f
		chkconfig --add sf-firewall
	else
		chkconfig sf-firewall on
	fi
	$f restart

else
	echo "skipping firewall setup due to incompatible system type"
	exit 0
fi
