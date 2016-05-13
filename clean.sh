#!/bin/bash
SETTINGS=./settings
SCRIPT_DIR=/root/backups/
LOG_DIR=/var/log/backups/
LOG_FILE=etc.log
SLOG_DIR=/var/log/backups/
SLOG_FILE=scripts.log

TEMP_CRONTAB=mycron



function copyCrontab(){
	crontab -l > ${TEMP_CRONTAB}
}

function removeFromCrontab(){
	f_name="$1"
	$(which sed) -i "/${f_name}/d" ${TEMP_CRONTAB}
}

function loadCrontab(){
	crontab ${TEMP_CRONTAB}
	rm -rf ${TEMP_CRONTAB}
}




# Ensure we are root
if [ ! "`whoami`" = "root" ]; then
	echo "Error: You must be root to run this script!";
	exit 1;
fi

#Ensure we have settings file
if [ ! -f $SETTINGS ]; then
        echo "Error: settings file not found!"
        exit 1
fi

#read settings file
while read LINE
do
        if [[ $LINE == SCRIPT_DIR* ]]; then
                IFS='=' read -a SCRIPT_DIR_ARRAY <<< "$LINE";
                if [ ${#SCRIPT_DIR_ARRAY[@]} == 2 ]; then
                        SCRIPT_DIR=${SCRIPT_DIR_ARRAY[1]};
			#echo "$SCRIPT_DIR"
                fi
        elif [[ $LINE == LOG_DIR* ]]; then
                IFS='=' read -a LOG_DIR_ARRAY <<< "$LINE";
                if [ ${#LOG_DIR_ARRAY[@]} == 2 ]; then
                        LOG_DIR=${LOG_DIR_ARRAY[1]};
			#echo "$LOG_DIR"
                fi
        elif [[ $LINE == LOG_FILE* ]]; then
                IFS='=' read -a LOG_FILE_ARRAY <<< "$LINE";
                if [ ${#LOG_FILE_ARRAY[@]} == 2 ]; then
                        LOG_FILE=${LOG_FILE_ARRAY[1]};
			#echo "$LOG_FILE"
                fi
        elif [[ $LINE == SLOG_DIR* ]]; then
                IFS='=' read -a SLOG_DIR_ARRAY <<< "$LINE";
                if [ ${#SLOG_DIR_ARRAY[@]} == 2 ]; then
                        SLOG_DIR=${SLOG_DIR_ARRAY[1]};
			#echo "$SLOG_DIR"
                fi
        elif [[ $LINE == SLOG_FILE* ]]; then
                IFS='=' read -a SLOG_FILE_ARRAY <<< "$LINE";
                if [ ${#SLOG_FILE_ARRAY[@]} == 2 ]; then
                        SLOG_FILE=${SLOG_FILE_ARRAY[1]};
			#echo "$SLOG_FILE"
                fi
        fi
done < $SETTINGS

echo -e "folders and files are:\nSCRIPT_DIR=${SCRIPT_DIR}\nLOG_DIR=${LOG_DIR}\nLOG_FILE=${LOG_FILE}\nSLOG_DIR=${SLOG_DIR}\nSLOG_FILE=${SLOG_FILE}"
read -p "Are you sure you have checked those folder and files? [Y/N]" USER_RESPONSE
if echo $USER_RESPONSE | grep -iq Y; then
	:
else
	echo "Please check these folders and files to see if there is anything important you want to keep!"
	exit 1;
fi


copyCrontab
#find all the script names to delete them in the crontab
for entry in "$SCRIPT_DIR"/*
do
	file_name=${entry##*/}
	removeFromCrontab "$file_name"
done
loadCrontab


#remove script files and logs
$(which rm) -rf ${SCRIPT_DIR}
$(which rm) ${LOG_DIR}/${LOG_FILE}
$(which rm) ${SLOG_DIR}/${SLOG_FILE}
