#!/bin/bash /etc/ikcommon
FEATURE_ID=3
ENABLE_FEATURE_CHECK=1
PLUGIN_NAME="extapi"
. /etc/mnt/plugins/configs/config.sh
. /etc/release

set_extapi() {
	if [ "$extapi" = "true" ];then
		touch $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/extapi_enabled
    start
	else
		rm -f $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/extapi_enabled
    stop
	fi
	return 0
}

start() {

  if [ ! -f /usr/openresty/lua/lib/extapi.lua ]; then
    ln -fs $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/script/extapi.lua /usr/openresty/lua/lib/extapi.lua
    chmod  +x /usr/openresty/lua/lib/extapi.lua
  fi

  if ! grep -q "extapitag" /usr/openresty/lua/lib/webman.lua; then
    codestr1="apiext = require \"extapi\" --extapitag"
    codestr2="ActionUri\[\"\/api\/call\"\] = apiext.ApiCall --extapitag"
    codestr3="VerifyExclUri\[\"\^\/api\/call\$\"\] = true --extapitag"
    sed -i "s/^init()/$codestr1\n$codestr2\n$codestr3\ninit()/g" /usr/openresty/lua/lib/webman.lua
  fi
  
  openresty -s reload
}

stop() {
  sed -i "/extapitag/d" /usr/openresty/lua/lib/webman.lua
	rm -f /usr/openresty/lua/lib/extapi.lua
}

renewToken() {
  token=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)
  echo -n "$token" > $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/extapi.token
  openresty -s reload
	return 0
}

addSK5Node() {
  param="name=$name address=$address port=$port type=$type user=$user password=$password interfacename=$interfacename dialer=$dialer"
  /usr/ikuai/function/plugin_socks5 save_server $param
  if [ $? -ne 0 ]; then
    echo "SK5节点 ${name} 保存失败"
    return 1
  fi
  return 0
}

delSK5Node() {
  param="name=$name"
  /usr/ikuai/function/plugin_socks5 delete_server $param
  if [ $? -ne 0 ]; then
    echo "SK5节点 ${name} 删除失败"
    return 1
  fi
  return 0
}

addSK5Rule() { 
  param="address_ip=$address_ip name_sk=$name_sk"
  /usr/ikuai/function/plugin_socks5 save_client $param
  if [ $? -ne 0 ]; then
    echo "SK5规则【${address_ip} ${name_sk}】保存失败"
    return 1
  fi
  return 0
}

delSK5Rule() { 
  param="address_ip=$address_ip"
  /usr/ikuai/function/plugin_socks5 delete_Client $param
  if [ $? -ne 0 ]; then
    echo "SK5规则 ${address_ip} 删除失败"
    return 1
  fi
  return 0
}

show() {

    Show __json_result__
}

__show_data() {

    local extapi=0
    local token=$(cat $EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/extapi.token)

    [ -f "$EXT_PLUGIN_CONFIG_DIR/$PLUGIN_NAME/extapi_enabled" ] && extapi=1
    
    json_append __json_result__ extapi:int
    json_append __json_result__ token:str
}
