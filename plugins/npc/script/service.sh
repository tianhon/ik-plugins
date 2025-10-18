#!/bin/bash /etc/ikcommon
PLUGIN_NAME="npc"
. /etc/mnt/plugins/configs/config.sh

if [ ! -f /usr/sbin/npc ]; then
    chmod +x $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/npc
    ln -fs $EXT_PLUGIN_INSTALL_DIR/$PLUGIN_NAME/bin/npc /usr/sbin/npc
fi

start() {
    if killall -q -0 npc; then
        killall npc
        return
    fi

    if [ -f $EXT_PLUGIN_CONFIG_DIR/npc/npc.config ]; then
        . $EXT_PLUGIN_CONFIG_DIR/npc/npc.config
        target=$(echo "$target" | sed 's/-/ /g') # 将 - 转换回空格

        # 确保 password 不为空
        if [ -n "$password" ]; then
            # 如果 local_type 不为空，使用 local_type 启动
            if [ -n "$local_type" ]; then
                npc -server=$server -vkey=$vkey -type=tcp -password=$password -local_type=$local_type >>/tmp/npc.log &

            else
                npc -server=$server -vkey=$vkey -type=tcp -password=$password -target=$target >>/tmp/npc.log &

            fi
        else
            # 如果 password 为空，给出错误提示
            npc -server=$server -vkey=$vkey -type=tcp >>/tmp/npc.log &
        fi
    fi
}

stop() {
    killall npc
}

disable() {
    killall npc
    rm $EXT_PLUGIN_CONFIG_DIR/npc/npc.config
}

update_config() {
    local server="$1"
    local vkey="$2"
    local password="$3"
    local target="$4"
    local local_type="$5"

    server=$(echo "$server" | sed 's/%20/-/g')
    vkey=$(echo "$vkey" | sed 's/%20/-/g')
    local_type=$(echo "$local_type" | sed 's/%20/-/g')
    target=$(echo "$target" | sed 's/%20/-/g')

    echo "${server}" >$EXT_PLUGIN_CONFIG_DIR/npc/npc.config
    echo "${vkey}" >>$EXT_PLUGIN_CONFIG_DIR/npc/npc.config
    echo "${password}" >>$EXT_PLUGIN_CONFIG_DIR/npc/npc.config
    echo "${target}" >>$EXT_PLUGIN_CONFIG_DIR/npc/npc.config
    echo "${local_type}" >>$EXT_PLUGIN_CONFIG_DIR/npc/npc.config

    echo "配置文件已更新："
    cat $EXT_PLUGIN_CONFIG_DIR/npc/npc.config
    if killall -q -0 npc; then
        killall npc
    fi
    start
}

show() {
    Show __json_result__
}

__show_status() {
    if killall -q -0 npc; then
        local status=1
    else
        local status=0
    fi
    json_append __json_result__ status:int
}

__show_config() {
    local server=""
    local vkey=""
    local password=""
    local target=""
    local local_type=""

    if [ -f $EXT_PLUGIN_CONFIG_DIR/npc/npc.config ]; then
        . $EXT_PLUGIN_CONFIG_DIR/npc/npc.config
        target=$(echo "$target" | sed 's/-/ /g') # 将 - 转换回空格
    fi

    json_append __json_result__ server:str
    json_append __json_result__ vkey:str
    json_append __json_result__ password:str
    json_append __json_result__ target:str
    json_append __json_result__ local_type:str
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
