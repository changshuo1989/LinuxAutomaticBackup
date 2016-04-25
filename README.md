Before run this script please manually check several things
1. check the crontab (type crontab -e)
2. check the place where store the sscripts( default under /root/backups/)
3. check the log file(default under /var/log/duplicity/etc.log)

Secondly, the -t, --time, and --restore-time options take a time string, which can be given in any of several formats:

1.
the string "now" (refers to the current time)
2.
a sequences of digits, like "123456890" (indicating the time in seconds after the epoch)
3.
A string like "2002-01-25T07:00:00+02:00" in datetime format
4.
An interval, which is a number followed by one of the characters s, m, h, D, W, M, or Y (indicating seconds, minutes, hours, days, weeks, months, or years respectively), or a series of such pairs. In this case the string refers to the time that preceded the current time by the length of the interval. For instance, "1h78m" indicates the time that was one hour and 78 minutes ago. The calendar here is unsophisticated: a month is always 30 days, a year is always 365 days, and a day is always 86400 seconds.
5.
A date format of the form YYYY/MM/DD, YYYY-MM-DD, MM/DD/YYYY, or MM-DD-YYYY, which indicates midnight on the day in question, relative to the current time zone settings. For instance, "2002/3/5", "03-05-2002", and "2002-3-05" all mean March 5th, 2002.

