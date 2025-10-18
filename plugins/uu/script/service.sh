#!/bin/bash /etc/ikcommon
PLUGIN_NAME="uu"
. /etc/mnt/plugins/configs/config.sh

start() {

	pidof uuplugin >/dev/null 2>&1 && return 0

	if [ -f /usr/sbin/uu/uuplugin_monitor.sh ]; then
		/bin/sh /usr/sbin/uu/uuplugin_monitor.sh >/dev/null &
	else
		$EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/script/uu_install.sh openwrt $(uname -m) >/dev/null &
	fi
	sleep 1
	return 0
}

stop() {
	for pid in $(ps | grep "uuplugin_monitor" | grep -v "grep" | awk '{print $1}'); do
		kill -9 $pid
	done

	for pid in $(ps | grep "uuplugin" | grep -v "grep" | awk '{print $1}'); do
		kill -9 $pid
	done
}

set_auto_start() {
	if [ "$autostart" = "true" ];then
		[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] || touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	fi
	return 0
}

show() {
	Show __json_result__
}

__show_data() {
	local autostart=0
	local status=0

    [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] && autostart=1
    [ -f /tmp/iktmp/plugins/${PLUGIN_NAME}_installed ] || status=2
    pidof uuplugin >/dev/null 2>&1 && status=1
    
    json_append __json_result__ autostart:int
	json_append __json_result__ status:int
}
