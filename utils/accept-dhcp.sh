#!/bin/sh

iptables -A INPUT -p udp -j ACCEPT --sport 67:68 --dport 67:68
