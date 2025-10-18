#!/bin/bash /etc/ikcommon
. /etc/mnt/plugins/configs/config.sh
PLUGIN_NAME="vremote"
start()
{
	[ -n "$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config)" ] || return

	[ -d $EXT_PLUGIN_LOG_DIR ] || mkdir -p $EXT_PLUGIN_LOG_DIR
	echo "启动VRemote" > $EXT_PLUGIN_LOG_DIR/vremote.log
	vremote > $EXT_PLUGIN_LOG_DIR/vremote.log 2>&1 &

	mkdir -p /tmp/vremote
	echo `date +%s` > /tmp/vremote/vremote_start_time
}

stop()
{
	if [ -f /tmp/iktmp/vremote.pid ];then
		kill -9 $(cat /tmp/iktmp/vremote.pid)
		rm -f /tmp/iktmp/vremote.pid
	fi
	sed -i '/vremote/d' /etc/crontabs/root
    rm -f /etc/crontabs/cron.d/vremote

	killall vrtty

	rm -f /tmp/vremote/vremote_start_time
	rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/lastShareSyncTime
	rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/lastSyncLogId
}

save()
{
	echo "$apiToken" > $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config
	if [ -n "$shareCode" ]; then 
		echo "$shareCode" > $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/sharecode
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/sharecode
	fi

	if [ "$enableProxy" = "true" ]; then
		touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy
	fi
		
	return 0
}

set_auto_start() {
	if [ "$autostart" = "true" ];then
		[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] || touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart
	fi
	return 0
}

show(){
    Show __json_result__
}

__show_data(){
	local status=0
	local autostart=0
	local lastSyncTime="尚未同步"
	local vntStatus=0
	local virtualIp=""
	local shareCode=""
	local enableProxy="false"
	local runningTime=""

	start_time=$(cat /tmp/vremote/vremote_start_time)
	if [ -n "$start_time" ]; then 
		time=$((`date +%s`-start_time))
		day=$((time/86400))
		[ "$day" = "0" ] && day='' || day="$day天"
		time=`date -u -d @${time} +%H小时%M分%S秒`
		runningTime="已运行: ${day}${time}"
	fi

	if killall -q -0 vnt;then
		virtualIp=$(vnt --info | grep "Virtual ip" | awk -F ":" '{print($2)}')
		vntStatus=1
	fi

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ]; then
		apiToken=$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config)
	fi

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy" ]; then
		enableProxy="true"
	fi

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/sharecode" ]; then
		shareCode=$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/sharecode)
	fi

	[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] && autostart=1
	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/lastSyncTime" ]; then
		lastSyncTime=$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/lastSyncTime)
	fi

	if [ -f "$EXT_PLUGIN_LOG_DIR/vremote_error" ]; then
		lastSyncTime="$lastSyncTime (同步失败)"
	fi

	[ -f /tmp/iktmp/plugins/vremote_installed ] || status=2

	[ -f /tmp/iktmp/vremote.pid ] && status=1

	json_append __json_result__ status:int
	json_append __json_result__ vntStatus:int
	json_append __json_result__ autostart:int
	json_append __json_result__ apiToken:str
	json_append __json_result__ shareCode:str
	json_append __json_result__ lastSyncTime:str
	json_append __json_result__ virtualIp:str
	json_append __json_result__ enableProxy:str
	json_append __json_result__ runningTime:str
}
