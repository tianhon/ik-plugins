#!/bin/bash /etc/ikcommon
DOCKER_PULL_STATUS="/var/run/docker.pull.status"
del()
{
	ikdocker images_del id="$id"
}

pull()
{
	if [ ! "$name" ];then
		echo "Need choose an image name"
		exit 1
	fi

	> $DOCKER_PULL_STATUS
	ikdocker images_pull name="$name" tag="$tag" >/dev/null 2>&1 &
}

__check_param_export()
{
        check_varl \
                'name     != ""' \
                'part     != ""' \
                'filename != ""'
}

EXPORT()
{
	__check_param_export || exit 1
	ikdocker images_export name="$name" tag="$tag" savepath="/$part/$filename"
}

IMPORT()
{
	if [ ! "$filepath" ];then
		echo "Need param filepath"
		exit 1
	fi
	if [ ! -f /etc/disk_user/$filepath ];then
		echo "not found $filepath"
		exit 1
	fi
	rm -rf /tmp/ikpkg/docker/load_progress
	docker load < "/etc/disk_user/$filepath"
	touch /tmp/ikpkg/docker/load_progress
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
	if data=$(ikdocker images_get) ;then
		json_append __json_result__ data:json
	else
		echo $data
		exit 1
	fi
}

__show_search()
{
	if [ ! "$keyword" ];then
		echo "Need input keyword"
		exit 1
	fi
	local search
        local mirror=$(sqlite3 /etc/mnt/ikuai/docker.db "select mirrors from global")
        if [ -z "$mirror" -o "$mirror" = "https://docker.1ms.run" ]; then
                search=$(wget  -4 -q -O- -t 3 -T30 --no-check-certificate --connect-timeout=30 --dns-timeout=20 "https://docker.1ms.run/v1/search?q=$keyword&n=100&page=1")
                if [ "$search" ]; then
                        search=$(echo $search|jq .results)
                        json_append __json_result__ search:json
                        return 0
                fi
        fi

	if search=$(ikdocker images_search keyword="$keyword") ;then
		json_append __json_result__ search:json
	else
		echo $search
		exit 1
	fi
}


__show_pull_progress()
{
	if [ -f $DOCKER_PULL_STATUS ];then
		local progress=$(awk '{a=a",\""$0"\""} END {gsub("^,","",a);printf "[%s]",a}' $DOCKER_PULL_STATUS) #IgnoreCheck-$0
		local last_line=$(tail -1 $DOCKER_PULL_STATUS)
		if [ "$last_line" == "Finished" ];then
			local status=0
		else
			local status=1
		fi
	else
		local progress='[]'
		local status=-1
	fi

	local pull_progress=$(json_output status:int progress:json)
	json_append __json_result__ pull_progress:json
}

__show_load_progress()
{
	 local progress_file="/tmp/ikpkg/docker/load_progress"
	 if [ -f "$progress_file" ]; then
		local status=1
	 else
		local status=0
	 fi
	 json_append __json_result__ status:int
}

__show_inspect()
{
	if [ ! "$id" ];then
		echo "id cannot empty"
		exit 1
	fi

	if inspect=$(ikdocker images_get_info id="$id") ;then
		json_append __json_result__ inspect:json
	else
		echo $inspect
		exit 1
	fi
}

__show_disks()
{
	local disks=$($IK_DIR_SCRIPT/utils/file_find.lua "/")
	json_append __json_result__ disks:json
}

__show_arch()
{
	local arch
	case "$ARCH" in
	x86) [ "$SYSBIT" = "x32" ]&&arch=386||arch=amd64 ;;
	arm) [ "$SYSBIT" = "x32" ]&&arch=arm||arch=arm64 ;;
	*) arch=$ARCH ;;
	esac

	json_append __json_result__ arch:str
}
