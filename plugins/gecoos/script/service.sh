#!/bin/bash /etc/ikcommon
FEATURE_ID=0
ENABLE_FEATURE_CHECK=1
PLUGIN_NAME="gecoos"
. /etc/mnt/plugins/configs/config.sh

CONFIG_DIR=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME
GECOOS_BIN=$EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/gecoos

start() {

	pidof gecoos >/dev/null 2>&1 && return 0

	[ -d $CONFIG_DIR/data.db ] || passParam="-passwd gecoos"

  tmpdir=$(mktemp -d)
  $GECOOS_BIN -p 60650 -f $tmpdir -dbpath $CONFIG_DIR -token 1 $passParam -lang zh >/dev/null 2>&1 &

}

stop() {
	pidof gecoos >/dev/null 2>&1 || return 0
  killall gecoos
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
    pidof gecoos >/dev/null 2>&1 && status=1
    
    json_append __json_result__ autostart:int
	json_append __json_result__ status:int
}
