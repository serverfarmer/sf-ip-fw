## Overview

`sf-ip-fw` extension provides several building blocks to build your own firewall solution, based on raw iptables. You can build your firewall profiles for each machine as simple shell scripts, portable across all major Linux distributions:
- Debian since 5.0 (Lenny)
- Ubuntu since 8.04 LTS
- Raspbian all versions
- most Debian/Ubuntu clones
- RHEL since 6.0 (or even earlier versions except LXC support)
- all RHEL clones (CentOS, Oracle Linux, Scientific Linux etc.)

FreeBSD (ipfw) support is planned for further future. Want it faster? See [this page](https://github.com/sponsors/tomaszklim).


## Building your own firewall extension on top of Server Farmer

### Repository

First, you need a fresh, Github private repository named `firewall` (under your own Github username).

It should contain:
- `ranges` file - it extends [allocs](https://github.com/serverfarmer/sf-ip-allocs/blob/master/allocs) file with your own variables
- `setup.sh` script - it will be executed during extension setup, see below
- `start.sh` script - the startup script for your firewall, it will:
   - execute initial firewall scripts
   - load per-host firewall profiles
   - enable ssh accesses that should be enabled everywhere (in case something is wrong with per-host profiles, to prevent locking access to the host)
   - enable any other accesses that you want to be enabled globally (see SNMP example below)


### `setup.sh` script

```
#!/bin/sh

/opt/farm/scripts/setup/extension.sh sf-ip-allocs
/opt/farm/scripts/setup/extension.sh sf-ip-fw
/opt/farm/scripts/setup/extension.sh sf-ip-noipv6
/opt/farm/scripts/setup/extension.sh sf-secure-kernel

echo "enforcing /opt/farm/ext/firewall file/directory permissions"
chown -R root:root /opt/farm/ext/firewall
chmod -R go-rwx /opt/farm/ext/firewall

/opt/farm/ext/ip-fw/service/install.sh
```


### `start.sh` script

`/etc/farmconfig` file provides `$HOST` variable. It contains the hostname defined during Server Farmer setup - it doesn't need to match `/etc/hostname`.

`/etc/local/.config` directory contains several Server Farmer per-host settings files - mostly used to disable particular Server Farmer features on particular hosts, but also to configure monitoring-related details.

In the below example, `$CACTI` variable is defined in `ranges` file (see below).

```
#!/bin/sh
. /opt/farm/ext/ip-allocs/allocs
. /opt/farm/ext/firewall/ranges
. /etc/farmconfig

/opt/farm/ext/ip-fw/utils/load.sh
/opt/farm/ext/ip-fw/utils/pre-start.sh

# custom per-host rules first (to allow injecting DROP rules for ssh)
if [ -x /opt/farm/ext/firewall/hosts/$HOST.sh ]; then
    /opt/farm/ext/firewall/hosts/$HOST.sh
fi

fw="/opt/farm/ext/ip-fw/utils/accept.sh"

if [ -s /etc/local/.config/snmp.community ]; then
    $fw udp 161 $CACTI
fi

# default ssh accesses on all servers - this is the real line from firewall script, used for customers in Poland
$fw tcp 22 $NONROUTABLE $INEA $EASTWEST $PLUS $PLAY $TMOBILE $MULTIMEDIA $NETIA $TPNET
```


### `ranges` file

It is recommended to provide at least `$CACTI` variable in this file - containing the list of IP addresses of your SNMP monitoring applications (not necessarily [Cacti](https://cacti.net/)).

```
CACTI="5.6.7.8"
```


### Example per-host firewall profile script

```
#!/bin/sh
. /opt/farm/ext/ip-allocs/allocs
. /opt/farm/ext/firewall/ranges
. /etc/farmconfig

fw="/opt/farm/ext/ip-fw/utils/accept.sh"

# expose ports 80/443 to the whole world
$fw tcp 80 any
$fw tcp 443 any

# enable ssh access from:
# - custom IP range(s) defined in https://github.com/serverfarmer/sf-ip-allocs/blob/master/allocs file (additionally to these defined in last line of start.sh script)
# - custom IP(s) resolved from my.host.domain.com
$fw tcp 22 $SONERAFI my.host.domain.com

# enable ssh access from explicitly defined subnet
$fw tcp 22 1.2.3.0/24
```


### Example per-host profile for server hosting LXC containers

`$YOURLAN` variable is often defined in `ranges` file as either your LAN subnet, or list of particular IP addresses.

```
#!/bin/sh
. /opt/farm/ext/ip-allocs/allocs
. /opt/farm/ext/firewall/ranges
. /etc/farmconfig
. /etc/default/lxc-net

LOCALIF="enp0s3"

# dnsmasq - DHCP service for LXC containers
/opt/farm/ext/ip-fw/utils/accept-dhcp.sh

# masquerade for LXC outgoing traffic
/opt/farm/ext/ip-fw/utils/masquerade.sh $LOCALIF

fw="/opt/farm/ext/ip-fw/utils/accept.sh"
nat="/opt/farm/ext/ip-fw/utils/nat.sh"

# DNS for LXC containers ($LXC_NETWORK variable is taken from /etc/default/lxc-net file)
$fw udp 53 $LXC_NETWORK

# container port redirects
$nat $LOCALIF $LXC_BRIDGE tcp 9993   lxc-imap-server   993 $LXC_NETWORK $YOURLAN $UPTIMEROBOT  # IMAP service, additionally monitored by Uptimerobot.com
$nat $LOCALIF $LXC_BRIDGE tcp 22001  lxc-imap-server    22 $LXC_NETWORK $YOURLAN  # ssh access
$nat $LOCALIF $LXC_BRIDGE tcp 45364  lxc-imap-server 45364 any  # certbot authentication (exposed as port 80 on edge router)
```


### Example per-host profile with Docker support

This example assumes that server has public IP address.

`$DOCKERONLY` variable always refers to the default Docker subnet 172.16.0.0/12.

`$YOUROFFICE` variable should be defined in `ranges` file, as your office external IP address.

```
#!/bin/sh
. /opt/farm/ext/ip-allocs/allocs
. /opt/farm/ext/firewall/ranges
. /etc/farmconfig

/opt/farm/ext/ip-fw/utils/docker-reset.sh

fw="/opt/farm/ext/ip-fw/utils/accept.sh"
dck="/opt/farm/ext/ip-fw/utils/docker-accept.sh"

# expose ports 80/443 to the whole world (from webserver installed on host, NOT exposed from Docker container)
$fw tcp 80 any
$fw tcp 443 any

# Postgres on host, available only for Docker containers
$fw tcp 5432 $DOCKERONLY

# Docker ports available for programmers/devops to use for exposing services
# these ports are accessible from:
# - Docker subnet (to allow particular containers to connect to themselves)
# - your office external IP address (eg. for debug purposes)
$fw  tcp 3000:4999 $DOCKERONLY $YOUROFFICE
$dck tcp 3000:4999 $DOCKERONLY $YOUROFFICE
```


### Example per-host profile for internal LAN webserver, exposed via SSL-terminating proxy

This example assumes that `proxy` resolved to the IP address of your LAN proxy server. This way, unencrypted web traffic is exchanged only between the application webserver, and proxy.

It can be easily combined with LXC services, where you have eg. 500 LXC containers with Apache or something else (separately for each customer), and additional LXC container with Nginx responsible for terminating SSL connections, and keeping SSL certificates away from direct customer access.

```
#!/bin/sh
. /opt/farm/ext/ip-allocs/allocs
. /opt/farm/ext/firewall/ranges
. /etc/farmconfig

fw="/opt/farm/ext/ip-fw/utils/accept.sh"
$fw tcp 80 proxy
```
