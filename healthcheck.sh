#!/bin/sh
# This finds the internal DNS IP and attempts to ping it.
ping -i 10 -c 1 $(grep -Eo "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}" /etc/resolv.conf)
