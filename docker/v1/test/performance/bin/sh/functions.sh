#!/bin/bash

EXEBASE=$(basename $0 | sed -e's/\.sh$//')
EXEBASELC=$(echo ${EXEBASE} | tr '[:upper:]' '[:lower:]')
EXEBASEUC=$(echo ${EXEBASE} | tr '[:lower:]' '[:upper:]')
EXEBASETC=$(echo ${EXEBASELC} | tr '-' ' ' | sed -r 's/\<./\U&/g')
sar_pid="NONE"
mysql_pid="NONE"

MYSQL_USER="root"
MYSQL_PASSWORD="xxxxx"
MYSQL_HOST="sql2"
MYSQL_DATABASE="CLONEID"
TABLE_NAME="Passaging"

LOGDIR="log/${EXEBASELC}"
mkdir -p $LOGDIR
trap 'kill -9 $sar_pid $mysql_pid; exit 1' SIGINT

LOOP=1
trap 'LOOP=0;' SIGUSR1
NEXTSTART=0

export CLONEID_MODULE3_PERFORMANCE_TEST_DIR=/data/lake/cloneid/module3/test/performance
export CLONEID_MODULE3_PERFORMANCE_TEST_REFERENCE=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/bin/sh/reference.sh
export CLONEID_MODULE3_PERFORMANCE_TEST_UNIT1=${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/bin/sh/unit-test-1.sh

collect_mysql_data() {
	local status=$1
	local log_prefix=$2
	local mysql_log="${log_prefix}.mysql.log"
	local mysql_uniq_log="${log_prefix}.mysql.uniq.log"

	case $status in
	"start")
		if [ $mysql_pid == "NONE" ]; then
			echo "Starting mysql data collection..."
			record_statements "$2" 2>&1 >"${LOGDIR}/${mysql_log}" &
			mysql_pid=$!
			echo "Mysql data collection started with pid: '${mysql_pid}'"
			sleep 10
		fi
		;;
	"stop")
		if [ $mysql_pid != "NONE" ]; then
			sleep 10
			echo "Stopping mysql data collection..."
			kill -s SIGUSR1 $mysql_pid
			sleep 3
			mysql_pid="NONE"
			sort "${LOGDIR}/${mysql_log}" | uniq -c | sort -rn >"${LOGDIR}/${mysql_uniq_log}"
		fi
		;;
	esac
}

collect_sar_data() {
	local status=$1
	local log_prefix=$2
	local sar_log="${log_prefix}.sar.log"

	case $status in

	"start")
		if [ $sar_pid == "NONE" ]; then
			echo "Starting sar data collection..." | tee "${LOGDIR}/${sar_log}"
			vmstat -SM -anwt 1 9999 2>&1 |
				sed -e 's/--.*--$//' \
					-e 's/-\([0-9][0-9]\)-\([0-9][0-9]\) \([0-9][0-9]\):\([0-9][0-9]\):/\1\2\3\4/g' \
					-e 's/ \{1,\}/ /g' \
					-e 's/ /\t/g' >>"${LOGDIR}/${sar_log}" &
			sar_pid=$(pidof vmstat)
			echo "Sar data collection started with pid: '${sar_pid}'"
			sleep 10
		fi
		;;

	"stop")
		if [ $sar_pid != "NONE" ]; then
			sleep 10
			killall vmstat
			sar_pid="NONE"
			echo "Finished sar data collection." | tee -a "${LOGDIR}/${sar_log}"
		fi
		;;

	esac

}

run_rscript() {
	local collect=$1 ; shift
	local script=$1	; shift
	local log=./${1}.log

	if [ $collect == "collect" ]; then
		collect_sar_data "start" "$1"
		collect_mysql_data "start" "$1"
	else
		echo -e "No activity collection\n"
	fi

	local RSCRIPT="bin/R/${script}/m3.R"

	local CWD=$(pwd)
	cd ${LOGDIR} &&
		(
			echo -n "$(echo ${script} | tr '[:lower:]' '[:upper:]')   $i : "
			echo -e "\nLaunching : Rscript --vanilla ${RSCRIPT}"
			date
			echo -e "####################################################################\n\n"
			TIMESTAMPSTART=$(date +%s)
			time Rscript --vanilla "${CLONEID_MODULE3_PERFORMANCE_TEST_DIR}/${RSCRIPT}"
			TIMESTAMPSTOP=$(date +%s)
			TIMESTAMPDIFF=$((TIMESTAMPSTOP - TIMESTAMPSTART))

			MINUTES=$((TIMESTAMPDIFF / 60))
			SECONDS=$((TIMESTAMPDIFF % 60))

			echo -e "\n\n####################################################################"
			date
			echo "Time taken: ${MINUTES} minutes and ${SECONDS} seconds"
			echo -e "Exited : Rscript --vanilla ${RSCRIPT}\n"
		) | tee -a "${log}"
	cd ${CWD}

	if [ $collect == "collect" ]; then
		collect_mysql_data "stop" "$1"
		collect_sar_data "stop" "$1"
	fi
}

fetch_and_log_queries() {
	local HISTORY=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE -e "SELECT STATEMENT_ID, sql_text FROM performance_schema.events_statements_history WHERE STATEMENT_ID>$NEXTSTART AND current_schema='CLONEID' AND event_name='statement/sql/select' ORDER BY STATEMENT_ID ASC;" | tail +2)
	[ -z "$HISTORY" ] && return
	local NEWSTART=$(echo "$HISTORY" | tail -1 | awk 'NR==1 {print $1}')
	if [ ! -z "$NEWSTART" ] && [ "$NEWSTART" -gt "$NEXTSTART" ]; then
		NEXTSTART=$NEWSTART
	fi
	echo "$HISTORY" | tee -a $OUTPUT_FILE | cut -f2,999
}

record_statements() {
	local OUTPUT_FILE="${LOGDIR}/queries.log"

	if [ $# -lt 1 ]; then
		echo "Usage: $0 output file"
	else
		OUTPUT_FILE="${LOGDIR}/$1.queries.log"
	fi

	while [ $LOOP == 1 ]; do
		fetch_and_log_queries
		sleep 1
	done
}

downcount() {
	echo $1 exiting...
	TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
	DOWNCOUNT=5
	while [ $DOWNCOUNT -gt 0 ]; do
		sleep 1s
		DOWNCOUNT=$(($DOWNCOUNT - 1))
		echo $1 exiting in $DOWNCOUNT
	done

	if [ $# -eq 2 ]; then
		if [ "$2" == "exit" ]; then
			exit 0
		fi
	fi

	sleep infinity
}

startup() {
	ifconfig
}

process_unit() {
	local COLLECT="collect"
	if [ $# -gt 0 ]; then
		COLLECT=$1
	fi
	LOOPINDEX=0
	LOOPCOUNT=1
	while [ "$LOOPINDEX" -lt "$LOOPCOUNT" ]; do
		LOOPINDEX=$((LOOPINDEX + 1))

		local TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)

		local LOGENTRY=${TIMESTAMP}-${EXEBASELC}-${LOOPINDEX}

		run_rscript "${COLLECT}" "${EXEBASELC}" "${LOGENTRY}"

		echo $EXEBASETC 10s DB cooldown
		sleep 10
	done

	downcount "${EXEBASETC}" exit
}
