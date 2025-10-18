#!/bin/bash /etc/ikcommon
PLUGIN_NAME="vnt"
. /etc/mnt/plugins/configs/config.sh

start()
{
	[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ] || return

	[ -d $EXT_PLUGIN_LOG_DIR ] || mkdir -p $EXT_PLUGIN_LOG_DIR
	echo "启动VNT" > $EXT_PLUGIN_LOG_DIR/vnt.log

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy" ]; then
		iptables -t nat -A POSTROUTING -o vnt-tun -s 0.0.0.0/0 -j MASQUERADE
	else
		iptables -t nat -D POSTROUTING -o vnt-tun -s 0.0.0.0/0 -j MASQUERADE
	fi

	Vmen=0
	while true; do
		killall vnt
		vnt -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config >> $EXT_PLUGIN_LOG_DIR/vnt.log 2>&1 &
		sleep 3

		vSuccess=$(cat $EXT_PLUGIN_LOG_DIR/vnt.log | tail -n 5 | grep "Successfully" | wc -l)
		if [ $vSuccess -gt 0 ]; then
			echo "启动VNT成功" >> $EXT_PLUGIN_LOG_DIR/vnt.log
			return 0
		fi

		vError=$(cat $EXT_PLUGIN_LOG_DIR/vnt.log | tail -n 5 | grep "IpAlreadyExists" | wc -l)
		if [ $vError -gt 0 ]; then
			echo "启动VNT失败,IP地址已被占用,删除固定IP设置并重试" >> $EXT_PLUGIN_LOG_DIR/vnt.log
			sed -i '/^ip/d' $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config
            continue
		fi

		
		let Vmen=Vmen+1
		[ $Vmen -gt 10 ] && break
	done

	killall vnt
	echo "启动VNT失败,请检查配置文件" 
	return 1
}

stop()
{
	if killall -q -0 vnt;then
		killall vnt
	fi
	# 自启动锁死时可用停止按钮解锁
	if [ ! -f /tmp/iktmp/plugins/vnt_installed ]; then
		touch /tmp/iktmp/plugins/vnt_installed
	fi
}

save()
{
	. /etc/release
	local configpath=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config
	[ -f "$configpath" ] || touch $configpath

	if [ "$enableProxy" = "true" ]; then
		touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy
	fi
	
	if [ "$configMode" = "1" ];then
		if [ ! "$token" ]; then
			echo "组网编号为必填项"
			return 1
		fi
		
		sed -i '/^token/d' $configpath && echo "token: ${token}" >> $configpath
		sed -i '/^password/d' $configpath && [ "$password" ] && echo "password: ${password}" >> $configpath
		sed -i '/^server_address/d' $configpath && [ "$serverAddress" ] && echo "server_address: ${serverAddress}" >> $configpath
		sed -i '/^ip/d' $configpath && [ "$ipAddress" ] && echo "ip: ${ipAddress}" >> $configpath
		sed -i '/^name/d' $configpath && [ "$name" ] && echo "name: ${name}" >> $configpath

	else
		configTxt=$(echo "$config" | base64 -d)
		echo "$configTxt" > $configpath
	fi 

	sed -i '/^device_id/d' $configpath && echo "device_id: ${GWID}" >> $configpath
	sed -i '/^disable_stats/d' $configpath && echo "disable_stats: true" >> $configpath
	return 0
}

set_hostname(){

	hostname $name
	
	sqlite3 /etc/mnt/ikuai/config.db "update basic set hostname='$name' where id=1;" >/dev/null 2>&1

	$IK_DIR_SCRIPT/smbd.sh wsdd2_reconf hostname=$name 2>/dev/null 2>&1 &
	killall iksyslogd
	iksyslogd

	echo "127.0.0.1 $name" >/etc/hosts.d/hostname
	cat /etc/hosts.d/* >/etc/hosts
	killall lldpd; lldpd >/dev/null 2>&1 &
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

__show_configFileStream(){
	
	local config=""

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ]; then
		config=$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config  | grep -v disable_stats: | grep -v device_id: | base64)
	fi

	json_append __json_result__ config:str
}

__show_config(){
	local status=0
	local autostart=0
	local virtualIp=""
	local token=""
	local name=""
	local password=""
	local serverAddress=""
	local ipAddress=""
	local hostname=$(hostname)
	local enableProxy="false"

	if [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config" ]; then
		token=$(grep "token:" $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config | awk -F " " '{print($2)}')
		name=$(grep "name:" $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config | awk -F " " '{print($2)}')
		password=$(grep "password:" $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config | awk -F " " '{print($2)}')
		serverAddress=$(grep "server_address:" $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config | awk -F " " '{print($2)}')
		ipAddress=$(grep "ip:" $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/config | awk -F " " '{print($2)}')
	fi

	[ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/autostart" ] && autostart=1

	[ -f /tmp/iktmp/plugins/vnt_installed ] || status=2

	[ -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/enableProxy ] && enableProxy="true"

	if killall -q -0 vnt;then
		virtualIp=$(vnt --info | grep "Virtual ip" | awk -F ":" '{print($2)}')
		status=1
	fi

	json_append __json_result__ status:int
	json_append __json_result__ autostart:int
	json_append __json_result__ virtualIp:str
	json_append __json_result__ token:str
	json_append __json_result__ name:str
	json_append __json_result__ password:str
	json_append __json_result__ serverAddress:str
	json_append __json_result__ ipAddress:str
	json_append __json_result__ hostname:str
	json_append __json_result__ enableProxy:str
}
