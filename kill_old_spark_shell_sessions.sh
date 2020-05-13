#!/bin/bash


DATE=$(date '+%Y-%m-%d-%H-%M-%S')
logfile=/opt/mapr/logs/managedservices/$(basename $0).log.${DATE}
killedsessionlog=/opt/mapr/logs/managedservices/$(basename $0).killed.log
mkdir -p $(dirname $logfile)
echo "----------" >> $logfile
current_epoch=$(date +%s)

#Please set the correct allowed_duration_in_seconds.  To be safe, select one.
#24 hours
allowed_duration_in_seconds=86400
#12 hours
#allowed_duration_in_seconds=43200
#1 hour
#allowed_duration_in_seconds=3600
#60 seconds
#allowed_duration_in_seconds=60


print_var(){
  echo "----------" >> $logfile
  echo "${1}:" >> $logfile
  echo "${2}" >> $logfile
  echo "${3}" >> $logfile
}

yarnapplist=$(yarn application -list)
print_var yarnapplist "$yarnapplist"

#spark_shells=$(echo "$yarnapplist" | grep "Spark shell" | grep SPARK | awk '{print $1}')
spark_shells=$(echo "$yarnapplist" | grep TEZ | awk '{print $1}')
print_var spark_shells "$spark_shells"

for session in $spark_shells
  do
  echo "Session: $session" >> $logfile
  session_stat=$(yarn application -status $session)
  echo "session stat               : ${session_stat}" >> $logfile
  session_start_time=$(echo "${session_stat}" | grep "Start-Time" | cut -d: -f2 | sed -e 's/ //g')
  echo "session_start_time         : ${session_start_time}" >> $logfile
  session_user=$(echo "${session_stat}" | grep "User" | cut -d: -f2 | sed -e 's/ //g')
  echo "session_user               : ${session_user}" >> $logfile
  session_start_epoch=${session_start_time::-3}
  echo "session_start_epoch: $session_start_epoch" >> $logfile
  echo "current_epoch              : $current_epoch" >> $logfile
  running_duration_in_seconds=$(expr $current_epoch - $session_start_epoch)
  echo "running_duration_in_seconds: $running_duration_in_seconds" >> $logfile
  echo "allowed_duration_in_seconds: $allowed_duration_in_seconds" >> $logfile
  if [ "$running_duration_in_seconds" -gt "$allowed_duration_in_seconds" ]; then
    echo "$(date '+%Y-%m-%d-%H-%M-%S'): Session $session for user $session_user is killed.  It has been running for $running_duration_in_seconds seconds which is over the allowed duration of $allowed_duration_in_seconds seconds" >> $logfile
    echo "$(date '+%Y-%m-%d-%H-%M-%S'): Session $session for user $session_user is killed.  It has been running for $running_duration_in_seconds seconds which is over the allowed duration of $allowed_duration_in_seconds seconds" >> $killedsessionlog
    yarn application -kill $session
  else
    echo "$(date '+%Y-%m-%d-%H-%M-%S'): Session $session for user $session_user remains.  It has been running for $running_duration_in_seconds seconds which is within the allowed duration of $allowed_duration_in_seconds seconds" >> $logfile
  echo "----------" >> $logfile
  fi
done




#find /mapr/mscluster1.ps.lab/im_dva ! -path '*/claims*'  -printf '%m\t%u\t%g\t%p\0\n'
#find /mapr/mscluster1.ps.lab/im_dva -path */claims* -prune -o  -printf '%m\t%u\t%g\t%p\0\n'
#find /mapr/mscluster1.ps.lab/im_dva \( -path */claims* -o -path */corporate* \) -prune -o  -printf '%m\t%u\t%g\t%p\0\n'

#find  /mapr/mscluster1.ps.lab/im_dva -type d  -printf '%m\t%u\t%g\t%p\0\n'
#find  /mapr/mscluster1.ps.lab/test1 -type d -not -perm 3777 -printf '%m\t%u\t%g\t%p\0\n'

#hadoop mfs -getace -R /mapr/mscluster1.ps.lab//im_dva/etl/claims
#hadoop mfs -stat /mapr/mscluster1.ps.lab//im_dva/etl/claims

#find /mapr/icbc.cluster.com/im_sya '(' -path '*/hr*' -o -path '*/siu*' ')' -prune -o -type d -perm 3775 -o -printf '%m\t%u\t%g\t%p\0\n'
