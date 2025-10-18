#!/bin/bash /etc/ikcommon
PLUGIN_NAME="msd_lite"
. /etc/mnt/plugins/configs/config.sh

if [ ! -f /usr/sbin/msd_lite ]; then

	ln -s $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/msd_lite /usr/sbin/msd_lite
	chmod +x $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/msd_lite
fi

start() {

	if [ -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite ]; then
		msd_lite -c $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf >/dev/null &
	fi

}

app_start() {

	if killall -q -0 msd_lite; then
		killall msd_lite
		return
	fi

	echo "1" >$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite

	start

}

stop() {
	killall msd_lite

}

config() {
	echo "1" >>/tmp/npsconfig.log
	if [ -f /tmp/iktmp/import/file ]; then
		filesize=$(stat -c%s "/tmp/iktmp/import/file")
		if [ $filesize -lt 524288 ]; then
			rm $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf
			mv /tmp/iktmp/import/file $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf
			echo "ok" >>/tmp/npsconfig.log
			killall msd_lite
			start
		fi

	fi

}

update_config() {

	echo "All Parameters: $@" >>/tmp/msd_lite.log
	config_file=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf
	# 替换 fDropSlowClients 的值
	#sed -i "s|<fDropSlowClients>.*</fDropSlowClients>|<fDropSlowClients>$fDropSlowClients</fDropSlowClients>|" "$config_file"

	# 替换 fSocketHalfClosed 的值
	#sed -i "s|<fSocketHalfClosed>.*</fSocketHalfClosed>|<fSocketHalfClosed>$fSocketHalfClosed</fSocketHalfClosed>|" "$config_file"

	# 替换 fSocketTCPNoDelay 的值
	#sed -i "s|<fSocketTCPNoDelay>.*</fSocketTCPNoDelay>|<fSocketTCPNoDelay>$fSocketTCPNoDelay</fSocketTCPNoDelay>|" "$config_file"

	# 替换 fSocketTCPNoPush 的值
	#sed -i "s|<fSocketTCPNoPush>.*</fSocketTCPNoPush>|<fSocketTCPNoPush>$fSocketTCPNoPush</fSocketTCPNoPush>|" "$config_file"

	# 替换 precache 的值
	sed -i "s|<precache>.*</precache>|<precache>$precache</precache>|" "$config_file"

	# 替换 ringBufSize 的值
	sed -i "s|<ringBufSize>.*</ringBufSize>|<ringBufSize>$ringBufSize</ringBufSize>|" "$config_file"

	# 替换 sndBuf 的值
	#sed -i "s|<sndBuf>.*</sndBuf>|<sndBuf>$sndBuf</sndBuf>|" "$config_file"

	# 替换 rcvBuf 的值
	sed -i "s|<rcvBuf>.*</rcvBuf>|<rcvBuf>$rcvBuf</rcvBuf>|" "$config_file"

	# 替换 sndLoWatermark 的值
	#sed -i "s|<sndLoWatermark>.*</sndLoWatermark>|<sndLoWatermark>$sndLoWatermark</sndLoWatermark>|" "$config_file"

	# 替换 congestionControl 的值
	#sed -i "s|<congestionControl>.*</congestionControl>|<congestionControl>$congestionControl</congestionControl>|" "$config_file"

	# 替换 rcvLoWatermark 的值
	#sed -i "s|<rcvLoWatermark>.*</rcvLoWatermark>|<rcvLoWatermark>$rcvLoWatermark</rcvLoWatermark>|" "$config_file"

	# 替换 rcvTimeout 的值
	sed -i "s|<rcvTimeout>.*</rcvTimeout>|<rcvTimeout>$rcvTimeout</rcvTimeout>|" "$config_file"

	# 替换 rejoinTime 的值
	sed -i "s|<rejoinTime>.*</rejoinTime>|<rejoinTime>$rejoinTime</rejoinTime>|" "$config_file"

	# 替换 threadsCountMax 的值
	sed -i "s|<threadsCountMax>.*</threadsCountMax>|<threadsCountMax>$threadsCountMax</threadsCountMax>|" "$config_file"

	#修改端口值
	sed -i "s|\(<address>[^<]*:\)[0-9]*</address>|\1$bridge_port</address>|g" "$config_file"

	# 修改 ifName
	sed -i "s|<ifName>[^<]*</ifName>|<ifName>$ifName</ifName>|g" "$config_file"

	if killall -q -0 msd_lite; then
		killall msd_lite
	fi
	start
}

show() {

	Show __json_result__
}

__show_status() {
	local status=0

	if killall -q -0 msd_lite; then
		local status=1
	fi

	config_file=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf
	#config_file=/etc/log/app_dir/msd_lite/data/msd_lite.conf

	#bindPortIPv4=$(grep -o '<bind><address>0.0.0.0:[0-9]*</address>' "$config_file" | sed -E 's/.*:([0-9]+)<\/address>/\1/')
	bridge_port=$(grep -o '<bind><address>[^<]*:[0-9]*</address>' "$config_file" | sed -E 's/.*:([0-9]+)<\/address>/\1/' | sort | uniq)
	ifName=$(sed -n 's/.*<ifName>\([^<]*\)<\/ifName>.*/\1/p' "$config_file")

	# 提取并输出相应的值
	fDropSlowClients=$(grep -o '<fDropSlowClients>.*</fDropSlowClients>' "$config_file" | sed 's/<fDropSlowClients>\(.*\)<\/fDropSlowClients>/\1/')
	fSocketHalfClosed=$(grep -o '<fSocketHalfClosed>.*</fSocketHalfClosed>' "$config_file" | sed 's/<fSocketHalfClosed>\(.*\)<\/fSocketHalfClosed>/\1/')
	fSocketTCPNoDelay=$(grep -o '<fSocketTCPNoDelay>.*</fSocketTCPNoDelay>' "$config_file" | sed 's/<fSocketTCPNoDelay>\(.*\)<\/fSocketTCPNoDelay>/\1/')
	fSocketTCPNoPush=$(grep -o '<fSocketTCPNoPush>.*</fSocketTCPNoPush>' "$config_file" | sed 's/<fSocketTCPNoPush>\(.*\)<\/fSocketTCPNoPush>/\1/')
	precache=$(grep -o '<precache>.*</precache>' "$config_file" | sed 's/<precache>\(.*\)<\/precache>/\1/')
	ringBufSize=$(grep -o '<ringBufSize>.*</ringBufSize>' "$config_file" | sed 's/<ringBufSize>\(.*\)<\/ringBufSize>/\1/')
	sndBuf=$(grep -o '<sndBuf>.*</sndBuf>' "$config_file" | sed 's/<sndBuf>\(.*\)<\/sndBuf>/\1/')
	rcvBuf=$(grep -o '<rcvBuf>.*</rcvBuf>' "$config_file" | sed 's/<rcvBuf>\(.*\)<\/rcvBuf>/\1/')
	sndLoWatermark=$(grep -o '<sndLoWatermark>.*</sndLoWatermark>' "$config_file" | sed 's/<sndLoWatermark>\(.*\)<\/sndLoWatermark>/\1/')
	congestionControl=$(grep -o '<congestionControl>.*</congestionControl>' "$config_file" | sed 's/<congestionControl>\(.*\)<\/congestionControl>/\1/')
	rcvLoWatermark=$(sed -n 's/.*<rcvLoWatermark>\([0-9]*\)<\/rcvLoWatermark>.*/\1/p' "$config_file")
	rcvTimeout=$(grep -o '<rcvTimeout>.*</rcvTimeout>' "$config_file" | sed 's/<rcvTimeout>\(.*\)<\/rcvTimeout>/\1/')
	rejoinTime=$(grep -o '<rejoinTime>.*</rejoinTime>' "$config_file" | sed 's/<rejoinTime>\(.*\)<\/rejoinTime>/\1/')
	threadsCountMax=$(grep -o '<threadsCountMax>.*</threadsCountMax>' "$config_file" | sed 's/<threadsCountMax>\(.*\)<\/threadsCountMax>/\1/')
	#fBindToCPU=$(sed -n 's|<fBindToCPU>\([^<]*\)</fBindToCPU>|\1|p' "$config_file" | sed 's/<!--.*-->//g')
	fBindToCPU=$(awk -F'<fBindToCPU>|</fBindToCPU>' '/<fBindToCPU>/ {print $2}' "$config_file" | sed 's/<!--.*-->//g')

	json_append __json_result__ status:int
	json_append __json_result__ npsweb:int
	json_append __json_result__ fDropSlowClients:str
	json_append __json_result__ fSocketHalfClosed:str
	json_append __json_result__ fSocketTCPNoDelay:str
	json_append __json_result__ fSocketTCPNoPush:str
	json_append __json_result__ precache:str
	json_append __json_result__ ringBufSize:str
	json_append __json_result__ sndBuf:str
	json_append __json_result__ rcvBuf:str
	json_append __json_result__ sndLoWatermark:str
	json_append __json_result__ congestionControl:str
	json_append __json_result__ rcvLoWatermark:str
	json_append __json_result__ rcvTimeout:str
	json_append __json_result__ rejoinTime:str
	json_append __json_result__ threadsCountMax:str
	json_append __json_result__ bridge_port:str
	json_append __json_result__ ifName:str
	json_append __json_result__ fBindToCPU:str

}

DropSlowClients() {
	config_file=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf
	local newFDropSlowClients="no"
	[ "$status" = "true" ] && newFDropSlowClients="yes"
	sed -i "s|<fDropSlowClients>[^<]*</fDropSlowClients>|<fDropSlowClients>$newFDropSlowClients</fDropSlowClients>|g" "$config_file"
	start
}

BindToCPU() {
	config_file=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/msd_lite.conf

	local newFBindToCPU="no"
	[ "$status" = "true" ] && newFBindToCPU="yes"
	sed -i "s|<fBindToCPU>[a-zA-Z]*</fBindToCPU>|<fBindToCPU>$newFBindToCPU</fBindToCPU>|g" "$config_file"
	start
}

case "$1" in
start)
	start
	;;
stop)
	stop
	;;
*) ;;
esac
