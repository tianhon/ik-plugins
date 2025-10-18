#!/bin/bash /etc/ikcommon
PLUGIN_NAME="vnts"
. /etc/mnt/plugins/configs/config.sh

start()
{
	if [ ! -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ]; then
		echo "启动VNTS失败,请先保存配置！" 
		return 1
	else
		. $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config
	fi

	[ -d $EXT_PLUGIN_LOG_DIR ] || mkdir -p $EXT_PLUGIN_LOG_DIR
	echo "启动VNTS" > $EXT_PLUGIN_LOG_DIR/vnts.log

	killall vnts
	param="-p $serviceport -P $webport -U $username -W $password -g $gateway -m $mask"
	$EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/vnts $param >> $EXT_PLUGIN_LOG_DIR/vnts.log 2>&1 &

	if killall -q -0 vnts;then
		echo "启动VNTS成功"
		return 0
	fi
	
	echo "启动VNTS失败,请检查配置文件" 
	return 1
}

stop()
{
	if killall -q -0 vnts;then
		killall vnts
	fi
}

save()
{
	local configpath=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config

	[ "$serviceport" ] || serviceport=29889
	[ "$webport" ] || webport=29888
	[ "$username" ] || username="admin"
	[ "$password" ] || password="admin"
	[ "$gateway" ] || gateway="10.26.0.1"
	[ "$mask" ] || mask="255.255.255.0"

	echo "serviceport=${serviceport}" > $configpath
	echo "webport=${webport}" >> $configpath
	echo "username=${username}" >> $configpath
	echo "password=${password}" >> $configpath
	echo "gateway=${gateway}" >> $configpath
	echo "mask=${mask}" >> $configpath
	
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

	local autostart=0
	local status=0
	local serviceport=29889
	local webport=29888
	local username="admin"
	local password="admin"
	local gateway="10.26.0.1"
	local mask="255.255.255.0"

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ]; then
		. $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config
	fi

	[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] && autostart=1

	[ -f /tmp/iktmp/plugins/vnts_installed ] || status=2

	if killall -q -0 vnts;then
		status=1
	fi

	json_append __json_result__ autostart:int
	json_append __json_result__ status:int
	json_append __json_result__ serviceport:int
	json_append __json_result__ webport:int
	json_append __json_result__ username:str
	json_append __json_result__ password:str
	json_append __json_result__ gateway:str
	json_append __json_result__ mask:str
}
