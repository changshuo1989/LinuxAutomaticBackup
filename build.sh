#!/bin/bash

#This is the script which is intended to create one or more cron jobs for backups.
#This script will read configure file and add cron jobs to the crontab

#options
FILE_MODE=1
DATABASE_MODE=0

#related files
ENCRYPTION_FILE=./encryption
CONFIG_FILE=./config_file
CONFIG_DB=./config_db

#encryption variables
PASSPHRASE="Unknown"
KEY="Unknown"

#config variables
CONFIG_FILE_NUM=11

#cronjobs
CRON_JOBS=()

#scripts directory
SCRIPT_DIR=~/backups/

#temp crontab file
TEMP_CRONTAB=mycron

#duplicity log file
LOG_DIR=/var/log/duplicity/
LOG_FILE=etc.log



#functions
function writeIntoFile(){
	#get parameters
	content="$1"

	#create directory
	mkdir -p $SCRIPT_DIR
	#naming script file based on timestamp
	desdir=${SCRIPT_DIR}$(date +%Y-%m-%d_%H:%M:%S:%N).sh
	#echo "$desdir"
	touch ${desdir}
	if [ -f "$desdir" ]; then
		echo -e "$content" > ${desdir}
	fi
	
	#return value
	echo $desdir
}

function createLog(){
	#create log file for duplicity
	mkdir -p ${LOG_DIR}
	touch ${LOG_DIR}${LOG_FILE}
}


function copyCrontab(){
	crontab -l > ${TEMP_CRONTAB}
}


function addIntoCrontab(){
	#get parameters
	dir_name="$1" 
	#echo -e "$dir_name \n"
	sch="$2"
	#echo -e "$sch \n"
	temp_dir="$3"
	#echo -e "$temp_dir \n" 
	command="${sch} $(which bash) ${dir_name}"
	echo "${command}" >> ${temp_dir}
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

#Ensure we have bash
if [ "`which bash`" = "" ]; then
	echo "Error: You have to install bash to run this script!"
	exit 1;
fi

#Ensure we have duplicity
if [ "`which duplicity`" = ""  ]; then
	echo "Error: You have to install duplicity to run this script!"
	exit 1;
fi

#Ensure we have crontab
if [ "`which crontab`" = "" ]; then
	echo "Error: You have to install cron stuff to run this script!"
	exit 1;
fi

#Ensure we have enryption file
if [ ! -f $ENCRYPTION_FILE ]; then
	echo "Error: encryption file not found!";
	exit 1;
fi


#Instruction
INSTRUCTION="
===============================================================================================================
||This script is used to backup important hrs files using duplicity and cron.                                ||
||Before run this script, please make sure you have manually deleted old or unnessary entries within crontab.||
||You can type crontab -l to see your current crontab and you can type crontab -e to edit your crontab.      ||
===============================================================================================================
"

#get option
usage()
{
cat << EOF
usage:

$INSTRUCTION

OPTIONS:
-h	Show this message
-d	Backup database
-f	Backup regular files under folders
EOF
}
#parse command line args
while getopts "hdf" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1
		;;
		d)
			DATABASE_MODE=1
			FILE_MODE=0
		;;
		f)
			FILE_MODE=1
			DATABASE_MODE=0
		;;	
		?)
			usage
			exit 1
		;;
esac
done


if [ $FILE_MODE == 1 ] && [ $DATABASE_MODE == 0 ]; then
        #Ensure we have config file
        if [ ! -f $CONFIG_FILE ]; then
                echo "Error: config_file file not found!";
                exit 1;
        fi
elif [ $FILE_MODE == 0 ] && [ $DATABASE_MODE == 1 ]; then
        #Ensure we have config file
        if [ ! -f $CONFIG_DB ]; then
                echo "Error: config_db file not found!";
                exit 1;
        fi
else
        usage
        exit 1
fi


echo "$INSTRUCTION";
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


copyCrontab

if [ $FILE_MODE==1 ] && [ $DATABASE_MODE==0 ]; then 
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
		backup_type="";	
		backup_save="";
		time_save="";
		if [[ ! $LINE == \#* ]]; then
			#read variables from config file
			IFS=' ' read -a CONFIG_ARRAY <<< "$LINE";
			if [ ${#CONFIG_ARRAY[@]} == $CONFIG_FILE_NUM ]; then
				m=${CONFIG_ARRAY[0]};
				h=${CONFIG_ARRAY[1]};
				dom=${CONFIG_ARRAY[2]};
				mon=${CONFIG_ARRAY[3]};
				dow=${CONFIG_ARRAY[4]};
				local_folder=${CONFIG_ARRAY[5]};
				backup_host=${CONFIG_ARRAY[6]};
				backup_folder=${CONFIG_ARRAY[7]};
				backup_type=${CONFIG_ARRAY[8]};
				backup_save=${CONFIG_ARRAY[9]};
				time_save=${CONFIG_ARRAY[10]};
				#validate the backup_type
				if [[  "$backup_type" == i* ]] || [[ "$backup_type" == I* ]]; then
					backup_type="incremental";
				elif [[ "$backup_type" == f* ]] || [[ "$backup_type" == F* ]]; then		
					backup_type="full";	
				elif [ "$backup_type" == '*' ]; then
					backup_type="";
				else
					echo "Error: config file invalid!";
					exit 1;	
				fi
				
				has_backup_save=false
				has_time_save=false
				#validate the backup_save
				re='^[0-9]+$'
				if [[ "$backup_save" =~ $re ]]; then
					has_backup_save=true;
					#echo "$has_backup_save";

				elif [ "$backup_save" = '*' ]; then
				
					has_backup_save=false;
					#echo "$has_backup_save";
				else
					echo "Error: config file invalid!";
					exit 1;
				fi
				
				#validate the time_save
				
				if [ "$time_save" = '*' ]; then
					has_time_save=false;
				
				else
					has_time_save=true;
				fi
				
				
				#fomat script
				schedule="${m} ${h} ${dom} ${mon} ${dow}";
				head="#${schedule}\n#!/bin/bash\n";
				dup="export PASSPHRASE=\"${PASSPHRASE}\" \n$(which duplicity) ${backup_type} --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
				if [ "$has_backup_save" = true ]; then
					b="$(which duplicity) remove-all-but-n-full ${backup_save} --force sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
					dup=$dup'\n'$b;
					#echo  -e "$dup";
				fi

				if [ "$has_time_save" = true ]; then
					b="$(which duplicity) remove-older-than ${time_save} --force sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
					dup=$dup'\n'$b;
					#echo -e "$dup";		
				fi
				
				context=$head$dup;
				#echo -e "$context";
				dir=$(writeIntoFile "$context")
				addIntoCrontab "$dir" "$schedule" "$TEMP_CRONTAB"
				#echo $dir
				#cronjob="${m} ${h} ${dom} ${mon} ${dow} (${dup}) >/dev/null 2>&1";
				#writeIntoFile "$cronjob"
				#echo "$cronjob";
				#CRON_JOBS[$i]=${cronjob};
				#echo "${CRON_JOBS[$i]}";			
				i=$((i+1));

			else
				echo "Error: config file invalid!"
				exit 1
			fi
			 	
		fi
	done < $CONFIG_FILE

elif [ $FILE_MODE==0 ] && [ $DATABASE_MODE==1 ]; then

	




fi


createLog
loadCrontab

#TODO
#copy crontab
#crontab -l > mycron
#add these cronjobs to the crontab
#for j in "${CRON_JOBS[@]}"
#do
#	echo "${j}" >> mycron
#done
#install crontab
#crontab mycron
#create log file for duplicity
#mkdir -p ${LOG_DIR}
#touch ${LOG_DIR}${LOG_FILE}
#delete temp crontab file
#rm mycron
