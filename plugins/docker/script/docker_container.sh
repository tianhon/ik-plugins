#!/bin/bash /etc/ikcommon

__check_param()
{
        check_varl \
                'name       != ""' \
                'interface  != ""' \
		'auto_start != ""' \
		'memory     != ""'
}

__check_srcpath()
{
        local ROOT_PATH="/etc/disk_user"
        local srcpaths="$1"
        for path_dir in ${srcpaths//,/ }; do
		local path_dir=${path_dir//:*/}

		if [ "$path_dir" = "/" ]; then
			echo "$path_dir not found"
			return 1
		fi

		local tmp_dir=${path_dir//\.\./}
		if [ "$tmp_dir" != "$path_dir" ]; then
			echo "$path_dir not found"
			return 1
		fi

		local abs_path="${ROOT_PATH}${path_dir}"

		if [ ! -e "$abs_path" ]; then
			echo "$path_dir not found"
			return 1
		fi
		local dir_arry=(${path_dir//\// })
		local hardlink=$(readlink ${ROOT_PATH}/${dir_arry[0]})

		if [ ! -d "$hardlink" ]; then
			echo "$path_dir not found"
			return 1
		fi
		local i=0
		for dir_one in ${dir_arry[*]}; do
			i=$((i+1))
			[ "$i" = "1" ] && continue
			hardlink+="/$dir_one"
		done
		if [ ! -e "$hardlink" ]; then
			echo "$path_dir not found"
			return 1
		fi
        done
}

add()
{
	local id
	__check_param|| exit 1
	__check_srcpath $mounts || exit 1
	if id=$(ikdocker container_add name="$name" image="$image" env="$env" cmd="$cmd" interface="$interface" comment="$comment" mounts="$mounts" auto_start="$auto_start" memory="$memory" ipaddr="$ipaddr" ip6addr="$ip6addr") ;then
		echo "\"$id\""
	else
		echo $id
		exit 1
	fi
}

del()
{
	ikdocker container_del id="$id"
}

up()
{
	local illegal=0
	for doconfig in /etc/disk_user/*/Docker/lib/containers/$id/config.v2.json; do
		Source=$(jq -r '.MountPoints[] | .Source' $doconfig)
		[ -n "$Source" ] && for path in "$Source"; do { ! readlink "$path" | grep -q "^/etc/disk"; } && illegal=1; done
	done
	for doconfig in /etc/disk_user/*/Docker/lib/containers/$id/hostconfig.json; do
		Privileged=$(jq -r '.Privileged' $doconfig)
		CapAdd=$(jq -r '.CapAdd' $doconfig)
		[[ "$Privileged" != "false" || "$CapAdd" != "null" ]] && illegal=1
	done

	if [ $illegal -eq 1 ]; then
		ikdocker container_del id="$id"
		return
	fi

	ikdocker container_start id="$id"
}

down()
{
	ikdocker container_stop id="$id"
}

update()
{
	ikdocker container_update id="$id" interface="$interface" ipaddr="$ipaddr" ip6addr="$ip6addr" memory="$memory"
}

commit()
{
	ikdocker container_commit id="$id" name="$name" tag="$tag"
}

show()
{
    local __filter=$(sql_auto_get_filter)
    local __order=$(sql_auto_get_order)
    local __limit=$(sql_auto_get_limit)
    local __where="$__filter $__order $__limit"
    Show __json_result__
}

__show_data()
{
	local data
	if data=$(ikdocker container_get) ;then
		json_append __json_result__ data:json
	else
		echo $data
		exit 1
	fi
}

__show_log()
{
	local log
	if log=$(ikdocker container_get_log id="$id") ;then
		json_append __json_result__ log:json
	else
		echo $log
		exit 1
	fi
}

__show_top()
{
	local top
	if top=$(ikdocker container_get_top id="$id") ;then
		json_append __json_result__ top:json
	else
		echo $top
		exit 1
	fi
}

__show_cpuused()
{
	local cpuused
	if cpuused=$(ikdocker container_cpuused) ;then
		json_append __json_result__ cpuused:json
	else
		echo $cpuused
		exit 1
	fi
}

__show_network()
{
	local network
	if network=$(ikdocker network_get_name) ;then
		# network=$(echo "$network" | jq '. + ["host"]') # 添加host网络支持
		json_append __json_result__ network:json
	else
		echo $network
		exit 1
	fi
}

__show_image()
{
	local image
	if image=$(ikdocker images_get_name) ;then
		json_append __json_result__ image:json
	else
		echo $image
		exit 1
	fi
}

__show_memavailable()
{
	Include sys/sysstat.sh
	sysstat_get_mem
	local memavailable="${SYSSTAT_MEM[MemAvailable]}"

	json_append __json_result__ memavailable:int
}
__show_sysbit()
{
	local sysbit=$SYSBIT
	json_append __json_result__ sysbit:str
}
