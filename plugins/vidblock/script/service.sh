#!/bin/bash /etc/ikcommon
FEATURE_ID=4
ENABLE_FEATURE_CHECK=1
PLUGIN_NAME="vidblock"
. /etc/mnt/plugins/configs/config.sh

start() {

  configfile=$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/vidblock.cfg
  echo "douyincdn.com   #抖音的内容分发域名，用于视频加载
douyinvod.com   #抖音的视频点播服务器（VOD：Video on Demand）
yximgs.com      #多个平台，快手、映客等（尤其是短视频类）使用的 CDN 资源域名，用于加载图像或视频。
#xhscdn.com      #小红书使用的内容分发 CDN 域名，用于加载图片、视频。
#hdslb.com       #B站用于视频内容分发的域名
#bilivideo.com   #B站的视频加速分发域名，常用于播放器的视频资源请求。" > $configfile

  if [ ! -f $configfile ]; then
    echo "加载配置失败"
    return 1
  fi

  iptables -N VIDREJECT_DOMAINS 2>/dev/null

  iptables -C FORWARD -j VIDREJECT_DOMAINS 2>/dev/null || \
  iptables -A FORWARD -j VIDREJECT_DOMAINS

  # 添加匹配规则到自定义链
  while IFS= read -r line || [ -n "$line" ]; do

    line="$(echo "$line" | sed 's/#.*//' | sed 's/ //g')"

    if [ -n "$line" ]; then
      iptables -C VIDREJECT_DOMAINS -m string --string "$line" --algo bm --to 65535 -j REJECT 2>/dev/null || \
      iptables -A VIDREJECT_DOMAINS -m string --string "$line" --algo bm --to 65535 -j REJECT
    fi
  done < $configfile
  return 0
}

stop() {
  iptables -D FORWARD -j VIDREJECT_DOMAINS 2>/dev/null
  iptables -F VIDREJECT_DOMAINS 2>/dev/null
  iptables -X VIDREJECT_DOMAINS 2>/dev/null
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
    iptables -C FORWARD -j VIDREJECT_DOMAINS >/dev/null 2>&1 && status=1
    
    json_append __json_result__ autostart:int
	  json_append __json_result__ status:int
}
