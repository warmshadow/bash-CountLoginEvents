#!/bin/bash

init() {
    # yesterday's date
    fullDate=$(date -d "yesterday" +"%Y-%m-%d")
    year=$(date -d "yesterday" +"%Y")
    month=$(date -d "yesterday" +"%m")
    day=$(date -d "yesterday" +"%d")

    ### CHANGE THESE ACCORDINGLY ###
    # paths of log files
    LOGS="log/$year/$month/$day/UDC1.log
    log/$year/$month/$day/UDC2.log
    log/$year/$month/$day/UDC3.log"

    # paths of files with ip pools
    POOLS="pools/P01
    pools/P02
    pools/P03
    pools/P04
    pools/P05
    pools/P06
    pools/P07
    pools/P08"

    resultsDir="results"
    reportsDir="$resultsDir/$year/reports"
    shareDir="sharedir"
    mailRecipient="recipient@example.com"
    mailSubj="$year - $month logins report"
    mailBody="Previous month logins by group"

    if [ ! -d "$resultsDir" ]
    then
            mkdir $resultsDir
    fi

    if [ ! -d "$resultsDir/$year" ]
    then
            mkdir $resultsDir/$year
    fi

    if [ ! -d "$resultsDir/$year/$month" ]
    then
            mkdir $resultsDir/$year/$month
    fi

    if [ ! -d "$reportsDir" ]
    then
            mkdir $reportsDir
    fi
}

main(){
    # calls countMatches for each log file and each pool file
    # stores returned results in array
    declare -A resultArray
    l2=0
    p2=0
    for l in $LOGS
    do
        bzip2 -dk $l.bz2   ### CHANGE this line if different archive extension or REMOVE it if your log is not compressed
        for p in $POOLS
        do
            resultArray[$l2,$p2]=$(countMatches "$l" "$p")
            ((p2++))
        done
        rm $l
        ((l2++))
        p2=0
    done

    # for each pool sums the total number of results found in all log files combined 
    # and prints it to a pool's result file together with the date
    l2=0
    p2=0
    for p in $POOLS
    do
        sumDay=0
        for l in $LOGS
        do
            sumDay=$((sumDay + resultArray[$l2,$p2]))
            ((l2++))
        done
        prfile="$(basename -- $p)"
        touch $resultsDir/$year/$month/$prfile
        echo $fullDate >> $resultsDir/$year/$month/$prfile
        echo $sumDay >> $resultsDir/$year/$month/$prfile
        ((p2++))
        l2=0
    done

    # generates a report if today is start of new month
    today=$(date +"%d")
    if [ $today -eq 1 ]
    then
        generateReport
    fi
}

# checks the log file for matches of a specified pattern for every ip address from the file
# returns total number of occurences for all ip addressess in the pool
countMatches() {
	sum=0
    while IFS='' read -r LINE || [[ -n "$LINE" ]]; 
    do
        tmp=$(grep "success" $1 | grep "4768" | grep -v 'Account.Name:[A-Z]' | grep -v 'Account.Name:[a-z]' | grep -E 'Account.Name:[0-9]*' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep -ow $LINE | wc -l)
        sum=$((sum + tmp))
    done < $2
	echo $sum
}

# generates a report file with previous month results.
generateReport() {
    report="$reportsDir/$month"-report.csv""
    touch "$report"
    for p in $POOLS
    do
        prfile="$(basename -- $p)"
        poolMonth="$resultsDir/$year/$month/$prfile"
        sumMonth=0
        x=0
        while IFS='' read -r LINE || [[ -n "$LINE" ]];
        do
            ((x++))
            [ $((x%2)) -eq 0 ] && { sumMonth=$((sumMonth + LINE)); }
        done < $poolMonth
        echo  "$year.$month","$prfile","$sumMonth" >> "$report"
    done
    mailReport
    copyToShare
}

# sends the report via email
mailReport() {
	echo "$mailBody" | mutt -s "$mailSubj" "$mailRecipient" -a "$report"
}

# copies the report to shared directory
copyToShare() {
    if [ ! -d "$shareDir/$year" ]
    then
            mkdir $shareDir/$year
    fi
    cp $report $shareDir/$year
}

init
main
