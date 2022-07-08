#!/bin/bash

iotb=(
    "1@PB21"
    "2@PB20"
    "3@PB3"
    "4@PI20"
    "5@PI21"
    "6@PH25"
    "7@PI18"
    "8@PI19"
)

ctl_dev="1405190410c243305cc"

#adb_sh <cmd>
adb_sh()
{
    adb -s ${ctl_dev} shell "$@" | sed 's/\r//g'
}

init_debug()
{
    basedir="$(adb_sh "mount" | awk '/type debugfs/{print $3}')"
    if [ -z "${basedir}" ]; then
        adb_sh "mount -t debugfs debugfs /sys/kernel/debug"
        basedir="$(adb_sh "mount" | awk '/type debugfs/{print $3}')"
    fi
    [ -z "${basedir}" ] \
        && echo "not found debugfs on device" \
        && return 1

    basedir="${basedir}/sunxi_pinctrl"
    return 0
}

#get_func <gpio>
get_func()
{
    adb_sh "echo $1 > ${basedir}/sunxi_pin && cat ${basedir}/function | awk '{print \$3}'"
}

#set_func <gpio>
set_func()
{
    adb_sh "echo $1 1 > ${basedir}/function"
}

#get_data <gpio>
get_data()
{
    adb_sh "echo $1 > ${basedir}/sunxi_pin && cat ${basedir}/data | awk '{print \$3}'"
}

#set_data <gpio> <val>
set_data()
{
    adb_sh "echo $1 $2 > ${basedir}/data"
}

#get_gpio <num>
get_gpio()
{
    echo "${iotb[@]}" | sed 's/ /\n/g' | awk -F@ "/^$1/{print \$2}"
}

#set_up <num>
set_up()
{
    [ -z "$1" ] && echo "miss num" && return 1

    init_debug || return 1

    local gpio="$(get_gpio $1)"
    [ -z "${gpio}" ] && echo "mismatch #$1" && return 1

    set_func ${gpio}
    [ "$(get_func ${gpio})" != "1" ] && echo "set function failed" && return 1

    set_data ${gpio} 1
}

#set_down <num>
set_down()
{
    [ -z "$1" ] && echo "miss num" && return 1

    init_debug || return 1

    local gpio="$(get_gpio $1)"
    [ -z "${gpio}" ] && echo "mismatch #$1" && return 1

    set_func ${gpio}
    [ "$(get_func ${gpio})" != "1" ] && echo "set function failed" && return 1

    set_data ${gpio} 0
}

#up_down <num> <up_sec> <down_sec>
up_down()
{
    [ "$#" -ne "3" ] && echo "up_down <num> <up sec> <down sec>" && return 1

    num=$1
    upsec=$2
    down_sec=$3

    set_up ${num}
    sleep ${upsec}
    set_down ${num}
    sleep ${down_sec}
}

show_help()
{
	echo "pfail [-hf] <-t times> <-n port num> <-u up sec> <-d down sec>"
	echo
	echo "-f : kill old jobs and force to do new jobs"
	echo "-h : show this message and exit"
	echo "-t : loop times"
	echo "-n : control which port"
	echo "-u : up second"
	echo "-d : down second"
}

loop()
{
    local opts force times num up down
    opts=`getopt -o "hft:n:u:d:" -- $@` || return 1
    eval set -- "${opts}"
    while true
    do
        case "$1" in
			-h)
				show_help
				return
				;;
			-f)
				force=1
				shift
				;;
			-t)
				shift
				times="$1"
				shift
				;;
			-n)
				shift
				num="$1"
				shift
				;;
			-u)
				shift
				up="$1"
				shift
				;;
			-d)
				shift
				down="$1"
				shift
				;;
			--)
				shift
				break
		esac
	done
	[ -z "${times}" -o -z "${num}" -o -z "${up}" -o -z "${down}" ] \
		&& show_help && return 1

	lock="/var/lock/pflock-${num}"
	[ -f "${lock}" -a -z "${force}" ] \
		&& echo "num $2 locked, please add -f if you really need" \
		&& return 1

	trap "rm -f ${lock}" SIGINT
	if [ -n "${force}" -a -f "${lock}" ]; then
		cat ${lock} | xargs kill
		rm -f ${lock}
	fi
	echo $$ > ${lock}

    while [ "${times}" -gt "0" ];
    do
        up_down ${num} ${up} ${down} || return $1
        let 'times--'
    done

	rm -f ${lock}
}

loop $@
