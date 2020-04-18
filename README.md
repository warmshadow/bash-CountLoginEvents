# bash-countLoginEvents
Checking the number of domain logins from groups of computers in a windows network by matching successful Windows Security ID 4768 events.

## Info
This script was made to check how many times users have logged in from specific groups of computers (e.g. classrooms), calculating separately for each group.\
Made to run as a daily cron job for counting and saving the number of yesterday's login events by checking previous day domain controller logs. Results are saved to files representing each IP pool's results.\
When full month ends it generates a report with total numbers which is copied to a shared directory and sent via email (using *mutt*).

This version was made for the environment with numeric domain usernames and 3 windows domain controllers with their logs synced to Ubuntu server.

Using grep to find ID **4768** events with status **success** from specified **IPs** and numeric account names like **52469**.\
Log files are stored by date and compressed - *log/2020/04/20/UDC.log.bz2*\
Pool files with *IPv4* addresses line by line
## Apply to your needs
Change variables inside init() function to your file paths and email information.

Change or remove log file decompression line.

Or use only part of the code you need!

## LICENSE
MIT
