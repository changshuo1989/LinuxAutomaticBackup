#!/bin/bash

#This is the script which is intended to creat one or more cron jobs for backups.
#This script will read configure file and add cron jobs to the crontab

#related files
ENCRYPTION_FILE=./encryption
CONFIG_FILE=./config

#encryption variables
PASSPHRASE="Unknown"
KEY="Unknown"

#config variables
CONFIG_NUM=8

#cronjobs
CRON_JOBS=()

#duplicity log file
LOG_DIR=/var/log/duplicity/
LOG_FILE=etc.log

# Ensure we are root
if [ ! "`whoami`" = "root" ]; then

	echo "Error: You must be root to run this script!";

	exit 1;

fi

#Ensure we have duplicity
if [ "`which duplicity`" = ""  ]; then
	echo "Error: You have to install duplicity to run this script!;"
	exit 1;
fi


#Ensure we have enryption file
if [ ! -f $ENCRYPTION_FILE ]; then
	echo "Error: encryption file not found!";
	exit 1;
fi

#Ensure we have config file
if [ ! -f $CONFIG_FILE ]; then
	echo "Error: config file not found!";
	exit 1;
fi

#Instruction
echo "
===============================================================================================================
||This script is used to backup important hrs files using duplicity and cron.                                ||
||Before run this script, please make sure you have manually deleted old or unnessary entries within crontab.||
||You can type crontab -l to see your current crontab and you can type crontab -e to edit your crontab.      ||
=============================================================================================================== ";    

read -p "Are you sure you have manually checked your crontab? [Y/N]" USER_RESPONSE
if echo $USER_RESPONSE | grep -iq Y; then
	:
else
	echo "Error: please check your crontab!";
	exit 1;
fi

#read encryption file
while read LINE
do 
	if [[ $LINE == PASSPHRASE* ]]; then
		IFS='=' read -a ENCRYPTION_ARRAY <<< "$LINE";
		if [ ${#ENCRYPTION_ARRAY[@]} == 2 ]; then
			#echo ${#ENCRYPTION_ARRAY[@]};
			#echo ${ENCRYPTION_ARRAY[1]}; 
			PASSPHRASE=${ENCRYPTION_ARRAY[1]};
	           	#echo $PASSPHRASE;
		fi
	elif [[ $LINE == KEY* ]]; then
		IFS='=' read -a ENCRYPTION_ARRAY <<< "$LINE";
		if [ ${#ENCRYPTION_ARRAY[@]} == 2 ]; then
			KEY=${ENCRYPTION_ARRAY[1]};
			#echo $KEY;	
		fi
	fi
done < $ENCRYPTION_FILE



#read config file
i=0;
while read LINE
do
	#configuration variables
	m="*";
	h="*";
	dom="*";
	mon="*";
	dow="*";
	local_folder="";
	backup_host="";
	backup_folder="";
	if [[ ! $LINE == \#* ]]; then
		#read variables from config file
		IFS=' ' read -a CONFIG_ARRAY <<< "$LINE";
		if [ ${#CONFIG_ARRAY[@]} == $CONFIG_NUM ]; then
			m=${CONFIG_ARRAY[0]};
			h=${CONFIG_ARRAY[1]};
			dom=${CONFIG_ARRAY[2]};
			mon=${CONFIG_ARRAY[3]};
			dow=${CONFIG_ARRAY[4]};
			local_folder=${CONFIG_ARRAY[5]};
			backup_host=${CONFIG_ARRAY[6]};
			backup_folder=${CONFIG_ARRAY[7]};
			#fomat cronjob
			dup="PASSPHRASE=\"${PASSPHRASE}\" $(which duplicity) --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} >> /var/log/duplicity/etc.log";
			
			cronjob="${m} ${h} ${dom} ${mon} ${dow} (${dup}) >/dev/null 2>&1";
			#echo "$cronjob";
			CRON_JOBS[$i]=${cronjob};
			#echo "${CRON_JOBS[$i]}";
			i=$((i+1));
		fi
			 	
	fi
done < $CONFIG_FILE

#copy crontab
crontab -l > mycron
#add these cronjobs to the crontab
for j in "${CRON_JOBS[@]}"
do
	echo "${j}" >> mycron
done
#install crontab
crontab mycron
#create log file for duplicity
mkdir -p ${LOG_DIR}
touch ${LOG_DIR}${LOG_FILE}
#delete temp crontab file
rm mycron
