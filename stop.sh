[ -f supervisord.pid ] || ( echo >&2 Already running && exit 1 )

kill $(cat supervisord.pid)
chown moment:moment dhcpd.conf
echo 0 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -F  POSTROUTING
