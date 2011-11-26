source settings


function bring_up_nm_con(){
    echo "Bring up network manager interface"
    ( nmcli con status | grep "$WAN_NAME" > /dev/null ) && echo "Interface already up" && return
    uuid=$(nmcli con | grep "$WAN_NAME" | grep -o '[0-9]*-[^ ]*')
    nmcli con up uuid $uuid || exit 1
}

function ensure_installed(){
    (dpkg -l $1 | grep ii > /dev/null ) || apt-get install $1
}

[ ! -f settings ] && echo >&2 You need to make settings file && exit 1
[ -f supervisord.pid ] && echo >&2 Already running && exit 1

bash hostapd.tmpl > hostapd.conf # Put secrets in the configuration file


[ "$USES_NETWORK_MANAGER" ] && bring_up_nm_con

ensure_installed hostapd
ensure_installed dhcp3-server
ensure_installed supervisor

ifconfig wlan0 10.10.0.1
chown dhcpd:dhcpd dhcpd.conf
touch dhcpd.pid
chown dhcpd:dhcpd dhcpd.pid
cp /usr/sbin/dhcpd mydhcpd # stupid apparmor hack - I want to run on other people's machines after all
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE
supervisord -c route.svd


