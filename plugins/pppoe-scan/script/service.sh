#!/bin/bash /etc/ikcommon
script_path=$(readlink -f "${BASH_SOURCE[0]}")
plugin_dir=$(dirname "$script_path")
Include interface.sh

__check_param()
{
    check_varl \
        'interface ifname or == "auto"' \
        'attempts > 0 and <= 10' \
        'timeout > 0 and <= 60'
}

__show_interface()
{
    local interface=$(interface_get_ifname_comment_json all auto)
    json_append __json_result__ interface:json
}

start()
{
    __check_param || exit 1
    stop
    touch /tmp/on_pppoe
    rm -f /tmp/pppoe_scan

    if [ ! -f "/usr/bin/pppoe-discovery" ]; then
        chmod +x $plugin_dir/../bin/pppoe-discovery
        ln -fs $plugin_dir/../bin/pppoe-discovery /usr/bin/pppoe-discovery
    fi
    
    if [ "${interface}" == "auto" ]; then
        # get first wan
        interface="$(cat $IK_DIR_CACHE/ifname/wan_phy | head -n 1)"
    fi

    echo -e "interface=$interface\nattempts=$attempts\ntimeout=$timeout" >/tmp/pppoe_scan.conf

    echo 'Start PPPoE scan ...' > /tmp/pppoe_scan
    echo '--------------------------------------------------' >> /tmp/pppoe_scan
    (pppoe-discovery -I "$interface" -a "$attempts" -t "$timeout" >> /tmp/pppoe_scan 2>&1; rm -f /tmp/on_pppoe) >/dev/null 2>&1 &
}

stop()
{
    if [ ! -e "/tmp/pppoe_scan.conf" ]; then
        return
    fi

    local $(cat /tmp/pppoe_scan.conf)

    ps -w | grep "pppoe-discovery -I $interface" | grep -v grep | awk '{system("kill "$1)}'

    rm -f /tmp/on_pppoe
}

show()
{
    Show __json_result__
}

__show_interface()
{
    local interface=$(interface_get_ifname_comment_json wan_phy,lan auto)
    json_append __json_result__ interface:json
}

__show_data()
{
    local `cat /tmp/pppoe_scan.conf`
    [ -e /tmp/on_pppoe ] && status=1 || status=0
    response="$(awk '$1!='\x00'{gsub(/\t/,"\\t");printf "%s\\n",$0}' /tmp/pppoe_scan)"
    data=$(json_output status:int response:str)
    data="[$data]"
    json_append __json_result__ interface:str attempts:int timeout:int data:json
}
