==================================================================
BEFORE RUN THIS SCRIPT
==================================================================		
1. Make sure you are using Ubuntu server or similar linux version
2. Install necessary software in advance. however if you miss some vital software, this script will give you a hint(duplicity, cron, etc)
3. Generate ssh key for root user, and use ssh-copy-id command to pass this key to the backup side to enable password free ssh
4. Generate gng key for data encryption/decryption and remember the passphrase and public key


=================================================================
CONFIGURATION
=================================================================
Note:
1. All directories should be absolute pathes
2. No space for each configuration variable
3. For 1-5 variables, please follow cron schedule rules
4. For 13 in config_file and 17 in config_db please follow time format rule
5. Some of variabes can be N/A, should be assgined as *
6. If you want to have the full backup monitoring system work, you should assign interval and remote log file variables

This script accepts two types of configuration file for two types of backup mode:
1. config_file:
  1. m: cron schedule variable
  2. h: cron schedule variable
  3. dom: cron schedule variable
  4. mon: cron schedule variable
  5. dow: cron schedule variable
  6. interval minutes: approximate minutes from one backup to another same backup *
  7. local folder: folder that need to be backup
  8. backup host: remote backup host
  9. backup folder: folder taht store these backup files
  10. remote log file: remote absolute path of the file which is used to store log *
  11. backup type: full, increment, default *
  12. full backup versions save in the backup host: versions number *
  13. time of backup sets save in the backup host: time format  * (TIME_FORMAT)

2. config_db:
  1. m: same above
  2. h: same above
  3. dom: same above
  4. mon: same above
  5. dow: same above
  6. interval minutes: same above *
  7. database host: host of mysql database
  8. database username: username of database
  9. database password: password of database
  10. databasename: databasename *
  11. local folder(used to store dump file): can be empty
  12. backup host: same above
  13. backup folder: same above
  14. remote log file: same above *
  15. backup type: same above *
  16. full backup versions save in the backup host: same above *
  17. time of backup sets in the backup host: same above * (TIME_FORMAT)
  18. minutes that the previous dump file save: same above *
	
==============================================================
RERUN THIS SCRIPT	
==============================================================
1. check the crontab (type crontab -e)
2. check the place where store the scripts( default under /root/backups/)
3. check the log file(default under /var/log/backups/etc.log)
4. check the log file for script status(default under /var/log/backups/scripts.log)
4. if you run this script with database mode(-d), please check the folder that you assign in the config_db file for storing the db dump files.




=============================================================
TIME FORMAT
=============================================================
time_format:

1. the string "now" (refers to the current time)
2. a sequences of digits, like "123456890" (indicating the time in seconds after the epoch)
3. A string like "2002-01-25T07:00:00+02:00" in datetime format
4. An interval, which is a number followed by one of the characters s, m, h, D, W, M, or Y (indicating seconds, minutes, hours, days, weeks, months, or years respectively), or a series of such pairs. In this case the string refers to the time that preceded the current time by the length of the interval. For instance, "1h78m" indicates the time that was one hour and 78 minutes ago. The calendar here is unsophisticated: a month is always 30 days, a year is always 365 days, and a day is always 86400 seconds.
5. A date format of the form YYYY/MM/DD, YYYY-MM-DD, MM/DD/YYYY, or MM-DD-YYYY, which indicates midnight on the day in question, relative to the current time zone settings. For instance, "2002/3/5", "03-05-2002", and "2002-3-05" all mean March 5th, 2002.
		 
