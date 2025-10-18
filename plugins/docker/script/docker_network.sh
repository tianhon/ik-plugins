#!/bin/bash /etc/ikcommon

__check_param()
{
	check_varl \
		'name    != ""' \
		'subnet  ipmaskb' \
		'gateway == "" or ip'
}

add()
{
	__check_param || exit 1
	local id
	if id=$(ikdocker network_add name="$name" subnet="$subnet" gateway="$gateway" subnet6="$subnet6" gateway6="$gateway6" comment="$comment") ;then
		echo "\"$id\""
	else
		echo $id
		exit 1
	fi
}

edit()
{
	__check_param || exit 1

	local _id
	if _id=$(ikdocker network_edit id=$id name="$name" subnet="$subnet" gateway="$gateway" subnet6="$subnet6" gateway6="$gateway6" comment="$comment") ;then
		echo "\"$_id\""
	else
		echo $_id
		exit 1
	fi
}


del()
{
	ikdocker network_del id="$id"
}


connect()
{
	ikdocker network_connect id="$id" cid="$cid" ipaddr="$ipaddr" ip6addr="$ip6addr"
}

disconnect()
{
	ikdocker network_disconnect id="$id" cid="$cid"
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
	if data=$(ikdocker network_get) ;then
		json_append __json_result__ data:json
	else
		echo $data
		exit 1
	fi
}


__show_inspect()
{
	local inspect
	if inspect=$(ikdocker network_inspect id=$id) ;then
		json_append __json_result__ inspect:json
	else
		echo $inspect
		exit 1
	fi
}
