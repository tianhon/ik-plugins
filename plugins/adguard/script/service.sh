#!/bin/bash /etc/ikcommon
PLUGIN_NAME="adguard"
. /etc/mnt/plugins/configs/config.sh

set_auto_start() {
	if [ "$autostart" = "true" ]; then
		[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] || touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	fi
	return 0
}

set_dns_hijacking() {

	if [ "$dnshijacking" = "true" ]; then
		PID=$(pidof CrashCore | awk '{print $NF}')
		if [ -n "$PID" ]; then
			if iptables -t nat -L shellcrash_dns -n 2>/dev/null | grep -q '^Chain'; then
				echo "检测到Crash正在劫持本机DNS，请先停止Crash或禁用其DNS劫持。"
				return 1
			fi
		fi

		[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/dnshijacking" ] || touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/dnshijacking
		__do_dns_hijacking start
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/dnshijacking
		__do_dns_hijacking stop
	fi
	return 0
}

__do_dns_hijacking() {
	action=$1

	if [ "$action" = "start" ]; then
		iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353
		iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
		ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353
		ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
	fi
	if [ "$action" = "stop" ]; then
		while true; do
			dns5353=$(iptables -t nat -vnL PREROUTING --line-number | grep "5353" | wc -l)
			if [ $dns5353 -gt 0 ]; then
				iptables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353
				iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
				ip6tables -t nat -D PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353
				ip6tables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
			else
				break
			fi
		done
	fi

}

show() {
	Show __json_result__
}

__show_data() {

	local status=0

	PID=$(pidof AdGuardHome | awk '{print $NF}')
	[ -n "$PID" ] && status=1
	[ -f /tmp/iktmp/plugins/adguard_installed ] || status=2

	local autostart=0
	[ -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart ] && autostart=1

	local dnshijacking=0
	[ -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/dnshijacking ] && dnshijacking=1

	local listenPort="$(grep -A 5 '^dns' $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/AdGuardHome.yaml | grep 'port:' | awk '{print($2)}')"

	local webPort="$(grep -A 5 '^http' $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/AdGuardHome.yaml | grep 'address' | awk -F ':' '{print($3)}')"


	local runningTime=""
	start_time=$(cat /tmp/AdGuardHome/adguards_start_time)
	if [ -n "$start_time" ]; then 
		time=$((`date +%s`-start_time))
		day=$((time/86400))
		[ "$day" = "0" ] && day='' || day="$day天"
		time=`date -u -d @${time} +%H小时%M分%S秒`
		runningTime="已运行: ${day}${time}"
	fi

	json_append __json_result__ autostart:int
	json_append __json_result__ status:int
	json_append __json_result__ listenPort:int
	json_append __json_result__ webPort:int
	json_append __json_result__ dnshijacking:int
	json_append __json_result__ runningTime:str

}

start() {

	PID=$(pidof AdGuardHome | awk '{print $NF}')
	[ -n "$PID" ] && return 0

	# PID=$(pidof CrashCore | awk '{print $NF}')
	# if [ -n "$PID" ]; then
	# 	echo "请先停止ShellClash，再启动AdGuardHome！" 
	# 	return 1
	# fi

	BIN_DIR=$EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin

	tar -zxf $BIN_DIR/AdGuardHome.tar.gz -C /tmp
	mkdir -p /tmp/AdGuardHome/data
	ln -sf $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/AdGuardHome.yaml /tmp/AdGuardHome/AdGuardHome.yaml
	ln -sf $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/filters /tmp/AdGuardHome/data/filters

	chmod +x /tmp/AdGuardHome/AdGuardHome 
	/tmp/AdGuardHome/AdGuardHome >/dev/null &
	sleep 5 && rm -f /tmp/AdGuardHome/AdGuardHome 

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/dnshijacking" ]; then
		__do_dns_hijacking start
	fi

	# 禁止外网访问
	for iface in $(ip link show | awk -F: '/: wan[0-9]+:/{print $2}' | tr -d ' '); do
		iptables -A INPUT -i "$iface" -p tcp --dport 3000 -j DROP
		iptables -A INPUT -i "$iface" -p tcp --dport 53 -j DROP
	done

	echo `date +%s` > /tmp/AdGuardHome/adguards_start_time
	return 0
}

stop() {

	PID=$(pidof AdGuardHome | awk '{print $NF}')
	[ -n "$PID" ] && kill $PID && rm -rf /tmp/AdGuardHome

	__do_dns_hijacking stop

	# 恢复外网对3000端口的访问
	for iface in $(ip link show | awk -F: '/: wan[0-9]+:/{print $2}' | tr -d ' '); do
		iptables -D INPUT -i "$iface" -p tcp --dport 3000 -j DROP
		iptables -D INPUT -i "$iface" -p tcp --dport 53 -j DROP
	done

	return 0
}
