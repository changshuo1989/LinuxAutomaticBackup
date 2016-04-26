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
CONFIG_FILE_NUM=13
CONFIG_DB_NUM=18
#cronjobs
CRON_JOBS=()

#scripts directory
SCRIPT_DIR=~/backups/

#mysql dump main directory
#DUMP_DIR=~/mysqldump/

#temp crontab file
TEMP_CRONTAB=mycron

#temp log file
TEMP_LOG=log

#duplicity log dirctroy(remote) and file
LOG_DIR=/var/log/duplicity/
LOG_FILE=etc.log


#functions
function writeIntoFile(){
	#get parameters
	content="$1"

	#create directory
	mkdir -p $SCRIPT_DIR
	#naming script file based on timestamp
	desdir=${SCRIPT_DIR}$(date +%Y-%m-%d-%H-%M-%S-%N).sh
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


function validateBackupType(){
	type="$1"
	if [[  "$ype" == i* ]] || [[ "$type" == I* ]]; then
		echo "incremental";
	elif [[ "$type" == f* ]] || [[ "$type" == F* ]]; then		
		echo "full";	
	elif [ "$type" == '*' ]; then
		echo "";
	else
		echo "ERROR";
	fi
}

function validateBackupSave(){
	b_save="$1"
	re='^[0-9]+$'
        if [[ "$b_save" =~ $re ]]; then
        	echo "true"

       	elif [ "$b_save" = '*' ]; then
              	echo "false"
                #echo "$has_backup_save";
        else
       		echo "ERROR"
        fi
}

function validateTimeSave(){
	t_save="$1"
	if [ "$t_save" = '*' ]; then
		echo "false"
	else
		echo "true"
	fi

}

function setDBDumpDirectory(){
	host="$1"
	DUMP_DIR="$2"
	spec_dir="${DUMP_DIR}/${host}/"
	mkdir -p $spec_dir
	#return variable
	echo "$spec_dir"
}

function setDBDumpFile(){
	host_dir="$1"
	des_file=${host_dir}$(date +%Y-%m-%d-%H-%M-%S-%N).sql
	touch ${des_file}
	#return variable
	echo ${des_file}

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


if [ "$FILE_MODE" = 1 ] && [ "$DATABASE_MODE" = 0 ]; then
        #Ensure we have config file
        if [ ! -f $CONFIG_FILE ]; then
                echo "Error: config_file file not found!";
                exit 1;
        fi
elif [ "$FILE_MODE" = 0 ] && [ "$DATABASE_MODE" = 1 ]; then
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

if [ "$FILE_MODE" = 1 ] && [ "$DATABASE_MODE" = 0 ]; then 
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
		interval="*";
		local_folder="";
		backup_host="";
		backup_folder="";
		remote_log_dir="*";
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
				interval=${CONFIG_ARRAY[5]};
				local_folder=${CONFIG_ARRAY[6]};
				backup_host=${CONFIG_ARRAY[7]};
				backup_folder=${CONFIG_ARRAY[8]};
				remote_log_dir=${CONFIG_ARRAY[9]};
				backup_type=${CONFIG_ARRAY[10]};
				backup_save=${CONFIG_ARRAY[11]};
				time_save=${CONFIG_ARRAY[12]};
				#validate the backup_type
                                backup_type=$(validateBackupType "$backup_type")
                                if [ "$backup_type" = "ERROR" ]; then
                                        echo "Error: config file invalid!"
                                        exit 1
                                fi
				
				#backup_save
                                has_backup_save=$(validateBackupSave "$backup_save")
                                if [ "$has_backup_save" = "ERROR" ]; then
                                        echo "ERROR: config file invalid!"
                                        exit 1
                                fi
                                #time_save
                                has_time_save=$(validateTimeSave "$time_save")
                                if [ "$has_time_save" = "ERROR" ]; then
                                        echo "ERROR: config file invalid!"
                                        exit 1
                                fi
				#interval
				has_interval=$(validateBackupSave "$interval")
				if [ "$has_interval" = "ERROR" ]; then
					echo "ERROR: config file invalid!"
					exit 1
					
				fi
				
				#format script
				schedule="${m} ${h} ${dom} ${mon} ${dow}";
				head="#${schedule}\n#!/bin/bash\n";
				dup="";
				if [ "$remote_log_dir" != '*' ]; then
				
					dup="export PASSPHRASE=\"${PASSPHRASE}\" \n$(which duplicity) ${backup_type} --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} > ${TEMP_LOG}";
					#add into log
					#cat ${TEMP_LOG} >> ${LOG_DIR}${LOG_FILE}
					temp_log="$(which cat) ${TEMP_LOG} >> ${LOG_DIR}${LOG_FILE}"
					if [ "$has_interval" = true ]; then
						temp_interval="$(which echo) \"Interval ${interval}\" >> ${TEMP_LOG}"
						temp_log=$temp_log'\n'$temp_interval
					fi
					
					dup=$dup'\n'$temp_log
					#log_dup="$(which duplicity) full --no-encryption ${TEMP_LOG} sftp://${backup_host}/${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \n$(which duplicity) remove-all-but-n-full 1 --force sftp://${backup_host}/${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \nrm -rf ${TEMP_LOG}";
					#dup=$dup'\n'$log_dup
					log_copy="$(which scp) ${TEMP_LOG} ${backup_host}:${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \nrm -rf ${TEMP_LOG} ";
					dup=$dup'\n'$log_copy		

				else
					dup="export PASSPHRASE=\"${PASSPHRASE}\" \n$(which duplicity) ${backup_type} --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";

				fi

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

#database version
elif [ "$FILE_MODE" = 0 ] && [ "$DATABASE_MODE" == 1 ]; then
	#read config file
	j=0;
	while read LINE
	do
		#configuration variables
		m="*"
		h="*"
		dom="*"
		mon="*"
		dow="*"
		interval="*"
		db_host=""
		user_name=""
		password=""
		dbname=""
		local_folder=""
		backup_host=""
		backup_folder=""
		remote_log_dir=""
		backup_type=""
		backup_save=""
		time_save=""	
		if [[ ! $LINE == \#* ]]; then
			IFS=' ' read -a DB_ARRAY <<< "$LINE";
			if [ ${#DB_ARRAY[@]} == $CONFIG_DB_NUM ]; then
				m=${DB_ARRAY[0]};
				h=${DB_ARRAY[1]};
				dom=${DB_ARRAY[2]};
				mon=${DB_ARRAY[3]};
				dow=${DB_ARRAY[4]};
				interval=${DB_ARRAY[5]};
				db_host=${DB_ARRAY[6]};
				user_name=${DB_ARRAY[7]};
				password=${DB_ARRAY[8]};
				dbname=${DB_ARRAY[9]};
				local_folder=${DB_ARRAY[10]};
				backup_host=${DB_ARRAY[11]};
				backup_folder=${DB_ARRAY[12]};
				remote_log_dir=${DB_ARRAY[13]};
				backup_type=${DB_ARRAY[14]};
				backup_save=${DB_ARRAY[15]};
				time_save=${DB_ARRAY[16]};
				dump_save=${DB_ARRAY[17]};
				#TODO:need to finish database
				#validate these variables
				#db_host
				if [ "$db_host" = '*' ]; then
					db_host="localhost"
				fi
				#db user name
				if [ "$user_name" = '*' ]; then 
					echo "Error: invalid database username!"
					exit 1
				fi
				#db password
				if [ "$password" = '*' ]; then
					password=""
				fi
				#backup_type
				backup_type=$(validateBackupType "$backup_type")
				if [ "$backup_type" = "ERROR" ]; then
					echo "Error: db config file invalid!"
					exit 1
				fi
				#backup_save
				has_backup_save=$(validateBackupSave "$backup_save")
				if [ "$has_backup_save" = "ERROR" ]; then
					echo "ERROR: dbconfig file invalid!"
					exit 1
				fi
				#time_save
				has_time_save=$(validateTimeSave "$time_save")
				if [ "$has_time_save" = "ERROR" ]; then
					echo "ERROR: dbconfig file invalid!"
					exit 1
				fi
				#dump_save
				has_dump_save=$(validateBackupSave "$dump_save")
				if [ "$has_dump_save" = "ERROR" ]; then
					echo "ERROR: dbconfig file invalid!"		
					exit 1
				fi
				#interval
                                has_interval=$(validateBackupSave "$interval")
                                if [ "$has_interval" = "ERROR" ]; then
                                        echo "ERROR: config file invalid!"
                                        exit 1

                                fi

				#validate mysql connection
				echo "validate mysql connection..."
				if [ "$dbname" = '*' ]; then
					if ! mysql -u$user_name -p$password -h$db_host -e ";" ; then
						echo "Error: cannot connect to mysql!"
						exit 1
					else
						echo "success!"
					fi 
				else
					if ! mysql -u$user_name -p$password -h$db_host -e "use ${dbname}" ; then
						echo "Error: cannot connect to mysql!"
						exit 1
					else 
						echo "success!"
					fi
				fi
				#create or use local folder
				mkdir -p ${local_folder}
				#format script
				schedule="${m} ${h} ${dom} ${mon} ${dow}";
				head="#${schedule}\n#!/bin/bash";
				
				#db dump part
				#set up directory and file
				dump_dir=$(setDBDumpDirectory "$db_host" "$local_folder")
				#dump_file=$(setDBDumpFile "$dump_dir")				
				#dump_file="des_file=${dump_dir}'$(date +%Y-%m-%d-%H-%M-%S-%N).sql'\n touch '$des_file'"				
				dump_file_name='$(date +%Y-%m-%d-%H-%M-%S-%N).sql'
				dump_file_variable='$des_file'
				dump_file="des_file=${dump_dir}${dump_file_name}\ntouch ${dump_file_variable}"				

				dump=""
				if [ "$dbname" = '*' ]; then
					dump="$(which mysqldump) -u${user_name} -p${password} -h${db_host} --all-databases > ${dump_file_variable}"
				else
					dump="$(which mysqldump) -u${user_name} -p${password} -h${db_host} ${dbname} > ${dump_file_variable}"
				fi

				#remove previous files(based on days)
				if [ "$has_dump_save" = true ]; then 
					remove_old_dumps="$(which find) ${dump_dir}* -mmin +${dump_save} -type f -delete"
					dump=$remove_old_dumps' \n'$dump
				fi
				#duplicity part
				dup=""
				if [ "$remote_log_dir" != '*' ]; then
					dup="export PASSPHRASE=\"${PASSPHRASE}\" \n$(which duplicity) ${backup_type} --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} > ${TEMP_LOG}";
					#add into log
                                        #cat ${TEMP_LOG} >> ${LOG_DIR}${LOG_FILE}
                                        temp_log="$(which cat) ${TEMP_LOG} >> ${LOG_DIR}${LOG_FILE}"
                                        if [ "$has_interval" = true ]; then
                                                temp_interval="$(which echo) \"Interval ${interval}\" >> ${TEMP_LOG}"
                                                temp_log=$temp_log'\n'$temp_interval
                                        fi
					dup=$dup'\n'$temp_log
                                        #log_dup="$(which duplicity) full --no-encryption ${TEMP_LOG} sftp://${backup_host}/${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \n$(which duplicity) remove-all-but-n-full 1 --force sftp://${backup_host}/${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \nrm -rf ${TEMP_LOG}";
                                        #dup=$dup'\n'$log_dup
                                        log_copy="$(which scp) ${TEMP_LOG} ${backup_host}:${remote_log_dir} >> ${LOG_DIR}${LOG_FILE} \nrm -rf ${TEMP_LOG} ";
                                        dup=$dup'\n'$log_copy
				else
					dup="export PASSPHRASE=\"${PASSPHRASE}\" \n$(which duplicity) ${backup_type} --encrypt-key ${KEY} ${local_folder} sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
				fi
				if [ "$has_backup_save" = true ]; then
					b="$(which duplicity) remove-all-but-n-full ${backup_save} --force sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
					dup=$dup'\n'$b;
				fi


				if [ "$has_time_save" = true ]; then
					b="$(which duplicity) remove-older-than ${time_save} --force sftp://${backup_host}/${backup_folder} >> ${LOG_DIR}${LOG_FILE}";
					dup=$dup'\n'$b;
					#echo -e "$dup";
				fi
				context=$head'\n'$dump_file'\n'$dump'\n'$dup;
				#echo -e "$context"
				dir=$(writeIntoFile "$context")
				addIntoCrontab "$dir" "$schedule" "$TEMP_CRONTAB"
				j=$((j+1));
			else
                                echo "Error: db config file invalid!"
                                exit 1
	
			fi
		fi

	done < $CONFIG_DB

fi


createLog
loadCrontab

#TODO
#copy crontab
#crontab -l > mycron
#add these cronjobs to the crontab
#for j in "${CRON_JOBS[@]}"
#do
#echo "${j}" >> mycron
#done
#install crontab
#crontab mycron
#create log file for duplicity
#mkdir -p ${LOG_DIR}
#touch ${LOG_DIR}${LOG_FILE}
#delete temp crontab file
#rm mycron
