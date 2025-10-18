#!/bin/bash /etc/ikcommon
PLUGIN_NAME="alist"
. /etc/mnt/plugins/configs/config.sh
if [[ "$EXT_PLUGIN_RUN_INMEM" = "yes" && -d "$EXT_PLUGIN_IPK_DIR" ]]; then
     # 兼容京东云，它的闪存空间太小了，放不下
    EXT_PLUGIN_CONFIG_DIR=$EXT_PLUGIN_IPK_DIR
fi

start()
{
	PID=$(pidof alist | awk '{print $NF}')
	[ -n "$PID" ] && return

    chrootmgt install_disk
    chrootmgt mount_plugin $PLUGIN_NAME

    inited=0 && [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/data.db" ] && inited=1
    chrootmgt run $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/alist server --data $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME --log-std > /dev/null &
    
    if [ $inited -eq 0 ]; then
        sleep 1
        chrootmgt run $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/alist --data $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME admin set password > /dev/null
    fi
    
    mkdir -p /tmp/alist
    echo `date +%s` > /tmp/alist/alist_start_time
    return 0
}

stop()
{
	killall alist

    chrootmgt umount_plugin $PLUGIN_NAME
    rm -f /tmp/alist/alist_start_time
}

setpwd() {
	chrootmgt run $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/alist --data $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME admin set $password > /dev/null
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

show() {

    Show __json_result__
}

__show_data() {

    local status=0

	PID=$(pidof alist | awk '{print $NF}')
	[ -n "$PID" ] && status=1
	[ -f /tmp/iktmp/plugins/alist_installed ] || status=2

    local autostart=0
	[ -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart ] && autostart=1

    local runningTime=""
	start_time=$(cat /tmp/alist/alist_start_time)
	if [ -n "$start_time" ]; then 
		time=$((`date +%s`-start_time))
		day=$((time/86400))
		[ "$day" = "0" ] && day='' || day="$day天"
		time=`date -u -d @${time} +%H小时%M分%S秒`
		runningTime="已运行: ${day}${time}"
	fi

    local webPort="5244"  # 默认端口，TODO： 目前尚无法准确获取真实端口号

    json_append __json_result__ autostart:int
	json_append __json_result__ status:int
	json_append __json_result__ runningTime:str
    json_append __json_result__ webPort:str
}
